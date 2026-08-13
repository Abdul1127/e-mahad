import {
  z,
} from "zod";

import {
  createClient,
} from "@/lib/supabase/server";

import {
  leadershipTahfizStudentHistorySchema,
  type LeadershipTahfizStudentHistory,
} from "../schemas/leadership-tahfiz-schema";

const studentIdSchema =
  z.string().uuid();

export async function getLeadershipTahfizStudentHistory(
  studentId:
    string,

  page:
    number,
): Promise<LeadershipTahfizStudentHistory> {
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

  const safePage =
    Number.isInteger(
      page,
    ) &&
    page > 0
      ? page
      : 1;

  const limit =
    10;

  const offset =
    (
      safePage -
      1
    ) *
    limit;

  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_leadership_tahfiz_student_history",
      {
        p_student_id:
          studentValidation.data,

        p_limit:
          limit,

        p_offset:
          offset,
      },
    );

  if (error) {
    throw new Error(
      `Gagal mengambil riwayat Tahfiz santri: ${error.message}`,
    );
  }

  const validation =
    leadershipTahfizStudentHistorySchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format riwayat Tahfiz pimpinan tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format riwayat Tahfiz santri dari database tidak valid.",
    );
  }

  return validation.data;
}