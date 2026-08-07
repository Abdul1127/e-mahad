"use client";

import type { MouseEvent } from "react";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import {
  initialGuardianAccountStatusActionState,
  type GuardianAccountStatusActionState,
} from "../types/guardian-account-action-state";

type GuardianAccountStatusAction = (
  state:
    GuardianAccountStatusActionState,
  formData: FormData,
) => Promise<GuardianAccountStatusActionState>;

type GuardianAccountStatusButtonProps = {
  action: GuardianAccountStatusAction;

  targetIsActive: boolean;
  guardianName: string;
};

function SubmitButton({
  targetIsActive,
  guardianName,
}: {
  targetIsActive: boolean;
  guardianName: string;
}) {
  const { pending } = useFormStatus();

  function handleClick(
    event: MouseEvent<HTMLButtonElement>,
  ) {
    const confirmationMessage =
      targetIsActive
        ? `Aktifkan kembali akun login ${guardianName}?`
        : `Nonaktifkan akun login ${guardianName}? Wali tidak dapat login sampai akun diaktifkan kembali.`;

    const confirmed =
      window.confirm(
        confirmationMessage,
      );

    if (!confirmed) {
      event.preventDefault();
    }
  }

  return (
    <button
      type="submit"
      disabled={pending}
      onClick={handleClick}
      className={
        targetIsActive
          ? "inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100 disabled:cursor-not-allowed disabled:opacity-60"
          : "inline-flex min-h-10 items-center justify-center rounded-xl border border-red-200 bg-white px-4 text-sm font-semibold text-red-600 transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
      }
    >
      {pending
        ? "Memproses..."
        : targetIsActive
          ? "Aktifkan akun"
          : "Nonaktifkan akun"}
    </button>
  );
}

export function GuardianAccountStatusButton({
  action,
  targetIsActive,
  guardianName,
}: GuardianAccountStatusButtonProps) {
  const [state, formAction] =
    useActionState(
      action,
      initialGuardianAccountStatusActionState,
    );

  return (
    <form action={formAction}>
      <SubmitButton
        targetIsActive={targetIsActive}
        guardianName={guardianName}
      />

      {state.message && (
        <p className="mt-2 max-w-sm text-xs font-medium leading-5 text-red-600">
          {state.message}
        </p>
      )}
    </form>
  );
}