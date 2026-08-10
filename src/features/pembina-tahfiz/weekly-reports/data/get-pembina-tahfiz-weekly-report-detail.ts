import {
  z,
} from "zod";

import {
  createClient,
} from "@/lib/supabase/server";

import {
  pembinaTahfizWeeklyReportDetailSchema,
  type PembinaTahfizWeeklyReportDetailData,
} from "../schemas/pembina-tahfiz-weekly-report-detail-schema";

const studentIdSchema =
  z.string().uuid();

const weekStartSchema =
  z.string()
    .regex(
      /^\d{4}-\d{2}-\d{2}$/,
    );

export async function getPembinaTahfizWeeklyReportDetail(
  studentId:
    string,

  weekStart:
    string,
): Promise<PembinaTahfizWeeklyReportDetailData> {
  const studentValidation =
    studentIdSchema.safeParse(
      studentId,
    );

  const weekValidation =
    weekStartSchema.safeParse(
      weekStart,
    );

  if (
    !studentValidation.success ||
    !weekValidation.success
  ) {
    throw new Error(
      "Parameter laporan Tahfiz tidak valid.",
    );
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pembina_tahfiz_weekly_report_detail",
    {
      p_student_id:
        studentValidation.data,

      p_week_start:
        weekValidation.data,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil detail Laporan Tahfiz: ${error.message}`,
    );
  }

  const validation =
    pembinaTahfizWeeklyReportDetailSchema.safeParse(
      data,
    );

  if (!validation.success) {
    console.error(
      "Format detail Laporan Tahfiz tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format detail Laporan Tahfiz dari database tidak valid.",
    );
  }

  return validation.data;
}