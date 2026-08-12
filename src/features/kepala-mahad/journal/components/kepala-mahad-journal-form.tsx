"use client";

import {
  useActionState,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import type {
  KepalaMahadJournalDetail,
} from "../schemas/mahad-head-journal-schema";

import {
  initialMahadHeadJournalActionState,
  type MahadHeadJournalActionState,
} from "../types/mahad-head-journal-action-state";

type Action = (
  previousState:
    MahadHeadJournalActionState,

  formData:
    FormData,
) => Promise<MahadHeadJournalActionState>;

function ActionButtons() {
  const {
    pending,
  } =
    useFormStatus();

  return (
    <div className="flex flex-col gap-3 sm:flex-row sm:justify-end">
      <button
        type="submit"
        name="intent"
        value="save"
        disabled={
          pending
        }
        className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:opacity-60"
      >
        {pending
          ? "Memproses..."
          : "Simpan Draft"}
      </button>

      <button
        type="submit"
        name="intent"
        value="submit"
        disabled={
          pending
        }
        className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:opacity-60"
      >
        Kirim Jurnal
      </button>
    </div>
  );
}

export function KepalaMahadJournalForm({
  data,
  action,
}: {
  data:
    KepalaMahadJournalDetail;

  action:
    Action;
}) {
  const [
    state,
    formAction,
  ] =
    useActionState(
      action,
      initialMahadHeadJournalActionState,
    );

  const pillars =
    Array.from(
      new Map(
        data.checklist.map(
          (item) => [
            item.pillar_code,
            item.pillar_name,
          ],
        ),
      ),
    );

  return (
    <form
      action={
        formAction
      }
      className="space-y-6"
    >
      {pillars.map(
        ([
          pillarCode,
          pillarName,
        ]) => {
          const items =
            data.checklist.filter(
              (item) =>
                item.pillar_code ===
                pillarCode,
            );

          return (
            <section
              key={
                pillarCode
              }
              className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6"
            >
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
                Pilar Kinerja
              </p>

              <h2 className="mt-2 text-lg font-bold text-ink">
                {pillarName}
              </h2>

              <p className="mt-1 text-xs text-muted">
                Ekuivalensi 3 JTM
              </p>

              <div className="mt-5 space-y-3">
                {items.map(
                  (item) => (
                    <label
                      key={
                        item.id
                      }
                      className="flex cursor-pointer items-start gap-3 rounded-2xl border border-line bg-slate-50/60 p-4 transition hover:border-brand-200 hover:bg-brand-50/40"
                    >
                      <input
                        type="checkbox"
                        name="checked_item_keys"
                        value={
                          item.item_key
                        }
                        defaultChecked={
                          item.is_checked
                        }
                        className="mt-1 size-4 rounded border-slate-300 accent-emerald-700"
                      />

                      <span className="text-sm leading-6 text-slate-700">
                        {
                          item.label
                        }
                      </span>
                    </label>
                  ),
                )}
              </div>
            </section>
          );
        },
      )}

      <section className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <label
          htmlFor="performance_notes"
          className="text-sm font-bold text-ink"
        >
          Catatan Kinerja
        </label>

        <p className="mt-1 text-xs leading-5 text-muted">
          Tuliskan narasi singkat
          kegiatan utama yang telah
          diselesaikan.
        </p>

        <textarea
          id="performance_notes"
          name="performance_notes"
          rows={
            6
          }
          maxLength={
            5000
          }
          defaultValue={
            data.journal.performance_notes ??
            ""
          }
          className="mt-3 w-full rounded-2xl border border-line bg-white p-4 text-sm leading-6 text-ink outline-none transition focus:border-brand-300 focus:ring-4 focus:ring-brand-50"
        />
      </section>

      <section className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <label
          htmlFor="obstacles_follow_up"
          className="text-sm font-bold text-ink"
        >
          Kendala dan Tindak Lanjut
        </label>

        <p className="mt-1 text-xs leading-5 text-muted">
          Catat permasalahan yang
          membutuhkan intervensi atau
          perhatian lanjutan.
        </p>

        <textarea
          id="obstacles_follow_up"
          name="obstacles_follow_up"
          rows={
            5
          }
          maxLength={
            5000
          }
          defaultValue={
            data.journal.obstacles_follow_up ??
            ""
          }
          className="mt-3 w-full rounded-2xl border border-line bg-white p-4 text-sm leading-6 text-ink outline-none transition focus:border-brand-300 focus:ring-4 focus:ring-brand-50"
        />
      </section>

      {state.message && (
        <div
          className={
            state.status ===
            "error"
              ? "rounded-2xl border border-red-100 bg-red-50 p-4 text-sm text-red-700"
              : "rounded-2xl border border-emerald-100 bg-emerald-50 p-4 text-sm text-emerald-700"
          }
        >
          {
            state.message
          }
        </div>
      )}

      <section className="rounded-3xl border border-line bg-white p-5 shadow-soft">
        <p className="mb-4 text-xs leading-5 text-muted">
          Setelah jurnal dikirim,
          data tidak dapat diedit lagi
          dan akan tersedia untuk
          monitoring Penanggung Jawab.
        </p>

        <ActionButtons />
      </section>
    </form>
  );
}