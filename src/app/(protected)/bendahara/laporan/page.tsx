import type {
  Metadata,
} from "next";

import {
  BendaharaFinanceReport,
} from "@/features/bendahara/reports/components/bendahara-finance-report";

import {
  getBendaharaFinanceReport,
} from "@/features/bendahara/reports/data/get-bendahara-finance-report";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Laporan Keuangan",

  description:
    "Laporan keuangan periode untuk Bendahara E-Ma'had.",
};

type PageProps = {
  searchParams:
    Promise<{
      start?:
        string | string[];

      end?:
        string | string[];
    }>;
};

const DATE_PATTERN =
  /^\d{4}-\d{2}-\d{2}$/;

function getSingleQueryValue(
  value:
    string |
    string[] |
    undefined,
): string | null {
  if (
    typeof value !==
    "string"
  ) {
    return null;
  }

  const normalized =
    value.trim();

  if (
    !DATE_PATTERN.test(
      normalized,
    )
  ) {
    return null;
  }

  return normalized;
}

export default async function BendaharaFinanceReportPage({
  searchParams,
}: PageProps) {
  await requireRole(
    "bendahara",
  );

  const query =
    await searchParams;

  const startDate =
    getSingleQueryValue(
      query.start,
    );

  const endDate =
    getSingleQueryValue(
      query.end,
    );

  const data =
    await getBendaharaFinanceReport({
      startDate,
      endDate,
    });

  return (
    <BendaharaFinanceReport
      data={
        data
      }
    />
  );
}