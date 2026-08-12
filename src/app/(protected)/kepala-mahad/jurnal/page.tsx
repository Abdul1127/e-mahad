import type {
  Metadata,
} from "next";

import {
  MahadHeadJournalOverview,
} from "@/features/kepala-mahad/journal/components/mahad-head-journal-overview";

import {
  getKepalaMahadJournalOverview,
} from "@/features/kepala-mahad/journal/data/get-kepala-mahad-journal-overview";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Jurnal Kepala Ma'had",
};

type PageProps = {
  searchParams:
    Promise<{
      from?:
        string;

      to?:
        string;
    }>;
};

export default async function KepalaMahadJournalPage({
  searchParams,
}: PageProps) {
  await requireRole(
    "kepala_mahad",
  );

  const query =
    await searchParams;

  const data =
    await getKepalaMahadJournalOverview({
      dateFrom:
        query.from ??
        null,

      dateTo:
        query.to ??
        null,
    });

  return (
    <MahadHeadJournalOverview
      mode="kepala_mahad"
      data={
        data
      }
    />
  );
}