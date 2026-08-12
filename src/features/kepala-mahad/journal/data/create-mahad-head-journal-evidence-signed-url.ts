import {
  createClient,
} from "@/lib/supabase/server";

const BUCKET =
  "mahad-head-journal-evidence";

export async function createMahadHeadJournalEvidenceSignedUrl(
  evidencePath:
    string | null,
): Promise<string | null> {
  if (!evidencePath) {
    return null;
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.storage
      .from(
        BUCKET,
      )
      .createSignedUrl(
        evidencePath,
        300,
      );

  if (error) {
    console.error(
      "Gagal membuat signed URL bukti Jurnal Kepala Ma'had:",
      error,
    );

    return null;
  }

  return (
    data.signedUrl ??
    null
  );
}