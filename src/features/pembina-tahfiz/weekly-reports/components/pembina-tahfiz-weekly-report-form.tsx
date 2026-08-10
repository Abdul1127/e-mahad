"use client";

import {
  useActionState,
} from "react";

import {
  useFormStatus,
} from "react-dom";

import {
  savePembinaTahfizWeeklyReport,
} from "../actions/save-pembina-tahfiz-weekly-report";

import type {
  PembinaTahfizWeeklyReportDetailData,
} from "../schemas/pembina-tahfiz-weekly-report-detail-schema";

import {
  initialPembinaTahfizWeeklyReportActionState,
} from "../types/pembina-tahfiz-weekly-report-action-state";

type Props = {
  data:
    PembinaTahfizWeeklyReportDetailData;
};

function ActionButtons({
  isPublished,
}: {
  isPublished:
    boolean;
}) {
  const {
    pending,
  } = useFormStatus();

  if (
    isPublished
  ) {
    return (
      <button
        type="submit"
        name="intent"
        value="save"
        disabled={
          pending
        }
        className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-6 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {pending
          ? "Menyimpan..."
          : "Simpan Perubahan"}
      </button>
    );
  }

  return (
    <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
      <button
        type="submit"
        name="intent"
        value="save"
        disabled={
          pending
        }
        className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-6 text-sm font-semibold text-slate-700 transition hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {pending
          ? "Menyimpan..."
          : "Simpan Draft"}
      </button>

      <button
        type="submit"
        name="intent"
        value="publish"
        disabled={
          pending
        }
        onClick={(
          event,
        ) => {
          if (
            pending
          ) {
            return;
          }

          const confirmed =
            window.confirm(
              "Publikasikan laporan Tahfiz ini?\n\nSetelah dipublikasikan, laporan nantinya dapat dilihat oleh Orang Tua/Wali santri.",
            );

          if (
            !confirmed
          ) {
            event.preventDefault();
          }
        }}
        className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-6 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-50"
      >
        {pending
          ? "Memproses..."
          : "Simpan & Publikasikan"}
      </button>
    </div>
  );
}

