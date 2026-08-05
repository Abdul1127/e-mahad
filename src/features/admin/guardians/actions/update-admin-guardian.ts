"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";

import { createClient } from "@/lib/supabase/server";

import { guardianFormSchema } from "../schemas/guardian-form-schema";
import type { GuardianFormActionState } from "../types/guardian-form-action-state";

export async function updateAdminGuardian(
  guardianId: string,
  previousState: GuardianFormActionState,
  formData: FormData,
): Promise<GuardianFormActionState> {
  void previousState;

  const values = {
    legacy_guardian_id: String(
      formData.get("legacy_guardian_id") ??
        "",
    ),

    full_name: String(
      formData.get("full_name") ?? "",
    ),

    phone: String(
      formData.get("phone") ?? "",
    ),

    email: String(
      formData.get("email") ?? "",
    ),

    is_active:
      formData.get("is_active") === "on",
  };

  const validationResult =
    guardianFormSchema.safeParse(values);

  if (!validationResult.success) {
    return {
      status: "error",

      message:
        "Periksa kembali data wali yang diisi.",

      fieldErrors:
        validationResult.error.flatten()
          .fieldErrors,

      values,
    };
  }

  const supabase = await createClient();

  const { error } = await supabase.rpc(
    "update_admin_guardian",
    {
      p_guardian_id: guardianId,

      p_legacy_guardian_id:
        validationResult.data
          .legacy_guardian_id,

      p_full_name:
        validationResult.data.full_name,

      p_phone:
        validationResult.data.phone,

      p_email:
        validationResult.data.email,

      p_is_active:
        validationResult.data.is_active,
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

  redirect(
    `/admin/wali/${guardianId}`,
  );
}