"use client";

import { useActionState } from "react";

import { loginAction } from "@/features/auth/actions/login";
import { initialLoginActionState } from "@/features/auth/types/login-action-state";

export function LoginForm() {
  const [
    state,
    formAction,
    isPending,
  ] = useActionState(
    loginAction,
    initialLoginActionState,
  );

  return (
    <form
      action={formAction}
      className="space-y-5"
    >
      <div>
        <label
          htmlFor="login_id"
          className="mb-2 block text-sm font-semibold text-slate-700"
        >
          ID Pengguna
        </label>

        <input
          id="login_id"
          name="login_id"
          type="text"
          autoComplete="username"
          autoCapitalize="characters"
          spellCheck={false}
          required
          maxLength={64}
          disabled={isPending}
          placeholder="Contoh: ADM-001"
          aria-describedby="login-id-help login-id-error"
          aria-invalid={Boolean(
            state.fieldErrors.login_id,
          )}
          className="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 font-medium uppercase tracking-wide text-slate-900 outline-none transition placeholder:normal-case placeholder:tracking-normal placeholder:text-slate-400 focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100 disabled:cursor-not-allowed disabled:bg-slate-100"
        />

        <p
          id="login-id-help"
          className="mt-2 text-xs leading-5 text-slate-500"
        >
          Gunakan ID akun yang diberikan
          oleh administrator.
        </p>

        <div
          id="login-id-error"
          className="mt-2 space-y-1"
        >
          {state.fieldErrors.login_id?.map(
            (errorMessage) => (
              <p
                key={errorMessage}
                className="text-sm text-red-600"
              >
                {errorMessage}
              </p>
            ),
          )}
        </div>
      </div>

      <div>
        <label
          htmlFor="password"
          className="mb-2 block text-sm font-semibold text-slate-700"
        >
          Password
        </label>

        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          disabled={isPending}
          placeholder="Masukkan password"
          aria-describedby="password-error"
          aria-invalid={Boolean(
            state.fieldErrors.password,
          )}
          className="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-emerald-600 focus:ring-4 focus:ring-emerald-100 disabled:cursor-not-allowed disabled:bg-slate-100"
        />

        <div
          id="password-error"
          className="mt-2 space-y-1"
        >
          {state.fieldErrors.password?.map(
            (errorMessage) => (
              <p
                key={errorMessage}
                className="text-sm text-red-600"
              >
                {errorMessage}
              </p>
            ),
          )}
        </div>
      </div>

      {state.status === "error" && (
        <div
          role="alert"
          aria-live="polite"
          className="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm leading-6 text-red-700"
        >
          {state.message}
        </div>
      )}

      <button
        type="submit"
        disabled={isPending}
        className="flex w-full items-center justify-center rounded-xl bg-emerald-700 px-5 py-3 font-semibold text-white transition hover:bg-emerald-800 disabled:cursor-not-allowed disabled:bg-emerald-400"
      >
        {isPending
          ? "Memverifikasi akun..."
          : "Masuk ke E-Ma'had"}
      </button>
    </form>
  );
}