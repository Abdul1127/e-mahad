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
  KepalaMahadCareJournalDetail,
} from "@/features/kepala-mahad/care-journals/components/kepala-mahad-care-journal-detail";

import {
  getKepalaMahadCareJournalDetail,
} from "@/features/kepala-mahad/care-journals/data/get-kepala-mahad-care-journal-detail";

import {
  requireRole,
} from "@/lib/auth/guards";

const journalIdSchema =
  z.string().uuid();

type Props = {
  params: Promise<{
    role: string;
    journalId: string;
  }>;
};

export default async function Page({
  params,
}: Props) {
  const {
    role,
    journalId,
  } = await params;

  if (
    getRoleCodeBySlug(
      role,
    ) !==
    "kepala_mahad"
  ) {
    notFound();
  }

  const validation =
    journalIdSchema.safeParse(
      journalId,
    );

  if (!validation.success) {
    notFound();
  }

  await requireRole(
    "kepala_mahad",
  );

  const data =
    await getKepalaMahadCareJournalDetail(
      validation.data,
    );

  return (
    <KepalaMahadCareJournalDetail
      data={
        data
      }
    />
  );
}