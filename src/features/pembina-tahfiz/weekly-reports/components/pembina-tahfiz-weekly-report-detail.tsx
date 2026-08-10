import Link from "next/link";

import type {
  PembinaTahfizWeeklyReportDetailData,
} from "../schemas/pembina-tahfiz-weekly-report-detail-schema";

import {
  PembinaTahfizWeeklyReportForm,
} from "./pembina-tahfiz-weekly-report-form";

type Props = {
  data:
    PembinaTahfizWeeklyReportDetailData;
};

function formatDate(
  value:
    string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day:
        "2-digit",

      month:
        "long",

      year:
        "numeric",
    },
  ).format(
    new Date(
      `${value}T00:00:00Z`,
    ),
  );
}

export function PembinaTahfizWeeklyReportDetail({
  data,
}: Props) {
  const report =
    data.report;

  return (
    <div className="mx-auto w-full max-w-[1200px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <Link
        href={`/pembina-tahfiz/laporan?week=${data.week.start}`}
        className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
      >
        ← Kembali ke Laporan
      </Link>

      {/* =====================================================
          HEADER
      ===================================================== */}

      <section className="mt-5 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Laporan Tahfiz Mingguan
        </p>

        <div className="mt-3 flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h1 className="text-3xl font-bold text-ink">
              {
                data.student
                  .full_name
              }
            </h1>

            <div className="mt-3 flex flex-wrap gap-2">
              <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                {
                  data.tahfiz_group
                    .name
                }
              </span>

              {data.class && (
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                  Kelas{" "}
                  {
                    data.class
                      .name
                  }
                </span>
              )}

              {data.student
                .nis && (
                <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                  NIS{" "}
                  {
                    data.student
                      .nis
                  }
                </span>
              )}

              <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                {data.student
                  .gender ===
                "male"
                  ? "Putra"
                  : "Putri"}
              </span>
            </div>
          </div>

          {report === null ? (
            <span className="w-fit rounded-full bg-slate-100 px-3 py-1.5 text-sm font-semibold text-slate-600">
              Belum Dibuat
            </span>
          ) : report.status ===
            "draft" ? (
            <span className="w-fit rounded-full bg-amber-50 px-3 py-1.5 text-sm font-semibold text-amber-700">
              Draft
            </span>
          ) : (
            <span className="w-fit rounded-full bg-emerald-50 px-3 py-1.5 text-sm font-semibold text-emerald-700">
              Published
            </span>
          )}
        </div>

        {/* =================================================
            WEEK
        ================================================= */}

        <div className="mt-5 rounded-2xl bg-slate-50 p-4">
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-slate-400">
            Periode Laporan
          </p>

          <p className="mt-2 font-bold text-ink">
            {formatDate(
              data.week.start,
            )}
            {" – "}
            {formatDate(
              data.week.end,
            )}
          </p>

          <p className="mt-1 text-xs text-muted">
            Tahun Ajaran{" "}
            {
              data.academic_year
                .name
            }
          </p>
        </div>
      </section>

      {/* =====================================================
          PUBLISHED NOTICE
      ===================================================== */}

      {report?.status ===
        "published" && (
        <section className="mt-5 rounded-2xl border border-emerald-200 bg-emerald-50 p-4 sm:p-5">
          <p className="font-semibold text-emerald-800">
            Laporan sudah
            dipublikasikan
          </p>

          <p className="mt-1 text-sm leading-6 text-emerald-700">
            Laporan ini sudah masuk
            ke data publikasi Tahfiz.
            Pembina masih dapat
            memperbaiki isi laporan
            apabila terdapat
            kekeliruan.
          </p>

          {report.published_at && (
            <p className="mt-2 text-xs font-medium text-emerald-600">
              Dipublikasikan{" "}
              {new Intl.DateTimeFormat(
                "id-ID",
                {
                  dateStyle:
                    "medium",

                  timeStyle:
                    "short",
                },
              ).format(
                new Date(
                  report.published_at,
                ),
              )}
            </p>
          )}
        </section>
      )}

      {/* =====================================================
          FORM
      ===================================================== */}

      <PembinaTahfizWeeklyReportForm
        data={
          data
        }
      />
    </div>
  );
}