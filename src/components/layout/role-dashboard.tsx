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
        label:
          "Data Santri",

        description:
          "Kelola data dan penempatan santri.",

        href:
          "/admin/santri",

        available:
          true,
      },
      {
        label:
          "Orang Tua/Wali",

        description:
          "Kelola wali dan hubungan dengan santri.",

        href:
          "/admin/wali",

        available:
          true,
      },
      {
        label:
          "Staf dan Akun",

        description:
          "Kelola staf, akun login, dan role.",

        href:
          "/admin/staf",

        available:
          true,
      },
      {
        label:
          "Kelompok dan Assignment",

        description:
          "Kelola kelompok serta penugasan staf.",

        href:
          "/admin/kelompok",

        available:
          true,
      },
    ],
  },

  penanggung_jawab: {
    focusTitle:
      "Pantau operasional Ma'had",

    focusDescription:
      "Penanggung Jawab memonitor kondisi operasional asrama, kinerja Kepala Ma'had, dan perkembangan Tahfiz tanpa mengakses keuangan.",

    modules: [
      {
        label:
          "Monitoring Asrama",

        description:
          "Lihat ringkasan Pengasuhan, Jurnal Kepala Ma'had, dan kelengkapan laporan Tahfiz pekan berjalan.",

        href:
          "/penanggung-jawab/monitoring",

        available:
          true,
      },
      {
        label:
          "Jurnal Kepala Ma'had",

        description:
          "Pantau jurnal kegiatan dan kinerja Kepala Ma'had.",

        href:
          "/penanggung-jawab/jurnal",

        available:
          true,
      },
      {
        label:
          "Perkembangan Tahfiz",

        description:
          "Pantau laporan Tahfiz published seluruh santri secara read-only.",

        href:
          "/penanggung-jawab/tahfiz",

        available:
          true,
      },
    ],
  },

  kepala_mahad: {
    focusTitle:
      "Kendalikan operasional harian Ma'had",

    focusDescription:
      "Kepala Ma'had mereview pengasuhan, mencatat jurnal operasional, serta memonitor perkembangan Tahfiz dan keuangan.",

    modules: [
      {
        label:
          "Jurnal Pengasuhan",

        description:
          "Review jurnal dan kondisi santri dari Pengasuh.",

        href:
          "/kepala-mahad/pengasuhan",

        available:
          true,
      },
      {
        label:
          "Jurnal Kepala Ma'had",

        description:
          "Catat kegiatan dan kinerja operasional Kepala Ma'had.",

        href:
          "/kepala-mahad/jurnal",

        available:
          true,
      },
      {
        label:
          "Perkembangan Tahfiz",

        description:
          "Pantau laporan Tahfiz published seluruh santri.",

        href:
          "/kepala-mahad/tahfiz",

        available:
          true,
      },
      {
        label:
          "Ringkasan Keuangan",

        description:
          "Pantau tagihan, penerimaan, sisa kewajiban, dan transaksi terbaru secara read-only.",

        href:
          "/kepala-mahad/keuangan",

        available:
          true,
      },
    ],
  },

  pengasuh: {
    focusTitle:
      "Pantau kondisi santri dalam pengasuhan",

    focusDescription:
      "Pengasuh mengelola Jurnal Pengasuhan sesuai kelompok dan assignment yang diberikan.",

    modules: [
      {
        label:
          "Santri Ampuan",

        description:
          "Lihat santri sesuai kelompok pengasuhan.",

        href:
          "/pengasuh/santri",

        available:
          true,
      },
      {
        label:
          "Jurnal Pengasuhan",

        description:
          "Isi kondisi santri dan kirim jurnal untuk direview.",

        href:
          "/pengasuh/jurnal",

        available:
          true,
      },
      {
        label:
          "Riwayat Pengasuhan",

        description:
          "Lihat jurnal terdahulu dan tindak lanjut review.",

        href:
          "/pengasuh/riwayat",

        available:
          true,
      },
    ],
  },

  pembina_tahfiz: {
    focusTitle:
      "Perbarui perkembangan Tahfiz mingguan",

    focusDescription:
      "Pembina membuat dan mempublikasikan laporan Tahfiz individu santri sesuai kelompok yang diampu.",

    modules: [
      {
        label:
          "Laporan Mingguan",

        description:
          "Isi dan publikasikan laporan Tahfiz per santri.",

        href:
          "/pembina-tahfiz/laporan",

        available:
          true,
      },
      {
        label:
          "Riwayat Laporan",

        description:
          "Lihat kembali laporan mingguan yang pernah dibuat.",

        href:
          "/pembina-tahfiz/laporan/riwayat",

        available:
          true,
      },
    ],
  },

  bendahara: {
    focusTitle:
      "Kelola tagihan dan pembayaran santri",

    focusDescription:
      "Bendahara membuat tagihan, mencatat pembayaran, menyimpan bukti, dan melakukan koreksi transaksi.",

    modules: [
      {
        label:
          "Tagihan",

        description:
          "Kelola tagihan dan status pembayaran santri.",

        href:
          "/bendahara/tagihan",

        available:
          true,
      },
      {
        label:
          "Pembayaran",

        description:
          "Pantau riwayat transaksi pembayaran.",

        href:
          "/bendahara/pembayaran",

        available:
          true,
      },
      {
        label:
          "Laporan Keuangan",

        description:
          "Lihat rekap tagihan dan pembayaran berdasarkan periode laporan.",

        href:
          "/bendahara/laporan",

        available:
          true,
      },
    ],
  },

  guardian: {
    focusTitle:
      "Pantau informasi anak",

    focusDescription:
      "Orang tua atau wali hanya dapat melihat data anak yang terhubung dengan akun.",

    modules: [
      {
        label:
          "Tagihan",

        description:
          "Lihat tagihan anak pada tahun ajaran aktif.",

        href:
          "/wali/tagihan",

        available:
          true,
      },
      {
        label:
          "Riwayat Pembayaran",

        description:
          "Lihat pembayaran dan bukti transaksi anak.",

        href:
          "/wali/pembayaran",

        available:
          true,
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
  const roleDefinition =
    roleDefinitions[
      roleCode
    ];

  const workspace =
    workspaceByRole[
      roleCode
    ];

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="overflow-hidden rounded-3xl border border-brand-100 bg-white shadow-soft">
        <div className="grid gap-8 p-6 sm:p-8 xl:grid-cols-[minmax(0,1fr)_340px] xl:p-10">
          <div className="min-w-0">
            <div className="inline-flex items-center gap-2 rounded-full bg-brand-50 px-3 py-1.5 text-xs font-semibold text-brand-700">
              <span className="size-2 rounded-full bg-brand-500" />

              Dashboard{" "}
              {
                roleDefinition.label
              }
            </div>

            <h2 className="mt-5 max-w-3xl text-3xl font-bold tracking-tight text-ink sm:text-4xl">
              Assalamu&apos;alaikum,{" "}
              {
                context.fullName
              }
            </h2>

            <p className="mt-4 max-w-3xl text-base leading-7 text-muted">
              {
                roleDefinition.description
              }
            </p>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50/70 p-5">
            <div className="flex items-start gap-3">
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
                  Menu dan data
                  dibatasi sesuai
                  kewenangan role
                  pengguna.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <div className="mt-6 grid gap-6 xl:grid-cols-[minmax(0,0.8fr)_minmax(0,1.2fr)]">
        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Fokus Utama
          </p>

          <h3 className="mt-3 text-2xl font-bold tracking-tight text-ink">
            {
              workspace.focusTitle
            }
          </h3>

          <p className="mt-3 leading-7 text-muted">
            {
              workspace.focusDescription
            }
          </p>

          <div className="mt-6 rounded-2xl border border-brand-100 bg-brand-50 p-5">
            <p className="font-semibold text-brand-900">
              E-Ma&apos;had
            </p>

            <p className="mt-2 text-sm leading-6 text-brand-700">
              Gunakan ruang kerja
              sesuai tugas dan
              kewenangan untuk
              menjaga data tetap
              konsisten dan mudah
              dipantau.
            </p>
          </div>
        </section>

        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Ruang Kerja
          </p>

          <h3 className="mt-3 text-xl font-bold text-ink">
            Modul Tersedia
          </h3>

          <div className="mt-5 space-y-3">
            {workspace.modules.map(
              (
                module,
              ) => {
                if (
                  module.available &&
                  module.href
                ) {
                  return (
                    <Link
                      key={
                        module.label
                      }
                      href={
                        module.href
                      }
                      className="group flex min-h-16 items-center gap-4 rounded-2xl border border-line bg-slate-50/70 px-4 py-3 transition hover:border-brand-200 hover:bg-brand-50"
                    >
                      <div className="grid size-9 shrink-0 place-items-center rounded-xl bg-white text-brand-700 shadow-sm">
                        <AppIcon
                          name="chevron-right"
                          className="size-4 transition group-hover:translate-x-0.5"
                        />
                      </div>

                      <div className="min-w-0 flex-1">
                        <p className="text-sm font-semibold text-ink">
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

                      <span className="hidden text-xs font-semibold text-brand-700 sm:block">
                        Buka
                      </span>
                    </Link>
                  );
                }

                return (
                  <div
                    key={
                      module.label
                    }
                    className="flex min-h-16 items-center gap-4 rounded-2xl border border-line bg-slate-50/70 px-4 py-3"
                  >
                    <div className="grid size-9 shrink-0 place-items-center rounded-xl bg-white text-slate-400 shadow-sm">
                      <AppIcon
                        name="chevron-right"
                        className="size-4"
                      />
                    </div>

                    <div className="min-w-0 flex-1">
                      <p className="text-sm font-semibold text-slate-600">
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

                    <span className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                      Belum tersedia
                    </span>
                  </div>
                );
              },
            )}
          </div>
        </section>
      </div>
    </div>
  );
}