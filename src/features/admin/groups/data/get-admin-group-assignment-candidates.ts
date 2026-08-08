import { z } from "zod";

import { createClient } from "@/lib/supabase/server";

import {
  adminGroupAssignmentCandidatesSchema,
  type AdminGroupAssignmentCandidatesData,
} from "../schemas/admin-group-assignment-candidates-schema";
import {
  adminGroupTypeSchema,
  type AdminGroupType,
} from "../schemas/admin-group-assignment-detail-schema";

const groupIdSchema =
  z.string().uuid();

export async function getAdminGroupAssignmentCandidates(
  groupType: AdminGroupType,
  groupId: string,
): Promise<AdminGroupAssignmentCandidatesData | null> {
  const groupTypeValidation =
    adminGroupTypeSchema.safeParse(
      groupType,
    );

  const groupIdValidation =
    groupIdSchema.safeParse(
      groupId,
    );

  if (
    !groupTypeValidation.success ||
    !groupIdValidation.success
  ) {
    return null;
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_group_assignment_candidates",
    {
      p_group_type:
        groupTypeValidation.data,

      p_group_id:
        groupIdValidation.data,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil kandidat assignment: ${error.message}`,
    );
  }

  if (data === null) {
    return null;
  }

  const validationResult =
    adminGroupAssignmentCandidatesSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Format kandidat assignment tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format data kandidat assignment dari database tidak valid.",
    );
  }

  return validationResult.data;
}