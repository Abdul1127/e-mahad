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
  PengasuhJournalHistory,
} from "@/features/pengasuh/journals/components/pengasuh-journal-history";

import {
  getPengasuhJournalHistory,
} from "@/features/pengasuh/journals/data/get-pengasuh-journal-history";

import {
  parsePengasuhJournalHistoryQuery,
  type PengasuhJournalHistorySearchParams,
} from "@/features/pengasuh/journals/lib/parse-pengasuh-journal-history-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Riwayat Pengasuhan",

  description:
    "Riwayat Jurnal Pengasuhan E-Ma'had.",
};

type Props = {
  params: Promise<{
    role: string;
  }>;

  searchParams: Promise<PengasuhJournalHistorySearchParams>;
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
    "pengasuh"
  ) {
    notFound();
  }

  await requireRole(
    "pengasuh",
  );

  const query =
    parsePengasuhJournalHistoryQuery(
      await searchParams,
    );

  const data =
    await getPengasuhJournalHistory(
      query,
    );

  return (
    <PengasuhJournalHistory
      data={
        data
      }
      page={
        query.page
      }
    />
  );
}