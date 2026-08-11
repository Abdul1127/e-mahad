"use client";

import Link from "next/link";

import {
  useActionState,
} from "react";

import {
  createPengasuhActivityScheduleAction,
} from "../actions/create-pengasuh-activity-schedule";

import {
  initialCreatePengasuhActivityScheduleState,
} from "../types/create-pengasuh-activity-schedule-state";

import type {
  PengasuhActivityScheduleListData,
} from "../schemas/pengasuh-activity-schema";

type Props = {
  groups:
    PengasuhActivityScheduleListData["groups"];
};

function genderLabel(
  gender:
    "male" | "female",
): string {
  return gender ===
    "male"
    ? "Putra"
    : "Putri";
}

export function PengasuhCreateActivityScheduleForm({
  groups,
}: Props) {
  const [
    state,
    formAction,
    pending,
  ] = useActionState(
    createPengasuhActivityScheduleAction,
    initialCreatePengasuhActivityScheduleState,
  );

  return (
    <form
      action={
        formAction
      }
      className="space-y-6"
    >
      {state.status ===
        "error" && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-4">
          <p className="text-sm font-semibold text-red-800">
            Jadwal belum tersimpan
          </p>

          <p className="mt-1 text-sm leading-6 text-red-700">
            {state.message}
          </p>
        </div>
      )}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Kegiatan
        </p>

        <div className="mt-5 grid gap-5 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <label
              htmlFor="careGroupId"
              className="text-sm font-semibold text-ink"
            >
              Kelompok Asrama
            </label>

            <select
              id="careGroupId"
              name="careGroupId"
              required
              defaultValue={
                state.values
                  ?.careGroupId ??
                ""
              }
              className="mt-2 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            >
              <option value="">
                Pilih kelompok asrama
              </option>

              {groups.map(
                (
                  group,
                ) => (
                  <option
                    key={
                      group.id
                    }
                    value={
                      group.id
                    }
                  >
                    {group.name} —{" "}
                    {genderLabel(
                      group.gender,
                    )}
                  </option>
                ),
              )}
            </select>
          </div>

          <div>
            <label
              htmlFor="activityDate"
              className="text-sm font-semibold text-ink"
            >
              Tanggal
            </label>

            <input
              id="activityDate"
              name="activityDate"
              type="date"
              required
              defaultValue={
                state.values
                  ?.activityDate ??
                ""
              }
              className="mt-2 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>

          <div>
            <label
              htmlFor="activityName"
              className="text-sm font-semibold text-ink"
            >
              Nama Kegiatan
            </label>

            <input
              id="activityName"
              name="activityName"
              type="text"
              required
              maxLength={
                150
              }
              defaultValue={
                state.values
                  ?.activityName ??
                ""
              }
              placeholder="Contoh: Apel malam"
              className="mt-2 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>

          <div>
            <label
              htmlFor="startTime"
              className="text-sm font-semibold text-ink"
            >
              Waktu Mulai
            </label>

            <input
              id="startTime"
              name="startTime"
              type="time"
              required
              defaultValue={
                state.values
                  ?.startTime ??
                ""
              }
              className="mt-2 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>

          <div>
            <label
              htmlFor="endTime"
              className="text-sm font-semibold text-ink"
            >
              Waktu Selesai
            </label>

            <input
              id="endTime"
              name="endTime"
              type="time"
              defaultValue={
                state.values
                  ?.endTime ??
                ""
              }
              className="mt-2 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>

          <div className="sm:col-span-2">
            <label
              htmlFor="location"
              className="text-sm font-semibold text-ink"
            >
              Lokasi
            </label>

            <input
              id="location"
              name="location"
              type="text"
              maxLength={
                150
              }
              defaultValue={
                state.values
                  ?.location ??
                ""
              }
              placeholder="Contoh: Aula Asrama"
              className="mt-2 w-full rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>

          <div className="sm:col-span-2">
            <label
              htmlFor="notes"
              className="text-sm font-semibold text-ink"
            >
              Catatan
            </label>

            <textarea
              id="notes"
              name="notes"
              rows={
                4
              }
              maxLength={
                1000
              }
              defaultValue={
                state.values
                  ?.notes ??
                ""
              }
              placeholder="Catatan tambahan kegiatan..."
              className="mt-2 w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm leading-6 text-ink outline-none placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>
        </div>
      </section>

      <section className="flex flex-col-reverse gap-3 border-t border-line pt-5 sm:flex-row sm:justify-end">
        <Link
          href="/pengasuh/jadwal"
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-muted transition hover:bg-slate-50 hover:text-ink"
        >
          Batal
        </Link>

        <button
          type="submit"
          disabled={
            pending
          }
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-600 px-6 text-sm font-semibold text-white transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {pending
            ? "Menyimpan..."
            : "Simpan Jadwal"}
        </button>
      </section>
    </form>
  );
}