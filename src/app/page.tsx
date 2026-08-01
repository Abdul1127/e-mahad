import Link from "next/link";

import { appConfig } from "@/config/app";

const foundations = [
  {
    title: "Next.js",
    description:
      "Aplikasi dibangun menggunakan Next.js App Router dan TypeScript.",
  },
  {
    title: "Supabase Cloud",
    description:
      "PostgreSQL, Auth, dan Storage menggunakan project Supabase Cloud.",
  },
  {
    title: "Role-Based Access",
    description:
      "Pengguna akan memperoleh menu dan dashboard berdasarkan role dan assignment.",
  },
  {
    title: "Manual Development",
    description:
      "Setiap perubahan kode dan SQL dapat ditinjau sebelum dipindahkan ke VS Code atau SQL Editor.",
  },
];

const plannedModules = [
  "Data santri",
  "Data pengurus",
  "Data wali santri",
  "Role dan assignment",
  "Kelas",
  "Kelompok tahfiz",
  "Jurnal pengasuhan",
  "Laporan tahfiz mingguan",
  "Klinik Tahsin",
  "Tagihan dan pembayaran",
  "Jurnal Kepala Ma'had",
  "Dashboard wali santri",
];

export default function HomePage() {
  return (
    <main className="min-h-screen px-5 py-10 sm:px-8 lg:px-12">
      <div className="mx-auto max-w-6xl">
        <section className="overflow-hidden rounded-3xl border border-emerald-100 bg-white shadow-sm">
          <div className="border-b border-emerald-100 bg-emerald-50 px-6 py-3 sm:px-10">
            <p className="text-sm font-semibold text-emerald-800">
              Tahap 0 — Project Foundation
            </p>
          </div>

          <div className="px-6 py-10 sm:px-10 sm:py-14">
            <p className="text-sm font-bold uppercase tracking-[0.2em] text-emerald-700">
              Sistem Informasi Pesantren
            </p>

            <h1 className="mt-4 text-4xl font-bold tracking-tight text-slate-900 sm:text-6xl">
              {appConfig.name}
            </h1>

            <p className="mt-5 max-w-3xl text-base leading-8 text-slate-600 sm:text-lg">
              {appConfig.description}
            </p>

            <div className="mt-8 flex flex-wrap gap-3">
              <Link
                href="/api/health"
                className="rounded-xl bg-emerald-700 px-5 py-3 text-sm font-semibold text-white transition hover:bg-emerald-800"
              >
                Periksa API Health
              </Link>

              <span className="rounded-xl border border-slate-200 bg-slate-50 px-5 py-3 text-sm font-medium text-slate-600">
                Status: Fondasi project siap
              </span>
            </div>
          </div>
        </section>

        <section className="mt-8 grid gap-4 md:grid-cols-2">
          {foundations.map((foundation) => (
            <article
              key={foundation.title}
              className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm"
            >
              <h2 className="text-lg font-bold text-slate-900">
                {foundation.title}
              </h2>

              <p className="mt-2 leading-7 text-slate-600">
                {foundation.description}
              </p>
            </article>
          ))}
        </section>

        <section className="mt-8 rounded-3xl border border-slate-200 bg-white p-6 shadow-sm sm:p-8">
          <div>
            <p className="text-sm font-semibold text-emerald-700">
              Rencana pengembangan
            </p>

            <h2 className="mt-2 text-2xl font-bold text-slate-900">
              Modul E-Ma&apos;had
            </h2>

            <p className="mt-3 max-w-3xl leading-7 text-slate-600">
              Modul berikut akan dikerjakan secara bertahap.
              Keberadaan modul pada daftar ini belum berarti fitur
              tersebut sudah diimplementasikan.
            </p>
          </div>

          <div className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {plannedModules.map((module) => (
              <div
                key={module}
                className="rounded-xl border border-slate-200 bg-slate-50 px-4 py-3 text-sm font-medium text-slate-700"
              >
                {module}
              </div>
            ))}
          </div>
        </section>
      </div>
    </main>
  );
}