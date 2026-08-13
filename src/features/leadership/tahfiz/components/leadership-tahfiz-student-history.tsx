import {
  CarryReturnToLink,
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import type {
  LeadershipTahfizRating,
  LeadershipTahfizStudentHistory,
} from "../schemas/leadership-tahfiz-schema";

type RoleSlug =
  | "kepala-mahad"
  | "penanggung-jawab";

type Props = {
  data:
    LeadershipTahfizStudentHistory;

  roleSlug:
    RoleSlug;

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
        "long",

      year:
        "numeric",
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
    LeadershipTahfizRating | null,
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

function ratingClassName(
  value:
    LeadershipTahfizRating | null,
): string {
  switch (
    value
  ) {
    case "excellent":
      return "bg-emerald-50 text-emerald-700";

    case "good":
      return "bg-brand-50 text-brand-700";

    case "fair":
      return "bg-amber-50 text-amber-700";

    case "needs_guidance":
      return "bg-red-50 text-red-700";

    default:
      return "bg-slate-50 text-slate-600";
  }
}

export function LeadershipTahfizStudentHistory({
  data,
  roleSlug,
  page,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1200px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <ReturnLink
        fallbackHref={`/${roleSlug}/tahfiz`}
        allowedPrefixes={[
          `/${roleSlug}/tahfiz`,
        ]}
        className="text-sm font-semibold text-brand-700"
      >
        ← Kembali ke Monitoring Tahfiz
      </ReturnLink>

      <section className="mt-6 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <h1 className="text-3xl font-bold text-ink">
                {
                  data.student
                    .full_name
                }
              </h1>

              <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                {data.student
                  .gender ===
                "male"
                  ? "Putra"
                  : "Putri"}
              </span>

              <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
                Read-only
              </span>
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
                Tahun Ajaran{" "}
                {
                  data.academic_year
                    .name
                }
              </span>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div className="rounded-2xl bg-brand-50 px-5 py-4">
              <p className="text-xs text-brand-700">
                Published
              </p>

              <p className="mt-1 text-3xl font-bold text-brand-900">
                {
                  data.summary
                    .published_report_count
                }
              </p>
            </div>

            <div className="rounded-2xl bg-red-50 px-5 py-4">
              <p className="text-xs text-red-700">
                Perhatian
              </p>

              <p className="mt-1 text-3xl font-bold text-red-900">
                {
                  data.summary
                    .attention_report_count
                }
              </p>
            </div>
          </div>
        </div>

        {data.current_group && (
          <div className="mt-5 rounded-2xl bg-slate-50 p-4">
            <p className="text-xs font-semibold uppercase tracking-[0.12em] text-muted">
              Kelompok Tahfiz Aktif
            </p>

            <p className="mt-2 font-bold text-ink">
              {
                data.current_group
                  .name
              }
            </p>

            <p className="mt-1 text-xs text-muted">
              {
                data.current_group
                  .code
              }
            </p>

            <p className="mt-3 text-sm text-muted">
              Pembina:{" "}
              <span className="font-semibold text-ink">
                {data.current_group
                  .supervisors
                  .length >
                0
                  ? data.current_group
                      .supervisors
                      .map(
                        (
                          supervisor,
                        ) =>
                          supervisor
                            .full_name,
                      )
                      .join(
                        ", ",
                      )
                  : "Belum tersedia"}
              </span>
            </p>
          </div>
        )}
      </section>

      <section className="mt-7">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Riwayat Published
        </p>

        <h2 className="mt-2 text-2xl font-bold text-ink">
          Laporan Tahfiz Pekanan
        </h2>

        {data.items.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Belum ada laporan
            </h3>

            <p className="mt-2 text-sm text-muted">
              Belum terdapat laporan
              Tahfiz published untuk
              santri ini.
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
                          {" � "}
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

                    <div className="mt-4 grid gap-3 sm:grid-cols-3">
                      <div className={`rounded-2xl p-4 ${ratingClassName(
                        report.fluency_rating,
                      )}`}>
                        <p className="text-xs opacity-75">
                          Kelancaran
                        </p>

                        <p className="mt-2 font-bold">
                          {ratingLabel(
                            report.fluency_rating,
                          )}
                        </p>
                      </div>

                      <div className={`rounded-2xl p-4 ${ratingClassName(
                        report.tajwid_rating,
                      )}`}>
                        <p className="text-xs opacity-75">
                          Tajwid
                        </p>

                        <p className="mt-2 font-bold">
                          {ratingLabel(
                            report.tajwid_rating,
                          )}
                        </p>
                      </div>

                      <div className={`rounded-2xl p-4 ${ratingClassName(
                        report.consistency_rating,
                      )}`}>
                        <p className="text-xs opacity-75">
                          Konsistensi
                        </p>

                        <p className="mt-2 font-bold">
                          {ratingLabel(
                            report.consistency_rating,
                          )}
                        </p>
                      </div>
                    </div>

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
                      {report.published_by && (
                        <p className="text-xs text-slate-400">
                          Dipublikasikan
                          oleh{" "}
                          {
                            report
                              .published_by
                              .full_name
                          }
                        </p>
                      )}

                      {report.published_at && (
                        <p className="mt-1 text-xs text-slate-400">
                          {formatDateTime(
                            report.published_at,
                          )}
                        </p>
                      )}
                    </div>
                  </div>
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {(
        data.pagination
          .has_previous ||
        data.pagination
          .has_next
      ) && (
        <section className="mt-7 flex items-center justify-between gap-4">
          {data.pagination
            .has_previous ? (
            <CarryReturnToLink
              href={`/${roleSlug}/tahfiz/${data.student.id}?page=${Math.max(
                page -
                  1,
                1,
              )}`}
              className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-700"
            >
              ← Sebelumnya
            </CarryReturnToLink>
          ) : (
            <span />
          )}

          <p className="text-sm font-medium text-muted">
            Halaman{" "}
            {page}
          </p>

          {data.pagination
            .has_next ? (
            <CarryReturnToLink
              href={`/${roleSlug}/tahfiz/${data.student.id}?page=${page + 1}`}
              className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white"
            >
              Berikutnya →
            </CarryReturnToLink>
          ) : (
            <span />
          )}
        </section>
      )}

      <section className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-5">
        <p className="font-semibold text-blue-800">
          Monitoring read-only
        </p>

        <p className="mt-1 text-sm leading-6 text-blue-700">
          Seluruh laporan pada
          halaman ini sudah
          dipublikasikan oleh
          Pembina Tahfiz. Role
          pimpinan tidak mempunyai
          fungsi edit atau publish.
        </p>
      </section>
    </div>
  );
}
