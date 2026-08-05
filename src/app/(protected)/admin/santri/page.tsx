import type { Metadata } from "next";

import { AdminStudentList } from "@/features/admin/students/components/admin-student-list";
import { getAdminStudentList } from "@/features/admin/students/data/get-admin-student-list";
import {
  parseStudentListQuery,
  type StudentListSearchParams,
} from "@/features/admin/students/lib/parse-student-list-query";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Data Santri",
  description:
    "Daftar santri E-Ma'had.",
};

type AdminStudentsPageProps = {
  searchParams: Promise<StudentListSearchParams>;
};

export default async function AdminStudentsPage({
  searchParams,
}: AdminStudentsPageProps) {
  await requireRole("admin");

  const resolvedSearchParams =
    await searchParams;

  const query = parseStudentListQuery(
    resolvedSearchParams,
  );

  const data =
    await getAdminStudentList(query);

  return (
    <AdminStudentList
      data={data}
      query={query}
    />
  );
}