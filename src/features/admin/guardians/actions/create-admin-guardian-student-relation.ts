"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { createClient } from "@/lib/supabase/server";

import { guardianStudentRelationFormSchema } from "../schemas/guardian-student-relation-form-schema";
import type { GuardianStudentRelationActionState } from "../types/guardian-student-relation-action-state";

const guardianIdSchema = z.string().uuid();

export async function createAdminGuardianStudentRelation(
  guardianId: string,
  previousState:
    GuardianStudentRelationActionState,
  formData: FormData,
): Promise<GuardianStudentRelationActionState> {
  void previousState;

  const values = {
    student_id: String(
      formData.get("student_id") ?? "",
    ),

    relationship_type: String(
      formData.get(
        "relationship_type",
      ) ?? "",
    ),

    is_primary_contact:
      formData.get(
        "is_primary_contact",
      ) === "on",
  };

  const guardianIdValidation =
    guardianIdSchema.safeParse(
      guardianId,
    );

  if (!guardianIdValidation.success) {
    return {
      status: "error",

      message:
        "ID wali tidak valid.",

      fieldErrors: {},
      values,
    };
  }

  const validationResult =
    guardianStudentRelationFormSchema.safeParse(
      values,
    );

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Periksa kembali hubungan wali dan santri.",

      fieldErrors:
        validationResult.error.flatten()
          .fieldErrors,

      values,
    };
  }

  const supabase = await createClient();

  const { error } = await supabase.rpc(
    "create_admin_guardian_student_relation",
    {
      p_guardian_id:
        guardianIdValidation.data,

      p_student_id:
        validationResult.data.student_id,

      p_relationship_type:
        validationResult.data
          .relationship_type,

      p_is_primary_contact:
        validationResult.data
          .is_primary_contact,
    },
  );

  if (error) {
    return {
      status: "error",
      message: error.message,
      fieldErrors: {},
      values,
    };
  }

  revalidatePath("/admin/wali");

  revalidatePath(
    `/admin/wali/${guardianId}`,
  );

  revalidatePath(
    `/admin/santri/${validationResult.data.student_id}`,
  );

  redirect(
    `/admin/wali/${guardianId}`,
  );
}