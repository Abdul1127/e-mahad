import Link from "next/link";

import {
  PengasuhCreateActivityScheduleForm,
} from "@/features/pengasuh/activities/components/pengasuh-create-activity-schedule-form";

import {
  getPengasuhActivityScheduleListData,
} from "@/features/pengasuh/activities/data/get-pengasuh-activity-schedule-list-data";

import {
  requireRole,
} from "@/lib/auth/guards";

export default async function PengasuhBuatJadwalPage() {
  await requireRole(
    "pengasuh",
  );

  const data =
    await getPengasuhActivityScheduleListData();

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <Link
        href="/pengasuh/jadwal"
        className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
      >
        ← Kembali ke Jadwal
      </Link>

      <section className="mt-6">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pengasuhan
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Buat Jadwal Kegiatan
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Tambahkan kegiatan untuk
          kelompok asrama yang menjadi
          tanggung jawab Anda.
        </p>
      </section>

      {data.groups.length ===
      0 ? (
        <section className="mt-7 rounded-2xl border border-amber-100 bg-amber-50 p-5">
          <p className="font-semibold text-amber-800">
            Kelompok asrama tidak
            ditemukan
          </p>

          <p className="mt-2 text-sm leading-6 text-amber-700">
            Akun Pengasuh belum
            memiliki assignment
            kelompok aktif pada tahun
            ajaran ini.
          </p>
        </section>
      ) : (
        <section className="mt-7">
          <PengasuhCreateActivityScheduleForm
            groups={
              data.groups
            }
          />
        </section>
      )}
    </div>
  );
}