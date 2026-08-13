import {
  PreserveStateLink,
} from "@/components/navigation/navigation-state-link";

import type {
  KepalaMahadCareJournalOverviewData,
  KepalaMahadCareJournalOverviewItem,
  KepalaMahadCareJournalStatus,
} from "../schemas/kepala-mahad-care-journal-overview-schema";

type Props = {
  data:
    KepalaMahadCareJournalOverviewData;
};

function statusLabel(
  status:
    KepalaMahadCareJournalStatus,
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

function sessionLabel(
  session:
    "morning" | "evening",
): string {
  return session ===
    "morning"
    ? "Pagi"
    : "Sore";
}

function statusClass(
  status:
    KepalaMahadCareJournalStatus,
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

function JournalCard({
  journal,
}: {
  journal:
    KepalaMahadCareJournalOverviewItem;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex flex-wrap gap-2">
            <span
              className={`rounded-full px-2.5 py-1 text-xs font-semibold ${statusClass(
                journal.status,
              )}`}
            >
              {statusLabel(
                journal.status,
              )}
            </span>

            <span className="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-700">
              {sessionLabel(
                journal.session,
              )}
            </span>

            <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">
              {
                journal.journal_date
              }
            </span>
          </div>

          <h2 className="mt-3 text-xl font-bold text-ink">
            {
              journal.care_group
                .name
            }
          </h2>

          <p className="mt-2 text-sm text-muted">
            Dikirim oleh{" "}
            <strong className="text-slate-700">
              {journal.submitted_by
                ?.full_name ??
                journal.created_by
                  .full_name}
            </strong>
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 px-4 py-3 text-center">
          <p className="text-xl font-bold text-ink">
            {
              journal.complete_entry_count
            }
            {" / "}
            {
              journal.entry_count
            }
          </p>

          <p className="mt-1 text-xs text-muted">
            data lengkap
          </p>
        </div>
      </div>

      {journal.latest_review && (
        <div className="mt-4 rounded-xl bg-slate-50 p-3">
          <p className="text-xs font-semibold text-slate-500">
            Review terakhir
          </p>

          <p className="mt-1 text-sm text-slate-700">
            {statusLabel(
              journal.latest_review
                .action,
            )}
            {"  "}
            {
              journal.latest_review
                .reviewer_name
            }
          </p>
        </div>
      )}

      <PreserveStateLink
        href={`/kepala-mahad/pengasuhan/${journal.id}`}
        className="mt-4 inline-flex min-h-11 w-full items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
      >
        {journal.status ===
        "submitted"
          ? "Review Jurnal"
          : "Lihat Detail"}
      </PreserveStateLink>
    </article>
  );
}

export function KepalaMahadCareJournalOverview({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Kepala Ma&apos;had
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Jurnal Pengasuhan
        </h1>

        <p className="mt-3 max-w-2xl text-sm leading-7 text-muted">
          Pantau jurnal Pengasuh,
          periksa kondisi santri,
          dan tindak lanjuti jurnal
          yang menunggu review.
        </p>

        <p className="mt-2 text-sm font-semibold text-slate-600">
          Tahun Ajaran{" "}
          {
            data.academic_year
              .name
          }
        </p>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
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
      </section>

      <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft">
        <form
          action="/kepala-mahad/pengasuhan"
          method="get"
          className="grid gap-3 sm:grid-cols-[1fr_1fr_auto]"
        >
          <div>
            <label
              htmlFor="status"
              className="mb-2 block text-xs font-semibold text-slate-500"
            >
              Status
            </label>

            <select
              id="status"
              name="status"
              defaultValue={
                data.filters.status ??
                "all"
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="submitted">
                Menunggu Review
              </option>

              <option value="revision_requested">
                Perlu Revisi
              </option>

              <option value="reviewed">
                Sudah Direview
              </option>

              <option value="draft">
                Draft
              </option>

              <option value="all">
                Semua Status
              </option>
            </select>
          </div>

          <div>
            <label
              htmlFor="date"
              className="mb-2 block text-xs font-semibold text-slate-500"
            >
              Tanggal
            </label>

            <input
              id="date"
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
            className="min-h-11 self-end rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white hover:bg-brand-800"
          >
            Tampilkan
          </button>
        </form>
      </section>

      {data.items.length ===
      0 ? (
        <section className="mt-6 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
          <h2 className="font-bold text-ink">
            Tidak ada jurnal
          </h2>

          <p className="mt-2 text-sm text-muted">
            Tidak ada jurnal yang
            sesuai dengan filter
            saat ini.
          </p>
        </section>
      ) : (
        <section className="mt-6 grid gap-4 xl:grid-cols-2">
          {data.items.map(
            (journal) => (
              <JournalCard
                key={
                  journal.id
                }
                journal={
                  journal
                }
              />
            ),
          )}
        </section>
      )}
    </div>
  );
}