export function PembinaTahfizWeeklyReportForm({
  data,
}: Props) {
  const report =
    data.report;

  const [
    state,
    formAction,
  ] = useActionState(
    savePembinaTahfizWeeklyReport,
    initialPembinaTahfizWeeklyReportActionState,
  );

  const isPublished =
    report?.status ===
    "published";

  return (
    <form
      action={
        formAction
      }
      className="mt-6"
    >
      <input
        type="hidden"
        name="studentId"
        value={
          data.student.id
        }
      />

      <input
        type="hidden"
        name="weekStart"
        value={
          data.week.start
        }
      />

      {/* =================================================
          HAFALAN & MURAJAAH
      ================================================= */}

      <section className="grid gap-5 lg:grid-cols-2">
        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <label
            htmlFor="memorizationAchievement"
            className="text-sm font-bold text-ink"
          >
            Capaian Hafalan Baru
          </label>

          <p className="mt-1 text-xs leading-5 text-muted">
            Tuliskan capaian
            hafalan santri selama
            pekan ini.
          </p>

          <textarea
            id="memorizationAchievement"
            name="memorizationAchievement"
            rows={
              5
            }
            maxLength={
              5000
            }
            defaultValue={
              report
                ?.memorization_achievement ??
              ""
            }
            placeholder="Contoh: QS. Al-Baqarah ayat 1–20"
            className="mt-3 w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
          />
        </div>

        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <label
            htmlFor="murajaahAchievement"
            className="text-sm font-bold text-ink"
          >
            Capaian Murajaah
          </label>

          <p className="mt-1 text-xs leading-5 text-muted">
            Tuliskan bagian
            hafalan yang diulang
            dan dievaluasi.
          </p>

          <textarea
            id="murajaahAchievement"
            name="murajaahAchievement"
            rows={
              5
            }
            maxLength={
              5000
            }
            defaultValue={
              report
                ?.murajaah_achievement ??
              ""
            }
            placeholder="Contoh: Juz 30, An-Naba sampai An-Nazi'at"
            className="mt-3 w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
          />
        </div>
      </section>

      {/* =================================================
          RATING
      ================================================= */}

      <section className="mt-5 rounded-2xl border border-line bg-white p-5 shadow-soft">
        <div>
          <h2 className="text-lg font-bold text-ink">
            Penilaian Pekanan
          </h2>

          <p className="mt-1 text-sm text-muted">
            Berikan penilaian
            terhadap kualitas
            Tahfiz santri selama
            pekan ini.
          </p>
        </div>

        <div className="mt-5 grid gap-4 md:grid-cols-3">
          <div>
            <label
              htmlFor="fluencyRating"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Kelancaran
            </label>

            <select
              id="fluencyRating"
              name="fluencyRating"
              defaultValue={
                report
                  ?.fluency_rating ??
                ""
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="">
                Pilih penilaian
              </option>

              <option value="excellent">
                Sangat Baik
              </option>

              <option value="good">
                Baik
              </option>

              <option value="fair">
                Cukup
              </option>

              <option value="needs_guidance">
                Perlu Bimbingan
              </option>
            </select>
          </div>

          <div>
            <label
              htmlFor="tajwidRating"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Tajwid
            </label>

            <select
              id="tajwidRating"
              name="tajwidRating"
              defaultValue={
                report
                  ?.tajwid_rating ??
                ""
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="">
                Pilih penilaian
              </option>

              <option value="excellent">
                Sangat Baik
              </option>

              <option value="good">
                Baik
              </option>

              <option value="fair">
                Cukup
              </option>

              <option value="needs_guidance">
                Perlu Bimbingan
              </option>
            </select>
          </div>

          <div>
            <label
              htmlFor="consistencyRating"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Konsistensi
            </label>

            <select
              id="consistencyRating"
              name="consistencyRating"
              defaultValue={
                report
                  ?.consistency_rating ??
                ""
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="">
                Pilih penilaian
              </option>

              <option value="excellent">
                Sangat Baik
              </option>

              <option value="good">
                Baik
              </option>

              <option value="fair">
                Cukup
              </option>

              <option value="needs_guidance">
                Perlu Bimbingan
              </option>
            </select>
          </div>
        </div>
      </section>

      {/* =================================================
          NOTES + TARGET
      ================================================= */}

      <section className="mt-5 grid gap-5 lg:grid-cols-2">
        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <label
            htmlFor="supervisorNotes"
            className="text-sm font-bold text-ink"
          >
            Catatan Pembina
          </label>

          <p className="mt-1 text-xs leading-5 text-muted">
            Catatan evaluasi
            tambahan. Bagian ini
            boleh dikosongkan.
          </p>

          <textarea
            id="supervisorNotes"
            name="supervisorNotes"
            rows={
              5
            }
            maxLength={
              5000
            }
            defaultValue={
              report
                ?.supervisor_notes ??
              ""
            }
            placeholder="Contoh: Perkembangan hafalan baik, perlu meningkatkan konsentrasi ketika murajaah."
            className="mt-3 w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
          />
        </div>

        <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <label
            htmlFor="nextWeekTarget"
            className="text-sm font-bold text-brand-900"
          >
            Target Pekan Berikutnya
          </label>

          <p className="mt-1 text-xs leading-5 text-brand-700">
            Tentukan target hafalan
            atau murajaah untuk pekan
            berikutnya.
          </p>

          <textarea
            id="nextWeekTarget"
            name="nextWeekTarget"
            rows={
              5
            }
            maxLength={
              5000
            }
            defaultValue={
              report
                ?.next_week_target ??
              ""
            }
            placeholder="Contoh: Melanjutkan QS. Al-Baqarah ayat 21–35"
            className="mt-3 w-full resize-y rounded-xl border border-brand-200 bg-white px-4 py-3 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />
        </div>
      </section>

      {/* =================================================
          ERROR
      ================================================= */}

      {state.status ===
        "error" &&
        state.message && (
          <section className="mt-5 rounded-2xl border border-red-200 bg-red-50 p-4">
            <p className="font-semibold text-red-800">
              Laporan belum dapat
              diproses
            </p>

            <p className="mt-1 text-sm leading-6 text-red-700">
              {
                state.message
              }
            </p>
          </section>
        )}

      {/* =================================================
          ACTION BAR
      ================================================= */}

      <section className="sticky bottom-4 z-20 mt-6 rounded-2xl border border-line bg-white/95 p-4 shadow-lg backdrop-blur sm:p-5">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <p className="font-semibold text-ink">
              {isPublished
                ? "Laporan sudah dipublikasikan"
                : report
                  ? "Laporan tersimpan sebagai Draft"
                  : "Laporan belum disimpan"}
            </p>

            <p className="mt-1 max-w-2xl text-sm leading-6 text-muted">
              {isPublished
                ? "Perubahan berikutnya langsung memperbarui laporan yang sudah dapat dilihat Orang Tua."
                : "Draft belum dapat dilihat Orang Tua. Publikasikan setelah seluruh data wajib sudah lengkap."}
            </p>
          </div>

          <ActionButtons
            isPublished={
              isPublished
            }
          />
        </div>
      </section>
    </form>
  );
}