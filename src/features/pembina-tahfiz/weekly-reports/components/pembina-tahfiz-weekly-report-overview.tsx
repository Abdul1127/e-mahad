import Link from "next/link";

import type {
  PembinaTahfizWeeklyReportOverviewData,
  PembinaTahfizWeeklyReportOverviewItem,
} from "../schemas/pembina-tahfiz-weekly-report-overview-schema";

type Props = {
  data: PembinaTahfizWeeklyReportOverviewData;
};

/*
 * =========================================================
 * DATE FORMATTER
 * =========================================================
 */

function formatDate(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day: "2-digit",
      month: "long",
      year: "numeric",
    },
  ).format(
    new Date(
      `${value}T00:00:00Z`,
    ),
  );
}

/*
 * =========================================================
 * STUDENT REPORT CARD
 * =========================================================
 */

function StudentReportCard({
  item,
  weekStart,
}: {
  item: PembinaTahfizWeeklyReportOverviewItem;
  weekStart: string;
}) {
  const report =
    item.report;

  return (
    <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-lg font-bold text-ink">
              {
                item.student
                  .full_name
              }
            </h2>

            {report === null ? (
              <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                Belum Dibuat
              </span>
            ) : report.status ===
              "draft" ? (
              <span className="rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700">
                Draft
              </span>
            ) : (
              <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                Published
              </span>
            )}
          </div>

          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-400">
            {item.student
              .nis && (
              <span>
                NIS{" "}
                {
                  item.student
                    .nis
                }
              </span>
            )}

            {item.student
              .legacy_student_id && (
              <span>
                ID{" "}
                {
                  item.student
                    .legacy_student_id
                }
              </span>
            )}

            {item.class && (
              <span>
                Kelas{" "}
                {
                  item.class
                    .name
                }
              </span>
            )}

            <span>
              {item.student
                .gender ===
              "male"
                ? "Putra"
                : "Putri"}
            </span>
          </div>
        </div>
      </div>

      {/* =================================================
          TAHFIZ GROUP
      ================================================= */}

      <div className="mt-4 rounded-xl bg-brand-50 p-3">
        <p className="text-xs font-medium text-brand-600">
          Kelompok Tahfiz
        </p>

        <p className="mt-1 text-sm font-semibold text-brand-900">
          {
            item.tahfiz_group
              .name
          }
        </p>

        <p className="mt-1 text-xs text-brand-600">
          {
            item.tahfiz_group
              .code
          }
        </p>
      </div>

      {/* =================================================
          REPORT INFORMATION
      ================================================= */}

      {report?.published_at && (
        <p className="mt-3 text-xs text-slate-400">
          Dipublikasikan{" "}
          {new Intl.DateTimeFormat(
            "id-ID",
            {
              dateStyle:
                "medium",

              timeStyle:
                "short",
            },
          ).format(
            new Date(
              report.published_at,
            ),
          )}
        </p>
      )}

      {report &&
        !report.published_at && (
          <p className="mt-3 text-xs text-slate-400">
            Terakhir diperbarui{" "}
            {new Intl.DateTimeFormat(
              "id-ID",
              {
                dateStyle:
                  "medium",

                timeStyle:
                  "short",
              },
            ).format(
              new Date(
                report.updated_at,
              ),
            )}
          </p>
        )}

      {/* =================================================
          ACTION
      ================================================= */}

      <Link
        href={`/pembina-tahfiz/laporan/${item.student.id}?week=${weekStart}`}
        className="mt-4 inline-flex min-h-11 w-full items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
      >
        {report === null
          ? "Buat Laporan"
          : report.status ===
              "draft"
            ? "Lanjutkan Draft"
            : "Lihat Laporan"}
      </Link>
    </article>
  );
}

/*
 * =========================================================
 * MAIN COMPONENT
 * =========================================================
 */

