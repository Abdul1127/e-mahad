import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { AdminStudentDetail } from "@/features/admin/students/components/admin-student-detail";
import { getAdminStudentDetail } from "@/features/admin/students/data/get-admin-student-detail";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Detail Santri",
  description: "Detail data santri E-Ma'had.",
};

type AdminStudentDetailPageProps = {
  params: Promise<{
    studentId: string;
  }>;
};

export default async function AdminStudentDetailPage({
  params,
}: AdminStudentDetailPageProps) {
  await requireRole("admin");

  const { studentId } = await params;

  const data =
    await getAdminStudentDetail(studentId);

  if (!data) {
    notFound();
  }

  return (
    <AdminStudentDetail data={data} />
  );
}