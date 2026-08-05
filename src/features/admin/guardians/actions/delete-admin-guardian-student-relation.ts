"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { createClient } from "@/lib/supabase/server";

import { getAdminGuardianDetail } from "../data/get-admin-guardian-detail";
import type { GuardianStudentRelationDeleteActionState } from "../types/guardian-student-relation-mutation-state";

const uuidSchema = z.string().uuid();

export async function deleteAdminGuardianStudentRelation(
  guardianId: string,
  relationId: string,
  previousState:
    GuardianStudentRelationDeleteActionState,
  formData: FormData,
): Promise<GuardianStudentRelationDeleteActionState> {
  void previousState;
  void formData;

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
    };
  }

  if (!guardianDetail) {
    return {
      status: "error",
      message: "Data wali tidak ditemukan.",
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
    };
  }

  const supabase = await createClient();

  const { error } = await supabase.rpc(
    "delete_admin_guardian_student_relation",
    {
      p_relation_id:
        relationIdValidation.data,
    },
  );

  if (error) {
    return {
      status: "error",
      message: error.message,
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