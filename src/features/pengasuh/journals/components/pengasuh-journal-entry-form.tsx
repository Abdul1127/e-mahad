"use client";

import {
  useActionState,
  useEffect,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import {
  useRouter,
} from "next/navigation";

import {
  savePengasuhJournalEntry,
} from "../actions/save-pengasuh-journal-entry";

import type {
  PengasuhJournalEntry,
} from "../schemas/pengasuh-journal-detail-schema";

import {
  initialPengasuhJournalMutationState,
} from "../types/pengasuh-journal-mutation-state";

type PengasuhJournalEntryFormProps = {
  journalId:
    string;

  entry:
    PengasuhJournalEntry;

  disabled:
    boolean;
};

function SaveButton({
  disabled,
}: {
  disabled:
    boolean;
}) {
  const {
    pending,
  } = useFormStatus();

  return (
    <button
      type="submit"
      disabled={
        disabled ||
        pending
      }
      className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100 disabled:cursor-not-allowed disabled:opacity-50"
    >
      {pending
        ? "Menyimpan..."
        : "Simpan"}
    </button>
  );
}

export function PengasuhJournalEntryForm({
  journalId,
  entry,
  disabled,
}: PengasuhJournalEntryFormProps) {
  const router =
    useRouter();

  const [
    state,
    formAction,
  ] = useActionState(
    savePengasuhJournalEntry,
    initialPengasuhJournalMutationState,
  );

  useEffect(
    () => {
      if (
        state.status ===
        "success"
      ) {
        router.refresh();
      }
    },
    [
      router,
      state.status,
    ],
  );

  const isComplete =
    entry.health_condition !==
      null &&
    entry.sleep_compliance !==
      null &&
    entry.psychological_condition !==
      null &&
    entry.parent_visit !==
      null;

  return (
    <article className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="font-bold text-ink">
              {
                entry.full_name
              }
            </h2>

            <span
              className={
                isComplete
                  ? "rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-semibold text-emerald-700"
                  : "rounded-full bg-amber-50 px-2.5 py-1 text-[11px] font-semibold text-amber-700"
              }
            >
              {isComplete
                ? "Sudah diisi"
                : "Belum lengkap"}
            </span>
          </div>

          <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-400">
            {entry.nis && (
              <span>
                NIS{" "}
                {
                  entry.nis
                }
              </span>
            )}

            {entry.legacy_student_id && (
              <span>
                ID{" "}
                {
                  entry.legacy_student_id
                }
              </span>
            )}

            {entry.class && (
              <span>
                Kelas{" "}
                {
                  entry.class
                    .name
                }
              </span>
            )}

            <span>
              {entry.gender ===
              "male"
                ? "Putra"
                : "Putri"}
            </span>
          </div>
        </div>

        <div className="text-xs text-slate-400">
          {isComplete
            ? "Data tersimpan"
            : "Lengkapi 4 kondisi wajib"}
        </div>
      </div>

      <form
        action={
          formAction
        }
        className="mt-5"
      >
        <input
          type="hidden"
          name="journalId"
          value={
            journalId
          }
        />

        <input
          type="hidden"
          name="studentId"
          value={
            entry.student_id
          }
        />

        <fieldset
          disabled={
            disabled
          }
        >
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
            <div>
              <label
                htmlFor={`health-${entry.id}`}
                className="mb-2 block text-xs font-semibold text-slate-600"
              >
                Kondisi Kesehatan
              </label>

              <select
                id={`health-${entry.id}`}
                name="healthCondition"
                required
                defaultValue={
                  entry.health_condition ??
                  ""
                }
                className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
              >
                <option
                  value=""
                  disabled
                >
                  Pilih kondisi
                </option>

                <option value="healthy">
                  Sehat
                </option>

                <option value="unwell">
                  Kurang Fit
                </option>
              </select>
            </div>

            <div>
              <label
                htmlFor={`sleep-${entry.id}`}
                className="mb-2 block text-xs font-semibold text-slate-600"
              >
                Kepatuhan Jam Tidur
              </label>

              <select
                id={`sleep-${entry.id}`}
                name="sleepCompliance"
                required
                defaultValue={
                  entry.sleep_compliance ??
                  ""
                }
                className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
              >
                <option
                  value=""
                  disabled
                >
                  Pilih kondisi
                </option>

                <option value="on_time">
                  Tepat Waktu
                </option>

                <option value="needs_reminder">
                  Perlu Teguran
                </option>
              </select>
            </div>

            <div>
              <label
                htmlFor={`psychological-${entry.id}`}
                className="mb-2 block text-xs font-semibold text-slate-600"
              >
                Kondisi Psikologis
              </label>

              <select
                id={`psychological-${entry.id}`}
                name="psychologicalCondition"
                required
                defaultValue={
                  entry.psychological_condition ??
                  ""
                }
                className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
              >
                <option
                  value=""
                  disabled
                >
                  Pilih kondisi
                </option>

                <option value="cheerful">
                  Ceria
                </option>

                <option value="gloomy">
                  Murung
                </option>

                <option value="quiet">
                  Pendiam
                </option>

                <option value="homesick">
                  Homesick
                </option>

                <option value="emotional">
                  Emosional
                </option>
              </select>
            </div>

            <div>
              <label
                htmlFor={`visit-${entry.id}`}
                className="mb-2 block text-xs font-semibold text-slate-600"
              >
                Kunjungan Orang Tua
              </label>

              <select
                id={`visit-${entry.id}`}
                name="parentVisit"
                required
                defaultValue={
                  entry.parent_visit ===
                  null
                    ? ""
                    : entry.parent_visit
                      ? "true"
                      : "false"
                }
                className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
              >
                <option
                  value=""
                  disabled
                >
                  Pilih
                </option>

                <option value="false">
                  Tidak Ada
                </option>

                <option value="true">
                  Ada
                </option>
              </select>
            </div>
          </div>

          <div className="mt-4 grid gap-4 lg:grid-cols-2">
            <div>
              <label
                htmlFor={`case-${entry.id}`}
                className="mb-2 block text-xs font-semibold text-slate-600"
              >
                Catatan Kasus / Kejadian
              </label>

              <textarea
                id={`case-${entry.id}`}
                name="caseNotes"
                rows={
                  3
                }
                maxLength={
                  2000
                }
                defaultValue={
                  entry.case_notes ??
                  ""
                }
                placeholder="Kosongkan apabila tidak ada kejadian khusus."
                className="w-full resize-y rounded-xl border border-line bg-white px-3 py-3 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
              />
            </div>

            <div>
              <label
                htmlFor={`handling-${entry.id}`}
                className="mb-2 block text-xs font-semibold text-slate-600"
              >
                Solusi / Penanganan
              </label>

              <textarea
                id={`handling-${entry.id}`}
                name="handlingNotes"
                rows={
                  3
                }
                maxLength={
                  2000
                }
                defaultValue={
                  entry.handling_notes ??
                  ""
                }
                placeholder="Isi tindakan yang dilakukan apabila diperlukan."
                className="w-full resize-y rounded-xl border border-line bg-white px-3 py-3 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
              />
            </div>
          </div>

          <div className="mt-4 flex flex-col gap-3 border-t border-line pt-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              {state.status ===
                "success" &&
                state.message && (
                  <p className="text-sm font-medium text-emerald-700">
                    {
                      state.message
                    }
                  </p>
                )}

              {state.status ===
                "error" &&
                state.message && (
                  <p className="text-sm font-medium text-red-600">
                    {
                      state.message
                    }
                  </p>
                )}
            </div>

            <SaveButton
              disabled={
                disabled
              }
            />
          </div>
        </fieldset>
      </form>
    </article>
  );
}