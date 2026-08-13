import {
  createClient,
} from "@/lib/supabase/server";

import {
  kepalaMahadFinanceSummarySchema,
  type KepalaMahadFinanceSummaryData,
} from "../schemas/kepala-mahad-finance-summary-schema";

export async function getKepalaMahadFinanceSummary(): Promise<KepalaMahadFinanceSummaryData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_kepala_mahad_finance_summary",
    );

  if (error) {
    throw new Error(
      `Gagal mengambil Ringkasan Keuangan Kepala Ma'had: ${error.message}`,
    );
  }

  const parsed =
    kepalaMahadFinanceSummarySchema.safeParse(
      data,
    );

  if (
    !parsed.success
  ) {
    console.error(
      "Invalid Kepala Ma'had finance summary payload:",
      parsed.error.flatten(),
    );

    throw new Error(
      "Data Ringkasan Keuangan Kepala Ma'had tidak sesuai dengan kontrak aplikasi.",
    );
  }

  return parsed.data;
}