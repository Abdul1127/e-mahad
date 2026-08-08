import { createClient } from "@/lib/supabase/server";

import {
  pengasuhJournalOverviewSchema,
  type PengasuhJournalOverviewData,
} from "../schemas/pengasuh-journal-overview-schema";

export async function getPengasuhJournalOverview(
  date: string,
): Promise<PengasuhJournalOverviewData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pengasuh_journal_overview",
    {
      p_date:
        date,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Jurnal Pengasuhan: ${error.message}`,
    );
  }

  const validationResult =
    pengasuhJournalOverviewSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Format overview Jurnal Pengasuhan tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format overview Jurnal Pengasuhan dari database tidak valid.",
    );
  }

  return validationResult.data;
}