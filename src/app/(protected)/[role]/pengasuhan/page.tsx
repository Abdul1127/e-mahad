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
  KepalaMahadCareJournalOverview,
} from "@/features/kepala-mahad/care-journals/components/kepala-mahad-care-journal-overview";

import {
  getKepalaMahadCareJournalOverview,
} from "@/features/kepala-mahad/care-journals/data/get-kepala-mahad-care-journal-overview";

import {
  parseKepalaMahadCareJournalQuery,
  type KepalaMahadCareJournalSearchParams,
} from "@/features/kepala-mahad/care-journals/lib/parse-kepala-mahad-care-journal-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Jurnal Pengasuhan",

  description:
    "Review Jurnal Pengasuhan Kepala Ma'had.",
};

type Props = {
  params: Promise<{
    role: string;
  }>;

  searchParams: Promise<KepalaMahadCareJournalSearchParams>;
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
    "kepala_mahad"
  ) {
    notFound();
  }

  await requireRole(
    "kepala_mahad",
  );

  const query =
    parseKepalaMahadCareJournalQuery(
      await searchParams,
    );

  const data =
    await getKepalaMahadCareJournalOverview(
      query,
    );

  return (
    <KepalaMahadCareJournalOverview
      data={
        data
      }
    />
  );
}