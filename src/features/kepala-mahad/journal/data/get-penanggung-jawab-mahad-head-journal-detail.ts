import {
  createClient,
} from "@/lib/supabase/server";

import {
  penanggungJawabMahadHeadJournalDetailSchema,
  type PenanggungJawabMahadHeadJournalDetail,
} from "../schemas/mahad-head-journal-schema";

export async function getPenanggungJawabMahadHeadJournalDetail(
  journalId: string,
): Promise<PenanggungJawabMahadHeadJournalDetail> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_penanggung_jawab_mahad_head_journal_detail",
      {
        p_journal_id:
          journalId,
      },
    );

  if (error) {
    throw new Error(
      `Gagal mengambil detail monitoring Jurnal Kepala Ma'had: ${error.message}`,
    );
  }

  return penanggungJawabMahadHeadJournalDetailSchema.parse(
    data,
  );
}