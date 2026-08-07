import { createClient } from "@/lib/supabase/server";

import {
  staffLoginIdentitySchema,
  type StaffLoginIdentityData,
} from "../schemas/staff-login-identity-schema";

export async function getAdminStaffLoginIdentity(
  staffId: string,
): Promise<StaffLoginIdentityData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_staff_login_identity",
    {
      p_staff_id: staffId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca identitas login staf: ${error.message}`,
    );
  }

  const validationResult =
    staffLoginIdentitySchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response identitas login staf tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format identitas login staf tidak sesuai.",
    );
  }

  return validationResult.data;
}