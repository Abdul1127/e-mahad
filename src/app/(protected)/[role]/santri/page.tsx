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
  PengasuhStudentList,
} from "@/features/pengasuh/students/components/pengasuh-student-list";

import {
  getPengasuhStudentList,
} from "@/features/pengasuh/students/data/get-pengasuh-student-list";

import {
  parsePengasuhStudentListQuery,
  type PengasuhStudentListSearchParams,
} from "@/features/pengasuh/students/lib/parse-pengasuh-student-list-query";

import {
  PembinaTahfizStudentList,
} from "@/features/pembina-tahfiz/students/components/pembina-tahfiz-student-list";

import {
  getPembinaTahfizStudentList,
} from "@/features/pembina-tahfiz/students/data/get-pembina-tahfiz-student-list";

import {
  parsePembinaTahfizStudentListQuery,
  type PembinaTahfizStudentListSearchParams,
} from "@/features/pembina-tahfiz/students/lib/parse-pembina-tahfiz-student-list-query";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Santri Ampuan",

  description:
    "Daftar Santri Ampuan E-Ma'had.",
};

type CombinedSearchParams =
  PengasuhStudentListSearchParams &
  PembinaTahfizStudentListSearchParams;

type Props = {
  params: Promise<{
    role: string;
  }>;

  searchParams:
    Promise<CombinedSearchParams>;
};

export default async function Page({
  params,
  searchParams,
}: Props) {
  const {
    role,
  } = await params;

  const roleCode =
    getRoleCodeBySlug(
      role,
    );

  const resolvedSearchParams =
    await searchParams;

  /*
   * =====================================================
   * PENGASUH
   * =====================================================
   */

  if (
    roleCode ===
    "pengasuh"
  ) {
    await requireRole(
      "pengasuh",
    );

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
          query.search ??
          ""
        }
      />
    );
  }

  /*
   * =====================================================
   * PEMBINA TAHFIZ
   * =====================================================
   */

  if (
    roleCode ===
    "pembina_tahfiz"
  ) {
    await requireRole(
      "pembina_tahfiz",
    );

    const query =
      parsePembinaTahfizStudentListQuery(
        resolvedSearchParams,
      );

    const data =
      await getPembinaTahfizStudentList(
        query,
      );

    return (
      <PembinaTahfizStudentList
        data={
          data
        }
      />
    );
  }

  /*
   * =====================================================
   * ROLE LAIN
   * =====================================================
   */

  notFound();
}