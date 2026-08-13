import Link from "next/link";

import {
  PreserveStateLink,
} from "@/components/navigation/navigation-state-link";

import type {
  PengasuhJournalHistoryData,
  PengasuhJournalHistoryItem,
} from "../schemas/pengasuh-journal-history-schema";

type Props = {
  data:
    PengasuhJournalHistoryData;

  page:
    number;
};

function getSessionLabel(
  session:
    "morning" | "evening",
): string {
  return session === "morning"
    ? "Pagi"
    : "Sore";
}

function getStatusLabel(
  status:
    | "draft"
    | "submitted"
    | "revision_requested"
    | "reviewed",
): string {
  switch (status) {
    case "draft":
      return "Draft";

    case "submitted":
      return "Menunggu Review";

    case "revision_requested":
      return "Perlu Revisi";

    case "reviewed":
      return "Sudah Direview";
  }
}

function getStatusClassName(
  status:
    | "draft"
    | "submitted"
    | "revision_requested"
    | "reviewed",
): string {
  switch (status) {
    case "draft":
      return "bg-slate-100 text-slate-700";

    case "submitted":
      return "bg-blue-50 text-blue-700";

    case "revision_requested":
      return "bg-amber-50 text-amber-700";

    case "reviewed":
      return "bg-emerald-50 text-emerald-700";
  }
}

function formatDate(
  value:
    string,
): string {
  const date =
    new Date(
      `${value}T00:00:00`,
    );

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
    date,
  );
}

function createPaginationHref(
  data:
    PengasuhJournalHistoryData,
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
    data.filters.session
  ) {
    params.set(
      "session",
      data.filters.session,
    );
  }

  if (
    data.filters.date
  ) {
    params.set(
      "date",
      data.filters.date,
    );
  }

  params.set(
    "page",
    String(
      page,
    ),
  );

  return `/pengasuh/riwayat?${params.toString()}`;
}

function JournalHistoryCard({
  journal,
}: {
  journal:
    PengasuhJournalHistoryItem;
}) {
  const incompleteCount =
    Math.max(
      0,
      journal.entry_count -
        journal.complete_entry_count,
    );

  return (
    <article className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
      <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <div className="flex flex-wrap gap-2">
            <span
              className={`rounded-full px-2.5 py-1 text-xs font-semibold ${getStatusClassName(
                journal.status,
              )}`}
            >
              {getStatusLabel(
                journal.status,
              )}
            </span>

            <span className="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-700">
              {getSessionLabel(
                journal.session,
              )}
            </span>

            {journal.submission_version >
              0 && (
              <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                Submission{" "}
                {
                  journal.submission_version
                }
              </span>
            )}
          </div>

          <p className="mt-4 text-sm font-medium text-slate-500">
            {formatDate(
              journal.journal_date,
            )}
          </p>

          <h2 className="mt-1 text-xl font-bold text-ink">
            {
              journal.care_group
                .name
            }
          </h2>

          <p className="mt-2 text-sm text-muted">
            Dibuat oleh{" "}
            <span className="font-semibold text-slate-700">
              {
                journal.created_by
                  .full_name
              }
            </span>
          </p>
        </div>

        <div className="min-w-32 rounded-2xl bg-slate-50 px-4 py-3 text-center">
          <p className="text-2xl font-bold text-ink">
            {
              journal.complete_entry_count
            }
            {" / "}
            {
              journal.entry_count
            }
          </p>

          <p className="mt-1 text-xs text-muted">
            Santri Lengkap
          </p>
        </div>
      </div>

      {incompleteCount >
        0 && (
        <div className="mt-4 rounded-xl border border-amber-100 bg-amber-50 px-4 py-3">
          <p className="text-sm font-medium text-amber-800">
            {
              incompleteCount
            }{" "}
            santri belum lengkap.
          </p>
        </div>
      )}

      {journal.latest_review && (
        <div className="mt-4 rounded-2xl border border-line bg-slate-50 p-4">
          <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.12em] text-slate-400">
                Review Terakhir
              </p>

              <p className="mt-2 font-semibold text-ink">
                {
                  journal.latest_review
                    .reviewer
                    .full_name
                }
              </p>

              <p className="mt-1 text-xs text-slate-400">
                Submission{" "}
                {
                  journal.latest_review
                    .submission_version
                }
              </p>
            </div>

            <span
              className={
                journal.latest_review
                  .action ===
                "reviewed"
                  ? "w-fit rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700"
                  : "w-fit rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700"
              }
            >
              {journal.latest_review
                .action ===
              "reviewed"
                ? "Selesai Direview"
                : "Minta Revisi"}
            </span>
          </div>

          {journal.latest_review
            .note && (
            <p className="mt-3 whitespace-pre-wrap text-sm leading-6 text-slate-600">
              {
                journal.latest_review
                  .note
              }
            </p>
          )}
        </div>
      )}

      <div className="mt-5 border-t border-line pt-4">
        <PreserveStateLink
          href={`/pengasuh/jurnal/${journal.id}`}
          className="inline-flex min-h-11 w-full items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800 sm:w-auto"
        >
          Lihat Detail
        </PreserveStateLink>
      </div>
    </article>
  );
}

