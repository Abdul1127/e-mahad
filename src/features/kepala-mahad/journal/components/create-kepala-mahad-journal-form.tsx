"use client";

import {
  useActionState,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import {
  createKepalaMahadJournalAction,
} from "../actions/create-kepala-mahad-journal-action";

import {
  initialMahadHeadJournalActionState,
} from "../types/mahad-head-journal-action-state";

function SubmitButton() {
  const {
    pending,
  } =
    useFormStatus();

  return (
    <button
      type="submit"
      disabled={
        pending
      }
      className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Membuka jurnal..."
        : "Lanjutkan"}
    </button>
  );
}

export function CreateKepalaMahadJournalForm({
  defaultDate,
}: {
  defaultDate:
    string;
}) {
  const [
    state,
    formAction,
  ] =
    useActionState(
      createKepalaMahadJournalAction,
      initialMahadHeadJournalActionState,
    );

  return (
    <form
      action={
        formAction
      }
      className="rounded-3xl border border-line bg-white p-6 shadow-soft"
    >
      <label
        htmlFor="journal_date"
        className="text-sm font-semibold text-ink"
      >
        Tanggal Pelaksanaan
      </label>

      <input
        id="journal_date"
        name="journal_date"
        type="date"
        required
        defaultValue={
          defaultDate
        }
        className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none transition focus:border-brand-300 focus:ring-4 focus:ring-brand-50"
      />

      <p className="mt-2 text-xs leading-5 text-muted">
        Satu Kepala Ma&apos;had
        memiliki satu jurnal untuk
        setiap tanggal pada tahun
        ajaran aktif.
      </p>

      {state.status ===
        "error" && (
        <div className="mt-4 rounded-xl border border-red-100 bg-red-50 p-3 text-sm text-red-700">
          {
            state.message
          }
        </div>
      )}

      <div className="mt-6">
        <SubmitButton />
      </div>
    </form>
  );
}