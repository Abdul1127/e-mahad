import type {
  Metadata,
} from "next";

import {
  notFound,
} from "next/navigation";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  PembinaTahfizWeeklyReportOverview,
} from "@/features/pembina-tahfiz/weekly-reports/components/pembina-tahfiz-weekly-report-overview";

import {
  getPembinaTahfizWeeklyReportOverview,
} from "@/features/pembina-tahfiz/weekly-reports/data/get-pembina-tahfiz-weekly-report-overview";

import {
  parsePembinaTahfizWeeklyReportQuery,
  type PembinaTahfizWeeklyReportSearchParams,
} from "@/features/pembina-tahfiz/weekly-reports/lib/parse-pembina-tahfiz-weekly-report-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Laporan Tahfiz",

  description:
    "Laporan Tahfiz Mingguan E-Ma'had.",
};

type Props = {
  params: Promise<{
    role: string;
  }>;

  searchParams:
    Promise<PembinaTahfizWeeklyReportSearchParams>;
};

export default async function Page({
  params,
  searchParams,
}: Props) {
  const {
    role,
  } = await params;

  if (
    getRoleCodeBySlug(
      role,
    ) !==
    "pembina_tahfiz"
  ) {
    notFound();
  }

  await requireRole(
    "pembina_tahfiz",
  );

  const query =
    parsePembinaTahfizWeeklyReportQuery(
      await searchParams,
    );

  const data =
    await getPembinaTahfizWeeklyReportOverview(
      query,
    );

  return (
    <PembinaTahfizWeeklyReportOverview
      data={
        data
      }
    />
  );
}