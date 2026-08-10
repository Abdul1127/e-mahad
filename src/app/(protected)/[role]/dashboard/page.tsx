import { notFound } from "next/navigation";

import { RoleDashboard } from "@/components/layout/role-dashboard";
import { getRoleCodeBySlug } from "@/config/roles";

import { BendaharaDashboard } from "@/features/bendahara/dashboard/components/bendahara-dashboard";
import { getBendaharaDashboardData } from "@/features/bendahara/dashboard/data/get-bendahara-dashboard-data";

import { GuardianTahfizDashboard } from "@/features/guardian/dashboard/components/guardian-tahfiz-dashboard";
import { getGuardianTahfizDashboardData } from "@/features/guardian/dashboard/data/get-guardian-tahfiz-dashboard-data";

import { PembinaTahfizDashboard } from "@/features/pembina-tahfiz/dashboard/components/pembina-tahfiz-dashboard";
import { getPembinaTahfizDashboardData } from "@/features/pembina-tahfiz/dashboard/data/get-pembina-tahfiz-dashboard-data";

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
  const { role } = await params;

  /*
   * =====================================================
   * RESOLVE ROLE
   * =====================================================
   */

  const roleCode =
    getRoleCodeBySlug(role);

  if (!roleCode) {
    notFound();
  }

  /*
   * =====================================================
   * AUTHORIZATION
   *
   * context tetap disimpan karena dibutuhkan oleh
   * RoleDashboard generic.
   * =====================================================
   */

  const context =
    await requireRole(roleCode);

  /*
   * =====================================================
   * DASHBOARD PENGASUH
   * =====================================================
   */

  if (
    roleCode ===
    "pengasuh"
  ) {
    const data =
      await getPengasuhDashboardData();

    return (
      <PengasuhDashboard
        data={data}
      />
    );
  }

  /*
   * =====================================================
   * DASHBOARD PEMBINA TAHFIZ
   * =====================================================
   */

  if (
    roleCode ===
    "pembina_tahfiz"
  ) {
    const data =
      await getPembinaTahfizDashboardData();

    return (
      <PembinaTahfizDashboard
        data={data}
      />
    );
  }

  /*
   * =====================================================
   * DASHBOARD ORANG TUA / WALI
   * =====================================================
   */

  if (
    roleCode ===
    "guardian"
  ) {
    const data =
      await getGuardianTahfizDashboardData();

    return (
      <GuardianTahfizDashboard
        data={data}
      />
    );
  }

  /*
   * =====================================================
   * DASHBOARD BENDAHARA
   * =====================================================
   */

  if (
    roleCode ===
    "bendahara"
  ) {
    const data =
      await getBendaharaDashboardData();

    return (
      <BendaharaDashboard
        data={data}
      />
    );
  }

  /*
   * =====================================================
   * DASHBOARD GENERIC
   *
   * Role yang belum mempunyai dashboard khusus akan
   * menggunakan dashboard generic.
   *
   * Saat ini antara lain:
   * - admin
   * - penanggung_jawab
   * - kepala_mahad
   * =====================================================
   */

  return (
    <RoleDashboard
      roleCode={roleCode}
      context={context}
    />
  );
}