export function PembinaTahfizWeeklyReportOverview({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* =====================================================
          HEADER
      ===================================================== */}

      <section>
        <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Pembina Tahfiz
            </p>

            <h1 className="mt-2 text-3xl font-bold text-ink">
              Laporan Tahfiz Mingguan
            </h1>

            <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
              Kelola laporan Tahfiz
              individual setiap
              santri pada pekan yang
              dipilih.
            </p>

            <div className="mt-3 flex flex-wrap gap-2">
              <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                Tahun Ajaran{" "}
                {
                  data.academic_year
                    .name
                }
              </span>

              <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                {formatDate(
                  data.week.start,
                )}
                {" – "}
                {formatDate(
                  data.week.end,
                )}
              </span>
            </div>
          </div>

          {/* =================================================
              HISTORY BUTTON
          ================================================= */}

          <Link
            href="/pembina-tahfiz/laporan/riwayat"
            className="inline-flex min-h-11 w-fit shrink-0 items-center justify-center rounded-xl border border-brand-200 bg-white px-5 text-sm font-semibold text-brand-700 transition hover:bg-brand-50"
          >
            Lihat Riwayat Laporan
          </Link>
        </div>
      </section>

      {/* =====================================================
          SUMMARY
      ===================================================== */}

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        {/* TOTAL */}

        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Total Santri
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {
              data.summary
                .student_count
            }
          </p>
        </div>

        {/* NOT CREATED */}

        <div className="rounded-2xl border border-slate-200 bg-slate-50 p-5">
          <p className="text-xs text-slate-600">
            Belum Dibuat
          </p>

          <p className="mt-2 text-3xl font-bold text-slate-900">
            {
              data.summary
                .not_created_count
            }
          </p>
        </div>

        {/* DRAFT */}

        <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
          <p className="text-xs font-medium text-amber-700">
            Draft
          </p>

          <p className="mt-2 text-3xl font-bold text-amber-900">
            {
              data.summary
                .draft_count
            }
          </p>
        </div>

        {/* PUBLISHED */}

        <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
          <p className="text-xs font-medium text-emerald-700">
            Published
          </p>

          <p className="mt-2 text-3xl font-bold text-emerald-900">
            {
              data.summary
                .published_count
            }
          </p>
        </div>
      </section>

      {/* =====================================================
          FILTER
      ===================================================== */}

      <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          action="/pembina-tahfiz/laporan"
          method="get"
          className="grid gap-4 lg:grid-cols-[280px_1fr_auto]"
        >
          {/* WEEK */}

          <div>
            <label
              htmlFor="week"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Awal Pekan
            </label>

            <input
              id="week"
              name="week"
              type="date"
              defaultValue={
                data.week.start
              }
              min={
                data.academic_year
                  .start_date
              }
              max={
                data.academic_year
                  .end_date
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />

            <p className="mt-1 text-xs text-slate-400">
              Pilih tanggal hari
              Senin.
            </p>
          </div>

          {/* SEARCH */}

          <div>
            <label
              htmlFor="search"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Cari Santri
            </label>

            <input
              id="search"
              name="search"
              type="search"
              defaultValue={
                data.filters.search ??
                ""
              }
              placeholder="Nama, NIS, ID santri, atau kelompok Tahfiz..."
              className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />
          </div>

          {/* SUBMIT */}

          <button
            type="submit"
            className="min-h-11 self-start rounded-xl bg-brand-700 px-6 text-sm font-semibold text-white transition hover:bg-brand-800 lg:self-end"
          >
            Tampilkan
          </button>
        </form>

        {/* ACTIVE SEARCH */}

        {data.filters.search && (
          <div className="mt-4 flex flex-wrap items-center gap-2 text-sm">
            <span className="text-muted">
              Pencarian:
            </span>

            <span className="font-semibold text-ink">
              &quot;
              {
                data.filters.search
              }
              &quot;
            </span>

            <Link
              href={`/pembina-tahfiz/laporan?week=${data.week.start}`}
              className="font-semibold text-brand-700 transition hover:text-brand-800"
            >
              Reset Pencarian
            </Link>
          </div>
        )}
      </section>

      {/* =====================================================
          LIST HEADER
      ===================================================== */}

      <section className="mt-7">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Laporan Individual
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Daftar Santri
            </h2>
          </div>

          <p className="text-sm text-muted">
            {
              data.summary
                .filtered_count
            }{" "}
            santri ditampilkan
          </p>
        </div>

        {/* =================================================
            EMPTY
        ================================================= */}

        {data.items.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Santri tidak ditemukan
            </h3>

            <p className="mt-2 text-sm leading-6 text-muted">
              Tidak ada santri
              Tahfiz ampuan yang
              sesuai dengan
              pencarian pada pekan
              ini.
            </p>

            {data.filters.search && (
              <Link
                href={`/pembina-tahfiz/laporan?week=${data.week.start}`}
                className="mt-4 inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
              >
                Tampilkan Semua
              </Link>
            )}
          </div>
        ) : (
          /* ===============================================
             STUDENT CARDS
          =============================================== */

          <div className="mt-5 grid gap-4 xl:grid-cols-2">
            {data.items.map(
              (item) => (
                <StudentReportCard
                  key={
                    item.student.id
                  }
                  item={
                    item
                  }
                  weekStart={
                    data.week.start
                  }
                />
              ),
            )}
          </div>
        )}
      </section>

      {/* =====================================================
          INFORMATION
      ===================================================== */}

      <section className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-4 sm:p-5">
        <p className="font-semibold text-blue-800">
          Laporan dibuat per santri
          setiap pekan
        </p>

        <p className="mt-1 max-w-4xl text-sm leading-6 text-blue-700">
          Laporan yang masih
          berstatus Draft belum
          menjadi laporan publikasi.
          Setelah laporan
          dipublikasikan, statusnya
          berubah menjadi Published
          dan nantinya dapat
          ditampilkan kepada Orang
          Tua/Wali santri yang
          terhubung.
        </p>
      </section>
    </div>
  );
}