import {
  createClient,
} from "@/lib/supabase/server";

import {
  bendaharaBillDetailSchema,
  type BendaharaBillDetailData,
} from "../schemas/bendahara-bill-detail-schema";

export async function getBendaharaBillDetailData(
  billId: string,
): Promise<BendaharaBillDetailData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_bendahara_bill_detail",
    {
      p_bill_id:
        billId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil detail tagihan: ${error.message}`,
    );
  }

  const validation =
    bendaharaBillDetailSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format Detail Tagihan Bendahara tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format detail tagihan dari database tidak valid.",
    );
  }

  return validation.data;
}