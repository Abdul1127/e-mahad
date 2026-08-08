import { createClient } from "@/lib/supabase/server";

import {
  pengasuhDashboardSchema,
  type PengasuhDashboardData,
} from "../schemas/pengasuh-dashboard-schema";

export async function getPengasuhDashboardData(): Promise<PengasuhDashboardData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pengasuh_dashboard",
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Dashboard Pengasuh: ${error.message}`,
    );
  }

  const validationResult =
    pengasuhDashboardSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Format Dashboard Pengasuh tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format data Dashboard Pengasuh dari database tidak valid.",
    );
  }

  return validationResult.data;
}