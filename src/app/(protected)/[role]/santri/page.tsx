import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { getRoleCodeBySlug } from "@/config/roles";
import { PengasuhStudentList } from "@/features/pengasuh/students/components/pengasuh-student-list";
import { getPengasuhStudentList } from "@/features/pengasuh/students/data/get-pengasuh-student-list";
import {
  parsePengasuhStudentListQuery,
  type PengasuhStudentListSearchParams,
} from "@/features/pengasuh/students/lib/parse-pengasuh-student-list-query";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Santri Ampuan",
  description:
    "Daftar santri yang menjadi tanggung jawab Pengasuh E-Ma'had.",
};

type PengasuhStudentsPageProps = {
  params: Promise<{
    role: string;
  }>;

  searchParams: Promise<PengasuhStudentListSearchParams>;
};

export default async function PengasuhStudentsPage({
  params,
  searchParams,
}: PengasuhStudentsPageProps) {
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
    parsePengasuhStudentListQuery(
      resolvedSearchParams,
    );

  const data =
    await getPengasuhStudentList(
      query,
    );

  return (
    <PengasuhStudentList
      data={
        data
      }
      search={
        query.search
      }
    />
  );
}