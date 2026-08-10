import {
  z,
} from "zod";

import {
  createClient,
} from "@/lib/supabase/server";

import type {
  GuardianTahfizReportHistoryQuery,
} from "../lib/parse-guardian-tahfiz-report-history-query";

import {
  guardianTahfizReportHistorySchema,
  type GuardianTahfizReportHistoryData,
} from "../schemas/guardian-tahfiz-report-history-schema";

const studentIdSchema =
  z.string().uuid();

export async function getGuardianTahfizReportHistory(
  studentId:
    string,

  query:
    GuardianTahfizReportHistoryQuery,
): Promise<GuardianTahfizReportHistoryData> {
  const studentValidation =
    studentIdSchema.safeParse(
      studentId,
    );

  if (
    !studentValidation.success
  ) {
    throw new Error(
      "Student ID tidak valid.",
    );
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_guardian_tahfiz_report_history",
    {
      p_student_id:
        studentValidation.data,

      p_limit:
        query.limit,

      p_offset:
        query.offset,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Riwayat Tahfiz: ${error.message}`,
    );
  }

  const validation =
    guardianTahfizReportHistorySchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format Riwayat Tahfiz Wali tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Riwayat Tahfiz dari database tidak valid.",
    );
  }

  return validation.data;
}