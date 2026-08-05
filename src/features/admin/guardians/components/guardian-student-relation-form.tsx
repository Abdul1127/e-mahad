"use client";

import Link from "next/link";
import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import type { GuardianStudentOption } from "../schemas/guardian-student-options-schema";
import type { GuardianStudentRelationActionState } from "../types/guardian-student-relation-action-state";

type GuardianStudentRelationAction = (
  state: GuardianStudentRelationActionState,
  formData: FormData,
) => Promise<GuardianStudentRelationActionState>;

type GuardianStudentRelationFormProps = {
  guardianId: string;

  options: GuardianStudentOption[];

  action:
    GuardianStudentRelationAction;

  initialState:
    GuardianStudentRelationActionState;
};

const genderLabels: Record<
  string,
  string
> = {
  male: "Putra",
  female: "Putri",
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
        ? "Menghubungkan..."
        : "Hubungkan santri"}
    </button>
  );
}

export function GuardianStudentRelationForm({
  guardianId,
  options,
  action,
  initialState,
}: GuardianStudentRelationFormProps) {
  const [state, formAction] =
    useActionState(
      action,
      initialState,
    );

  if (options.length === 0) {
    return (
      <section className="rounded-3xl border border-dashed border-line bg-white px-6 py-12 text-center shadow-soft">
        <div className="mx-auto grid size-14 place-items-center rounded-2xl bg-brand-50 text-xl font-bold text-brand-700">
          S
        </div>

        <h2 className="mt-5 text-lg font-bold text-ink">
          Santri tidak ditemukan
        </h2>

        <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-muted">
          Tidak ada santri aktif yang cocok,
          atau seluruh hasil sudah terhubung
          dengan wali ini.
        </p>

        <Link
          href={`/admin/wali/${guardianId}/hubungkan`}
          className="mt-6 inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
        >
          Reset pencarian
        </Link>
      </section>
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

      <section>
        <div className="flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h2 className="text-lg font-bold text-ink">
              Pilih Santri
            </h2>

            <p className="mt-1 text-sm leading-6 text-muted">
              Pilih satu santri yang akan
              dihubungkan dengan wali ini.
            </p>
          </div>

          <p className="text-xs font-semibold text-slate-400">
            {options.length} hasil
          </p>
        </div>

        <div className="mt-5 max-h-[520px] space-y-3 overflow-y-auto pr-1">
          {options.map((student) => {
            const inputId =
              `student-${student.student_id}`;

            const isSelected =
              state.values.student_id ===
              student.student_id;

            return (
              <label
                key={student.student_id}
                htmlFor={inputId}
                className="flex cursor-pointer items-start gap-3 rounded-2xl border border-line p-4 transition hover:border-brand-300 hover:bg-brand-50/40"
              >
                <input
                  id={inputId}
                  name="student_id"
                  type="radio"
                  value={student.student_id}
                  defaultChecked={
                    isSelected
                  }
                  className="mt-1 size-4 shrink-0 border-slate-300 text-brand-700 focus:ring-brand-500"
                />

                <div className="min-w-0 flex-1">
                  <div className="flex flex-wrap items-center gap-2">
                    <p className="font-bold text-ink">
                      {student.full_name}
                    </p>

                    <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-slate-600">
                      {genderLabels[
                        student.gender
                      ] ??
                        student.gender}
                    </span>
                  </div>

                  <p className="mt-2 text-sm text-muted">
                    {student.class_name ??
                      "Belum ada kelas aktif"}

                    {student.academic_year_name
                      ? ` · ${student.academic_year_name}`
                      : ""}
                  </p>

                  <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-400">
                    <span>
                      ID Santri:{" "}
                      {student.legacy_student_id ??
                        "-"}
                    </span>

                    <span>
                      NIS:{" "}
                      {student.nis ?? "-"}
                    </span>

                    <span>
                      {student.guardian_count} wali
                      terhubung
                    </span>
                  </div>

                  {student.primary_guardian_name && (
                    <p className="mt-2 text-xs font-medium text-brand-700">
                      Kontak utama saat ini:{" "}
                      {
                        student.primary_guardian_name
                      }
                    </p>
                  )}
                </div>
              </label>
            );
          })}
        </div>

        {state.fieldErrors.student_id && (
          <div className="mt-3 space-y-1">
            {state.fieldErrors.student_id.map(
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
      </section>

      <section className="mt-7 border-t border-line pt-7">
        <div className="grid gap-6 md:grid-cols-2">
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
                state.values
                  .relationship_type
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
                  Kontak utama wali lain untuk
                  santri ini akan dipindahkan
                  secara otomatis.
                </span>
              </span>
            </label>
          </div>
        </div>

        <div className="mt-5 rounded-2xl border border-brand-100 bg-brand-50 px-4 py-3 text-xs leading-5 text-brand-800">
          Apabila santri belum mempunyai wali,
          hubungan pertama otomatis menjadi
          kontak utama walaupun pilihan di atas
          tidak dicentang.
        </div>
      </section>

      <div className="mt-7 flex flex-col-reverse gap-3 border-t border-line pt-6 sm:flex-row sm:justify-end">
        <Link
          href={`/admin/wali/${guardianId}`}
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
        >
          Batal
        </Link>

        <SubmitButton />
      </div>
    </form>
  );
}