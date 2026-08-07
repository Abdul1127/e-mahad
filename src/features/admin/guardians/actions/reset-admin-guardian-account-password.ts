"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createAdminClient } from "@/lib/supabase/admin";

import { getAdminGuardianDetail } from "../data/get-admin-guardian-detail";
import { guardianAccountResetPasswordSchema } from "../schemas/guardian-account-reset-password-schema";
import type { GuardianAccountResetPasswordActionState } from "../types/guardian-account-action-state";

const guardianIdSchema = z.string().uuid();

export async function resetAdminGuardianAccountPassword(
  guardianId: string,
  previousState:
    GuardianAccountResetPasswordActionState,
  formData: FormData,
): Promise<GuardianAccountResetPasswordActionState> {
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
    guardianAccountResetPasswordSchema.safeParse(
      values,
    );

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Periksa kembali password baru.",

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
      "Gagal memeriksa akun wali:",
      error,
    );

    return {
      status: "error",

      message:
        "Gagal memeriksa data akun wali.",

      fieldErrors: {},
    };
  }

  if (!guardianDetail) {
    return {
      status: "error",
      message: "Data wali tidak ditemukan.",
      fieldErrors: {},
    };
  }

  if (
    !guardianDetail.account.linked ||
    !guardianDetail.account.profile_id
  ) {
    return {
      status: "error",

      message:
        "Wali belum mempunyai akun login.",

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
    error: updatePasswordError,
  } =
    await adminSupabase.auth.admin.updateUserById(
      guardianDetail.account.profile_id,
      {
        password:
          validationResult.data.password,
      },
    );

  if (updatePasswordError) {
    return {
      status: "error",

      message:
        `Gagal mengganti password akun wali: ${updatePasswordError.message}`,

      fieldErrors: {},
    };
  }

  revalidatePath(
    `/admin/wali/${guardianId}`,
  );

  redirect(
    `/admin/wali/${guardianId}?account=password-reset-success`,
  );
}