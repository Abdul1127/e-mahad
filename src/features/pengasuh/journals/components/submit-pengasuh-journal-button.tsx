"use client";

import {
  useActionState,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import {
  submitPengasuhJournal,
} from "../actions/submit-pengasuh-journal";

import {
  initialPengasuhJournalMutationState,
} from "../types/pengasuh-journal-mutation-state";

type SubmitPengasuhJournalButtonProps = {
  journalId:
    string;

  disabled:
    boolean;
};

function SubmitButton({
  disabled,
}: {
  disabled:
    boolean;
}) {
  const {
    pending,
  } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={
        disabled ||
        pending
      }
      className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {pending
        ? "Mengirim..."
        : "Kirim untuk Review"}
    </button>
  );
}

export function SubmitPengasuhJournalButton({
  journalId,
  disabled,
}: SubmitPengasuhJournalButtonProps) {
  const [
    state,
    formAction,
  ] = useActionState(
    submitPengasuhJournal,
    initialPengasuhJournalMutationState,
  );

  return (
    <form
      action={
        formAction
      }
    >
      <input
        type="hidden"
        name="journalId"
        value={
          journalId
        }
      />

      <SubmitButton
        disabled={
          disabled
        }
      />

      {state.status ===
        "error" &&
        state.message && (
          <p className="mt-2 max-w-sm text-xs leading-5 text-red-600">
            {
              state.message
            }
          </p>
        )}
    </form>
  );
}