import Link from "next/link";

import {
  AppIcon,
} from "@/components/app-shell/app-icon";

import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";

import type {
  AccessContext,
} from "@/lib/auth/types";

type WorkspaceModule = {
  label:
    string;

  description:
    string;

  href?:
    string;

  available:
    boolean;
};

type WorkspaceDefinition = {
  focusTitle:
    string;

  focusDescription:
    string;

  modules:
    WorkspaceModule[];
};

const workspaceByRole: Record<
  RoleCode,
  WorkspaceDefinition
> = {
  admin: {
    focusTitle:
      "Kelola data dasar E-Ma'had",

    focusDescription:
      "Admin mengelola santri, wali, staf, akun, kelompok, dan assignment.",

    modules: [
      {
        label: "Data Santri",
        description: "Kelola data santri.",
        href: "/admin/santri",
        available: true,
      },
      {
        label: "Orang Tua/Wali",
        description: "Kelola wali dan hubungan dengan santri.",
        href: "/admin/wali",
        available: true,
      },
      {
        label: "Staf dan Akun",
        description: "Kelola staf, akun, dan role.",
        href: "/admin/staf",
        available: true,
      },
      {
        label: "Kelompok dan Assignment",
        description: "Kelola kelompok dan penugasan.",
        href: "/admin/kelompok",
        available: true,
      },
    ],
  },

  penanggung_jawab: {
    focusTitle:
      "Pantau operasional Ma'had",

    focusDescription:
      "Penanggung Jawab memonitor kegiatan asrama dan kinerja Kepala Ma'had tanpa mengelola keuangan.",

    modules: [
      {
        label: "Jurnal Kepala Ma'had",
        description:
          "Pantau jurnal kegiatan dan kinerja Kepala Ma'had yang sudah dikirim.",
        href:
          "/penanggung-jawab/jurnal",
        available:
          true,
      },
      {
        label: "Monitoring Asrama",
        description:
          "Ringkasan pengasuhan dan kegiatan operasional.",
        available:
          false,
      },
      {
        label: "Perkembangan Tahfiz",
        description:
          "Monitoring laporan Tahfiz secara read-only.",
        available:
          false,
      },
    ],
  },

  kepala_mahad: {
    focusTitle:
      "Kendalikan operasional harian Ma'had",

    focusDescription:
      "Kepala Ma'had mereview pengasuhan, mencatat jurnal operasional, serta memonitor Tahfiz dan keuangan.",

    modules: [
      {
        label: "Review Jurnal Pengasuhan",
        description:
          "Review jurnal Pengasuh dan tindak lanjutnya.",
        href:
          "/kepala-mahad/pengasuhan",
        available:
          true,
      },
      {
        label: "Jurnal Kepala Ma'had",
        description:
          "Catat kegiatan, kinerja, bukti, serta kendala operasional.",
        href:
          "/kepala-mahad/jurnal",
        available:
          true,
      },
      {
        label: "Perkembangan Tahfiz",
        description:
          "Pantau laporan mingguan Tahfiz.",
        available:
          false,
      },
      {
        label: "Ringkasan Keuangan",
        description:
          "Lihat posisi tagihan dan pembayaran secara read-only.",
        available:
          false,
      },
    ],
  },

  pengasuh: {
    focusTitle:
      "Pantau kondisi santri ampuan",

    focusDescription:
      "Pengasuh mengelola santri sesuai penugasan dan mencatat Jurnal Pengasuhan.",

    modules: [
      {
        label: "Santri Ampuan",
        description: "Lihat santri yang diampu.",
        href: "/pengasuh/santri",
        available: true,
      },
      {
        label: "Jurnal Pengasuhan",
        description: "Isi Jurnal Pengasuhan.",
        href: "/pengasuh/jurnal",
        available: true,
      },
      {
        label: "Riwayat Pengasuhan",
        description: "Lihat riwayat jurnal dan review.",
        href: "/pengasuh/riwayat",
        available: true,
      },
    ],
  },

  pembina_tahfiz: {
    focusTitle:
      "Kelola perkembangan Tahfiz mingguan",

    focusDescription:
      "Pembina membuat dan mempublikasikan laporan Tahfiz santri.",

    modules: [
      {
        label: "Laporan Mingguan",
        description: "Isi perkembangan Tahfiz.",
        href:
          "/pembina-tahfiz/laporan",
        available: true,
      },
      {
        label: "Riwayat Laporan",
        description: "Lihat laporan yang pernah dibuat.",
        href:
          "/pembina-tahfiz/laporan/riwayat",
        available: true,
      },
    ],
  },

  bendahara: {
    focusTitle:
      "Kelola tagihan dan pembayaran",

    focusDescription:
      "Bendahara mengelola tagihan, pembayaran, bukti transaksi, dan riwayat.",

    modules: [
      {
        label: "Tagihan Santri",
        description: "Kelola tagihan.",
        href: "/bendahara/tagihan",
        available: true,
      },
      {
        label: "Pembayaran",
        description: "Kelola riwayat pembayaran.",
        href: "/bendahara/pembayaran",
        available: true,
      },
      {
        label: "Laporan Keuangan",
        description: "Rekap berdasarkan periode.",
        available: false,
      },
    ],
  },

  guardian: {
    focusTitle:
      "Pantau perkembangan anak",

    focusDescription:
      "Orang tua melihat Tahfiz serta informasi tagihan dan pembayaran anak.",

    modules: [
      {
        label: "Perkembangan Tahfiz",
        description: "Lihat laporan Tahfiz anak.",
        href: "/wali/dashboard",
        available: true,
      },
      {
        label: "Tagihan",
        description: "Lihat tagihan anak.",
        href: "/wali/tagihan",
        available: true,
      },
      {
        label: "Riwayat Pembayaran",
        description: "Lihat pembayaran anak.",
        href: "/wali/pembayaran",
        available: true,
      },
    ],
  },
};

