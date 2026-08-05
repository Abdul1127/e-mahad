import { createClient } from "@/lib/supabase/server";

import {
  studentFormOptionsSchema,
  type StudentFormOptions,
} from "../schemas/admin-student-form-schema";

export async function getAdminStudentFormOptions(): Promise<StudentFormOptions> {
  const supabase = await createClient();

  const { data, error } = await supabase.rpc(
    "get_admin_student_form_options",
  );

  if (error) {
    throw new Error(
      `Gagal membaca opsi form santri: ${error.message}`,
    );
  }

  const validationResult =
    studentFormOptionsSchema.safeParse(data);

  if (!validationResult.success) {
    console.error(
      "Response opsi form santri tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format opsi form santri tidak sesuai.",
    );
  }

  return validationResult.data;
}