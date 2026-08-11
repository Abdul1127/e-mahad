import {
  createClient,
} from "@/lib/supabase/server";

import {
  pengasuhActivityScheduleListSchema,
  type PengasuhActivityScheduleListData,
} from "../schemas/pengasuh-activity-schema";

type Input = {
  dateFrom?:
    string | null;

  dateTo?:
    string | null;
};

export async function getPengasuhActivityScheduleListData({
  dateFrom = null,
  dateTo = null,
}: Input = {}): Promise<PengasuhActivityScheduleListData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pengasuh_activity_schedule_list",
    {
      p_date_from:
        dateFrom,

      p_date_to:
        dateTo,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil jadwal kegiatan: ${error.message}`,
    );
  }

  const validation =
    pengasuhActivityScheduleListSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format jadwal Pengasuh tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format data jadwal Pengasuh tidak valid.",
    );
  }

  return validation.data;
}