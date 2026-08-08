import { z } from "zod";

import { createClient } from "@/lib/supabase/server";

import {
  adminGroupAssignmentDetailSchema,
  adminGroupTypeSchema,
  type AdminGroupAssignmentDetailData,
  type AdminGroupType,
} from "../schemas/admin-group-assignment-detail-schema";

const groupIdSchema =
  z.string().uuid();

export async function getAdminGroupAssignmentDetail(
  groupType: AdminGroupType,
  groupId: string,
): Promise<AdminGroupAssignmentDetailData | null> {
  const typeValidation =
    adminGroupTypeSchema.safeParse(
      groupType,
    );

  const idValidation =
    groupIdSchema.safeParse(
      groupId,
    );

  if (
    !typeValidation.success ||
    !idValidation.success
  ) {
    return null;
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_group_assignment_detail",
    {
      p_group_type:
        typeValidation.data,

      p_group_id:
        idValidation.data,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca detail kelompok: ${error.message}`,
    );
  }

  if (data === null) {
    return null;
  }

  const validationResult =
    adminGroupAssignmentDetailSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response detail kelompok tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format detail kelompok tidak sesuai.",
    );
  }

  if (
    validationResult.data.group_type !==
    typeValidation.data
  ) {
    throw new Error(
      "Tipe kelompok pada response tidak sesuai.",
    );
  }

  return validationResult.data;
}