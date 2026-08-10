import {
  createClient,
} from "@/lib/supabase/server";

import type {
  PembinaTahfizWeeklyReportQuery,
} from "../lib/parse-pembina-tahfiz-weekly-report-query";

import {
  pembinaTahfizWeeklyReportOverviewSchema,
  type PembinaTahfizWeeklyReportOverviewData,
} from "../schemas/pembina-tahfiz-weekly-report-overview-schema";

export async function getPembinaTahfizWeeklyReportOverview(
  query:
    PembinaTahfizWeeklyReportQuery,
): Promise<PembinaTahfizWeeklyReportOverviewData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pembina_tahfiz_weekly_report_overview",
    {
      p_week_start:
        query.weekStart,

      p_search:
        query.search,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Laporan Tahfiz Mingguan: ${error.message}`,
    );
  }

  const validation =
    pembinaTahfizWeeklyReportOverviewSchema.safeParse(
      data,
    );

  if (!validation.success) {
    console.error(
      "Format overview Laporan Tahfiz tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Laporan Tahfiz dari database tidak valid.",
    );
  }

  return validation.data;
}