import {
  createClient,
} from "@/lib/supabase/server";

import {
  kepalaMahadJournalOverviewSchema,
  type KepalaMahadJournalOverview,
} from "../schemas/mahad-head-journal-schema";

type Parameters = {
  dateFrom?:
    string | null;

  dateTo?:
    string | null;
};

export async function getKepalaMahadJournalOverview({
  dateFrom = null,
  dateTo = null,
}: Parameters = {}): Promise<KepalaMahadJournalOverview> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_kepala_mahad_journal_overview",
      {
        p_date_from:
          dateFrom,

        p_date_to:
          dateTo,
      },
    );

  if (error) {
    throw new Error(
      `Gagal mengambil Jurnal Kepala Ma'had: ${error.message}`,
    );
  }

  return kepalaMahadJournalOverviewSchema.parse(
    data,
  );
}