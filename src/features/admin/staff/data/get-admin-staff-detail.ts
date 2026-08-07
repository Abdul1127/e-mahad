import { createClient } from "@/lib/supabase/server";

import {
  adminStaffDetailSchema,
  type AdminStaffDetailData,
} from "../schemas/admin-staff-detail-schema";

export async function getAdminStaffDetail(
  staffId: string,
): Promise<AdminStaffDetailData | null> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_staff_detail",
    {
      p_staff_id: staffId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca detail staf: ${error.message}`,
    );
  }

  if (data === null) {
    return null;
  }

  const validationResult =
    adminStaffDetailSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response detail staf tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format detail staf tidak sesuai.",
    );
  }

  return validationResult.data;
}