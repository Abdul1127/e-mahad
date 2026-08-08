import { z } from "zod";

import { createClient } from "@/lib/supabase/server";

import {
  pengasuhJournalDetailSchema,
  type PengasuhJournalDetailData,
} from "../schemas/pengasuh-journal-detail-schema";

const journalIdSchema =
  z.string().uuid();

export async function getPengasuhJournalDetail(
  journalId: string,
): Promise<PengasuhJournalDetailData> {
  const validation =
    journalIdSchema.safeParse(
      journalId,
    );

  if (!validation.success) {
    throw new Error(
      "Journal ID tidak valid.",
    );
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pengasuh_journal_detail",
    {
      p_journal_id:
        validation.data,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil detail Jurnal Pengasuhan: ${error.message}`,
    );
  }

  const validationResult =
    pengasuhJournalDetailSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Format detail Jurnal Pengasuhan tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format detail Jurnal Pengasuhan dari database tidak valid.",
    );
  }

  return validationResult.data;
}