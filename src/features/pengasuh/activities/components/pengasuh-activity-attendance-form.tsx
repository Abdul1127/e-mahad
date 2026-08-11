"use client";

import {
  useActionState,
  useRef,
} from "react";

import {
  savePengasuhActivityAttendanceAction,
} from "../actions/save-pengasuh-activity-attendance";

import {
  initialSavePengasuhActivityAttendanceState,
} from "../types/save-pengasuh-activity-attendance-state";

import type {
  PengasuhActivityScheduleDetailData,
} from "../schemas/pengasuh-activity-schema";

type Props = {
  scheduleId:
    string;

  students:
    PengasuhActivityScheduleDetailData["students"];
};

function genderLabel(
  value:
    "male" | "female",
): string {
  return value ===
    "male"
    ? "Putra"
    : "Putri";
}

export function PengasuhActivityAttendanceForm({
  scheduleId,
  students,
}: Props) {
  const formRef =
    useRef<HTMLFormElement>(
      null,
    );

  const [
    state,
    formAction,
    pending,
  ] = useActionState(
    savePengasuhActivityAttendanceAction,
    initialSavePengasuhActivityAttendanceState,
  );

  function markAllPresent() {
    const form =
      formRef.current;

    if (!form) {
      return;
    }

    const selects =
      form.querySelectorAll<HTMLSelectElement>(
        'select[data-attendance-status="true"]',
      );

    selects.forEach(
      (
        select,
      ) => {
        select.value =
          "present";
      },
    );
  }

  return (
    <form
      ref={
        formRef
      }
      action={
        formAction
      }
      className="space-y-5"
    >
      <input
        type="hidden"
        name="scheduleId"
        value={
          scheduleId
        }
      />

      <input
        type="hidden"
        name="studentIds"
        value={
          JSON.stringify(
            students.map(
              (
                student,
              ) =>
                student.id,
            ),
          )
        }
      />

      {state.status ===
        "error" && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-4">
          <p className="text-sm font-semibold text-red-800">
            Absensi belum tersimpan
          </p>

          <p className="mt-1 text-sm leading-6 text-red-700">
            {state.message}
          </p>
        </div>
      )}

      <div className="flex flex-col gap-3 rounded-2xl border border-brand-100 bg-brand-50 p-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="font-semibold text-brand-800">
            Input absensi santri
          </p>

          <p className="mt-1 text-xs leading-5 text-brand-700">
            Periksa kembali status
            sebelum menyimpan.
          </p>
        </div>

        <button
          type="button"
          onClick={
            markAllPresent
          }
          disabled={
            pending
          }
          className="inline-flex min-h-10 shrink-0 items-center justify-center rounded-xl border border-brand-200 bg-white px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100 disabled:opacity-60"
        >
          Tandai Semua Hadir
        </button>
      </div>

      <div className="space-y-3">
        {students.map(
          (
            student,
            index,
          ) => (
            <article
              key={
                student.id
              }
              className="rounded-2xl border border-line bg-white p-4 shadow-soft"
            >
              <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_200px_minmax(220px,1fr)] lg:items-center">
                <div>
                  <div className="flex items-start gap-3">
                    <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-brand-50 text-xs font-bold text-brand-700">
                      {index +
                        1}
                    </span>

                    <div>
                      <p className="font-semibold text-ink">
                        {
                          student.full_name
                        }
                      </p>

                      <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-muted">
                        {student.nis && (
                          <span>
                            NIS{" "}
                            {
                              student.nis
                            }
                          </span>
                        )}

                        <span>
                          {genderLabel(
                            student.gender,
                          )}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                <div>
                  <label
                    htmlFor={`status_${student.id}`}
                    className="text-xs font-medium text-muted"
                  >
                    Status
                  </label>

                  <select
                    id={`status_${student.id}`}
                    name={`status_${student.id}`}
                    data-attendance-status="true"
                    defaultValue={
                      student.attendance
                        ?.status ??
                      "present"
                    }
                    disabled={
                      pending
                    }
                    className="mt-1.5 w-full rounded-xl border border-line bg-white px-3 py-2.5 text-sm font-semibold text-ink outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100 disabled:bg-slate-50"
                  >
                    <option value="present">
                      Hadir
                    </option>

                    <option value="permission">
                      Izin
                    </option>

                    <option value="sick">
                      Sakit
                    </option>

                    <option value="absent">
                      Alpa
                    </option>
                  </select>
                </div>

                <div>
                  <label
                    htmlFor={`notes_${student.id}`}
                    className="text-xs font-medium text-muted"
                  >
                    Catatan
                  </label>

                  <input
                    id={`notes_${student.id}`}
                    name={`notes_${student.id}`}
                    type="text"
                    maxLength={
                      500
                    }
                    disabled={
                      pending
                    }
                    defaultValue={
                      student.attendance
                        ?.notes ??
                      ""
                    }
                    placeholder="Opsional"
                    className="mt-1.5 w-full rounded-xl border border-line bg-white px-3 py-2.5 text-sm text-ink outline-none placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100 disabled:bg-slate-50"
                  />
                </div>
              </div>
            </article>
          ),
        )}
      </div>

      <div className="sticky bottom-4 flex justify-end">
        <button
          type="submit"
          disabled={
            pending ||
            students.length ===
              0
          }
          className="inline-flex min-h-12 items-center justify-center rounded-xl bg-brand-600 px-7 text-sm font-semibold text-white shadow-lg transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {pending
            ? "Menyimpan Absensi..."
            : "Simpan Absensi"}
        </button>
      </div>
    </form>
  );
}