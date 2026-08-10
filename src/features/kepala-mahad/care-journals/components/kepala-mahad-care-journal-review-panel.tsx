"use client";

import {
  useActionState,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import {
  reviewKepalaMahadCareJournal,
} from "../actions/review-kepala-mahad-care-journal";

import {
  initialKepalaMahadCareJournalReviewState,
} from "../types/kepala-mahad-care-journal-review-state";

type Props = {
  journalId:
    string;

  submissionVersion:
    number;
};

function ReviewButtons() {
  const {
    pending,
  } = useFormStatus();

  return (
    <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
      <button
        type="submit"
        name="reviewAction"
        value="revision_requested"
        disabled={
          pending
        }
        className="inline-flex min-h-11 items-center justify-center rounded-xl border border-amber-200 bg-amber-50 px-5 text-sm font-semibold text-amber-800 transition hover:bg-amber-100 disabled:cursor-not-allowed disabled:opacity-50"
        onClick={(
          event,
        ) => {
          if (
            pending
          ) {
            return;
          }

          const form =
            event.currentTarget
              .form;

          if (!form) {
            return;
          }

          const noteElement =
            form.elements.namedItem(
              "note",
            );

          if (
            noteElement instanceof
              HTMLTextAreaElement &&
            noteElement.value
              .trim()
              .length === 0
          ) {
            event.preventDefault();

            window.alert(
              "Catatan revisi wajib diisi sebelum meminta revisi.",
            );

            noteElement.focus();
          }
        }}
      >
        {pending
          ? "Memproses..."
          : "Minta Revisi"}
      </button>

      <button
        type="submit"
        name="reviewAction"
        value="reviewed"
        disabled={
          pending
        }
        className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-50"
        onClick={(
          event,
        ) => {
          if (
            pending
          ) {
            return;
          }

          const confirmed =
            window.confirm(
              "Tandai jurnal ini sebagai selesai direview?\n\nSetelah itu jurnal akan kembali dapat dilihat oleh Pengasuh dengan status Sudah Direview.",
            );

          if (
            !confirmed
          ) {
            event.preventDefault();
          }
        }}
      >
        {pending
          ? "Memproses..."
          : "Selesai Direview"}
      </button>
    </div>
  );
}

export function KepalaMahadCareJournalReviewPanel({
  journalId,
  submissionVersion,
}: Props) {
  const [
    state,
    formAction,
  ] = useActionState(
    reviewKepalaMahadCareJournal,
    initialKepalaMahadCareJournalReviewState,
  );

  return (
    <section className="sticky bottom-4 z-20 mt-6 rounded-2xl border border-line bg-white/95 p-5 shadow-lg backdrop-blur sm:p-6">
      <div className="flex flex-col gap-5 xl:flex-row xl:items-start xl:justify-between">
        <div className="max-w-xl">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Keputusan Review
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Submission{" "}
            {
              submissionVersion
            }
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Pilih Selesai Direview
            apabila jurnal sudah
            sesuai. Pilih Minta
            Revisi apabila terdapat
            data yang perlu
            diperbaiki oleh
            Pengasuh.
          </p>
        </div>

        <form
          action={
            formAction
          }
          className="w-full max-w-2xl"
        >
          <input
            type="hidden"
            name="journalId"
            value={
              journalId
            }
          />

          <div>
            <label
              htmlFor="review-note"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Catatan Review
            </label>

            <textarea
              id="review-note"
              name="note"
              rows={
                4
              }
              maxLength={
                2000
              }
              placeholder="Wajib diisi apabila meminta revisi. Untuk jurnal yang sudah sesuai, catatan bersifat opsional."
              className="w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />
          </div>

          {state.status ===
            "error" &&
            state.message && (
              <div className="mt-3 rounded-xl border border-red-200 bg-red-50 px-4 py-3">
                <p className="text-sm font-medium text-red-700">
                  {
                    state.message
                  }
                </p>
              </div>
            )}

          <div className="mt-4">
            <ReviewButtons />
          </div>
        </form>
      </div>
    </section>
  );
}