import {
  createClient,
} from "@/lib/supabase/server";

import {
  pembinaTahfizDashboardSchema,
  type PembinaTahfizDashboardData,
} from "../schemas/pembina-tahfiz-dashboard-schema";

export async function getPembinaTahfizDashboardData(): Promise<PembinaTahfizDashboardData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pembina_tahfiz_dashboard",
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Dashboard Pembina Tahfiz: ${error.message}`,
    );
  }

  const validation =
    pembinaTahfizDashboardSchema.safeParse(
      data,
    );

  if (!validation.success) {
    console.error(
      "Format Dashboard Pembina Tahfiz tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Dashboard Pembina Tahfiz dari database tidak valid.",
    );
  }

  return validation.data;
}