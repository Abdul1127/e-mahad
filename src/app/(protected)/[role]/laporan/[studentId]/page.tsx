import {
  notFound,
} from "next/navigation";

import {
  z,
} from "zod";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  PembinaTahfizWeeklyReportDetail,
} from "@/features/pembina-tahfiz/weekly-reports/components/pembina-tahfiz-weekly-report-detail";

import {
  getPembinaTahfizWeeklyReportDetail,
} from "@/features/pembina-tahfiz/weekly-reports/data/get-pembina-tahfiz-weekly-report-detail";

import {
  parsePembinaTahfizWeekStart,
  type PembinaTahfizWeeklyReportSearchParams,
} from "@/features/pembina-tahfiz/weekly-reports/lib/parse-pembina-tahfiz-weekly-report-query";

import {
  requireRole,
} from "@/lib/auth/guards";

const studentIdSchema =
  z.string().uuid();

type Props = {
  params: Promise<{
    role: string;
    studentId: string;
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
    studentId,
  } = await params;

  if (
    getRoleCodeBySlug(
      role,
    ) !==
    "pembina_tahfiz"
  ) {
    notFound();
  }

  const studentValidation =
    studentIdSchema.safeParse(
      studentId,
    );

  if (
    !studentValidation.success
  ) {
    notFound();
  }

  const resolvedSearchParams =
    await searchParams;

  const weekStart =
    parsePembinaTahfizWeekStart(
      resolvedSearchParams.week,
    );

  if (!weekStart) {
    notFound();
  }

  await requireRole(
    "pembina_tahfiz",
  );

  const data =
    await getPembinaTahfizWeeklyReportDetail(
      studentValidation.data,
      weekStart,
    );

  return (
    <PembinaTahfizWeeklyReportDetail
      data={
        data
      }
    />
  );
}