import { createClient } from "@/lib/supabase/server";

import {
  adminStudentDetailSchema,
  type AdminStudentDetailData,
} from "../schemas/admin-student-detail-schema";

export async function getAdminStudentDetail(
  studentId: string,
): Promise<AdminStudentDetailData | null> {
  const supabase = await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_student_detail",
    {
      p_student_id: studentId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca detail santri: ${error.message}`,
    );
  }

  if (data === null) {
    return null;
  }

  const validationResult =
    adminStudentDetailSchema.safeParse(data);

  if (!validationResult.success) {
    console.error(
      "Response detail santri tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format detail santri tidak sesuai.",
    );
  }

  return validationResult.data;
}