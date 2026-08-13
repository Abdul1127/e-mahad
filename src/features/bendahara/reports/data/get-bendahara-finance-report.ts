import {
  createClient,
} from "@/lib/supabase/server";

import {
  bendaharaFinanceReportSchema,
  type BendaharaFinanceReportData,
} from "../schemas/bendahara-finance-report-schema";

type Options = {
  startDate?:
    string | null;

  endDate?:
    string | null;
};

export async function getBendaharaFinanceReport({
  startDate = null,
  endDate = null,
}: Options = {}): Promise<BendaharaFinanceReportData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_bendahara_finance_report",
      {
        p_start_date:
          startDate,

        p_end_date:
          endDate,
      },
    );

  if (error) {
    throw new Error(
      `Gagal mengambil Laporan Keuangan Bendahara: ${error.message}`,
    );
  }

  const parsed =
    bendaharaFinanceReportSchema.safeParse(
      data,
    );

  if (
    !parsed.success
  ) {
    console.error(
      "Invalid Bendahara finance report payload:",
      parsed.error.flatten(),
    );

    throw new Error(
      "Data Laporan Keuangan Bendahara tidak sesuai dengan kontrak aplikasi.",
    );
  }

  return parsed.data;
}