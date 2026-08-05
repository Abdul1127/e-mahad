"use client";

import Link from "next/link";
import {
  useActionState,
} from "react";
import {
  useFormStatus,
} from "react-dom";

import type { GuardianFormActionState } from "../types/guardian-form-action-state";

import { GuardianFormFieldError } from "./guardian-form-field-error";

type GuardianFormAction = (
  state: GuardianFormActionState,
  formData: FormData,
) => Promise<GuardianFormActionState>;

type GuardianFormProps = {
  mode: "create" | "edit";
  action: GuardianFormAction;

  initialState: GuardianFormActionState;
  cancelHref: string;
};

function GuardianSubmitButton({
  mode,
}: {
  mode: "create" | "edit";
}) {
  const { pending } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Menyimpan..."
        : mode === "create"
          ? "Simpan wali"
          : "Simpan perubahan"}
    </button>
  );
}

export function GuardianForm({
  mode,
  action,
  initialState,
  cancelHref,
}: GuardianFormProps) {
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

      <div className="grid gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="legacy_guardian_id"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            ID Wali
          </label>

          <input
            id="legacy_guardian_id"
            name="legacy_guardian_id"
            type="text"
            defaultValue={
              state.values
                .legacy_guardian_id
            }
            placeholder="Contoh: WALI-001"
            aria-describedby="legacy_guardian_id-error"
            aria-invalid={
              Boolean(
                state.fieldErrors
                  .legacy_guardian_id,
              )
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <p className="mt-2 text-xs leading-5 text-slate-400">
            Opsional. Digunakan untuk ID lama
            atau kebutuhan impor data.
          </p>

          <GuardianFormFieldError
            id="legacy_guardian_id-error"
            errors={
              state.fieldErrors
                .legacy_guardian_id
            }
          />
        </div>

        <div>
          <label
            htmlFor="full_name"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Nama lengkap
            <span className="ml-1 text-red-500">
              *
            </span>
          </label>

          <input
            id="full_name"
            name="full_name"
            type="text"
            required
            autoComplete="name"
            defaultValue={
              state.values.full_name
            }
            placeholder="Nama orang tua atau wali"
            aria-describedby="full_name-error"
            aria-invalid={
              Boolean(
                state.fieldErrors.full_name,
              )
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <GuardianFormFieldError
            id="full_name-error"
            errors={
              state.fieldErrors.full_name
            }
          />
        </div>

        <div>
          <label
            htmlFor="phone"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Nomor telepon
          </label>

          <input
            id="phone"
            name="phone"
            type="tel"
            autoComplete="tel"
            defaultValue={
              state.values.phone
            }
            placeholder="Contoh: 081234567890"
            aria-describedby="phone-error"
            aria-invalid={
              Boolean(
                state.fieldErrors.phone,
              )
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <GuardianFormFieldError
            id="phone-error"
            errors={state.fieldErrors.phone}
          />
        </div>

        <div>
          <label
            htmlFor="email"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Email
          </label>

          <input
            id="email"
            name="email"
            type="email"
            autoComplete="email"
            defaultValue={
              state.values.email
            }
            placeholder="wali@example.com"
            aria-describedby="email-error"
            aria-invalid={
              Boolean(
                state.fieldErrors.email,
              )
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <p className="mt-2 text-xs leading-5 text-slate-400">
            Email ini belum otomatis menjadi
            akun login.
          </p>

          <GuardianFormFieldError
            id="email-error"
            errors={state.fieldErrors.email}
          />
        </div>
      </div>

      <div className="mt-6 rounded-2xl border border-line bg-slate-50 p-4">
        <label className="flex cursor-pointer items-start gap-3">
          <input
            name="is_active"
            type="checkbox"
            defaultChecked={
              state.values.is_active
            }
            className="mt-0.5 size-4 rounded border-slate-300 text-brand-700 focus:ring-brand-500"
          />

          <span>
            <span className="block text-sm font-semibold text-slate-700">
              Data wali aktif
            </span>

            <span className="mt-1 block text-xs leading-5 text-slate-500">
              Wali aktif dapat dihubungkan
              dengan santri dan disiapkan
              untuk akun orang tua.
            </span>
          </span>
        </label>
      </div>

      <div className="mt-7 flex flex-col-reverse gap-3 border-t border-line pt-6 sm:flex-row sm:justify-end">
        <Link
          href={cancelHref}
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
        >
          Batal
        </Link>

        <GuardianSubmitButton
          mode={mode}
        />
      </div>
    </form>
  );
}