export function PengasuhJournalHistory({
  data,
  page,
}: Props) {
  const previousPage =
    Math.max(
      1,
      page - 1,
    );

  const nextPage =
    page + 1;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* =====================================================
          HEADER
      ===================================================== */}

      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pengasuh
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Riwayat Pengasuhan
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Lihat kembali seluruh
          Jurnal Pengasuhan dari
          kelompok yang menjadi
          tanggung jawab Anda.
        </p>

        <p className="mt-2 text-sm font-semibold text-slate-600">
          Tahun Ajaran{" "}
          {
            data.academic_year
              .name
          }
        </p>
      </section>

      {/* =====================================================
          SUMMARY
      ===================================================== */}

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div className="rounded-2xl border border-line bg-white p-4 shadow-soft">
          <p className="text-xs text-muted">
            Total Jurnal
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {
              data.summary
                .total_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-blue-100 bg-blue-50 p-4">
          <p className="text-xs font-medium text-blue-700">
            Menunggu Review
          </p>

          <p className="mt-2 text-3xl font-bold text-blue-900">
            {
              data.summary
                .submitted_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-amber-100 bg-amber-50 p-4">
          <p className="text-xs font-medium text-amber-700">
            Perlu Revisi
          </p>

          <p className="mt-2 text-3xl font-bold text-amber-900">
            {
              data.summary
                .revision_requested_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-4">
          <p className="text-xs font-medium text-emerald-700">
            Sudah Direview
          </p>

          <p className="mt-2 text-3xl font-bold text-emerald-900">
            {
              data.summary
                .reviewed_count
            }
          </p>
        </div>
      </section>

      {/* =====================================================
          FILTER
      ===================================================== */}

      <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          action="/pengasuh/riwayat"
          method="get"
          className="grid gap-4 md:grid-cols-2 xl:grid-cols-[1fr_1fr_1fr_auto]"
        >
          <div>
            <label
              htmlFor="history-status"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Status
            </label>

            <select
              id="history-status"
              name="status"
              defaultValue={
                data.filters.status ??
                "all"
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="all">
                Semua Status
              </option>

              <option value="draft">
                Draft
              </option>

              <option value="submitted">
                Menunggu Review
              </option>

              <option value="revision_requested">
                Perlu Revisi
              </option>

              <option value="reviewed">
                Sudah Direview
              </option>
            </select>
          </div>

          <div>
            <label
              htmlFor="history-session"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Sesi
            </label>

            <select
              id="history-session"
              name="session"
              defaultValue={
                data.filters.session ??
                "all"
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="all">
                Semua Sesi
              </option>

              <option value="morning">
                Pagi
              </option>

              <option value="evening">
                Sore
              </option>
            </select>
          </div>

          <div>
            <label
              htmlFor="history-date"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Tanggal
            </label>

            <input
              id="history-date"
              name="date"
              type="date"
              defaultValue={
                data.filters.date ??
                ""
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
          </div>

          <button
            type="submit"
            className="min-h-11 self-end rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            Tampilkan
          </button>
        </form>
      </section>

      {/* =====================================================
          RESULTS
      ===================================================== */}

      <section className="mt-6">
        <div className="flex flex-col gap-1 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-ink">
              Daftar Riwayat
            </h2>

            <p className="mt-1 text-sm text-muted">
              {
                data.pagination
                  .filtered_count
              }{" "}
              jurnal ditemukan.
            </p>
          </div>

          {(data.filters.status ||
            data.filters.session ||
            data.filters.date) && (
            <Link
              href="/pengasuh/riwayat"
              className="mt-2 text-sm font-semibold text-brand-700 sm:mt-0"
            >
              Reset Filter
            </Link>
          )}
        </div>

        {data.items.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Belum ada riwayat
            </h3>

            <p className="mt-2 text-sm text-muted">
              Tidak ada jurnal yang
              sesuai dengan filter
              yang dipilih.
            </p>
          </div>
        ) : (
          <div className="mt-5 grid gap-4 xl:grid-cols-2">
            {data.items.map(
              (journal) => (
                <JournalHistoryCard
                  key={
                    journal.id
                  }
                  journal={
                    journal
                  }
                />
              ),
            )}
          </div>
        )}
      </section>

      {/* =====================================================
          PAGINATION
      ===================================================== */}

      {(page > 1 ||
        data.pagination
          .has_more) && (
        <section className="mt-6 flex items-center justify-between rounded-2xl border border-line bg-white p-4 shadow-soft">
          <div>
            <p className="text-xs text-muted">
              Halaman
            </p>

            <p className="font-bold text-ink">
              {page}
            </p>
          </div>

          <div className="flex gap-2">
            {page > 1 ? (
              <Link
                href={createPaginationHref(
                  data,
                  previousPage,
                )}
                className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-700 hover:bg-slate-50"
              >
                Sebelumnya
              </Link>
            ) : (
              <span className="inline-flex min-h-10 cursor-not-allowed items-center justify-center rounded-xl border border-line bg-slate-50 px-4 text-sm font-semibold text-slate-300">
                Sebelumnya
              </span>
            )}

            {data.pagination
              .has_more ? (
              <Link
                href={createPaginationHref(
                  data,
                  nextPage,
                )}
                className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white hover:bg-brand-800"
              >
                Berikutnya
              </Link>
            ) : (
              <span className="inline-flex min-h-10 cursor-not-allowed items-center justify-center rounded-xl bg-slate-100 px-4 text-sm font-semibold text-slate-400">
                Berikutnya
              </span>
            )}
          </div>
        </section>
      )}
    </div>
  );
}