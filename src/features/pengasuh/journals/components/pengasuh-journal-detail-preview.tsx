import {
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import type {
  CareJournalStatus,
} from "../schemas/pengasuh-journal-overview-schema";

import type {
  PengasuhJournalDetailData,
} from "../schemas/pengasuh-journal-detail-schema";

import {
  PengasuhJournalEntryBrowser,
} from "./pengasuh-journal-entry-browser";

import {
  SubmitPengasuhJournalButton,
} from "./submit-pengasuh-journal-button";


type PengasuhJournalDetailPreviewProps = {
  data:
    PengasuhJournalDetailData;
};


function getSessionLabel(
  session:
    "morning" |
    "evening",
): string {
  return session ===
    "morning"
    ? "Pagi"
    : "Sore";
}


function getStatusLabel(
  status:
    CareJournalStatus,
): string {
  switch (
    status
  ) {
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
    CareJournalStatus,
): string {
  switch (
    status
  ) {
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


export function PengasuhJournalDetailPreview({
  data,
}: PengasuhJournalDetailPreviewProps) {
  const {
    journal,
    summary,
    entries,
    reviews,
  } =
    data;


  const incompleteCount =
    Math.max(
      0,
      summary.entry_count -
        summary.complete_entry_count,
    );


  const journalComplete =
    summary.entry_count >
      0 &&
    summary.complete_entry_count ===
      summary.entry_count;


  const temporarilyLocked =
    journal.status ===
    "submitted";


  const latestReview =
    reviews[0] ??
    null;


  const progressPercentage =
    summary.entry_count >
    0
      ? Math.round(
          (
            summary.complete_entry_count /
            summary.entry_count
          ) *
            100,
        )
      : 0;


  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* =====================================================
          BACK
      ===================================================== */}

      <ReturnLink
        fallbackHref={`/pengasuh/jurnal?date=${journal.journal_date}`}
        allowedPrefixes={[
          "/pengasuh/jurnal",
          "/pengasuh/riwayat",
        ]}
        className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
      >
        ← Kembali ke Jurnal
      </ReturnLink>


      {/* =====================================================
          JOURNAL HEADER
      ===================================================== */}

      <section className="mt-5 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Jurnal Pengasuhan
            </p>

            <h1 className="mt-2 text-3xl font-bold text-ink">
              {
                journal
                  .care_group
                  .name
              }
            </h1>

            <div className="mt-4 flex flex-wrap gap-2">
              <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                {getSessionLabel(
                  journal.session,
                )}
              </span>

              <span
                className={`rounded-full px-3 py-1 text-xs font-semibold ${getStatusClassName(
                  journal.status,
                )}`}
              >
                {getStatusLabel(
                  journal.status,
                )}
              </span>

              <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                {
                  journal
                    .journal_date
                }
              </span>

              {journal.submission_version >
                0 && (
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                  Submission{" "}
                  {
                    journal
                      .submission_version
                  }
                </span>
              )}
            </div>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50 px-5 py-4">
            <p className="text-xs font-medium text-brand-600">
              Progress Pengisian
            </p>

            <p className="mt-1 text-2xl font-bold text-brand-900">
              {
                progressPercentage
              }
              %
            </p>
          </div>
        </div>


        <div className="mt-6 grid gap-4 sm:grid-cols-3">
          <div className="rounded-2xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Total Santri
            </p>

            <p className="mt-2 text-2xl font-bold text-ink">
              {
                summary
                  .entry_count
              }
            </p>
          </div>


          <div className="rounded-2xl bg-brand-50 p-4">
            <p className="text-xs text-brand-600">
              Sudah Diisi
            </p>

            <p className="mt-2 text-2xl font-bold text-brand-900">
              {
                summary
                  .complete_entry_count
              }
            </p>
          </div>


          <div className="rounded-2xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Belum Lengkap
            </p>

            <p className="mt-2 text-2xl font-bold text-ink">
              {
                incompleteCount
              }
            </p>
          </div>
        </div>


        <div className="mt-5">
          <div className="h-2.5 overflow-hidden rounded-full bg-slate-100">
            <div
              className="h-full rounded-full bg-brand-600 transition-all"
              style={{
                width:
                  `${progressPercentage}%`,
              }}
            />
          </div>
        </div>
      </section>


      {/* =====================================================
          LOCKED
      ===================================================== */}

      {temporarilyLocked && (
        <section className="mt-5 rounded-2xl border border-blue-200 bg-blue-50 p-4 sm:p-5">
          <p className="font-semibold text-blue-800">
            Jurnal sedang menunggu
            review Kepala Ma&apos;had
          </p>

          <p className="mt-1 text-sm leading-6 text-blue-700">
            Data jurnal tidak dapat
            diubah sementara sampai
            proses review selesai.
          </p>
        </section>
      )}


      {/* =====================================================
          REVISION REQUEST
      ===================================================== */}

      {journal.status ===
        "revision_requested" &&
        latestReview
          ?.action ===
          "revision_requested" && (
          <section className="mt-5 rounded-2xl border border-amber-200 bg-amber-50 p-4 sm:p-5">
            <p className="font-semibold text-amber-800">
              Kepala Ma&apos;had
              meminta revisi
            </p>

            <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-amber-700">
              {latestReview
                .note ??
                "Silakan periksa kembali jurnal ini."}
            </p>
          </section>
        )}


      {/* =====================================================
          REVIEWED
      ===================================================== */}

      {journal.status ===
        "reviewed" && (
        <section className="mt-5 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 sm:p-5">
          <p className="font-semibold text-emerald-800">
            Jurnal sudah direview
          </p>

          <p className="mt-1 text-sm leading-6 text-emerald-700">
            Jurnal tetap dapat
            diperbaiki. Ketika data
            santri diubah, status
            jurnal akan kembali
            menjadi Draft.
          </p>
        </section>
      )}


      {/* =====================================================
          JOURNAL ENTRIES
      ===================================================== */}

      <section className="mt-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Kondisi Santri
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Pengisian Jurnal
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
            Lengkapi empat kondisi
            wajib untuk setiap
            santri. Gunakan
            pengisian kondisi normal
            untuk mempercepat
            pencatatan, kemudian
            cari dan ubah santri
            yang mempunyai kondisi
            khusus.
          </p>
        </div>


        {entries.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-8 text-center">
            <p className="font-semibold text-ink">
              Tidak ada santri dalam
              jurnal ini.
            </p>
          </div>
        ) : (
          <PengasuhJournalEntryBrowser
            journalId={
              journal.id
            }
            entries={
              entries
            }
            incompleteCount={
              incompleteCount
            }
            disabled={
              temporarilyLocked
            }
          />
        )}
      </section>


      {/* =====================================================
          SUBMIT BAR
      ===================================================== */}

      <section className="sticky bottom-4 z-20 mt-6 rounded-2xl border border-line bg-white/95 p-4 shadow-lg backdrop-blur sm:p-5">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="font-semibold text-ink">
              {journalComplete
                ? "Jurnal sudah lengkap"
                : `${incompleteCount} santri belum lengkap`}
            </p>

            <p className="mt-1 text-sm text-muted">
              {temporarilyLocked
                ? "Jurnal sedang menunggu review Kepala Ma'had."
                : journalComplete
                  ? "Seluruh data wajib sudah lengkap. Jurnal dapat dikirim kepada Kepala Ma'had untuk direview."
                  : "Lengkapi seluruh data wajib atau gunakan pengisian kondisi normal sebelum mengirim jurnal."}
            </p>
          </div>


          {journal.status !==
            "submitted" &&
            journal.status !==
              "reviewed" && (
              <SubmitPengasuhJournalButton
                journalId={
                  journal.id
                }
                disabled={
                  !journalComplete
                }
              />
            )}
        </div>
      </section>


      {/* =====================================================
          REVIEW HISTORY
      ===================================================== */}

      {reviews.length >
        0 && (
        <section className="mt-6 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Riwayat Review
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Review Kepala Ma&apos;had
          </h2>


          <div className="mt-5 space-y-3">
            {reviews.map(
              (
                review,
              ) => (
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
                          review
                            .reviewer
                            .full_name
                        }
                      </p>

                      <p className="mt-1 text-xs text-slate-400">
                        Submission{" "}
                        {
                          review
                            .submission_version
                        }
                      </p>
                    </div>

                    <span
                      className={
                        review.action ===
                        "reviewed"
                          ? "rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700"
                          : "rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700"
                      }
                    >
                      {review.action ===
                      "reviewed"
                        ? "Direview"
                        : "Perlu Revisi"}
                    </span>
                  </div>

                  {review.note && (
                    <p className="mt-3 whitespace-pre-wrap text-sm leading-6 text-slate-600">
                      {
                        review
                          .note
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