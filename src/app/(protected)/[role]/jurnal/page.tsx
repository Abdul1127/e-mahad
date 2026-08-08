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
  PengasuhJournalOverview,
} from "@/features/pengasuh/journals/components/pengasuh-journal-overview";

import {
  getPengasuhJournalOverview,
} from "@/features/pengasuh/journals/data/get-pengasuh-journal-overview";

import {
  parsePengasuhJournalQuery,
  type PengasuhJournalSearchParams,
} from "@/features/pengasuh/journals/lib/parse-pengasuh-journal-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Jurnal Pengasuhan",

  description:
    "Jurnal harian pengasuhan santri E-Ma'had.",
};

type PengasuhJournalPageProps = {
  params: Promise<{
    role: string;
  }>;

  searchParams: Promise<PengasuhJournalSearchParams>;
};

export default async function PengasuhJournalPage({
  params,
  searchParams,
}: PengasuhJournalPageProps) {
  const {
    role,
  } = await params;

  const roleCode =
    getRoleCodeBySlug(
      role,
    );

  if (
    roleCode !==
    "pengasuh"
  ) {
    notFound();
  }

  await requireRole(
    "pengasuh",
  );

  const resolvedSearchParams =
    await searchParams;

  const query =
    parsePengasuhJournalQuery(
      resolvedSearchParams,
    );

  const data =
    await getPengasuhJournalOverview(
      query.date,
    );

  return (
    <PengasuhJournalOverview
      data={
        data
      }
    />
  );
}