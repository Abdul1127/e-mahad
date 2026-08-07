"use client";

import type { MouseEvent } from "react";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import {
  initialStaffAccountStatusActionState,
  type StaffAccountStatusActionState,
} from "../types/staff-account-action-state";

type StaffAccountStatusAction = (
  state:
    StaffAccountStatusActionState,

  formData:
    FormData,
) => Promise<StaffAccountStatusActionState>;

type StaffAccountStatusButtonProps = {
  action:
    StaffAccountStatusAction;

  targetIsActive:
    boolean;

  staffName:
    string;
};

function SubmitButton({
  targetIsActive,
  staffName,
}: {
  targetIsActive: boolean;
  staffName: string;
}) {
  const { pending } =
    useFormStatus();

  function handleClick(
    event:
      MouseEvent<HTMLButtonElement>,
  ) {
    const message =
      targetIsActive
        ? `Aktifkan kembali akun login ${staffName}?`
        : `Nonaktifkan akun login ${staffName}? Staf tidak dapat login sampai akun diaktifkan kembali.`;

    if (
      !window.confirm(
        message,
      )
    ) {
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

export function StaffAccountStatusButton({
  action,
  targetIsActive,
  staffName,
}: StaffAccountStatusButtonProps) {
  const [
    state,
    formAction,
  ] = useActionState(
    action,
    initialStaffAccountStatusActionState,
  );

  return (
    <form action={formAction}>
      <SubmitButton
        targetIsActive={
          targetIsActive
        }
        staffName={staffName}
      />

      {state.message && (
        <p className="mt-2 max-w-sm text-xs font-medium leading-5 text-red-600">
          {state.message}
        </p>
      )}
    </form>
  );
}