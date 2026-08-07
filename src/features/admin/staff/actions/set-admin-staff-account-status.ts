"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createAdminClient } from "@/lib/supabase/admin";
import { createClient } from "@/lib/supabase/server";

import { getAdminStaffDetail } from "../data/get-admin-staff-detail";
import type { StaffAccountStatusActionState } from "../types/staff-account-action-state";

const staffIdSchema =
  z.string().uuid();

const longBanDuration =
  "876000h";

export async function setAdminStaffAccountStatus(
  staffId: string,
  targetIsActive: boolean,
  _previousState:
    StaffAccountStatusActionState,
  _formData: FormData,
): Promise<StaffAccountStatusActionState> {
      void _previousState;
      void _formData;
      
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
    };
  }

  if (!staffDetail) {
    return {
      status: "error",

      message:
        "Data staf tidak ditemukan.",
    };
  }

  const staff =
    staffDetail.staff;

  const account =
    staffDetail.account;

  if (
    !account.linked ||
    !account.profile_id
  ) {
    return {
      status: "error",

      message:
        "Staf belum mempunyai akun login.",
    };
  }

  if (
    targetIsActive &&
    !staff.is_active
  ) {
    return {
      status: "error",

      message:
        "Data staf tidak aktif. Aktifkan data staf terlebih dahulu.",
    };
  }

  if (
    account.active ===
    targetIsActive
  ) {
    revalidatePath(
      `/admin/staf/${staffId}`,
    );

    redirect(
      `/admin/staf/${staffId}`,
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
        ban_duration:
          authStatus,
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

  const supabase =
    await createClient();

  const {
    error: profileStatusError,
  } = await supabase.rpc(
    "set_admin_staff_account_profile_status",
    {
      p_staff_id:
        staffIdValidation.data,

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
        "Rollback status Auth staf gagal:",
        {
          staffId,
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
        `Gagal memperbarui status profile staf: ${profileStatusError.message}`,
    };
  }

  revalidatePath(
    "/admin/staf",
  );

  revalidatePath(
    `/admin/staf/${staffId}`,
  );

  revalidatePath(
    "/select-role",
  );

  redirect(
    `/admin/staf/${staffId}`,
  );
}