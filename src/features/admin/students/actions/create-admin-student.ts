"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { requireRole } from "@/lib/auth/guards";
import { createClient } from "@/lib/supabase/server";

import {
  adminStudentFormSchema,
  studentMutationResultSchema,
} from "../schemas/admin-student-form-schema";
import type { StudentFormActionState } from "../types/student-form-action-state";

function getFormValues(formData: FormData) {
  return {
    legacyStudentId: String(
      formData.get("legacyStudentId") ?? "",
    ),

    nis: String(
      formData.get("nis") ?? "",
    ),

    fullName: String(
      formData.get("fullName") ?? "",
    ),

    gender: String(
      formData.get("gender") ?? "",
    ),

    status: String(
      formData.get("status") ?? "",
    ),

    classId: String(
      formData.get("classId") ?? "",
    ),

    careGroupId: String(
      formData.get("careGroupId") ?? "",
    ),

    tahfizGroupId: String(
      formData.get("tahfizGroupId") ?? "",
    ),
  };
}

export async function createAdminStudentAction(
  _previousState: StudentFormActionState,
  formData: FormData,
): Promise<StudentFormActionState> {
  await requireRole("admin");

  const validationResult =
    adminStudentFormSchema.safeParse(
      getFormValues(formData),
    );

  if (!validationResult.success) {
    return {
      status: "error",
      message:
        "Periksa kembali data santri yang dimasukkan.",
      fieldErrors:
        validationResult.error.flatten()
          .fieldErrors,
    };
  }

  const input = validationResult.data;
  const supabase = await createClient();

  const { data, error } = await supabase.rpc(
    "create_admin_student",
    {
      p_legacy_student_id:
        input.legacyStudentId,

      p_nis:
        input.nis || null,

      p_full_name:
        input.fullName,

      p_gender:
        input.gender,

      p_status:
        input.status,

      p_class_id:
        input.classId,

      p_care_group_id:
        input.careGroupId,

      p_tahfiz_group_id:
        input.tahfizGroupId,
    },
  );

  if (error) {
    console.error(
      "Gagal menambah santri:",
      error,
    );

    return {
      status: "error",
      message:
        error.message.includes(
          "sudah digunakan",
        )
          ? error.message
          : "Data santri gagal disimpan. Periksa kembali data dan penempatannya.",
      fieldErrors: {},
    };
  }

  const result =
    studentMutationResultSchema.safeParse(
      data,
    );

  if (!result.success) {
    return {
      status: "error",
      message:
        "Santri tersimpan, tetapi response database tidak sesuai.",
      fieldErrors: {},
    };
  }

  revalidatePath("/admin/dashboard");
  revalidatePath("/admin/santri");

  redirect(
    `/admin/santri/${result.data.student_id}`,
  );
}