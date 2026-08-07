"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createClient } from "@/lib/supabase/server";

import { getAdminStaffDetail } from "../data/get-admin-staff-detail";
import { getAdminStaffRoleOptions } from "../data/get-admin-staff-role-options";
import { staffRoleUpdateSchema } from "../schemas/staff-role-update-schema";
import type { StaffRoleActionState } from "../types/staff-account-action-state";

const staffIdSchema =
  z.string().uuid();

export async function setAdminStaffRoles(
  staffId: string,
  _previousState:
    StaffRoleActionState,
  formData: FormData,
): Promise<StaffRoleActionState> {
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
    staffRoleUpdateSchema.safeParse(
      {
        role_codes:
          selectedRoleCodes,
      },
    );

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Pilih minimal satu role staf.",

      fieldErrors:
        validationResult.error
          .flatten()
          .fieldErrors,
    };
  }

  const staffDetail =
    await getAdminStaffDetail(
      staffIdValidation.data,
    );

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

  const roleOptions =
    await getAdminStaffRoleOptions();

  const allowedRoleCodes =
    new Set(
      roleOptions.map(
        (role) =>
          role.code,
      ),
    );

  const invalidRoleCodes =
    validationResult.data.role_codes.filter(
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

  const supabase =
    await createClient();

  const {
    error,
  } = await supabase.rpc(
    "set_admin_staff_roles",
    {
      p_staff_id:
        staffIdValidation.data,

      p_role_codes:
        validationResult.data.role_codes,
    },
  );

  if (error) {
    return {
      status: "error",

      message:
        `Gagal memperbarui role staf: ${error.message}`,

      fieldErrors: {},
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