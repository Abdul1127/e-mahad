export const roleDefinitions = {
  admin: {
    slug: "admin",
    label: "Admin",
    dashboardPath: "/admin/dashboard",
    description:
      "Mengelola akun, data master, role, assignment, dan konfigurasi sistem.",
  },

  penanggung_jawab: {
    slug: "penanggung-jawab",
    label: "Penanggung Jawab",
    dashboardPath: "/penanggung-jawab/dashboard",
    description:
      "Memantau seluruh kegiatan asrama selain bagian keuangan.",
  },

  kepala_mahad: {
    slug: "kepala-mahad",
    label: "Kepala Ma'had",
    dashboardPath: "/kepala-mahad/dashboard",
    description:
      "Memantau operasional asrama, pengasuhan, tahfiz, dan keuangan.",
  },

  pengasuh: {
    slug: "pengasuh",
    label: "Pengasuh",
    dashboardPath: "/pengasuh/dashboard",
    description:
      "Mengelola jurnal pengasuhan santri sesuai cakupan Putra atau Putri.",
  },

  pembina_tahfiz: {
    slug: "pembina-tahfiz",
    label: "Pembina Tahfiz",
    dashboardPath: "/pembina-tahfiz/dashboard",
    description:
      "Mengelola perkembangan tahfiz dan Klinik Tahsin sesuai kelompok.",
  },

  bendahara: {
    slug: "bendahara",
    label: "Bendahara",
    dashboardPath: "/bendahara/dashboard",
    description:
      "Mengelola tagihan, pembayaran, dan laporan keuangan.",
  },

  guardian: {
    slug: "wali",
    label: "Orang Tua/Wali",
    dashboardPath: "/wali/dashboard",
    description:
      "Memantau tahfiz dan keuangan anak yang terhubung dengan akun.",
  },
} as const;

export type RoleCode = keyof typeof roleDefinitions;

export const roleCodes = Object.keys(
  roleDefinitions,
) as RoleCode[];

export function isRoleCode(
  value: unknown,
): value is RoleCode {
  return (
    typeof value === "string" &&
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
        roleDefinitions[roleCode].slug === slug,
    ) ?? null
  );
}