"use client";

import {
  useActionState,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import { createOrOpenPengasuhJournal } from "../actions/create-or-open-pengasuh-journal";
import type { CareJournalSession } from "../schemas/pengasuh-journal-overview-schema";
import {
  initialPengasuhJournalActionState,
} from "../types/pengasuh-journal-action-state";

type CreateJournalButtonProps = {
  careGroupId: string;
  journalDate: string;
  session:
    CareJournalSession;
};

function SubmitButton({
  session,
}: {
  session:
    CareJournalSession;
}) {
  const {
    pending,
  } = useFormStatus();

  const label =
    session === "morning"
      ? "Buat Jurnal Pagi"
      : "Buat Jurnal Sore";

  return (
    <button
      type="submit"
      disabled={
        pending
      }
      className="inline-flex min-h-11 w-full items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Menyiapkan..."
        : label}
    </button>
  );
}

export function CreateJournalButton({
  careGroupId,
  journalDate,
  session,
}: CreateJournalButtonProps) {
  const [
    state,
    formAction,
  ] = useActionState(
    createOrOpenPengasuhJournal,
    initialPengasuhJournalActionState,
  );

  return (
    <form
      action={
        formAction
      }
    >
      <input
        type="hidden"
        name="careGroupId"
        value={
          careGroupId
        }
      />

      <input
        type="hidden"
        name="journalDate"
        value={
          journalDate
        }
      />

      <input
        type="hidden"
        name="session"
        value={
          session
        }
      />

      <SubmitButton
        session={
          session
        }
      />

      {state.status ===
        "error" &&
        state.message && (
          <p className="mt-2 text-xs leading-5 text-red-600">
            {
              state.message
            }
          </p>
        )}
    </form>
  );
}