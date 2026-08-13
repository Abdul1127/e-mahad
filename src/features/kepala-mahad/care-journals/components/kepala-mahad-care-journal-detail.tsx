import {
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import type {
  KepalaMahadCareJournalDetailData,
} from "../schemas/kepala-mahad-care-journal-detail-schema";

import {
  KepalaMahadCareJournalReviewPanel,
} from "./kepala-mahad-care-journal-review-panel";

type Props = {
  data:
    KepalaMahadCareJournalDetailData;
};

function readable(
  value:
    string | boolean | null,
): string {
  switch (value) {
    case "healthy":
      return "Sehat";

    case "unwell":
      return "Kurang Fit";

    case "on_time":
      return "Tepat Waktu";

    case "needs_reminder":
      return "Perlu Teguran";

    case "cheerful":
      return "Ceria";

    case "gloomy":
      return "Murung";

    case "quiet":
      return "Pendiam";

    case "homesick":
      return "Homesick";

    case "emotional":
      return "Emosional";

    case true:
      return "Ada";

    case false:
      return "Tidak Ada";

    default:
      return "-";
  }
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

function reviewActionLabel(
  action:
    | "reviewed"
    | "revision_requested",
): string {
  return action ===
    "reviewed"
    ? "Selesai Direview"
    : "Minta Revisi";
}

export function KepalaMahadCareJournalDetail({
  data,
}: Props) {
  const {
    journal,
    summary,
    entries,
    reviews,
  } = data;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <ReturnLink
        fallbackHref="/kepala-mahad/pengasuhan"
        allowedPrefixes={[
          "/kepala-mahad/pengasuhan",
        ]}
        className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
      >
        ← Kembali ke Jurnal
      </ReturnLink>

      <section className="mt-5 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Review Jurnal Pengasuhan
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          {
            journal.care_group
              .name
          }
        </h1>

        <div className="mt-4 flex flex-wrap gap-2 text-xs font-semibold">
          <span className="rounded-full bg-brand-50 px-3 py-1 text-brand-700">
            {journal.session ===
            "morning"
              ? "Pagi"
              : "Sore"}
          </span>

          <span className="rounded-full bg-slate-100 px-3 py-1 text-slate-600">
            {
              journal.journal_date
            }
          </span>

          <span
            className={`rounded-full px-3 py-1 ${getStatusClassName(
              journal.status,
            )}`}
          >
            {getStatusLabel(
              journal.status,
            )}
          </span>

          <span className="rounded-full bg-slate-100 px-3 py-1 text-slate-600">
            Submission{" "}
            {
              journal.submission_version
            }
          </span>
        </div>

        <div className="mt-6 grid gap-4 sm:grid-cols-3">
          <div className="rounded-2xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Total Santri
            </p>

            <p className="mt-2 text-2xl font-bold text-ink">
              {
                summary.entry_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-brand-50 p-4">
            <p className="text-xs text-brand-600">
              Data Lengkap
            </p>

            <p className="mt-2 text-2xl font-bold text-brand-900">
              {
                summary.complete_entry_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Dikirim Oleh
            </p>

            <p className="mt-2 font-bold text-ink">
              {journal.submitted_by
                ?.full_name ??
                "-"}
            </p>
          </div>
        </div>
      </section>

      {journal.status ===
        "submitted" && (
          <section className="mt-5 rounded-2xl border border-blue-200 bg-blue-50 p-4 sm:p-5">
            <p className="font-semibold text-blue-800">
              Jurnal menunggu keputusan
              review
            </p>

            <p className="mt-1 text-sm leading-6 text-blue-700">
              Periksa kondisi seluruh
              santri. Setelah selesai,
              jurnal dapat dinyatakan
              selesai direview atau
              dikembalikan kepada
              Pengasuh untuk revisi.
            </p>
          </section>
        )}

      {journal.status ===
        "revision_requested" && (
          <section className="mt-5 rounded-2xl border border-amber-200 bg-amber-50 p-4 sm:p-5">
            <p className="font-semibold text-amber-800">
              Jurnal sudah dikembalikan
              untuk revisi
            </p>

            <p className="mt-1 text-sm leading-6 text-amber-700">
              Pengasuh dapat memperbaiki
              jurnal berdasarkan catatan
              review kemudian
              mengirimkannya kembali.
            </p>
          </section>
        )}

      {journal.status ===
        "reviewed" && (
          <section className="mt-5 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 sm:p-5">
            <p className="font-semibold text-emerald-800">
              Jurnal sudah selesai
              direview
            </p>

            <p className="mt-1 text-sm leading-6 text-emerald-700">
              Submission ini sudah
              diperiksa oleh Kepala
              Ma&apos;had.
            </p>
          </section>
        )}

      <section className="mt-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Detail Santri
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Kondisi Santri
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
            Data berikut merupakan
            kondisi yang dicatat oleh
            Pengasuh pada jurnal ini.
          </p>
        </div>

        {entries.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-8 text-center">
            <p className="font-semibold text-ink">
              Tidak ada data santri.
            </p>
          </div>
        ) : (
          <div className="mt-5 space-y-3">
            {entries.map(
              (entry) => (
                <article
                  key={
                    entry.id
                  }
                  className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5"
                >
                  <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <p className="font-bold text-ink">
                        {
                          entry.full_name
                        }
                      </p>

                      <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-400">
                        {entry.nis && (
                          <span>
                            NIS{" "}
                            {
                              entry.nis
                            }
                          </span>
                        )}

                        {entry.class && (
                          <span>
                            Kelas{" "}
                            {
                              entry.class
                                .name
                            }
                          </span>
                        )}
                      </div>
                    </div>

                    {(entry.case_notes ||
                      entry.handling_notes) && (
                      <span className="w-fit rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700">
                        Ada Catatan
                      </span>
                    )}
                  </div>

                  <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Kesehatan
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.health_condition,
                        )}
                      </p>
                    </div>

                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Jam Tidur
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.sleep_compliance,
                        )}
                      </p>
                    </div>

                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Psikologis
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.psychological_condition,
                        )}
                      </p>
                    </div>

                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Kunjungan Orang Tua
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.parent_visit,
                        )}
                      </p>
                    </div>
                  </div>

                  {(entry.case_notes ||
                    entry.handling_notes) && (
                      <div className="mt-4 grid gap-3 lg:grid-cols-2">
                        <div className="rounded-xl border border-amber-100 bg-amber-50 p-4">
                          <p className="text-xs font-semibold text-amber-700">
                            Kasus / Kejadian
                          </p>

                          <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-amber-900">
                            {entry.case_notes ??
                              "-"}
                          </p>
                        </div>

                        <div className="rounded-xl border border-brand-100 bg-brand-50 p-4">
                          <p className="text-xs font-semibold text-brand-700">
                            Penanganan
                          </p>

                          <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-brand-900">
                            {entry.handling_notes ??
                              "-"}
                          </p>
                        </div>
                      </div>
                    )}
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {journal.status ===
        "submitted" && (
          <KepalaMahadCareJournalReviewPanel
            journalId={
              journal.id
            }
            submissionVersion={
              journal.submission_version
            }
          />
        )}

      {reviews.length >
        0 && (
        <section className="mt-6 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Audit Review
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Riwayat Review
          </h2>

          <div className="mt-5 space-y-3">
            {reviews.map(
              (review) => (
                <article
                  key={
                    review.id
                  }
                  className="rounded-2xl border border-line bg-slate-50 p-4"
                >
                  <div className="flex flex-col gap-2 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <p className="font-semibold text-ink">
                        {
                          review.reviewer
                            .full_name
                        }
                      </p>

                      <p className="mt-1 text-xs text-slate-400">
                        Submission{" "}
                        {
                          review.submission_version
                        }
                      </p>
                    </div>

                    <span
                      className={
                        review.action ===
                        "reviewed"
                          ? "w-fit rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700"
                          : "w-fit rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700"
                      }
                    >
                      {reviewActionLabel(
                        review.action,
                      )}
                    </span>
                  </div>

                  {review.note && (
                    <p className="mt-3 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                      {
                        review.note
                      }
                    </p>
                  )}
                </article>
              ),
            )}
          </div>
        </section>
      )}
    </div>
  );
}