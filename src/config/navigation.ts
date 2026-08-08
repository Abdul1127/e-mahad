import type { AppIconName } from "@/components/app-shell/app-icon";
import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";

export type RoleNavigationItem = {
  label: string;
  href: string;
  icon: AppIconName;
  available: boolean;
};

const roleNavigation = {
  admin: [
    {
      label: "Dashboard",
      href: roleDefinitions.admin.dashboardPath,
      icon: "dashboard",
      available: true,
    },
    {
      label: "Data Santri",
      href: "/admin/santri",
      icon: "students",
      available: true,
    },
    {
      label: "Orang Tua/Wali",
      href: "/admin/wali",
      icon: "students",
      available: true,
    },
    {
      label: "Staf Pesantren",
      href: "/admin/staf",
      icon: "staff",
      available: true,
    },
    {
      label: "Kelompok dan Assignment",
      href: "/admin/kelompok",
      icon: "groups",
      available: true,
    },
  ],

  penanggung_jawab: [
    {
      label: "Dashboard",
      href: roleDefinitions.penanggung_jawab.dashboardPath,
      icon: "dashboard",
      available: true,
    },
    {
      label: "Monitoring Asrama",
      href: "/penanggung-jawab/monitoring",
      icon: "shield",
      available: false,
    },
    {
      label: "Perkembangan Tahfiz",
      href: "/penanggung-jawab/tahfiz",
      icon: "tahfiz",
      available: false,
    },
    {
      label: "Jurnal Kepala Ma'had",
      href: "/penanggung-jawab/jurnal",
      icon: "journal",
      available: false,
    },
  ],

  kepala_mahad: [
    {
      label: "Dashboard",
      href: roleDefinitions.kepala_mahad.dashboardPath,
      icon: "dashboard",
      available: true,
    },
    {
      label: "Jurnal Pengasuhan",
      href: "/kepala-mahad/pengasuhan",
      icon: "journal",
      available: false,
    },
    {
      label: "Perkembangan Tahfiz",
      href: "/kepala-mahad/tahfiz",
      icon: "tahfiz",
      available: false,
    },
    {
      label: "Klinik Tahsin",
      href: "/kepala-mahad/tahsin",
      icon: "clinic",
      available: false,
    },
    {
      label: "Ringkasan Keuangan",
      href: "/kepala-mahad/keuangan",
      icon: "finance",
      available: false,
    },
  ],

  pengasuh: [
    {
      label: "Dashboard",
      href: roleDefinitions.pengasuh.dashboardPath,
      icon: "dashboard",
      available: true,
    },
    {
      label: "Santri Ampuan",
      href: "/pengasuh/santri",
      icon: "students",
      available: true,
    },
    {
      label: "Jurnal Pengasuhan",
      href: "/pengasuh/jurnal",
      icon: "journal",
      available: true,
    },
    {
      label: "Riwayat Pengasuhan",
      href: "/pengasuh/riwayat",
      icon: "shield",
      available: false,
    },
  ],

  pembina_tahfiz: [
    {
      label: "Dashboard",
      href: roleDefinitions.pembina_tahfiz.dashboardPath,
      icon: "dashboard",
      available: true,
    },
    {
      label: "Kelompok Tahfiz",
      href: "/pembina-tahfiz/kelompok",
      icon: "groups",
      available: false,
    },
    {
      label: "Laporan Mingguan",
      href: "/pembina-tahfiz/laporan",
      icon: "tahfiz",
      available: false,
    },
    {
      label: "Klinik Tahsin",
      href: "/pembina-tahfiz/tahsin",
      icon: "clinic",
      available: false,
    },
  ],

  bendahara: [
    {
      label: "Dashboard",
      href: roleDefinitions.bendahara.dashboardPath,
      icon: "dashboard",
      available: true,
    },
    {
      label: "Tagihan Santri",
      href: "/bendahara/tagihan",
      icon: "finance",
      available: false,
    },
    {
      label: "Pembayaran",
      href: "/bendahara/pembayaran",
      icon: "journal",
      available: false,
    },
    {
      label: "Laporan Keuangan",
      href: "/bendahara/laporan",
      icon: "shield",
      available: false,
    },
  ],

  guardian: [
    {
      label: "Beranda",
      href: roleDefinitions.guardian.dashboardPath,
      icon: "home",
      available: true,
    },
    {
      label: "Tahfiz Anak",
      href: "/wali/tahfiz",
      icon: "tahfiz",
      available: false,
    },
    {
      label: "Tagihan",
      href: "/wali/tagihan",
      icon: "finance",
      available: false,
    },
    {
      label: "Riwayat Pembayaran",
      href: "/wali/pembayaran",
      icon: "journal",
      available: false,
    },
  ],
} satisfies Record<
  RoleCode,
  RoleNavigationItem[]
>;

export function getRoleNavigation(
  roleCode: RoleCode,
): RoleNavigationItem[] {
  return roleNavigation[roleCode];
}

export function getCurrentNavigationItem(
  roleCode: RoleCode,
  pathname: string,
): RoleNavigationItem | null {
  const availableItems =
    getRoleNavigation(roleCode)
      .filter(
        (item) => item.available,
      )
      .sort(
        (
          firstItem,
          secondItem,
        ) => {
          return (
            secondItem.href.length -
            firstItem.href.length
          );
        },
      );

  return (
    availableItems.find((item) => {
      return (
        pathname === item.href ||
        pathname.startsWith(
          `${item.href}/`,
        )
      );
    }) ?? null
  );
}