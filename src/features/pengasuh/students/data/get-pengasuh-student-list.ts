import { createClient } from "@/lib/supabase/server";

import type { PengasuhStudentListQuery } from "../lib/parse-pengasuh-student-list-query";
import {
  pengasuhStudentListSchema,
  type PengasuhStudentListData,
} from "../schemas/pengasuh-student-list-schema";

export async function getPengasuhStudentList(
  query:
    PengasuhStudentListQuery,
): Promise<PengasuhStudentListData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_pengasuh_student_list",
    {
      p_search:
        query.search.length > 0
          ? query.search
          : null,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Santri Ampuan: ${error.message}`,
    );
  }

  const validationResult =
    pengasuhStudentListSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Format Santri Ampuan tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format data Santri Ampuan dari database tidak valid.",
    );
  }

  return validationResult.data;
}