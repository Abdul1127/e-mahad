import {
  createClient,
} from "@/lib/supabase/server";

import type {
  PengasuhJournalHistoryQuery,
} from "../lib/parse-pengasuh-journal-history-query";

import {
  pengasuhJournalHistorySchema,
  type PengasuhJournalHistoryData,
} from "../schemas/pengasuh-journal-history-schema";

export async function getPengasuhJournalHistory(
  query:
    PengasuhJournalHistoryQuery,
): Promise<PengasuhJournalHistoryData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pengasuh_journal_history",
    {
      p_status:
        query.status,

      p_session:
        query.session,

      p_date:
        query.date,

      p_limit:
        query.limit,

      p_offset:
        query.offset,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Riwayat Pengasuhan: ${error.message}`,
    );
  }

  const validation =
    pengasuhJournalHistorySchema.safeParse(
      data,
    );

  if (!validation.success) {
    console.error(
      "Format Riwayat Pengasuhan tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Riwayat Pengasuhan dari database tidak valid.",
    );
  }

  return validation.data;
}