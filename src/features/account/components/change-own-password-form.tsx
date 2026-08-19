"use client";

import {
  useActionState,
} from "react";

import {
  changeOwnPassword,
} from "../actions/change-own-password";

import {
  initialChangeOwnPasswordActionState,
} from "../types/change-own-password-action-state";


function SubmitButton({
  isPending,
}: {
  isPending:
    boolean;
}) {
  return (
    <button
      type="submit"
      disabled={
        isPending
      }
      className="inline-flex min-h-11 w-full items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:bg-brand-400 sm:w-auto"
    >
      {isPending
        ? "Mengubah password..."
        : "Simpan Password Baru"}
    </button>
  );
}


type FieldErrorProps = {
  messages?:
    string[];
};


function FieldError({
  messages,
}: FieldErrorProps) {
  if (
    !messages ||
    messages.length === 0
  ) {
    return null;
  }

  return (
    <div className="mt-2 space-y-1">
      {messages.map(
        (
          message,
        ) => (
          <p
            key={
              message
            }
            className="text-sm leading-5 text-red-600"
          >
            {message}
          </p>
        ),
      )}
    </div>
  );
}


export function ChangeOwnPasswordForm() {
  const [
    state,
    formAction,
    isPending,
  ] =
    useActionState(
      changeOwnPassword,
      initialChangeOwnPasswordActionState,
    );


  return (
    <form
      action={
        formAction
      }
      className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-7"
    >
      {state.status ===
        "error" &&
        state.message && (
          <div
            role="alert"
            aria-live="polite"
            className="mb-6 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-medium leading-6 text-red-700"
          >
            {
              state.message
            }
          </div>
        )}


      <section className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Keamanan akun
        </p>

        <h2 className="mt-2 text-lg font-bold text-brand-900">
          Password pribadi
        </h2>

        <p className="mt-2 text-sm leading-6 text-brand-700">
          Password baru hanya digunakan
          untuk akun yang sedang login.
          Admin tidak perlu mengetahui
          password yang kamu pilih.
        </p>
      </section>


      <div className="mt-6">
        <label
          htmlFor="current_password"
          className="mb-2 block text-sm font-semibold text-slate-700"
        >
          Password saat ini
          <span className="ml-1 text-red-500">
            *
          </span>
        </label>

        <input
          id="current_password"
          name="current_password"
          type="password"
          autoComplete="current-password"
          required
          maxLength={
            256
          }
          disabled={
            isPending
          }
          placeholder="Masukkan password yang sedang digunakan"
          aria-invalid={
            Boolean(
              state
                .fieldErrors
                .current_password,
            )
          }
          className="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-brand-600 focus:ring-4 focus:ring-brand-50 disabled:cursor-not-allowed disabled:bg-slate-100"
        />

        <FieldError
          messages={
            state
              .fieldErrors
              .current_password
          }
        />
      </div>


      <div className="mt-6 grid gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="password"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Password baru
            <span className="ml-1 text-red-500">
              *
            </span>
          </label>

          <input
            id="password"
            name="password"
            type="password"
            autoComplete="new-password"
            required
            minLength={
              8
            }
            maxLength={
              72
            }
            disabled={
              isPending
            }
            placeholder="Minimal 8 karakter"
            aria-invalid={
              Boolean(
                state
                  .fieldErrors
                  .password,
              )
            }
            className="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-brand-600 focus:ring-4 focus:ring-brand-50 disabled:cursor-not-allowed disabled:bg-slate-100"
          />

          <FieldError
            messages={
              state
                .fieldErrors
                .password
            }
          />
        </div>


        <div>
          <label
            htmlFor="password_confirmation"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Konfirmasi password baru
            <span className="ml-1 text-red-500">
              *
            </span>
          </label>

          <input
            id="password_confirmation"
            name="password_confirmation"
            type="password"
            autoComplete="new-password"
            required
            minLength={
              8
            }
            maxLength={
              72
            }
            disabled={
              isPending
            }
            placeholder="Ulangi password baru"
            aria-invalid={
              Boolean(
                state
                  .fieldErrors
                  .password_confirmation,
              )
            }
            className="w-full rounded-xl border border-slate-300 bg-white px-4 py-3 text-slate-900 outline-none transition placeholder:text-slate-400 focus:border-brand-600 focus:ring-4 focus:ring-brand-50 disabled:cursor-not-allowed disabled:bg-slate-100"
          />

          <FieldError
            messages={
              state
                .fieldErrors
                .password_confirmation
            }
          />
        </div>
      </div>


      <section className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-4">
        <h3 className="text-sm font-bold text-amber-800">
          Simpan password pribadi
        </h3>

        <p className="mt-2 text-xs leading-5 text-amber-700">
          Setelah berhasil diubah,
          gunakan password baru pada
          proses login berikutnya.
          Jangan membagikan password
          kepada pengguna lain.
        </p>
      </section>


      <div className="mt-7 flex flex-col gap-3 border-t border-line pt-6 sm:flex-row sm:justify-end">
        <SubmitButton
          isPending={
            isPending
          }
        />
      </div>
    </form>
  );
}