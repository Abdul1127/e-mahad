"use client";

import Link from "next/link";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import type { StaffAccountResetPasswordActionState } from "../types/staff-account-action-state";

type ResetPasswordAction = (
  state:
    StaffAccountResetPasswordActionState,

  formData:
    FormData,
) => Promise<StaffAccountResetPasswordActionState>;

type StaffAccountResetPasswordFormProps = {
  action:
    ResetPasswordAction;

  initialState:
    StaffAccountResetPasswordActionState;

  cancelHref: string;
  staffName: string;
  loginId: string;
};

function FieldErrors({
  errors,
}: {
  errors?: string[];
}) {
  if (
    !errors ||
    errors.length === 0
  ) {
    return null;
  }

  return (
    <div className="mt-2 space-y-1">
      {errors.map(
        (error) => (
          <p
            key={error}
            className="text-sm font-medium text-red-600"
          >
            {error}
          </p>
        ),
      )}
    </div>
  );
}

function SubmitButton() {
  const { pending } =
    useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Mengganti password..."
        : "Simpan password baru"}
    </button>
  );
}

export function StaffAccountResetPasswordForm({
  action,
  initialState,
  cancelHref,
  staffName,
  loginId,
}: StaffAccountResetPasswordFormProps) {
  const [
    state,
    formAction,
  ] = useActionState(
    action,
    initialState,
  );

  return (
    <form
      action={formAction}
      className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-7"
    >
      {state.message && (
        <div
          role="alert"
          className="mb-6 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium leading-6 text-red-700"
        >
          {state.message}
        </div>
      )}

      <section className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Akun staf pesantren
        </p>

        <h2 className="mt-2 text-lg font-bold text-brand-900">
          {staffName}
        </h2>

        <div className="mt-4">
          <p className="text-xs font-medium text-brand-600">
            ID Pengguna
          </p>

          <p className="mt-1 break-all text-base font-bold tracking-wide text-brand-900">
            {loginId}
          </p>
        </div>
      </section>

      <div className="mt-6 grid gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="password"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Password baru *
          </label>

          <input
            id="password"
            name="password"
            type="password"
            required
            minLength={8}
            maxLength={72}
            autoComplete="new-password"
            placeholder="Minimal 8 karakter"
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <FieldErrors
            errors={
              state.fieldErrors.password
            }
          />
        </div>

        <div>
          <label
            htmlFor="password_confirmation"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Konfirmasi password *
          </label>

          <input
            id="password_confirmation"
            name="password_confirmation"
            type="password"
            required
            minLength={8}
            maxLength={72}
            autoComplete="new-password"
            placeholder="Ketik ulang password"
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <FieldErrors
            errors={
              state.fieldErrors
                .password_confirmation
            }
          />
        </div>
      </div>

      <div className="mt-7 flex flex-col-reverse gap-3 border-t border-line pt-6 sm:flex-row sm:justify-end">
        <Link
          href={cancelHref}
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600"
        >
          Batal
        </Link>

        <SubmitButton />
      </div>
    </form>
  );
}