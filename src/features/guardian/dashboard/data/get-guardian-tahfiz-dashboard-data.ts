import {
  createClient,
} from "@/lib/supabase/server";

import {
  guardianTahfizDashboardSchema,
  type GuardianTahfizDashboardData,
} from "../schemas/guardian-tahfiz-dashboard-schema";

export async function getGuardianTahfizDashboardData(): Promise<GuardianTahfizDashboardData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_guardian_tahfiz_dashboard",
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Dashboard Orang Tua/Wali: ${error.message}`,
    );
  }

  const validation =
    guardianTahfizDashboardSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format Dashboard Orang Tua/Wali tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Dashboard Orang Tua/Wali dari database tidak valid.",
    );
  }

  return validation.data;
}