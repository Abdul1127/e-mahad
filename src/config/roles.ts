export const roleDefinitions = {
  admin: {
    slug: "admin",
    label: "Admin",
    dashboardPath:
      "/admin/dashboard",
    description:
      "Mengelola akun, data master, role, assignment, dan konfigurasi sistem.",
  },

  penanggung_jawab: {
    slug:
      "penanggung-jawab",
    label:
      "Penanggung Jawab",
    dashboardPath:
      "/penanggung-jawab/dashboard",
    description:
      "Memantau seluruh kegiatan asrama dan kinerja pengelolaan Ma'had selain bagian keuangan.",
  },

  kepala_mahad: {
    slug:
      "kepala-mahad",
    label:
      "Kepala Ma'had",
    dashboardPath:
      "/kepala-mahad/dashboard",
    description:
      "Memantau operasional asrama, pengasuhan, tahfiz, dan ringkasan keuangan.",
  },

  pengasuh: {
    slug:
      "pengasuh",
    label:
      "Pengasuh",
    dashboardPath:
      "/pengasuh/dashboard",
    description:
      "Mengelola jurnal pengasuhan santri sesuai kelompok penugasan.",
  },

  pembina_tahfiz: {
    slug:
      "pembina-tahfiz",
    label:
      "Pembina Tahfiz",
    dashboardPath:
      "/pembina-tahfiz/dashboard",
    description:
      "Mengelola perkembangan dan laporan tahfiz mingguan sesuai kelompok yang diampu.",
  },

  bendahara: {
    slug:
      "bendahara",
    label:
      "Bendahara",
    dashboardPath:
      "/bendahara/dashboard",
    description:
      "Mengelola tagihan, pembayaran, dan informasi keuangan santri.",
  },

  guardian: {
    slug:
      "wali",
    label:
      "Orang Tua/Wali",
    dashboardPath:
      "/wali/dashboard",
    description:
      "Memantau tahfiz dan keuangan anak yang terhubung dengan akun.",
  },
} as const;

export type RoleCode =
  keyof typeof roleDefinitions;

export const roleCodes =
  Object.keys(
    roleDefinitions,
  ) as RoleCode[];

export function isRoleCode(
  value: unknown,
): value is RoleCode {
  return (
    typeof value ===
      "string" &&
    Object.prototype.hasOwnProperty.call(
      roleDefinitions,
      value,
    )
  );
}

export function getRoleCodeBySlug(
  slug: string,
): RoleCode | null {
  return (
    roleCodes.find(
      (roleCode) =>
        roleDefinitions[
          roleCode
        ].slug === slug,
    ) ?? null
  );
}