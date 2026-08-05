import { createClient } from "@/lib/supabase/server";

import {
  guardianStudentOptionsSchema,
  type GuardianStudentOptionsData,
} from "../schemas/guardian-student-options-schema";

export async function getAdminGuardianStudentOptions(
  guardianId: string,
  search: string,
): Promise<GuardianStudentOptionsData> {
  const supabase = await createClient();

  const { data, error } = await supabase.rpc(
    "get_admin_guardian_student_options",
    {
      p_guardian_id: guardianId,

      p_search:
        search.length > 0
          ? search
          : null,

      p_limit: 50,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca pilihan santri: ${error.message}`,
    );
  }

  const validationResult =
    guardianStudentOptionsSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response pilihan santri tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format pilihan santri tidak sesuai.",
    );
  }

  return validationResult.data;
}