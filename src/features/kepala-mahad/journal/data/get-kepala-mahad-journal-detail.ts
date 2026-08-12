import {
  createClient,
} from "@/lib/supabase/server";

import {
  kepalaMahadJournalDetailSchema,
  type KepalaMahadJournalDetail,
} from "../schemas/mahad-head-journal-schema";

export async function getKepalaMahadJournalDetail(
  journalId: string,
): Promise<KepalaMahadJournalDetail> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_kepala_mahad_journal_detail",
      {
        p_journal_id:
          journalId,
      },
    );

  if (error) {
    throw new Error(
      `Gagal mengambil detail Jurnal Kepala Ma'had: ${error.message}`,
    );
  }

  return kepalaMahadJournalDetailSchema.parse(
    data,
  );
}