import Link from "next/link";

import type {
  GuardianTahfizReportHistoryData,
} from "../schemas/guardian-tahfiz-report-history-schema";

type Props = {
  data:
    GuardianTahfizReportHistoryData;

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

function formatDateTime(
  value:
    string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle:
        "medium",

      timeStyle:
        "short",
    },
  ).format(
    new Date(
      value,
    ),
  );
}

function ratingLabel(
  value:
    | "excellent"
    | "good"
    | "fair"
    | "needs_guidance"
    | null,
): string {
  switch (
    value
  ) {
    case "excellent":
      return "Sangat Baik";

    case "good":
      return "Baik";

    case "fair":
      return "Cukup";

    case "needs_guidance":
      return "Perlu Bimbingan";

    default:
      return "-";
  }
}

function relationshipLabel(
  value:
    string,
): string {
  switch (
    value
      .trim()
      .toLowerCase()
  ) {
    case "father":
      return "Ayah";

    case "mother":
      return "Ibu";

    case "parent":
      return "Orang Tua";

    case "guardian":
      return "Wali";

    default:
      return value;
  }
}

function buildPageHref(
  studentId:
    string,

  page:
    number,
): string {
  return `/wali/tahfiz/${studentId}?page=${page}`;
}

export function GuardianTahfizReportHistory({
  data,
  page,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1200px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* =====================================================
          HEADER
      ===================================================== */}

      <section>
        <Link
          href="/wali/dashboard"
          className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
        >
          ← Kembali ke Dashboard
        </Link>

        <p className="mt-5 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Orang Tua / Wali
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Riwayat Tahfiz
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Laporan perkembangan
          Tahfiz yang telah
          dipublikasikan oleh
          Pembina Tahfiz.
        </p>
      </section>

      {/* =====================================================
          STUDENT
      ===================================================== */}

      <section className="mt-6 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="text-2xl font-bold text-ink">
                {
                  data.student
                    .full_name
                }
              </h2>

              <span className="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-700">
                {data.student
                  .gender ===
                "male"
                  ? "Putra"
                  : "Putri"}
              </span>

              {data.relationship
                .is_primary_contact && (
                <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">
                  Kontak Utama
                </span>
              )}
            </div>

            <div className="mt-3 flex flex-wrap gap-x-4 gap-y-2 text-sm text-muted">
              {data.student
                .nis && (
                <span>
                  NIS{" "}
                  {
                    data.student
                      .nis
                  }
                </span>
              )}

              <span>
                Hubungan:{" "}
                {relationshipLabel(
                  data.relationship
                    .type,
                )}
              </span>

              <span>
                Tahun Ajaran{" "}
                {
                  data.academic_year
                    .name
                }
              </span>
            </div>
          </div>

          <div className="w-fit rounded-2xl bg-brand-50 px-5 py-4">
            <p className="text-xs font-medium text-brand-700">
              Total Laporan
            </p>

            <p className="mt-1 text-3xl font-bold text-brand-900">
              {
                data.summary
                  .published_report_count
              }
            </p>
          </div>
        </div>
      </section>

      {/* =====================================================
          LIST
      ===================================================== */}

      <section className="mt-7">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Laporan Published
        </p>

        <h2 className="mt-2 text-2xl font-bold text-ink">
          Riwayat Pekanan
        </h2>

        {data.items.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Belum ada laporan
            </h3>

            <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-muted">
              Belum terdapat
              laporan Tahfiz yang
              telah dipublikasikan
              untuk santri ini.
            </p>
          </div>
        ) : (
          <div className="mt-5 space-y-5">
            {data.items.map(
              (report) => (
                <article
                  key={
                    report.id
                  }
                  className="overflow-hidden rounded-3xl border border-line bg-white shadow-soft"
                >
                  {/* REPORT HEADER */}

                  <div className="border-b border-line p-5 sm:p-6">
                    <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                      <div>
                        <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                          Periode Laporan
                        </p>

                        <h3 className="mt-2 text-xl font-bold text-ink">
                          {formatDate(
                            report.week_start,
                          )}
                          {" – "}
                          {formatDate(
                            report.week_end,
                          )}
                        </h3>

                        <p className="mt-2 text-sm text-muted">
                          {
                            report
                              .tahfiz_group
                              .name
                          }
                        </p>
                      </div>

                      <span className="w-fit rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700">
                        Published
                      </span>
                    </div>
                  </div>

                  {/* REPORT BODY */}

                  <div className="p-5 sm:p-6">
                    <div className="grid gap-4 lg:grid-cols-2">
                      <div className="rounded-2xl border border-line p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                          Capaian Hafalan Baru
                        </p>

                        <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-ink">
                          {
                            report
                              .memorization_achievement ??
                            "-"
                          }
                        </p>
                      </div>

                      <div className="rounded-2xl border border-line p-4">
                        <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                          Capaian Murajaah
                        </p>

                        <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-ink">
                          {
                            report
                              .murajaah_achievement ??
                            "-"
                          }
                        </p>
                      </div>
                    </div>

                    {/* RATINGS */}

                    <div className="mt-4 grid gap-3 sm:grid-cols-3">
                      <div className="rounded-2xl bg-slate-50 p-4">
                        <p className="text-xs text-muted">
                          Kelancaran
                        </p>

                        <p className="mt-2 font-bold text-ink">
                          {ratingLabel(
                            report
                              .fluency_rating,
                          )}
                        </p>
                      </div>

                      <div className="rounded-2xl bg-slate-50 p-4">
                        <p className="text-xs text-muted">
                          Tajwid
                        </p>

                        <p className="mt-2 font-bold text-ink">
                          {ratingLabel(
                            report
                              .tajwid_rating,
                          )}
                        </p>
                      </div>

                      <div className="rounded-2xl bg-slate-50 p-4">
                        <p className="text-xs text-muted">
                          Konsistensi
                        </p>

                        <p className="mt-2 font-bold text-ink">
                          {ratingLabel(
                            report
                              .consistency_rating,
                          )}
                        </p>
                      </div>
                    </div>

                    {/* NOTES + TARGET */}

                    <div className="mt-4 grid gap-4 lg:grid-cols-2">
                      <div className="rounded-2xl border border-line p-4">
                        <p className="text-xs font-semibold text-slate-500">
                          Catatan Pembina
                        </p>

                        <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-ink">
                          {
                            report
                              .supervisor_notes ??
                            "-"
                          }
                        </p>
                      </div>

                      <div className="rounded-2xl border border-brand-100 bg-brand-50 p-4">
                        <p className="text-xs font-semibold text-brand-700">
                          Target Pekan Berikutnya
                        </p>

                        <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-brand-950">
                          {
                            report
                              .next_week_target ??
                            "-"
                          }
                        </p>
                      </div>
                    </div>

                    <div className="mt-4 border-t border-line pt-4">
                      <p className="text-xs text-slate-400">
                        Dipublikasikan{" "}
                        {formatDateTime(
                          report
                            .published_at,
                        )}
                      </p>
                    </div>
                  </div>
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {/* =====================================================
          PAGINATION
      ===================================================== */}

      {(
        data.pagination
          .has_previous ||
        data.pagination
          .has_next
      ) && (
        <section className="mt-7 flex items-center justify-between gap-4">
          <div>
            {data.pagination
              .has_previous ? (
              <Link
                href={buildPageHref(
                  data.student.id,
                  Math.max(
                    page - 1,
                    1,
                  ),
                )}
                className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-700 transition hover:bg-slate-50"
              >
                ← Sebelumnya
              </Link>
            ) : (
              <span />
            )}
          </div>

          <p className="text-sm font-medium text-muted">
            Halaman{" "}
            {page}
          </p>

          <div>
            {data.pagination
              .has_next ? (
              <Link
                href={buildPageHref(
                  data.student.id,
                  page + 1,
                )}
                className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
              >
                Berikutnya →
              </Link>
            ) : (
              <span />
            )}
          </div>
        </section>
      )}

      {/* =====================================================
          INFO
      ===================================================== */}

      <section className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-4 sm:p-5">
        <p className="font-semibold text-blue-800">
          Riwayat Tahfiz
        </p>

        <p className="mt-1 max-w-4xl text-sm leading-6 text-blue-700">
          Halaman ini hanya
          menampilkan laporan yang
          sudah dipublikasikan oleh
          Pembina Tahfiz. Draft tidak
          ditampilkan kepada Orang
          Tua/Wali.
        </p>
      </section>
    </div>
  );
}