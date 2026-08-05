import { createClient } from "@/lib/supabase/server";

import {
  adminGuardianDetailSchema,
  type AdminGuardianDetailData,
} from "../schemas/admin-guardian-detail-schema";

export async function getAdminGuardianDetail(
  guardianId: string,
): Promise<AdminGuardianDetailData | null> {
  const supabase = await createClient();

  const { data, error } = await supabase.rpc(
    "get_admin_guardian_detail",
    {
      p_guardian_id: guardianId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca detail wali: ${error.message}`,
    );
  }

  if (data === null) {
    return null;
  }

  const validationResult =
    adminGuardianDetailSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response detail wali tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format detail wali tidak sesuai.",
    );
  }

  return validationResult.data;
}