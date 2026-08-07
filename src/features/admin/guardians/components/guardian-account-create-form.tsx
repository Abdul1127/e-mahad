"use client";

import Link from "next/link";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import type { AdminGuardianDetailData } from "../schemas/admin-guardian-detail-schema";
import type { GuardianLoginIdentityData } from "../schemas/guardian-login-identity-schema";
import type { GuardianAccountActionState } from "../types/guardian-account-action-state";

type GuardianAccountCreateAction = (
  state: GuardianAccountActionState,
  formData: FormData,
) => Promise<GuardianAccountActionState>;

type GuardianAccountCreateFormProps = {
  guardian:
    AdminGuardianDetailData["guardian"];

  loginIdentity:
    GuardianLoginIdentityData;

  action:
    GuardianAccountCreateAction;

  initialState:
    GuardianAccountActionState;

  cancelHref: string;
};

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
        ? "Membuat akun..."
        : "Buat akun login"}
    </button>
  );
}

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
      {errors.map((error) => (
        <p
          key={error}
          className="text-sm font-medium text-red-600"
        >
          {error}
        </p>
      ))}
    </div>
  );
}

export function GuardianAccountCreateForm({
  guardian,
  loginIdentity,
  action,
  initialState,
  cancelHref,
}: GuardianAccountCreateFormProps) {
  const [state, formAction] =
    useActionState(
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
          Akun orang tua atau wali
        </p>

        <h2 className="mt-2 text-lg font-bold text-brand-900">
          {guardian.full_name}
        </h2>

        <dl className="mt-4 grid gap-3 sm:grid-cols-2">
          <div>
            <dt className="text-xs font-medium text-brand-600">
              ID Pengguna
            </dt>

            <dd className="mt-1 break-all text-base font-bold tracking-wide text-brand-900">
              {loginIdentity.login_id}
            </dd>
          </div>

          <div>
            <dt className="text-xs font-medium text-brand-600">
              Nomor telepon
            </dt>

            <dd className="mt-1 text-sm font-semibold text-brand-900">
              {guardian.phone ??
                "Belum tersedia"}
            </dd>
          </div>

          <div className="sm:col-span-2">
            <dt className="text-xs font-medium text-brand-600">
              Email kontak
            </dt>

            <dd className="mt-1 break-all text-sm font-semibold text-brand-900">
              {guardian.email ??
                "Tidak diisi — akun tetap dapat dibuat"}
            </dd>
          </div>
        </dl>
      </section>

      <div className="mt-6 rounded-2xl border border-blue-200 bg-blue-50 p-4">
        <p className="text-sm font-bold text-blue-800">
          Catat ID Pengguna
        </p>

        <p className="mt-2 text-xs leading-5 text-blue-700">
          Wali akan login menggunakan ID{" "}
          <strong>
            {loginIdentity.login_id}
          </strong>
          , bukan menggunakan email.
        </p>
      </div>

      <div className="mt-6 grid gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="password"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Password sementara
            <span className="ml-1 text-red-500">
              *
            </span>
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
            aria-invalid={Boolean(
              state.fieldErrors.password,
            )}
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <p className="mt-2 text-xs leading-5 text-slate-400">
            Minimal 8 karakter serta memiliki
            setidaknya satu huruf dan satu angka.
          </p>

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
            Konfirmasi password
            <span className="ml-1 text-red-500">
              *
            </span>
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
            aria-invalid={Boolean(
              state.fieldErrors
                .password_confirmation,
            )}
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

      <section className="mt-6 rounded-2xl border border-amber-200 bg-amber-50 p-4">
        <h3 className="text-sm font-bold text-amber-800">
          Simpan kredensial dengan aman
        </h3>

        <p className="mt-2 text-xs leading-5 text-amber-700">
          Sampaikan ID Pengguna dan password
          sementara kepada wali. Password tidak
          akan ditampilkan kembali setelah akun
          dibuat.
        </p>
      </section>

      <div className="mt-7 flex flex-col-reverse gap-3 border-t border-line pt-6 sm:flex-row sm:justify-end">
        <Link
          href={cancelHref}
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
        >
          Batal
        </Link>

        <SubmitButton />
      </div>
    </form>
  );
}