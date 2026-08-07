"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

import { getAdminGuardianDetail } from "../data/get-admin-guardian-detail";
import { getAdminGuardianLoginIdentity } from "../data/get-admin-guardian-login-identity";
import { guardianAccountCreateSchema } from "../schemas/guardian-account-create-schema";
import type { GuardianAccountActionState } from "../types/guardian-account-action-state";

const guardianIdSchema =
  z.string().uuid();

function mapCreateAuthError(
  message: string,
): string {
  const normalizedMessage =
    message.toLowerCase();

  if (
    normalizedMessage.includes(
      "already",
    ) ||
    normalizedMessage.includes(
      "exists",
    ) ||
    normalizedMessage.includes(
      "registered",
    )
  ) {
    return (
      "ID Pengguna tersebut sudah mempunyai " +
      "akun Auth. Muat ulang halaman dan coba kembali."
    );
  }

  if (
    normalizedMessage.includes(
      "password",
    )
  ) {
    return (
      "Password ditolak oleh Supabase Auth: " +
      message
    );
  }

  return (
    "Gagal membuat akun Auth: " +
    message
  );
}

export async function createAdminGuardianAccount(
  guardianId: string,
  previousState:
    GuardianAccountActionState,
  formData: FormData,
): Promise<GuardianAccountActionState> {
  void previousState;

  await requireRole("admin");

  const guardianIdValidation =
    guardianIdSchema.safeParse(
      guardianId,
    );

  if (!guardianIdValidation.success) {
    return {
      status: "error",
      message: "ID wali tidak valid.",
      fieldErrors: {},
    };
  }

  const values = {
    password: String(
      formData.get("password") ?? "",
    ),

    password_confirmation: String(
      formData.get(
        "password_confirmation",
      ) ?? "",
    ),
  };

  const validationResult =
    guardianAccountCreateSchema.safeParse(
      values,
    );

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Periksa kembali password akun wali.",

      fieldErrors:
        validationResult.error.flatten()
          .fieldErrors,
    };
  }

  let guardianDetail;

  try {
    guardianDetail =
      await getAdminGuardianDetail(
        guardianIdValidation.data,
      );
  } catch (error) {
    console.error(
      "Gagal memeriksa data wali:",
      error,
    );

    return {
      status: "error",
      message:
        "Gagal memeriksa data wali.",
      fieldErrors: {},
    };
  }

  if (!guardianDetail) {
    return {
      status: "error",
      message:
        "Data wali tidak ditemukan.",
      fieldErrors: {},
    };
  }

  const guardian =
    guardianDetail.guardian;

  if (!guardian.is_active) {
    return {
      status: "error",

      message:
        "Wali tidak aktif tidak dapat dibuatkan akun.",

      fieldErrors: {},
    };
  }

  if (guardianDetail.account.linked) {
    return {
      status: "error",

      message:
        "Wali sudah mempunyai akun login.",

      fieldErrors: {},
    };
  }

  if (
    guardianDetail.summary
      .children_count === 0
  ) {
    return {
      status: "error",

      message:
        "Hubungkan wali dengan minimal satu santri sebelum membuat akun.",

      fieldErrors: {},
    };
  }

  let loginIdentity;

  try {
    loginIdentity =
      await getAdminGuardianLoginIdentity(
        guardianIdValidation.data,
      );
  } catch (error) {
    console.error(
      "Gagal membentuk identitas login wali:",
      error,
    );

    return {
      status: "error",

      message:
        error instanceof Error
          ? error.message
          : "Gagal membentuk ID Pengguna wali.",

      fieldErrors: {},
    };
  }

  if (
    loginIdentity.status !==
    "candidate"
  ) {
    return {
      status: "error",

      message:
        "Wali sudah mempunyai identitas akun login.",

      fieldErrors: {},
    };
  }

  let adminSupabase;

  try {
    adminSupabase =
      createAdminClient();
  } catch (error) {
    console.error(
      "Supabase Admin Client tidak tersedia:",
      error,
    );

    return {
      status: "error",

      message:
        "Secret Supabase Admin belum dikonfigurasi.",

      fieldErrors: {},
    };
  }

  const {
    data: createdAuthData,
    error: createAuthError,
  } =
    await adminSupabase.auth.admin.createUser({
      email:
        loginIdentity.internal_auth_email,

      password:
        validationResult.data.password,

      email_confirm: true,

      user_metadata: {
        full_name:
          guardian.full_name,

        phone:
          guardian.phone,

        login_id:
          loginIdentity.login_id,

        account_identifier:
          loginIdentity.login_id,

        account_type:
          "guardian",
      },
    });

  if (createAuthError) {
    return {
      status: "error",

      message: mapCreateAuthError(
        createAuthError.message,
      ),

      fieldErrors: {},
    };
  }

  const createdUser =
    createdAuthData.user;

  if (!createdUser) {
    return {
      status: "error",

      message:
        "Supabase Auth tidak mengembalikan user baru.",

      fieldErrors: {},
    };
  }

  const supabase =
    await createClient();

  const {
    error: provisionError,
  } = await supabase.rpc(
    "provision_admin_guardian_login_account",
    {
      p_guardian_id:
        guardianIdValidation.data,

      p_user_id:
        createdUser.id,

      p_login_id:
        loginIdentity.login_id,
    },
  );

  if (provisionError) {
    const {
      error: cleanupError,
    } =
      await adminSupabase.auth.admin.deleteUser(
        createdUser.id,
      );

    if (cleanupError) {
      console.error(
        "Cleanup Auth user gagal:",
        {
          guardianId,
          userId: createdUser.id,

          provisioningError:
            provisionError.message,

          cleanupError:
            cleanupError.message,
        },
      );

      return {
        status: "error",

        message:
          "Akun Auth berhasil dibuat, tetapi provisioning database dan pembersihan otomatis gagal. Periksa Supabase Authentication.",

        fieldErrors: {},
      };
    }

    return {
      status: "error",

      message:
        `Akun gagal dihubungkan ke data wali: ${provisionError.message}`,

      fieldErrors: {},
    };
  }

  revalidatePath("/admin/wali");

  revalidatePath(
    `/admin/wali/${guardianId}`,
  );

  revalidatePath("/select-role");

  redirect(
    `/admin/wali/${guardianId}?account=created-success`,
  );
}