import { createClient } from "@/lib/supabase/server";

import {
  adminStaffRoleOptionsSchema,
  type AdminStaffRoleOption,
} from "../schemas/admin-staff-role-options-schema";

export async function getAdminStaffRoleOptions(): Promise<
  AdminStaffRoleOption[]
> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_staff_role_options",
  );

  if (error) {
    throw new Error(
      `Gagal membaca pilihan role staf: ${error.message}`,
    );
  }

  const validationResult =
    adminStaffRoleOptionsSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response pilihan role staf tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format pilihan role staf tidak sesuai.",
    );
  }

  return validationResult.data;
}