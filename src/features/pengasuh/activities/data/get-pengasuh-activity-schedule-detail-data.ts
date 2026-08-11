import {
  createClient,
} from "@/lib/supabase/server";

import {
  pengasuhActivityScheduleDetailSchema,
  type PengasuhActivityScheduleDetailData,
} from "../schemas/pengasuh-activity-schema";

export async function getPengasuhActivityScheduleDetailData(
  scheduleId: string,
): Promise<PengasuhActivityScheduleDetailData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pengasuh_activity_schedule_detail",
    {
      p_schedule_id:
        scheduleId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil detail jadwal: ${error.message}`,
    );
  }

  const validation =
    pengasuhActivityScheduleDetailSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format detail jadwal tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format data detail jadwal tidak valid.",
    );
  }

  return validation.data;
}