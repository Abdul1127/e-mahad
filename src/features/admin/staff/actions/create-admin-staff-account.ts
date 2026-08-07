"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

import { getAdminStaffDetail } from "../data/get-admin-staff-detail";
import { getAdminStaffLoginIdentity } from "../data/get-admin-staff-login-identity";
import { getAdminStaffRoleOptions } from "../data/get-admin-staff-role-options";
import { staffAccountCreateSchema } from "../schemas/staff-account-create-schema";
import type { StaffLoginIdentityData } from "../schemas/staff-login-identity-schema";
import type { StaffAccountActionState } from "../types/staff-account-action-state";

const staffIdSchema =
  z.string().uuid();

function createErrorState(
  message: string,
): StaffAccountActionState {
  return {
    status: "error",
    message,
    fieldErrors: {},
  };
}

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
      "akun Auth. Periksa Supabase Authentication."
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
    "Gagal membuat akun Auth staf: " +
    message
  );
}

export async function createAdminStaffAccount(
  staffId: string,
  _previousState:
    StaffAccountActionState,
  formData: FormData,
): Promise<StaffAccountActionState> {
  await requireRole("admin");

  const staffIdValidation =
    staffIdSchema.safeParse(
      staffId,
    );

  if (!staffIdValidation.success) {
    return createErrorState(
      "ID staf tidak valid.",
    );
  }

  const selectedRoleCodes =
    Array.from(
      new Set(
        formData
          .getAll("role_codes")
          .map((value) =>
            String(value)
              .trim()
              .toLowerCase(),
          )
          .filter(Boolean),
      ),
    );

  const validationResult =
    staffAccountCreateSchema.safeParse(
      {
        password:
          String(
            formData.get(
              "password",
            ) ?? "",
          ),

        password_confirmation:
          String(
            formData.get(
              "password_confirmation",
            ) ?? "",
          ),

        role_codes:
          selectedRoleCodes,
      },
    );

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Periksa kembali password dan role staf.",

      fieldErrors:
        validationResult.error
          .flatten()
          .fieldErrors,
    };
  }

  let staffDetail:
    Awaited<
      ReturnType<
        typeof getAdminStaffDetail
      >
    >;

  try {
    staffDetail =
      await getAdminStaffDetail(
        staffIdValidation.data,
      );
  } catch (error) {
    console.error(
      "Gagal memeriksa detail staf:",
      error,
    );

    return createErrorState(
      "Gagal memeriksa data staf.",
    );
  }

  if (!staffDetail) {
    return createErrorState(
      "Data staf tidak ditemukan.",
    );
  }

  if (
    !staffDetail.staff.is_active
  ) {
    return createErrorState(
      "Staf tidak aktif tidak dapat dibuatkan akun.",
    );
  }

  if (
    staffDetail.account.linked
  ) {
    return createErrorState(
      "Staf sudah mempunyai akun login.",
    );
  }

  const roleOptions =
    await getAdminStaffRoleOptions();

  const allowedRoleCodes =
    new Set(
      roleOptions.map(
        (role) => role.code,
      ),
    );

  const invalidRoleCodes =
    validationResult.data.role_codes
      .filter(
        (roleCode) =>
          !allowedRoleCodes.has(
            roleCode,
          ),
      );

  if (
    invalidRoleCodes.length > 0
  ) {
    return {
      status: "error",

      message:
        "Terdapat role yang tidak valid.",

      fieldErrors: {
        role_codes: [
          `Role tidak valid: ${invalidRoleCodes.join(", ")}.`,
        ],
      },
    };
  }

  let loginIdentity:
    StaffLoginIdentityData;

  try {
    loginIdentity =
      await getAdminStaffLoginIdentity(
        staffIdValidation.data,
      );
  } catch (error) {
    console.error(
      "Gagal membentuk identitas login staf:",
      error,
    );

    return createErrorState(
      error instanceof Error
        ? error.message
        : "Gagal membentuk ID Pengguna staf.",
    );
  }

  if (
    loginIdentity.status !==
    "candidate"
  ) {
    return createErrorState(
      "Staf sudah mempunyai identitas akun login.",
    );
  }

  const adminSupabase =
    createAdminClient();

  const {
    data: createdAuthData,
    error: createAuthError,
  } =
    await adminSupabase
      .auth.admin.createUser({
        email:
          loginIdentity
            .internal_auth_email,

        password:
          validationResult
            .data.password,

        email_confirm: true,

        user_metadata: {
          full_name:
            staffDetail.staff
              .full_name,

          phone:
            staffDetail.staff.phone,

          position:
            staffDetail.staff
              .position,

          legacy_staff_id:
            staffDetail.staff
              .legacy_staff_id,

          login_id:
            loginIdentity.login_id,

          account_identifier:
            loginIdentity.login_id,

          account_type:
            "staff",
        },
      });

  if (createAuthError) {
    return createErrorState(
      mapCreateAuthError(
        createAuthError.message,
      ),
    );
  }

  const createdUser =
    createdAuthData.user;

  if (!createdUser) {
    return createErrorState(
      "Supabase Auth tidak mengembalikan akun staf baru.",
    );
  }

  const supabase =
    await createClient();

  const {
    error: provisionError,
  } = await supabase.rpc(
    "provision_admin_staff_login_account",
    {
      p_staff_id:
        staffIdValidation.data,

      p_user_id:
        createdUser.id,

      p_login_id:
        loginIdentity.login_id,

      p_role_codes:
        validationResult
          .data.role_codes,
    },
  );

  if (provisionError) {
    const {
      error: cleanupError,
    } =
      await adminSupabase
        .auth.admin.deleteUser(
          createdUser.id,
        );

    if (cleanupError) {
      console.error(
        "Cleanup akun Auth staf gagal:",
        {
          staffId:
            staffIdValidation.data,

          userId:
            createdUser.id,

          provisionError:
            provisionError.message,

          cleanupError:
            cleanupError.message,
        },
      );

      return createErrorState(
        "Akun Auth berhasil dibuat, tetapi provisioning database dan pembersihan otomatis gagal. Periksa Supabase Authentication.",
      );
    }

    return createErrorState(
      `Akun staf gagal dihubungkan: ${provisionError.message}`,
    );
  }

  revalidatePath(
    "/admin/staf",
  );

  revalidatePath(
    `/admin/staf/${staffIdValidation.data}`,
  );

  revalidatePath(
    "/select-role",
  );

  redirect(
    `/admin/staf/${staffIdValidation.data}`,
  );
}