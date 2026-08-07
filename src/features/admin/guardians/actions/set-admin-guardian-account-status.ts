"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

import { getAdminGuardianDetail } from "../data/get-admin-guardian-detail";
import type { GuardianAccountStatusActionState } from "../types/guardian-account-action-state";

const guardianIdSchema = z.string().uuid();

const longBanDuration = "876000h";

export async function setAdminGuardianAccountStatus(
  guardianId: string,
  targetIsActive: boolean,
  previousState:
    GuardianAccountStatusActionState,
  formData: FormData,
): Promise<GuardianAccountStatusActionState> {
  void previousState;
  void formData;

  await requireRole("admin");

  const guardianIdValidation =
    guardianIdSchema.safeParse(
      guardianId,
    );

  if (!guardianIdValidation.success) {
    return {
      status: "error",
      message: "ID wali tidak valid.",
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
    };
  }

  if (!guardianDetail) {
    return {
      status: "error",
      message: "Data wali tidak ditemukan.",
    };
  }

  const guardian =
    guardianDetail.guardian;

  const account =
    guardianDetail.account;

  if (
    !account.linked ||
    !account.profile_id
  ) {
    return {
      status: "error",
      message:
        "Wali belum mempunyai akun login.",
    };
  }

  if (
    targetIsActive &&
    !guardian.is_active
  ) {
    return {
      status: "error",

      message:
        "Data wali tidak aktif. Aktifkan data wali terlebih dahulu.",
    };
  }

  if (
    account.active === targetIsActive
  ) {
    revalidatePath(
      `/admin/wali/${guardianId}`,
    );

    redirect(
      `/admin/wali/${guardianId}`,
    );
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
    };
  }

  const authStatus =
    targetIsActive
      ? "none"
      : longBanDuration;

  const {
    error: authUpdateError,
  } =
    await adminSupabase.auth.admin.updateUserById(
      account.profile_id,
      {
        ban_duration: authStatus,
      },
    );

  if (authUpdateError) {
    return {
      status: "error",

      message:
        targetIsActive
          ? `Gagal mengaktifkan akun Auth: ${authUpdateError.message}`
          : `Gagal menonaktifkan akun Auth: ${authUpdateError.message}`,
    };
  }

  const supabase = await createClient();

  const {
    error: profileStatusError,
  } = await supabase.rpc(
    "set_admin_guardian_account_profile_status",
    {
      p_guardian_id:
        guardianIdValidation.data,

      p_is_active:
        targetIsActive,
    },
  );

  if (profileStatusError) {
    const rollbackBanDuration =
      account.active
        ? "none"
        : longBanDuration;

    const {
      error: rollbackError,
    } =
      await adminSupabase.auth.admin.updateUserById(
        account.profile_id,
        {
          ban_duration:
            rollbackBanDuration,
        },
      );

    if (rollbackError) {
      console.error(
        "Rollback status Auth gagal:",
        {
          guardianId,
          profileId:
            account.profile_id,

          profileError:
            profileStatusError.message,

          rollbackError:
            rollbackError.message,
        },
      );

      return {
        status: "error",

        message:
          "Status Auth berubah, tetapi status profile gagal diperbarui dan rollback juga gagal. Periksa akun melalui Supabase Authentication.",
      };
    }

    return {
      status: "error",

      message:
        `Gagal memperbarui status profile wali: ${profileStatusError.message}`,
    };
  }

  revalidatePath("/admin/wali");

  revalidatePath(
    `/admin/wali/${guardianId}`,
  );

  revalidatePath("/select-role");

  redirect(
    `/admin/wali/${guardianId}`,
  );
}