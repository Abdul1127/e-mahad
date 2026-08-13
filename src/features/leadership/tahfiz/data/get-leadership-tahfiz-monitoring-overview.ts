import {
  createClient,
} from "@/lib/supabase/server";

import type {
  LeadershipTahfizQuery,
} from "../lib/parse-leadership-tahfiz-query";

import {
  leadershipTahfizMonitoringOverviewSchema,
  type LeadershipTahfizMonitoringOverview,
} from "../schemas/leadership-tahfiz-schema";

export async function getLeadershipTahfizMonitoringOverview(
  query:
    LeadershipTahfizQuery,
): Promise<LeadershipTahfizMonitoringOverview> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_leadership_tahfiz_monitoring_overview",
      {
        p_week_start:
          query.weekStart,

        p_search:
          query.search,

        p_group_id:
          query.groupId,
      },
    );

  if (error) {
    throw new Error(
      `Gagal mengambil monitoring Tahfiz: ${error.message}`,
    );
  }

  const validation =
    leadershipTahfizMonitoringOverviewSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format monitoring Tahfiz pimpinan tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format monitoring Tahfiz dari database tidak valid.",
    );
  }

  return validation.data;
}