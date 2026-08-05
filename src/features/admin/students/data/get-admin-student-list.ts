import { createClient } from "@/lib/supabase/server";

import type { AdminStudentListQuery } from "../lib/parse-student-list-query";
import {
  adminStudentListSchema,
  type AdminStudentListData,
} from "../schemas/admin-student-list-schema";

export async function getAdminStudentList(
  query: AdminStudentListQuery,
): Promise<AdminStudentListData> {
  const supabase = await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_student_list",
    {
      p_search:
        query.search.length > 0
          ? query.search
          : null,

      p_grade_level:
        query.gradeLevel,

      p_gender:
        query.gender,

      p_care_group_id:
        query.careGroupId,

      p_tahfiz_group_id:
        query.tahfizGroupId,

      p_page:
        query.page,

      p_page_size:
        query.pageSize,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca data santri: ${error.message}`,
    );
  }

  const validationResult =
    adminStudentListSchema.safeParse(data);

  if (!validationResult.success) {
    console.error(
      "Response daftar santri tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format daftar santri tidak sesuai.",
    );
  }

  return validationResult.data;
}