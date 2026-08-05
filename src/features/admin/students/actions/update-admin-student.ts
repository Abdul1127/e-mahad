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

export async function updateAdminStudentAction(
  _previousState: StudentFormActionState,
  formData: FormData,
): Promise<StudentFormActionState> {
  await requireRole("admin");

  const studentId = String(
    formData.get("studentId") ?? "",
  );

  if (!studentId) {
    return {
      status: "error",
      message:
        "Student ID tidak tersedia.",
      fieldErrors: {},
    };
  }

  const validationResult =
    adminStudentFormSchema.safeParse({
      legacyStudentId: String(
        formData.get(
          "legacyStudentId",
        ) ?? "",
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
        formData.get(
          "tahfizGroupId",
        ) ?? "",
      ),
    });

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
    "update_admin_student",
    {
      p_student_id:
        studentId,

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
      "Gagal mengubah santri:",
      error,
    );

    return {
      status: "error",
      message:
        error.message.includes(
          "sudah digunakan",
        )
          ? error.message
          : "Perubahan santri gagal disimpan. Periksa identitas dan penempatannya.",
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
        "Perubahan tersimpan, tetapi response database tidak sesuai.",
      fieldErrors: {},
    };
  }

  revalidatePath("/admin/dashboard");
  revalidatePath("/admin/santri");
  revalidatePath(
    `/admin/santri/${studentId}`,
  );

  redirect(
    `/admin/santri/${studentId}`,
  );
}