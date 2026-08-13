import type {
  Metadata,
} from "next";

import {
  LeadershipTahfizMonitoringOverview,
} from "@/features/leadership/tahfiz/components/leadership-tahfiz-monitoring-overview";

import {
  getLeadershipTahfizMonitoringOverview,
} from "@/features/leadership/tahfiz/data/get-leadership-tahfiz-monitoring-overview";

import {
  parseLeadershipTahfizQuery,
  type LeadershipTahfizSearchParams,
} from "@/features/leadership/tahfiz/lib/parse-leadership-tahfiz-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Monitoring Tahfiz",
};

type Props = {
  searchParams:
    Promise<LeadershipTahfizSearchParams>;
};

export default async function KepalaMahadTahfizPage({
  searchParams,
}: Props) {
  await requireRole(
    "kepala_mahad",
  );

  const query =
    parseLeadershipTahfizQuery(
      await searchParams,
    );

  const data =
    await getLeadershipTahfizMonitoringOverview(
      query,
    );

  return (
    <LeadershipTahfizMonitoringOverview
      data={
        data
      }
      roleSlug="kepala-mahad"
      page={
        query.page
      }
      pageSize={
        query.pageSize
      }
    />
  );
}