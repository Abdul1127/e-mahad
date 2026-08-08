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
  PengasuhJournalDetailPreview,
} from "@/features/pengasuh/journals/components/pengasuh-journal-detail-preview";

import {
  getPengasuhJournalDetail,
} from "@/features/pengasuh/journals/data/get-pengasuh-journal-detail";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Detail Jurnal Pengasuhan",

  description:
    "Detail jurnal pengasuhan santri E-Ma'had.",
};

type PengasuhJournalDetailPageProps = {
  params: Promise<{
    role: string;
    journalId: string;
  }>;
};

export default async function PengasuhJournalDetailPage({
  params,
}: PengasuhJournalDetailPageProps) {
  const {
    role,
    journalId,
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

  const data =
    await getPengasuhJournalDetail(
      journalId,
    );

  return (
    <PengasuhJournalDetailPreview
      data={
        data
      }
    />
  );
}