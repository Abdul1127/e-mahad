"use client";

import Link from "next/link";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import type { GuardianStudentRelationEditActionState } from "../types/guardian-student-relation-mutation-state";

type EditRelationAction = (
  state:
    GuardianStudentRelationEditActionState,
  formData: FormData,
) => Promise<GuardianStudentRelationEditActionState>;

type GuardianStudentRelationEditFormProps = {
  action: EditRelationAction;

  initialState:
    GuardianStudentRelationEditActionState;

  cancelHref: string;
  studentName: string;
};

function SubmitButton() {
  const { pending } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Menyimpan..."
        : "Simpan perubahan"}
    </button>
  );
}

export function GuardianStudentRelationEditForm({
  action,
  initialState,
  cancelHref,
  studentName,
}: GuardianStudentRelationEditFormProps) {
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

      <section className="rounded-2xl border border-brand-100 bg-brand-50 p-4">
        <p className="text-xs font-semibold uppercase tracking-wide text-brand-600">
          Santri terhubung
        </p>

        <p className="mt-2 text-lg font-bold text-brand-900">
          {studentName}
        </p>

        <p className="mt-2 text-xs leading-5 text-brand-700">
          Form ini hanya mengubah jenis
          hubungan dan status kontak utama.
          Santri yang terhubung tidak berubah.
        </p>
      </section>

      <div className="mt-6 grid gap-6 md:grid-cols-2">
        <div>
          <label
            htmlFor="relationship_type"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Hubungan dengan santri
          </label>

          <select
            id="relationship_type"
            name="relationship_type"
            defaultValue={
              state.values.relationship_type
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="father">
              Ayah
            </option>

            <option value="mother">
              Ibu
            </option>

            <option value="guardian">
              Wali
            </option>

            <option value="other">
              Lainnya
            </option>
          </select>

          {state.fieldErrors
            .relationship_type && (
            <div className="mt-2 space-y-1">
              {state.fieldErrors.relationship_type.map(
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
          )}
        </div>

        <div className="rounded-2xl border border-line bg-slate-50 p-4">
          <label className="flex cursor-pointer items-start gap-3">
            <input
              name="is_primary_contact"
              type="checkbox"
              defaultChecked={
                state.values
                  .is_primary_contact
              }
              className="mt-0.5 size-4 rounded border-slate-300 text-brand-700 focus:ring-brand-500"
            />

            <span>
              <span className="block text-sm font-semibold text-slate-700">
                Jadikan kontak utama
              </span>

              <span className="mt-1 block text-xs leading-5 text-slate-500">
                Kontak utama sebelumnya akan
                dipindahkan secara otomatis.
              </span>
            </span>
          </label>
        </div>
      </div>

      <div className="mt-5 rounded-2xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-5 text-amber-800">
        Apabila hubungan ini merupakan
        satu-satunya wali untuk santri,
        sistem akan mempertahankannya sebagai
        kontak utama.
      </div>

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