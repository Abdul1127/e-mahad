"use client";

import {
  useActionState,
  useEffect,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import {
  useRouter,
} from "next/navigation";

import {
  fillNormalPengasuhJournal,
} from "../actions/fill-normal-pengasuh-journal";

import {
  initialPengasuhJournalMutationState,
} from "../types/pengasuh-journal-mutation-state";

type FillNormalPengasuhJournalButtonProps = {
  journalId:
    string;

  incompleteCount:
    number;

  disabled?:
    boolean;
};

function SubmitButton({
  incompleteCount,
  disabled,
}: {
  incompleteCount:
    number;

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
        pending ||
        incompleteCount === 0
      }
      className="inline-flex min-h-11 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-5 text-sm font-semibold text-brand-700 transition hover:bg-brand-100 focus:outline-none focus:ring-4 focus:ring-brand-100 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {pending
        ? "Mengisi..."
        : `Isi Kondisi Normal untuk ${incompleteCount} Santri`}
    </button>
  );
}

export function FillNormalPengasuhJournalButton({
  journalId,
  incompleteCount,
  disabled = false,
}: FillNormalPengasuhJournalButtonProps) {
  const router =
    useRouter();

  const [
    state,
    formAction,
  ] = useActionState(
    fillNormalPengasuhJournal,
    initialPengasuhJournalMutationState,
  );

  useEffect(
    () => {
      if (
        state.status ===
        "success"
      ) {
        router.refresh();
      }
    },
    [
      router,
      state.status,
    ],
  );

  function handleSubmit(
    event:
      React.FormEvent<HTMLFormElement>,
  ) {
    if (
      disabled ||
      incompleteCount === 0
    ) {
      event.preventDefault();
      return;
    }

    const confirmed =
      window.confirm(
        `Isi kondisi normal untuk ${incompleteCount} santri yang belum lengkap?\n\nData yang sudah diisi sebelumnya tidak akan ditimpa.`,
      );

    if (!confirmed) {
      event.preventDefault();
    }
  }

  return (
    <div>
      <form
        action={
          formAction
        }
        onSubmit={
          handleSubmit
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
          incompleteCount={
            incompleteCount
          }
          disabled={
            disabled
          }
        />
      </form>

      {state.status ===
        "success" &&
        state.message && (
          <p className="mt-2 text-sm font-medium text-emerald-700">
            {
              state.message
            }
          </p>
        )}

      {state.status ===
        "error" &&
        state.message && (
          <p className="mt-2 text-sm font-medium text-red-600">
            {
              state.message
            }
          </p>
        )}
    </div>
  );
}