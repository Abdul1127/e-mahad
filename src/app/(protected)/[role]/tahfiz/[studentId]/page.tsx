import type {
  Metadata,
} from "next";

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
  GuardianTahfizReportHistory,
} from "@/features/guardian/tahfiz/components/guardian-tahfiz-report-history";

import {
  getGuardianTahfizReportHistory,
} from "@/features/guardian/tahfiz/data/get-guardian-tahfiz-report-history";

import {
  parseGuardianTahfizReportHistoryQuery,
  type GuardianTahfizReportHistorySearchParams,
} from "@/features/guardian/tahfiz/lib/parse-guardian-tahfiz-report-history-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Riwayat Tahfiz",

  description:
    "Riwayat perkembangan Tahfiz santri E-Ma'had.",
};

const studentIdSchema =
  z.string().uuid();

type Props = {
  params: Promise<{
    role: string;
    studentId: string;
  }>;

  searchParams:
    Promise<GuardianTahfizReportHistorySearchParams>;
};

export default async function Page({
  params,
  searchParams,
}: Props) {
  const {
    role,
    studentId,
  } = await params;

  /*
   * =====================================================
   * ROLE
   * =====================================================
   */

  if (
    getRoleCodeBySlug(
      role,
    ) !==
    "guardian"
  ) {
    notFound();
  }

  /*
   * =====================================================
   * STUDENT ID
   * =====================================================
   */

  const studentValidation =
    studentIdSchema.safeParse(
      studentId,
    );

  if (
    !studentValidation.success
  ) {
    notFound();
  }

  /*
   * =====================================================
   * AUTHORIZATION
   * =====================================================
   */

  await requireRole(
    "guardian",
  );

  /*
   * =====================================================
   * QUERY
   * =====================================================
   */

  const query =
    parseGuardianTahfizReportHistoryQuery(
      await searchParams,
    );

  /*
   * =====================================================
   * DATA
   * =====================================================
   */

  const data =
    await getGuardianTahfizReportHistory(
      studentValidation.data,
      query,
    );

  return (
    <GuardianTahfizReportHistory
      data={data}
      page={query.page}
    />
  );
}