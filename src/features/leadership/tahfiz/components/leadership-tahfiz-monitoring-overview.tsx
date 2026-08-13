
import Link from "next/link";

import {
  PreserveStateLink,
} from "@/components/navigation/navigation-state-link";

import type {
  LeadershipTahfizMonitoringItem,
  LeadershipTahfizMonitoringOverview,
  LeadershipTahfizRating,
} from "../schemas/leadership-tahfiz-schema";

type RoleSlug =
  | "kepala-mahad"
  | "penanggung-jawab";

type Props = {
  data:
    LeadershipTahfizMonitoringOverview;

  roleSlug:
    RoleSlug;

  page:
    number;

  pageSize:
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
      return "bg-slate-50 text-slate-500";
  }
}

function StudentCard({
  item,
  roleSlug,
}: {
  item:
    LeadershipTahfizMonitoringItem;

  roleSlug:
    RoleSlug;
}) {
  const report =
    item.report;

  const needsAttention =
    report !== null &&
    (
      report.fluency_rating ===
        "needs_guidance" ||
      report.tajwid_rating ===
        "needs_guidance" ||
      report.consistency_rating ===
        "needs_guidance"
    );

  return (
    <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h3 className="text-lg font-bold text-ink">
              {
                item.student
                  .full_name
              }
            </h3>

            <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
              {item.student
                .gender ===
              "male"
                ? "Putra"
                : "Putri"}
            </span>

            {needsAttention && (
              <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700">
                Perlu Perhatian
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
          </div>
        </div>

        {report ? (
          <span className="w-fit rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
            Published
          </span>
        ) : (
          <span className="w-fit rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-500">
            Belum Published
          </span>
        )}
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <div className="rounded-xl bg-brand-50 p-3">
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

        <div className="rounded-xl bg-slate-50 p-3">
          <p className="text-xs text-muted">
            Pembina
          </p>

          <p className="mt-1 text-sm font-semibold text-ink">
            {item.supervisors.length >
            0
              ? item.supervisors
                  .map(
                    (
                      supervisor,
                    ) =>
                      supervisor
                        .full_name,
                  )
                  .join(", ")
              : "Belum tersedia"}
          </p>
        </div>
      </div>

      {report ? (
        <>
          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <div className={`rounded-xl p-3 ${ratingClassName(
              report.fluency_rating,
            )}`}>
              <p className="text-xs opacity-75">
                Kelancaran
              </p>

              <p className="mt-1 text-sm font-bold">
                {ratingLabel(
                  report.fluency_rating,
                )}
              </p>
            </div>

            <div className={`rounded-xl p-3 ${ratingClassName(
              report.tajwid_rating,
            )}`}>
              <p className="text-xs opacity-75">
                Tajwid
              </p>

              <p className="mt-1 text-sm font-bold">
                {ratingLabel(
                  report.tajwid_rating,
                )}
              </p>
            </div>

            <div className={`rounded-xl p-3 ${ratingClassName(
              report.consistency_rating,
            )}`}>
              <p className="text-xs opacity-75">
                Konsistensi
              </p>

              <p className="mt-1 text-sm font-bold">
                {ratingLabel(
                  report.consistency_rating,
                )}
              </p>
            </div>
          </div>

          <div className="mt-4 grid gap-3 lg:grid-cols-2">
            <div className="rounded-xl border border-line p-3">
              <p className="text-xs font-semibold text-muted">
                Hafalan Baru
              </p>

              <p className="mt-2 line-clamp-3 text-sm leading-6 text-ink">
                {
                  report
                    .memorization_achievement ??
                  "-"
                }
              </p>
            </div>

            <div className="rounded-xl border border-line p-3">
              <p className="text-xs font-semibold text-muted">
                Murajaah
              </p>

              <p className="mt-2 line-clamp-3 text-sm leading-6 text-ink">
                {
                  report
                    .murajaah_achievement ??
                  "-"
                }
              </p>
            </div>
          </div>
        </>
      ) : (
        <div className="mt-4 rounded-xl border border-dashed border-line bg-slate-50 p-4">
          <p className="text-sm text-muted">
            Belum ada laporan
            published untuk pekan
            yang dipilih.
          </p>
        </div>
      )}

      <PreserveStateLink
        href={`/${roleSlug}/tahfiz/${item.student.id}`}
        className="mt-4 inline-flex min-h-10 w-full items-center justify-center rounded-xl border border-brand-200 bg-white px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-50"
      >
        Lihat Riwayat Tahfiz
      </PreserveStateLink>
    </article>
  );
}

export function LeadershipTahfizMonitoringOverview({
  data,
  roleSlug,
  page,
  pageSize,
}: Props) {
  const totalItems =
    data.items.length;

  const totalPages =
    Math.max(
      1,
      Math.ceil(
        totalItems /
          pageSize,
      ),
    );

  const currentPage =
    Math.min(
      Math.max(
        page,
        1,
      ),
      totalPages,
    );

  const startIndex =
    (
      currentPage -
      1
    ) *
    pageSize;

  const visibleItems =
    data.items.slice(
      startIndex,
      startIndex +
        pageSize,
    );

  const fromItem =
    totalItems > 0
      ? startIndex + 1
      : 0;

  const toItem =
    totalItems > 0
      ? Math.min(
          startIndex +
            pageSize,
          totalItems,
        )
      : 0;

  function buildPageHref(
    targetPage:
      number,
  ): string {
    const params =
      new URLSearchParams();

    params.set(
      "week",
      data.week.start,
    );

    if (
      data.filters.group_id
    ) {
      params.set(
        "group",
        data.filters.group_id,
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
        targetPage,
      ),
    );

    return `/${roleSlug}/tahfiz?${params.toString()}`;
  }

  const titleRole =
    roleSlug ===
    "kepala-mahad"
      ? "Kepala Ma'had"
      : "Penanggung Jawab";

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          {titleRole}
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Monitoring Perkembangan
          Tahfiz
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Pantau laporan Tahfiz
          mingguan yang telah
          dipublikasikan oleh
          Pembina Tahfiz.
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
            {" � "}
            {formatDate(
              data.week.end,
            )}
          </span>

          <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
            Read-only
          </span>
        </div>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-5">
        <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <p className="text-xs font-medium text-brand-700">
            Kelompok
          </p>

          <p className="mt-2 text-3xl font-bold text-brand-900">
            {
              data.summary
                .group_count
            }
          </p>
        </div>

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

        <div className="rounded-2xl border border-slate-200 bg-slate-50 p-5">
          <p className="text-xs text-slate-600">
            Belum Published
          </p>

          <p className="mt-2 text-3xl font-bold text-slate-900">
            {
              data.summary
                .missing_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-red-100 bg-red-50 p-5">
          <p className="text-xs font-medium text-red-700">
            Perlu Perhatian
          </p>

          <p className="mt-2 text-3xl font-bold text-red-900">
            {
              data.summary
                .attention_count
            }
          </p>
        </div>
      </section>

      <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          method="get"
          className="grid gap-4 xl:grid-cols-[230px_250px_1fr_auto]"
        >
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
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            />

            <p className="mt-1 text-xs text-slate-400">
              Gunakan hari Senin.
            </p>
          </div>

          <div>
            <label
              htmlFor="group"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Kelompok
            </label>

            <select
              id="group"
              name="group"
              defaultValue={
                data.filters.group_id ??
                ""
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="">
                Semua Kelompok
              </option>

              {data.groups.map(
                (group) => (
                  <option
                    key={
                      group.id
                    }
                    value={
                      group.id
                    }
                  >
                    {
                      group.name
                    }
                  </option>
                ),
              )}
            </select>
          </div>

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
              placeholder="Nama, NIS, ID santri, atau kelompok..."
              className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />
          </div>

          <button
            type="submit"
            className="min-h-11 self-end rounded-xl bg-brand-700 px-6 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            Tampilkan
          </button>
        </form>

        {(
          data.filters.search ||
          data.filters.group_id
        ) && (
          <Link
            href={`/${roleSlug}/tahfiz?week=${data.week.start}`}
            className="mt-3 inline-flex text-sm font-semibold text-brand-700"
          >
            Reset Filter
          </Link>
        )}
      </section>

      <section className="mt-7">
        <div className="flex flex-col gap-2 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Kelompok Tahfiz
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Ringkasan Kelompok
            </h2>
          </div>

          <p className="text-sm text-muted">
            {
              data.summary
                .filtered_count
            }{" "}
            santri sesuai filter
          </p>
        </div>

        <div className="mt-5 grid gap-4 xl:grid-cols-2">
          {data.groups.map(
            (group) => {
              const percentage =
                group.member_count >
                0
                  ? Math.round(
                      (
                        group.published_count /
                        group.member_count
                      ) *
                        100,
                    )
                  : 0;

              return (
                <article
                  key={
                    group.id
                  }
                  className="rounded-2xl border border-line bg-white p-5 shadow-soft"
                >
                  <div className="flex items-start justify-between gap-4">
                    <div>
                      <h3 className="font-bold text-ink">
                        {
                          group.name
                        }
                      </h3>

                      <p className="mt-1 text-xs text-muted">
                        {
                          group.code
                        }
                      </p>
                    </div>

                    <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                      {percentage}%
                    </span>
                  </div>

                  <div className="mt-4 grid grid-cols-3 gap-3">
                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Santri
                      </p>

                      <p className="mt-1 text-xl font-bold text-ink">
                        {
                          group.member_count
                        }
                      </p>
                    </div>

                    <div className="rounded-xl bg-emerald-50 p-3">
                      <p className="text-xs text-emerald-700">
                        Published
                      </p>

                      <p className="mt-1 text-xl font-bold text-emerald-900">
                        {
                          group.published_count
                        }
                      </p>
                    </div>

                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Belum
                      </p>

                      <p className="mt-1 text-xl font-bold text-ink">
                        {
                          group.missing_count
                        }
                      </p>
                    </div>
                  </div>

                  <div className="mt-4 border-t border-line pt-4">
                    <p className="text-xs font-semibold text-muted">
                      Pembina
                    </p>

                    <p className="mt-1 text-sm font-medium text-ink">
                      {group.supervisors
                        .length >
                      0
                        ? group.supervisors
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
                    </p>
                  </div>
                </article>
              );
            },
          )}
        </div>
      </section>

      <section className="mt-8">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Monitoring Individual
        </p>

        <h2 className="mt-2 text-2xl font-bold text-ink">
          Daftar Santri
        </h2>

        <p className="mt-2 text-sm text-muted">
          Menampilkan{" "}
          <strong className="text-ink">
            {fromItem}
          </strong>
          {"–"}
          <strong className="text-ink">
            {toItem}
          </strong>
          {" dari "}
          <strong className="text-ink">
            {totalItems}
          </strong>
          {" santri."}
        </p>

        {visibleItems.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Santri tidak ditemukan
            </h3>

            <p className="mt-2 text-sm text-muted">
              Tidak ada santri yang
              sesuai dengan filter.
            </p>
          </div>
        ) : (
          <div className="mt-5 grid gap-4 xl:grid-cols-2">
            {visibleItems.map(
              (item) => (
                <StudentCard
                  key={
                    item.student
                      .id
                  }
                  item={
                    item
                  }
                  roleSlug={
                    roleSlug
                  }
                />
              ),
            )}
          </div>
        )}

        {totalItems > 0 &&
        totalPages > 1 && (
          <nav
            aria-label="Pagination monitoring Tahfiz"
            className="mt-6 flex flex-col gap-3 rounded-2xl border border-line bg-white p-4 shadow-soft sm:flex-row sm:items-center sm:justify-between"
          >
            <p className="text-center text-sm text-muted sm:text-left">
              Halaman{" "}
              <strong className="text-ink">
                {currentPage}
              </strong>
              {" dari "}
              <strong className="text-ink">
                {totalPages}
              </strong>
            </p>

            <div className="grid grid-cols-2 gap-3">
              {currentPage > 1 ? (
                <Link
                  href={buildPageHref(
                    currentPage -
                      1,
                  )}
                  className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
                >
                  Sebelumnya
                </Link>
              ) : (
                <span className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-slate-50 px-4 text-sm font-semibold text-slate-300">
                  Sebelumnya
                </span>
              )}

              {currentPage <
              totalPages ? (
                <Link
                  href={buildPageHref(
                    currentPage +
                      1,
                  )}
                  className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
                >
                  Berikutnya
                </Link>
              ) : (
                <span className="inline-flex min-h-10 items-center justify-center rounded-xl bg-slate-100 px-4 text-sm font-semibold text-slate-300">
                  Berikutnya
                </span>
              )}
            </div>
          </nav>
        )}
      </section>

      <section className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-5">
        <p className="font-semibold text-blue-800">
          Monitoring read-only
        </p>

        <p className="mt-1 max-w-4xl text-sm leading-6 text-blue-700">
          Halaman ini hanya
          menampilkan laporan Tahfiz
          yang telah dipublikasikan.
          Draft Pembina Tahfiz tidak
          ditampilkan dan tidak dapat
          diedit dari role pimpinan.
        </p>
      </section>
    </div>
  );
}