type RoleDashboardProps = {
  roleCode:
    RoleCode;

  context:
    AccessContext;
};

export function RoleDashboard({
  roleCode,
  context,
}: RoleDashboardProps) {
  const role =
    roleDefinitions[
      roleCode
    ];

  const workspace =
    workspaceByRole[
      roleCode
    ];

  const availableCount =
    workspace.modules.filter(
      (item) =>
        item.available,
    ).length;

  const developmentCount =
    workspace.modules.length -
    availableCount;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="rounded-3xl border border-brand-100 bg-white p-6 shadow-soft sm:p-8 lg:p-10">
        <div className="grid gap-7 xl:grid-cols-[1fr_340px]">
          <div>
            <span className="inline-flex items-center gap-2 rounded-full bg-brand-50 px-3 py-1.5 text-xs font-semibold text-brand-700">
              <span className="size-2 rounded-full bg-brand-500" />
              Dashboard{" "}
              {role.label}
            </span>

            <h1 className="mt-5 text-3xl font-bold tracking-tight text-ink sm:text-4xl">
              Assalamu&apos;alaikum,{" "}
              {
                context.fullName
              }
            </h1>

            <p className="mt-4 max-w-3xl leading-7 text-muted">
              {
                role.description
              }
            </p>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
            <div className="flex gap-3">
              <div className="grid size-10 shrink-0 place-items-center rounded-xl bg-brand-700 text-white">
                <AppIcon
                  name="shield"
                  className="size-5"
                />
              </div>

              <div>
                <p className="font-semibold text-brand-950">
                  Akses role aktif
                </p>

                <p className="mt-1 text-sm leading-6 text-brand-700">
                  Proteksi route dan
                  pembatasan akses telah
                  diterapkan.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <div className="mt-6 grid gap-6 xl:grid-cols-[1fr_1fr]">
        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Fokus Utama
          </p>

          <h2 className="mt-3 text-2xl font-bold text-ink">
            {
              workspace.focusTitle
            }
          </h2>

          <p className="mt-3 leading-7 text-muted">
            {
              workspace.focusDescription
            }
          </p>

          <div className="mt-6 grid gap-3 sm:grid-cols-2">
            <div className="rounded-2xl bg-brand-50 p-4">
              <p className="text-xs text-brand-700">
                Modul tersedia
              </p>

              <p className="mt-2 text-3xl font-bold text-brand-900">
                {
                  availableCount
                }
              </p>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <p className="text-xs text-muted">
                Dalam pengembangan
              </p>

              <p className="mt-2 text-3xl font-bold text-ink">
                {
                  developmentCount
                }
              </p>
            </div>
          </div>
        </section>

        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Ruang Kerja
          </p>

          <div className="mt-5 space-y-3">
            {workspace.modules.map(
              (module) =>
                module.available &&
                module.href ? (
                  <Link
                    key={
                      module.label
                    }
                    href={
                      module.href
                    }
                    className="flex items-center gap-3 rounded-2xl border border-line p-4 transition hover:border-brand-200 hover:bg-brand-50/40"
                  >
                    <div className="grid size-9 shrink-0 place-items-center rounded-xl bg-brand-50 text-brand-700">
                      <AppIcon
                        name="chevron-right"
                        className="size-4"
                      />
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="font-semibold text-ink">
                        {
                          module.label
                        }
                      </p>

                      <p className="mt-1 text-xs leading-5 text-muted">
                        {
                          module.description
                        }
                      </p>
                    </div>

                    <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-[9px] font-bold uppercase text-emerald-700">
                      Tersedia
                    </span>
                  </Link>
                ) : (
                  <div
                    key={
                      module.label
                    }
                    className="flex items-center gap-3 rounded-2xl border border-line bg-slate-50/70 p-4"
                  >
                    <div className="grid size-9 shrink-0 place-items-center rounded-xl bg-white text-slate-400">
                      <AppIcon
                        name="chevron-right"
                        className="size-4"
                      />
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="font-semibold text-slate-700">
                        {
                          module.label
                        }
                      </p>

                      <p className="mt-1 text-xs leading-5 text-slate-500">
                        {
                          module.description
                        }
                      </p>
                    </div>

                    <span className="rounded-full bg-slate-200 px-2.5 py-1 text-[9px] font-bold uppercase text-slate-500">
                      Belum tersedia
                    </span>
                  </div>
                ),
            )}
          </div>
        </section>
      </div>
    </div>
  );
}