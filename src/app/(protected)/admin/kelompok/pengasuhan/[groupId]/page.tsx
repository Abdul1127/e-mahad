import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { AdminGroupAssignmentDetail } from "@/features/admin/groups/components/admin-group-assignment-detail";
import { getAdminGroupAssignmentDetail } from "@/features/admin/groups/data/get-admin-group-assignment-detail";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Detail Kelompok Pengasuhan",
};

type PageProps = {
  params: Promise<{
    groupId: string;
  }>;
};

export default async function AdminCareGroupDetailPage({
  params,
}: PageProps) {
  await requireRole("admin");

  const { groupId } =
    await params;

  const data =
    await getAdminGroupAssignmentDetail(
      "care",
      groupId,
    );

  if (!data) {
    notFound();
  }

  return (
    <AdminGroupAssignmentDetail
      data={data}
    />
  );
}