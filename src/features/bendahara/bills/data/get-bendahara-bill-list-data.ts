import {
  createClient,
} from "@/lib/supabase/server";

import {
  bendaharaBillListSchema,
  type BendaharaBillListData,
  type BendaharaBillFilterStatus,
} from "../schemas/bendahara-bill-list-schema";

type Input = {
  search:
    string | null;

  status:
    BendaharaBillFilterStatus | null;

  page:
    number;

  pageSize:
    number;
};

export async function getBendaharaBillListData({
  search,
  status,
  page,
  pageSize,
}: Input): Promise<BendaharaBillListData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_bendahara_bill_list",
    {
      p_search:
        search,

      p_status:
        status,

      p_page:
        page,

      p_page_size:
        pageSize,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil daftar tagihan: ${error.message}`,
    );
  }

  const validation =
    bendaharaBillListSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format daftar tagihan Bendahara tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format daftar tagihan dari database tidak valid.",
    );
  }

  return validation.data;
}