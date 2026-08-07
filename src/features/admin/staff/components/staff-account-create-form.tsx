"use client";

import Link from "next/link";
import {
  useActionState,
  useState,
} from "react";
import { useFormStatus } from "react-dom";

import type { AdminStaffDetailData } from "../schemas/admin-staff-detail-schema";
import type { AdminStaffRoleOption } from "../schemas/admin-staff-role-options-schema";
import type { StaffLoginIdentityData } from "../schemas/staff-login-identity-schema";
import type { StaffAccountActionState } from "../types/staff-account-action-state";

type StaffAccountCreateAction = (
  state:
    StaffAccountActionState,

  formData:
    FormData,
) => Promise<StaffAccountActionState>;

type StaffAccountCreateFormProps = {
  staff:
    AdminStaffDetailData["staff"];

  loginIdentity:
    StaffLoginIdentityData;

  roleOptions:
    AdminStaffRoleOption[];

  action:
    StaffAccountCreateAction;

  initialState:
    StaffAccountActionState;

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

export function StaffAccountCreateForm({
  staff,
  loginIdentity,
  roleOptions,
  action,
  initialState,
  cancelHref,
}: StaffAccountCreateFormProps) {
  const [
    state,
    formAction,
  ] = useActionState(
    action,
    initialState,
  );

  const [
    selectedRoleCodes,
    setSelectedRoleCodes,
  ] = useState<string[]>([]);

  function handleRoleChange(
    roleCode: string,
    checked: boolean,
  ) {
    setSelectedRoleCodes(
      (currentValues) => {
        if (checked) {
          return Array.from(
            new Set([
              ...currentValues,
              roleCode,
            ]),
          );
        }

        return currentValues.filter(
          (value) =>
            value !== roleCode,
        );
      },
    );
  }

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
          {staff.full_name}
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
              ID Staf
            </dt>

            <dd className="mt-1 text-sm font-semibold text-brand-900">
              {staff.legacy_staff_id ??
                "-"}
            </dd>
          </div>

          <div>
            <dt className="text-xs font-medium text-brand-600">
              Jabatan
            </dt>

            <dd className="mt-1 text-sm font-semibold text-brand-900">
              {staff.position ??
                "Belum tersedia"}
            </dd>
          </div>

          <div>
            <dt className="text-xs font-medium text-brand-600">
              Nomor telepon
            </dt>

            <dd className="mt-1 text-sm font-semibold text-brand-900">
              {staff.phone ??
                "Belum tersedia"}
            </dd>
          </div>
        </dl>
      </section>

      <section className="mt-6">
        <div>
          <h3 className="text-sm font-bold text-slate-800">
            Pilih Role Staf
          </h3>

          <p className="mt-1 text-xs leading-5 text-slate-500">
            Pilih minimal satu role sesuai tugas
            dan tanggung jawab staf.
          </p>
        </div>

        <div className="mt-4 grid gap-3 sm:grid-cols-2">
          {roleOptions.map(
            (role) => {
              const checked =
                selectedRoleCodes.includes(
                  role.code,
                );

              return (
                <label
                  key={role.code}
                  className={
                    checked
                      ? "flex cursor-pointer items-start gap-3 rounded-2xl border border-brand-300 bg-brand-50 p-4"
                      : "flex cursor-pointer items-start gap-3 rounded-2xl border border-line bg-white p-4 transition hover:border-brand-200 hover:bg-brand-50/40"
                  }
                >
                  <input
                    name="role_codes"
                    type="checkbox"
                    value={role.code}
                    checked={checked}
                    onChange={(event) =>
                      handleRoleChange(
                        role.code,
                        event.target.checked,
                      )
                    }
                    className="mt-0.5 size-4 rounded border-slate-300 text-brand-700 focus:ring-brand-500"
                  />

                  <span className="min-w-0">
                    <span className="block text-sm font-bold text-slate-800">
                      {role.name}
                    </span>

                    <span className="mt-1 block text-xs font-medium text-slate-400">
                      {role.code}
                    </span>
                  </span>
                </label>
              );
            },
          )}
        </div>

        <FieldErrors
          errors={
            state.fieldErrors
              .role_codes
          }
        />
      </section>

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
              state.fieldErrors
                .password,
            )}
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <p className="mt-2 text-xs leading-5 text-slate-400">
            Minimal 8 karakter, satu huruf,
            dan satu angka.
          </p>

          <FieldErrors
            errors={
              state.fieldErrors
                .password
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
          sementara kepada staf. Password tidak
          akan ditampilkan lagi setelah akun
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