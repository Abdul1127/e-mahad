import { z } from "zod";

import {
  createClient,
} from "@/lib/supabase/server";

import {
  kepalaMahadCareJournalDetailSchema,
  type KepalaMahadCareJournalDetailData,
} from "../schemas/kepala-mahad-care-journal-detail-schema";

const journalIdSchema =
  z.string().uuid();

export async function getKepalaMahadCareJournalDetail(
  journalId: string,
): Promise<KepalaMahadCareJournalDetailData> {
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
    "get_kepala_mahad_care_journal_detail",
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

  const responseValidation =
    kepalaMahadCareJournalDetailSchema.safeParse(
      data,
    );

  if (!responseValidation.success) {
    console.error(
      "Format detail jurnal Kepala Ma'had tidak valid:",
      responseValidation.error.flatten(),
    );

    throw new Error(
      "Format detail Jurnal Pengasuhan dari database tidak valid.",
    );
  }

  return responseValidation.data;
}