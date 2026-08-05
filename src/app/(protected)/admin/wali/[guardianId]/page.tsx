import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { AdminGuardianDetail } from "@/features/admin/guardians/components/admin-guardian-detail";
import { getAdminGuardianDetail } from "@/features/admin/guardians/data/get-admin-guardian-detail";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Detail Wali",
  description:
    "Detail orang tua atau wali E-Ma'had.",
};

type AdminGuardianDetailPageProps = {
  params: Promise<{
    guardianId: string;
  }>;
};

export default async function AdminGuardianDetailPage({
  params,
}: AdminGuardianDetailPageProps) {
  await requireRole("admin");

  const { guardianId } = await params;

  const data =
    await getAdminGuardianDetail(
      guardianId,
    );

  if (!data) {
    notFound();
  }

  return (
    <AdminGuardianDetail data={data} />
  );
}