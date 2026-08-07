import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { AdminStaffDetail } from "@/features/admin/staff/components/admin-staff-detail";
import { getAdminStaffDetail } from "@/features/admin/staff/data/get-admin-staff-detail";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Detail Staf",

  description:
    "Detail identitas, akun login, dan role staf E-Ma'had.",
};

type AdminStaffDetailPageProps = {
  params: Promise<{
    staffId: string;
  }>;
};

export default async function AdminStaffDetailPage({
  params,
}: AdminStaffDetailPageProps) {
  await requireRole("admin");

  const { staffId } =
    await params;

  const data =
    await getAdminStaffDetail(
      staffId,
    );

  if (!data) {
    notFound();
  }

  return (
    <AdminStaffDetail
      data={data}
    />
  );
}