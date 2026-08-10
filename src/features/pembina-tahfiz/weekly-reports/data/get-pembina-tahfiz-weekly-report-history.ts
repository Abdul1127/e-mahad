import {
  createClient,
} from "@/lib/supabase/server";

import type {
  PembinaTahfizWeeklyReportHistoryQuery,
} from "../lib/parse-pembina-tahfiz-weekly-report-history-query";

import {
  pembinaTahfizWeeklyReportHistorySchema,
  type PembinaTahfizWeeklyReportHistoryData,
} from "../schemas/pembina-tahfiz-weekly-report-history-schema";

export async function getPembinaTahfizWeeklyReportHistory(
  query:
    PembinaTahfizWeeklyReportHistoryQuery,
): Promise<PembinaTahfizWeeklyReportHistoryData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pembina_tahfiz_weekly_report_history",
    {
      p_status:
        query.status,

      p_search:
        query.search,

      p_limit:
        query.limit,

      p_offset:
        query.offset,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Riwayat Laporan Tahfiz: ${error.message}`,
    );
  }

  const validation =
    pembinaTahfizWeeklyReportHistorySchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format Riwayat Laporan Tahfiz tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Riwayat Laporan Tahfiz dari database tidak valid.",
    );
  }

  return validation.data;
}