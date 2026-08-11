import {
  createClient,
} from "@/lib/supabase/server";

import {
  bendaharaPaymentHistorySchema,
  type BendaharaPaymentHistoryData,
  type BendaharaPaymentMethod,
  type BendaharaPaymentStatus,
} from "../schemas/bendahara-payment-history-schema";

type Input = {
  search:
    string | null;

  status:
    BendaharaPaymentStatus | null;

  method:
    BendaharaPaymentMethod | null;

  page:
    number;

  pageSize:
    number;
};

export async function getBendaharaPaymentHistoryData({
  search,
  status,
  method,
  page,
  pageSize,
}: Input): Promise<BendaharaPaymentHistoryData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_bendahara_payment_history",
    {
      p_search:
        search,

      p_status:
        status,

      p_method:
        method,

      p_page:
        page,

      p_page_size:
        pageSize,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil riwayat pembayaran: ${error.message}`,
    );
  }

  const validation =
    bendaharaPaymentHistorySchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format Riwayat Pembayaran Bendahara tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format riwayat pembayaran dari database tidak valid.",
    );
  }

  return validation.data;
}