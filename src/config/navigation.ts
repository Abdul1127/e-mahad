import type {
  AppIconName,
} from "@/components/app-shell/app-icon";

import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";


export type RoleNavigationItem = {
  label:
    string;

  href:
    string;

  icon:
    AppIconName;

  available:
    boolean;
};


const accountNavigationItem =
  {
    label:
      "Ubah Password",

    href:
      "/akun/password",

    icon:
      "shield",

    available:
      true,
  } satisfies RoleNavigationItem;


const roleNavigation = {
  admin: [
    {
      label:
        "Dashboard",

      href:
        roleDefinitions
          .admin
          .dashboardPath,

      icon:
        "dashboard",

      available:
        true,
    },

    accountNavigationItem,

    {
      label:
        "Data Santri",

      href:
        "/admin/santri",

      icon:
        "students",

      available:
        true,
    },
    {
      label:
        "Orang Tua/Wali",

      href:
        "/admin/wali",

      icon:
        "students",

      available:
        true,
    },
    {
      label:
        "Staf Pesantren",

      href:
        "/admin/staf",

      icon:
        "staff",

      available:
        true,
    },
    {
      label:
        "Kelompok dan Assignment",

      href:
        "/admin/kelompok",

      icon:
        "groups",

      available:
        true,
    },
  ],


  penanggung_jawab: [
    {
      label:
        "Dashboard",

      href:
        roleDefinitions
          .penanggung_jawab
          .dashboardPath,

      icon:
        "dashboard",

      available:
        true,
    },

    accountNavigationItem,

    {
      label:
        "Monitoring Asrama",

      href:
        "/penanggung-jawab/monitoring",

      icon:
        "shield",

      available:
        true,
    },

    {
      label:
        "Kondisi Pengasuhan",

      href:
        "/penanggung-jawab/pengasuhan",

      icon:
        "students",

      available:
        true,
    },

    {
      label:
        "Jurnal Kepala Ma'had",

      href:
        "/penanggung-jawab/jurnal",

      icon:
        "journal",

      available:
        true,
    },

    {
      label:
        "Perkembangan Tahfiz",

      href:
        "/penanggung-jawab/tahfiz",

      icon:
        "tahfiz",

      available:
        true,
    },
  ],


  kepala_mahad: [
    {
      label:
        "Dashboard",

      href:
        roleDefinitions
          .kepala_mahad
          .dashboardPath,

      icon:
        "dashboard",

      available:
        true,
    },

    accountNavigationItem,

    {
      label:
        "Jurnal Pengasuhan",

      href:
        "/kepala-mahad/pengasuhan",

      icon:
        "journal",

      available:
        true,
    },

    {
      label:
        "Jurnal Kepala Ma'had",

      href:
        "/kepala-mahad/jurnal",

      icon:
        "journal",

      available:
        true,
    },

    {
      label:
        "Perkembangan Tahfiz",

      href:
        "/kepala-mahad/tahfiz",

      icon:
        "tahfiz",

      available:
        true,
    },

    {
      label:
        "Ringkasan Keuangan",

      href:
        "/kepala-mahad/keuangan",

      icon:
        "finance",

      available:
        true,
    },
  ],


  pengasuh: [
    {
      label:
        "Dashboard",

      href:
        roleDefinitions
          .pengasuh
          .dashboardPath,

      icon:
        "dashboard",

      available:
        true,
    },

    accountNavigationItem,

    {
      label:
        "Santri Ampuan",

      href:
        "/pengasuh/santri",

      icon:
        "students",

      available:
        true,
    },

    {
      label:
        "Jurnal Pengasuhan",

      href:
        "/pengasuh/jurnal",

      icon:
        "journal",

      available:
        true,
    },

    {
      label:
        "Riwayat Pengasuhan",

      href:
        "/pengasuh/riwayat",

      icon:
        "shield",

      available:
        true,
    },
  ],


  pembina_tahfiz: [
    {
      label:
        "Dashboard",

      href:
        roleDefinitions
          .pembina_tahfiz
          .dashboardPath,

      icon:
        "dashboard",

      available:
        true,
    },

    accountNavigationItem,

    {
      label:
        "Laporan Mingguan",

      href:
        "/pembina-tahfiz/laporan",

      icon:
        "tahfiz",

      available:
        true,
    },

    {
      label:
        "Riwayat Laporan",

      href:
        "/pembina-tahfiz/laporan/riwayat",

      icon:
        "journal",

      available:
        true,
    },
  ],


  bendahara: [
    {
      label:
        "Dashboard",

      href:
        roleDefinitions
          .bendahara
          .dashboardPath,

      icon:
        "dashboard",

      available:
        true,
    },

    accountNavigationItem,

    {
      label:
        "Tagihan",

      href:
        "/bendahara/tagihan",

      icon:
        "finance",

      available:
        true,
    },

    {
      label:
        "Pembayaran",

      href:
        "/bendahara/pembayaran",

      icon:
        "journal",

      available:
        true,
    },

    {
      label:
        "Laporan Keuangan",

      href:
        "/bendahara/laporan",

      icon:
        "finance",

      available:
        true,
    },
  ],


  guardian: [
    {
      label:
        "Beranda",

      href:
        roleDefinitions
          .guardian
          .dashboardPath,

      icon:
        "home",

      available:
        true,
    },

    accountNavigationItem,

    {
      label:
        "Tagihan",

      href:
        "/wali/tagihan",

      icon:
        "finance",

      available:
        true,
    },

    {
      label:
        "Riwayat Pembayaran",

      href:
        "/wali/pembayaran",

      icon:
        "journal",

      available:
        true,
    },
  ],
} satisfies Record<
  RoleCode,
  RoleNavigationItem[]
>;


export function getRoleNavigation(
  roleCode:
    RoleCode,
): RoleNavigationItem[] {
  return roleNavigation[
    roleCode
  ];
}


export function getCurrentNavigationItem(
  roleCode:
    RoleCode,

  pathname:
    string,
): RoleNavigationItem | null {
  const availableItems =
    getRoleNavigation(
      roleCode,
    )
      .filter(
        (
          item,
        ) =>
          item.available,
      )
      .sort(
        (
          firstItem,
          secondItem,
        ) =>
          secondItem.href.length -
          firstItem.href.length,
      );


  return (
    availableItems.find(
      (
        item,
      ) =>
        pathname ===
          item.href ||
        pathname.startsWith(
          `${item.href}/`,
        ),
    ) ??
    null
  );
}