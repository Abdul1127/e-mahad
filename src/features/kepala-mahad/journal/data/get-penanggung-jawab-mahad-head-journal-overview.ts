import {
  createClient,
} from "@/lib/supabase/server";

import {
  penanggungJawabMahadHeadJournalOverviewSchema,
  type PenanggungJawabMahadHeadJournalOverview,
} from "../schemas/mahad-head-journal-schema";

type Parameters = {
  dateFrom?:
    string | null;

  dateTo?:
    string | null;
};

export async function getPenanggungJawabMahadHeadJournalOverview({
  dateFrom = null,
  dateTo = null,
}: Parameters = {}): Promise<PenanggungJawabMahadHeadJournalOverview> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_penanggung_jawab_mahad_head_journal_overview",
      {
        p_date_from:
          dateFrom,

        p_date_to:
          dateTo,
      },
    );

  if (error) {
    throw new Error(
      `Gagal mengambil monitoring Jurnal Kepala Ma'had: ${error.message}`,
    );
  }

  return penanggungJawabMahadHeadJournalOverviewSchema.parse(
    data,
  );
}