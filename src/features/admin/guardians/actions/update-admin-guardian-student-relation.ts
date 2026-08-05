"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { createClient } from "@/lib/supabase/server";

import { getAdminGuardianDetail } from "../data/get-admin-guardian-detail";
import { guardianStudentRelationEditSchema } from "../schemas/guardian-student-relation-edit-schema";
import type { GuardianStudentRelationEditActionState } from "../types/guardian-student-relation-mutation-state";

const uuidSchema = z.string().uuid();

export async function updateAdminGuardianStudentRelation(
  guardianId: string,
  relationId: string,
  previousState:
    GuardianStudentRelationEditActionState,
  formData: FormData,
): Promise<GuardianStudentRelationEditActionState> {
  void previousState;

  const values = {
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
    uuidSchema.safeParse(guardianId);

  const relationIdValidation =
    uuidSchema.safeParse(relationId);

  if (
    !guardianIdValidation.success ||
    !relationIdValidation.success
  ) {
    return {
      status: "error",
      message:
        "ID wali atau hubungan tidak valid.",
      fieldErrors: {},
      values,
    };
  }

  const validationResult =
    guardianStudentRelationEditSchema.safeParse(
      values,
    );

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Periksa kembali data hubungan.",

      fieldErrors:
        validationResult.error.flatten()
          .fieldErrors,

      values,
    };
  }

  let guardianDetail;

  try {
    guardianDetail =
      await getAdminGuardianDetail(
        guardianIdValidation.data,
      );
  } catch {
    return {
      status: "error",
      message:
        "Gagal memeriksa detail wali.",
      fieldErrors: {},
      values,
    };
  }

  if (!guardianDetail) {
    return {
      status: "error",
      message: "Data wali tidak ditemukan.",
      fieldErrors: {},
      values,
    };
  }

  const existingRelation =
    guardianDetail.children.find(
      (child) =>
        child.relation_id ===
        relationIdValidation.data,
    );

  if (!existingRelation) {
    return {
      status: "error",

      message:
        "Hubungan tersebut bukan milik wali yang sedang dibuka.",

      fieldErrors: {},
      values,
    };
  }

  const supabase = await createClient();

  const { error } = await supabase.rpc(
    "update_admin_guardian_student_relation",
    {
      p_relation_id:
        relationIdValidation.data,

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
    `/admin/santri/${existingRelation.student_id}`,
  );

  redirect(
    `/admin/wali/${guardianId}`,
  );
}