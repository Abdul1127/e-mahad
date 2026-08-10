import Link from "next/link";

import type {
  PembinaTahfizWeeklyReportHistoryData,
} from "../schemas/pembina-tahfiz-weekly-report-history-schema";

type Props = {
  data:
    PembinaTahfizWeeklyReportHistoryData;

  page:
    number;
};

function formatDate(
  value:
    string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day:
        "2-digit",

      month:
        "short",

      year:
        "numeric",
    },
  ).format(
    new Date(
      `${value}T00:00:00Z`,
    ),
  );
}

function buildPageHref(
  data:
    PembinaTahfizWeeklyReportHistoryData,

  page:
    number,
): string {
  const params =
    new URLSearchParams();

  if (
    data.filters.status
  ) {
    params.set(
      "status",
      data.filters.status,
    );
  }

  if (
    data.filters.search
  ) {
    params.set(
      "search",
      data.filters.search,
    );
  }

  params.set(
    "page",
    String(
      page,
    ),
  );

  return `/pembina-tahfiz/laporan/riwayat?${params.toString()}`;
}

export function PembinaTahfizWeeklyReportHistory({
  data,
  page,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* HEADER */}

      <section>
        <Link
          href="/pembina-tahfiz/laporan"
          className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
        >
          ← Kembali ke Laporan
        </Link>

        <p className="mt-5 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pembina Tahfiz
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Riwayat Laporan Tahfiz
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Lihat kembali seluruh
          laporan Tahfiz Mingguan
          yang pernah dibuat pada
          tahun ajaran berjalan.
        </p>

        <div className="mt-3">
          <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
            Tahun Ajaran{" "}
            {
              data.academic_year
                .name
            }
          </span>
        </div>
      </section>

      {/* SUMMARY */}

      <section className="mt-6 grid gap-4 sm:grid-cols-3">
        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Total Laporan
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {
              data.summary
                .total_count
            }
          </p>
        </div>

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

      {/* FILTER */}

      <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          action="/pembina-tahfiz/laporan/riwayat"
          method="get"
          className="grid gap-4 lg:grid-cols-[220px_1fr_auto]"
        >
          <div>
            <label
              htmlFor="status"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Status
            </label>

            <select
              id="status"
              name="status"
              defaultValue={
                data.filters.status ??
                ""
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="">
                Semua Status
              </option>

              <option value="draft">
                Draft
              </option>

              <option value="published">
                Published
              </option>
            </select>
          </div>

          <div>
            <label
              htmlFor="search"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Cari Laporan
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

          <button
            type="submit"
            className="min-h-11 self-end rounded-xl bg-brand-700 px-6 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            Terapkan
          </button>
        </form>

        {(
          data.filters.search ||
          data.filters.status
        ) && (
          <div className="mt-3">
            <Link
              href="/pembina-tahfiz/laporan/riwayat"
              className="text-sm font-semibold text-brand-700 hover:text-brand-800"
            >
              Reset Filter
            </Link>
          </div>
        )}
      </section>

      {/* LIST */}

      <section className="mt-7">
        <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Arsip Tahun Berjalan
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Daftar Laporan
            </h2>
          </div>

          <p className="text-sm text-muted">
            {
              data.summary
                .filtered_count
            }{" "}
            laporan ditemukan
          </p>
        </div>

        {data.items.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Belum ada riwayat
            </h3>

            <p className="mt-2 text-sm text-muted">
              Belum terdapat
              laporan Tahfiz yang
              sesuai dengan filter
              saat ini.
            </p>
          </div>
        ) : (
          <div className="mt-5 space-y-4">
            {data.items.map(
              (item) => (
                <article
                  key={
                    item.report.id
                  }
                  className="rounded-2xl border border-line bg-white p-5 shadow-soft"
                >
                  <div className="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <h3 className="text-lg font-bold text-ink">
                          {
                            item.student
                              .full_name
                          }
                        </h3>

                        {item.report
                          .status ===
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
                          {
                            item.tahfiz_group
                              .name
                          }
                        </span>
                      </div>

                      <div className="mt-4">
                        <p className="text-xs font-medium text-muted">
                          Periode
                        </p>

                        <p className="mt-1 text-sm font-semibold text-ink">
                          {formatDate(
                            item.report
                              .week_start,
                          )}
                          {" – "}
                          {formatDate(
                            item.report
                              .week_end,
                          )}
                        </p>
                      </div>

                      {item.report
                        .published_at && (
                        <p className="mt-2 text-xs text-emerald-600">
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
                              item.report
                                .published_at,
                            ),
                          )}
                        </p>
                      )}
                    </div>

                    <Link
                      href={`/pembina-tahfiz/laporan/${item.student.id}?week=${item.report.week_start}`}
                      className="inline-flex min-h-11 shrink-0 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
                    >
                      {item.report
                        .status ===
                      "draft"
                        ? "Lanjutkan Laporan"
                        : "Lihat Laporan"}
                    </Link>
                  </div>
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {/* PAGINATION */}

      {(
        data.pagination
          .has_previous ||
        data.pagination
          .has_next
      ) && (
        <section className="mt-6 flex items-center justify-between gap-4">
          <div>
            {data.pagination
              .has_previous ? (
              <Link
                href={buildPageHref(
                  data,
                  Math.max(
                    page - 1,
                    1,
                  ),
                )}
                className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-700 hover:bg-slate-50"
              >
                ← Sebelumnya
              </Link>
            ) : (
              <span />
            )}
          </div>

          <span className="text-sm font-medium text-muted">
            Halaman{" "}
            {page}
          </span>

          <div>
            {data.pagination
              .has_next ? (
              <Link
                href={buildPageHref(
                  data,
                  page + 1,
                )}
                className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white hover:bg-brand-800"
              >
                Berikutnya →
              </Link>
            ) : (
              <span />
            )}
          </div>
        </section>
      )}
    </div>
  );
}