import { AppIcon } from "@/components/app-shell/app-icon";
import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";
import type { AccessContext } from "@/lib/auth/types";

type WorkspaceDefinition = {
  focusTitle: string;
  focusDescription: string;
  modules: string[];
};

const workspaceByRole: Record<
  RoleCode,
  WorkspaceDefinition
> = {
  admin: {
    focusTitle: "Pastikan data dasar selalu siap",
    focusDescription:
      "Admin bertanggung jawab terhadap data santri, pengurus, akun, role, kelompok, dan assignment.",
    modules: [
      "Data Santri",
      "Pengurus dan Akun",
      "Role Pengguna",
      "Kelompok dan Assignment",
    ],
  },

  penanggung_jawab: {
    focusTitle: "Pantau kegiatan asrama secara menyeluruh",
    focusDescription:
      "Penanggung Jawab memantau pengasuhan, tahfiz, Klinik Tahsin, dan kinerja Kepala Ma'had tanpa mengakses keuangan.",
    modules: [
      "Monitoring Asrama",
      "Perkembangan Tahfiz",
      "Klinik Tahsin",
      "Jurnal Kepala Ma'had",
    ],
  },

  kepala_mahad: {
    focusTitle: "Kendalikan operasional harian asrama",
    focusDescription:
      "Kepala Ma'had meninjau jurnal pengasuhan, perkembangan tahfiz, Klinik Tahsin, dan ringkasan keuangan.",
    modules: [
      "Review Jurnal Pengasuhan",
      "Perkembangan Tahfiz",
      "Klinik Tahsin",
      "Ringkasan Keuangan",
    ],
  },

  pengasuh: {
    focusTitle: "Selesaikan pemantauan santri hari ini",
    focusDescription:
      "Pengasuh mengisi jurnal untuk santri Putra atau Putri sesuai assignment yang diberikan.",
    modules: [
      "Santri Ampuan",
      "Jurnal Hari Ini",
      "Jurnal Perlu Revisi",
      "Riwayat Pengasuhan",
    ],
  },

  pembina_tahfiz: {
    focusTitle: "Perbarui perkembangan tahfiz mingguan",
    focusDescription:
      "Pembina mengisi laporan individual setiap santri sesuai kelompok tahfiz yang diampu.",
    modules: [
      "Kelompok Tahfiz",
      "Laporan Mingguan",
      "Publikasi Laporan",
      "Klinik Tahsin",
    ],
  },

  bendahara: {
    focusTitle: "Kelola tagihan dan pembayaran santri",
    focusDescription:
      "Bendahara mencatat tagihan bulanan, pembayaran, verifikasi, dan laporan keuangan.",
    modules: [
      "Tagihan Santri",
      "Pembayaran",
      "Verifikasi",
      "Laporan Keuangan",
    ],
  },

  guardian: {
    focusTitle: "Pantau perkembangan anak",
    focusDescription:
      "Orang tua dapat melihat perkembangan tahfiz, tagihan, dan pembayaran anak yang terhubung dengan akun.",
    modules: [
      "Data Anak",
      "Perkembangan Tahfiz",
      "Tagihan",
      "Riwayat Pembayaran",
    ],
  },
};

type RoleDashboardProps = {
  roleCode: RoleCode;
  context: AccessContext;
};

export function RoleDashboard({
  roleCode,
  context,
}: RoleDashboardProps) {
  const roleDefinition =
    roleDefinitions[roleCode];

  const workspace =
    workspaceByRole[roleCode];

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="overflow-hidden rounded-3xl border border-brand-100 bg-white shadow-soft">
        <div className="grid gap-8 p-6 sm:p-8 xl:grid-cols-[minmax(0,1fr)_340px] xl:p-10">
          <div className="min-w-0">
            <div className="inline-flex items-center gap-2 rounded-full bg-brand-50 px-3 py-1.5 text-xs font-semibold text-brand-700">
              <span className="size-2 rounded-full bg-brand-500" />
              Dashboard {roleDefinition.label}
            </div>

            <h2 className="mt-5 max-w-3xl text-3xl font-bold tracking-tight text-ink sm:text-4xl">
              Assalamu&apos;alaikum,{" "}
              {context.fullName}
            </h2>

            <p className="mt-4 max-w-3xl text-base leading-7 text-muted">
              {roleDefinition.description}
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
                  Akses role sudah aktif
                </p>

                <p className="mt-1 text-sm leading-6 text-brand-700">
                  Session, proteksi route, dan pembatasan
                  dashboard sudah berfungsi.
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>

      <div className="mt-6 grid gap-6 xl:grid-cols-[minmax(0,1.25fr)_minmax(320px,0.75fr)]">
        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Fokus utama
          </p>

          <h3 className="mt-3 text-2xl font-bold tracking-tight text-ink">
            {workspace.focusTitle}
          </h3>

          <p className="mt-3 max-w-2xl leading-7 text-muted">
            {workspace.focusDescription}
          </p>

          <div className="mt-6 rounded-2xl border border-dashed border-brand-200 bg-brand-50/50 p-5">
            <p className="text-sm font-semibold text-brand-800">
              Tahap berikutnya
            </p>

            <p className="mt-2 text-sm leading-6 text-brand-700">
              Dashboard ini akan dihubungkan dengan data
              aktual dan tindakan yang sesuai pekerjaan
              pengguna, bukan statistik contoh.
            </p>
          </div>
        </section>

        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Ruang kerja
          </p>

          <h3 className="mt-3 text-xl font-bold text-ink">
            Modul yang disiapkan
          </h3>

          <div className="mt-5 space-y-2.5">
            {workspace.modules.map(
              (moduleName) => (
                <div
                  key={moduleName}
                  className="flex min-h-13 items-center gap-3 rounded-2xl border border-line bg-slate-50/70 px-4 py-3"
                >
                  <div className="grid size-8 shrink-0 place-items-center rounded-lg bg-white text-brand-700 shadow-sm">
                    <AppIcon
                      name="chevron-right"
                      className="size-4"
                    />
                  </div>

                  <p className="min-w-0 flex-1 text-sm font-semibold text-slate-700">
                    {moduleName}
                  </p>

                  <span className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                    Segera
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