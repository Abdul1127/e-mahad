"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createAdminClient } from "@/lib/supabase/admin";

import { getAdminStaffDetail } from "../data/get-admin-staff-detail";
import { staffAccountResetPasswordSchema } from "../schemas/staff-account-reset-password-schema";
import type { StaffAccountResetPasswordActionState } from "../types/staff-account-action-state";

const staffIdSchema =
  z.string().uuid();

export async function resetAdminStaffAccountPassword(
  staffId: string,
  _previousState:
    StaffAccountResetPasswordActionState,
  formData: FormData,
): Promise<StaffAccountResetPasswordActionState> {
  await requireRole("admin");

  const staffIdValidation =
    staffIdSchema.safeParse(
      staffId,
    );

  if (!staffIdValidation.success) {
    return {
      status: "error",
      message:
        "ID staf tidak valid.",
      fieldErrors: {},
    };
  }

  const validationResult =
    staffAccountResetPasswordSchema.safeParse(
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
      },
    );

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Periksa kembali password baru.",

      fieldErrors:
        validationResult.error
          .flatten()
          .fieldErrors,
    };
  }

  let staffDetail;

  try {
    staffDetail =
      await getAdminStaffDetail(
        staffIdValidation.data,
      );
  } catch (error) {
    console.error(
      "Gagal memeriksa akun staf:",
      error,
    );

    return {
      status: "error",

      message:
        "Gagal memeriksa data akun staf.",

      fieldErrors: {},
    };
  }

  if (!staffDetail) {
    return {
      status: "error",

      message:
        "Data staf tidak ditemukan.",

      fieldErrors: {},
    };
  }

  if (
    !staffDetail.account.linked ||
    !staffDetail.account.profile_id
  ) {
    return {
      status: "error",

      message:
        "Staf belum mempunyai akun login.",

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
      staffDetail.account.profile_id,
      {
        password:
          validationResult.data.password,
      },
    );

  if (updatePasswordError) {
    return {
      status: "error",

      message:
        `Gagal mengganti password akun staf: ${updatePasswordError.message}`,

      fieldErrors: {},
    };
  }

  revalidatePath(
    `/admin/staf/${staffId}`,
  );

  redirect(
    `/admin/staf/${staffId}`,
  );
}