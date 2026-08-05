import { createClient } from "@/lib/supabase/server";

import {
  adminDashboardSchema,
  type AdminDashboardData,
} from "../schemas/admin-dashboard-schema";

export async function getAdminDashboardData(): Promise<AdminDashboardData> {
  const supabase = await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_dashboard_summary",
  );

  if (error) {
    throw new Error(
      `Gagal membaca Dashboard Admin: ${error.message}`,
    );
  }

  const validationResult =
    adminDashboardSchema.safeParse(data);

  if (!validationResult.success) {
    console.error(
      "Response Dashboard Admin tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format data Dashboard Admin tidak sesuai.",
    );
  }

  return validationResult.data;
}