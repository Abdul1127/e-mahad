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
  LeadershipTahfizStudentHistory,
} from "@/features/leadership/tahfiz/components/leadership-tahfiz-student-history";

import {
  getLeadershipTahfizStudentHistory,
} from "@/features/leadership/tahfiz/data/get-leadership-tahfiz-student-history";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Riwayat Tahfiz Santri",
};

type Props = {
  params:
    Promise<{
      studentId:
        string;
    }>;

  searchParams:
    Promise<{
      page?:
        string;
    }>;
};

export default async function PenanggungJawabTahfizStudentPage({
  params,
  searchParams,
}: Props) {
  await requireRole(
    "penanggung_jawab",
  );

  const {
    studentId,
  } =
    await params;

  const validation =
    z.string()
      .uuid()
      .safeParse(
        studentId,
      );

  if (
    !validation.success
  ) {
    notFound();
  }

  const query =
    await searchParams;

  const rawPage =
    Number(
      query.page ??
      "1",
    );

  const page =
    Number.isInteger(
      rawPage,
    ) &&
    rawPage >
      0
      ? rawPage
      : 1;

  let data;

  try {
    data =
      await getLeadershipTahfizStudentHistory(
        validation.data,
        page,
      );
  } catch {
    notFound();
  }

  return (
    <LeadershipTahfizStudentHistory
      data={
        data
      }
      roleSlug="penanggung-jawab"
      page={
        page
      }
    />
  );
}