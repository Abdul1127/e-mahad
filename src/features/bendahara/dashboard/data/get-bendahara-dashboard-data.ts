import {
  createClient,
} from "@/lib/supabase/server";

import {
  bendaharaDashboardSchema,
  type BendaharaDashboardData,
} from "../schemas/bendahara-dashboard-schema";

export async function getBendaharaDashboardData(): Promise<BendaharaDashboardData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_bendahara_dashboard",
  );

  if (error) {
    throw new Error(
      `Gagal mengambil Dashboard Bendahara: ${error.message}`,
    );
  }

  const validation =
    bendaharaDashboardSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format Dashboard Bendahara tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format Dashboard Bendahara dari database tidak valid.",
    );
  }

  return validation.data;
}