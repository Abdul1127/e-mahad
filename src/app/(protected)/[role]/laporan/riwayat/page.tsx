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
  PembinaTahfizWeeklyReportHistory,
} from "@/features/pembina-tahfiz/weekly-reports/components/pembina-tahfiz-weekly-report-history";

import {
  getPembinaTahfizWeeklyReportHistory,
} from "@/features/pembina-tahfiz/weekly-reports/data/get-pembina-tahfiz-weekly-report-history";

import {
  parsePembinaTahfizWeeklyReportHistoryQuery,
  type PembinaTahfizWeeklyReportHistorySearchParams,
} from "@/features/pembina-tahfiz/weekly-reports/lib/parse-pembina-tahfiz-weekly-report-history-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Riwayat Laporan Tahfiz",

  description:
    "Riwayat Laporan Tahfiz Mingguan E-Ma'had.",
};

type Props = {
  params: Promise<{
    role: string;
  }>;

  searchParams:
    Promise<PembinaTahfizWeeklyReportHistorySearchParams>;
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
    parsePembinaTahfizWeeklyReportHistoryQuery(
      await searchParams,
    );

  const data =
    await getPembinaTahfizWeeklyReportHistory(
      query,
    );

  return (
    <PembinaTahfizWeeklyReportHistory
      data={
        data
      }
      page={
        query.page
      }
    />
  );
}