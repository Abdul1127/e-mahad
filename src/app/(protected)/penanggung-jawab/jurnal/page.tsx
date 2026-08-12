import type {
  Metadata,
} from "next";

import {
  MahadHeadJournalOverview,
} from "@/features/kepala-mahad/journal/components/mahad-head-journal-overview";

import {
  getPenanggungJawabMahadHeadJournalOverview,
} from "@/features/kepala-mahad/journal/data/get-penanggung-jawab-mahad-head-journal-overview";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Monitoring Jurnal Kepala Ma'had",
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

export default async function PenanggungJawabJournalPage({
  searchParams,
}: PageProps) {
  await requireRole(
    "penanggung_jawab",
  );

  const query =
    await searchParams;

  const data =
    await getPenanggungJawabMahadHeadJournalOverview({
      dateFrom:
        query.from ??
        null,

      dateTo:
        query.to ??
        null,
    });

  return (
    <MahadHeadJournalOverview
      mode="penanggung_jawab"
      data={
        data
      }
    />
  );
}