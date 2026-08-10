import {
  createClient,
} from "@/lib/supabase/server";

import type {
  KepalaMahadCareJournalQuery,
} from "../lib/parse-kepala-mahad-care-journal-query";

import {
  kepalaMahadCareJournalOverviewSchema,
  type KepalaMahadCareJournalOverviewData,
} from "../schemas/kepala-mahad-care-journal-overview-schema";

export async function getKepalaMahadCareJournalOverview(
  query:
    KepalaMahadCareJournalQuery,
): Promise<KepalaMahadCareJournalOverviewData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_kepala_mahad_care_journal_overview",
    {
      p_status:
        query.status,

      p_date:
        query.date,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Jurnal Pengasuhan Kepala Ma'had: ${error.message}`,
    );
  }

  const validation =
    kepalaMahadCareJournalOverviewSchema.safeParse(
      data,
    );

  if (!validation.success) {
    console.error(
      "Format overview jurnal Kepala Ma'had tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format overview Jurnal Pengasuhan dari database tidak valid.",
    );
  }

  return validation.data;
}