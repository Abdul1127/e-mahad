"use client";

import Link from "next/link";
import {
  useActionState,
  useState,
} from "react";
import { useFormStatus } from "react-dom";

import type { AdminStaffRoleOption } from "../schemas/admin-staff-role-options-schema";
import type { StaffRoleActionState } from "../types/staff-account-action-state";

type StaffRoleAction = (
  state:
    StaffRoleActionState,

  formData:
    FormData,
) => Promise<StaffRoleActionState>;

type StaffRoleManagementFormProps = {
  action:
    StaffRoleAction;

  initialState:
    StaffRoleActionState;

  roleOptions:
    AdminStaffRoleOption[];

  currentRoleCodes:
    string[];

  staffName: string;
  loginId: string;
  cancelHref: string;
};

function SubmitButton() {
  const { pending } =
    useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white disabled:opacity-60"
    >
      {pending
        ? "Menyimpan role..."
        : "Simpan perubahan role"}
    </button>
  );
}

export function StaffRoleManagementForm({
  action,
  initialState,
  roleOptions,
  currentRoleCodes,
  staffName,
  loginId,
  cancelHref,
}: StaffRoleManagementFormProps) {
  const [
    state,
    formAction,
  ] = useActionState(
    action,
    initialState,
  );

  const [
    selectedRoles,
    setSelectedRoles,
  ] = useState<string[]>(
    currentRoleCodes,
  );

  return (
    <form
      action={formAction}
      className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-7"
    >
      {state.message && (
        <div className="mb-6 rounded-2xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
          {state.message}
        </div>
      )}

      <section className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
        <p className="text-xs font-semibold uppercase tracking-wide text-brand-600">
          Role akun staf
        </p>

        <h2 className="mt-2 text-lg font-bold text-brand-900">
          {staffName}
        </h2>

        <p className="mt-2 text-sm font-semibold text-brand-700">
          {loginId}
        </p>
      </section>

      <section className="mt-6">
        <h3 className="font-bold text-slate-800">
          Role yang diberikan
        </h3>

        <p className="mt-2 text-sm text-slate-500">
          Minimal satu role harus tetap dipilih.
        </p>

        <div className="mt-4 grid gap-3 sm:grid-cols-2">
          {roleOptions.map(
            (role) => {
              const checked =
                selectedRoles.includes(
                  role.code,
                );

              return (
                <label
                  key={role.code}
                  className={
                    checked
                      ? "flex cursor-pointer items-start gap-3 rounded-2xl border border-brand-300 bg-brand-50 p-4"
                      : "flex cursor-pointer items-start gap-3 rounded-2xl border border-line bg-white p-4"
                  }
                >
                  <input
                    name="role_codes"
                    type="checkbox"
                    value={role.code}
                    checked={checked}
                    onChange={(event) => {
                      setSelectedRoles(
                        (current) =>
                          event.target.checked
                            ? Array.from(
                                new Set([
                                  ...current,
                                  role.code,
                                ]),
                              )
                            : current.filter(
                                (value) =>
                                  value !==
                                  role.code,
                              ),
                      );
                    }}
                    className="mt-0.5 size-4"
                  />

                  <span>
                    <span className="block text-sm font-bold text-slate-800">
                      {role.name}
                    </span>

                    <span className="mt-1 block text-xs text-slate-400">
                      {role.code}
                    </span>
                  </span>
                </label>
              );
            },
          )}
        </div>

        {state.fieldErrors
          .role_codes?.map(
            (error) => (
              <p
                key={error}
                className="mt-3 text-sm font-medium text-red-600"
              >
                {error}
              </p>
            ),
          )}
      </section>

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