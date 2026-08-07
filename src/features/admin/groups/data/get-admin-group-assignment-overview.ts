import { createClient } from "@/lib/supabase/server";

import {
  adminGroupAssignmentOverviewSchema,
  type AdminGroupAssignmentOverviewData,
} from "../schemas/admin-group-assignment-overview-schema";

export async function getAdminGroupAssignmentOverview(): Promise<AdminGroupAssignmentOverviewData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_group_assignment_overview",
  );

  if (error) {
    throw new Error(
      `Gagal membaca Kelompok dan Assignment: ${error.message}`,
    );
  }

  const validationResult =
    adminGroupAssignmentOverviewSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response Kelompok dan Assignment tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format data Kelompok dan Assignment tidak sesuai.",
    );
  }

  return validationResult.data;
}