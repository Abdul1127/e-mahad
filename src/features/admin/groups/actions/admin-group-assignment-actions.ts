"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createClient } from "@/lib/supabase/server";

import type { AdminGroupAssignmentActionState } from "../types/admin-group-assignment-action-state";

const groupTypeSchema = z.enum([
  "care",
  "tahfiz",
]);

const addAssignmentSchema =
  z.object({
    group_type:
      groupTypeSchema,

    group_id:
      z.string().uuid(),

    staff_id:
      z.string().uuid(),
  });

const endAssignmentSchema =
  z.object({
    group_type:
      groupTypeSchema,

    group_id:
      z.string().uuid(),

    assignment_id:
      z.string().uuid(),
  });

const setPrimarySchema =
  z.object({
    group_id:
      z.string().uuid(),

    assignment_id:
      z.string().uuid(),
  });

function createErrorState(
  message: string,
): AdminGroupAssignmentActionState {
  return {
    status: "error",
    message,
  };
}

function getGroupDetailPath(
  groupType:
    "care" | "tahfiz",
  groupId: string,
): string {
  return groupType === "care"
    ? `/admin/kelompok/pengasuhan/${groupId}`
    : `/admin/kelompok/tahfiz/${groupId}`;
}

export async function addAdminGroupAssignment(
  previousState:
    AdminGroupAssignmentActionState,
  formData: FormData,
): Promise<AdminGroupAssignmentActionState> {
  void previousState;

  await requireRole("admin");

  const validationResult =
    addAssignmentSchema.safeParse({
      group_type: String(
        formData.get(
          "group_type",
        ) ?? "",
      ),

      group_id: String(
        formData.get(
          "group_id",
        ) ?? "",
      ),

      staff_id: String(
        formData.get(
          "staff_id",
        ) ?? "",
      ),
    });

  if (!validationResult.success) {
    return createErrorState(
      "Data assignment tidak valid.",
    );
  }

  const {
    group_type: groupType,
    group_id: groupId,
    staff_id: staffId,
  } = validationResult.data;

  const supabase =
    await createClient();

  const {
    error,
  } = await supabase.rpc(
    "add_admin_group_assignment",
    {
      p_group_type:
        groupType,

      p_group_id:
        groupId,

      p_staff_id:
        staffId,
    },
  );

  if (error) {
    return createErrorState(
      error.message,
    );
  }

  const detailPath =
    getGroupDetailPath(
      groupType,
      groupId,
    );

  revalidatePath(
    "/admin/kelompok",
  );

  revalidatePath(
    detailPath,
  );

  revalidatePath(
    "/admin/staf",
  );

  revalidatePath(
    `/admin/staf/${staffId}`,
  );

  redirect(detailPath);
}

export async function endAdminGroupAssignment(
  previousState:
    AdminGroupAssignmentActionState,
  formData: FormData,
): Promise<AdminGroupAssignmentActionState> {
  void previousState;

  await requireRole("admin");

  const validationResult =
    endAssignmentSchema.safeParse({
      group_type: String(
        formData.get(
          "group_type",
        ) ?? "",
      ),

      group_id: String(
        formData.get(
          "group_id",
        ) ?? "",
      ),

      assignment_id:
        String(
          formData.get(
            "assignment_id",
          ) ?? "",
        ),
    });

  if (!validationResult.success) {
    return createErrorState(
      "Data assignment tidak valid.",
    );
  }

  const {
    group_type: groupType,
    group_id: groupId,
    assignment_id:
      assignmentId,
  } = validationResult.data;

  const supabase =
    await createClient();

  const {
    error,
  } = await supabase.rpc(
    "end_admin_group_assignment",
    {
      p_group_type:
        groupType,

      p_assignment_id:
        assignmentId,
    },
  );

  if (error) {
    return createErrorState(
      error.message,
    );
  }

  const detailPath =
    getGroupDetailPath(
      groupType,
      groupId,
    );

  revalidatePath(
    "/admin/kelompok",
  );

  revalidatePath(
    detailPath,
  );

  revalidatePath(
    "/admin/staf",
  );

  redirect(detailPath);
}

export async function setAdminTahfizPrimaryAssignment(
  previousState:
    AdminGroupAssignmentActionState,
  formData: FormData,
): Promise<AdminGroupAssignmentActionState> {
  void previousState;

  await requireRole("admin");

  const validationResult =
    setPrimarySchema.safeParse({
      group_id: String(
        formData.get(
          "group_id",
        ) ?? "",
      ),

      assignment_id:
        String(
          formData.get(
            "assignment_id",
          ) ?? "",
        ),
    });

  if (!validationResult.success) {
    return createErrorState(
      "Data Pembina Tahfiz tidak valid.",
    );
  }

  const {
    group_id: groupId,
    assignment_id:
      assignmentId,
  } = validationResult.data;

  const supabase =
    await createClient();

  const {
    error,
  } = await supabase.rpc(
    "set_admin_tahfiz_primary_assignment",
    {
      p_group_id:
        groupId,

      p_assignment_id:
        assignmentId,
    },
  );

  if (error) {
    return createErrorState(
      error.message,
    );
  }

  const detailPath =
    `/admin/kelompok/tahfiz/${groupId}`;

  revalidatePath(
    "/admin/kelompok",
  );

  revalidatePath(
    detailPath,
  );

  revalidatePath(
    "/admin/staf",
  );

  redirect(detailPath);
}