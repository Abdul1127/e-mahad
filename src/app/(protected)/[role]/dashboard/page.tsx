import { notFound } from "next/navigation";

import { RoleDashboard } from "@/components/layout/role-dashboard";
import { getRoleCodeBySlug } from "@/config/roles";
import { AdminDashboard } from "@/features/admin/dashboard/components/admin-dashboard";
import { getAdminDashboardData } from "@/features/admin/dashboard/data/get-admin-dashboard-data";
import { PengasuhDashboard } from "@/features/pengasuh/dashboard/components/pengasuh-dashboard";
import { getPengasuhDashboardData } from "@/features/pengasuh/dashboard/data/get-pengasuh-dashboard-data";
import { requireRole } from "@/lib/auth/guards";

type RoleDashboardPageProps = {
  params: Promise<{
    role: string;
  }>;
};

export default async function RoleDashboardPage({
  params,
}: RoleDashboardPageProps) {
  const {
    role,
  } = await params;

  const roleCode =
    getRoleCodeBySlug(
      role,
    );

  if (!roleCode) {
    notFound();
  }

  const context =
    await requireRole(
      roleCode,
    );

  if (
    roleCode ===
    "admin"
  ) {
    const dashboardData =
      await getAdminDashboardData();

    return (
      <AdminDashboard
        context={
          context
        }
        data={
          dashboardData
        }
      />
    );
  }

  if (
    roleCode ===
    "pengasuh"
  ) {
    const dashboardData =
      await getPengasuhDashboardData();

    return (
      <PengasuhDashboard
        data={
          dashboardData
        }
      />
    );
  }

  return (
    <RoleDashboard
      context={
        context
      }
      roleCode={
        roleCode
      }
    />
  );
}