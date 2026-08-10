import {
  createClient,
} from "@/lib/supabase/server";

import type {
  PembinaTahfizStudentListQuery,
} from "../lib/parse-pembina-tahfiz-student-list-query";

import {
  pembinaTahfizStudentListSchema,
  type PembinaTahfizStudentListData,
} from "../schemas/pembina-tahfiz-student-list-schema";

export async function getPembinaTahfizStudentList(
  query:
    PembinaTahfizStudentListQuery,
): Promise<PembinaTahfizStudentListData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pembina_tahfiz_student_list",
    {
      p_search:
        query.search,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Santri Tahfiz Ampuan: ${error.message}`,
    );
  }

  const validation =
    pembinaTahfizStudentListSchema.safeParse(
      data,
    );

  if (!validation.success) {
    console.error(
      "Format Santri Tahfiz Ampuan tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Santri Tahfiz Ampuan dari database tidak valid.",
    );
  }

  return validation.data;
}