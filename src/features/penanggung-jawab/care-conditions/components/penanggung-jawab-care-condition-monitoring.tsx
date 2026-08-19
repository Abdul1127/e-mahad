import Link from "next/link";

import type {
  PenanggungJawabCareConditionData,
  PenanggungJawabCareConditionItem,
} from "../schemas/penanggung-jawab-care-condition-schema";


type Props = {
  data:
    PenanggungJawabCareConditionData;
};


function readable(
  value:
    string | boolean | null,
): string {
  switch (value) {
    case "healthy":
      return "Sehat";

    case "unwell":
      return "Kurang Fit";

    case "on_time":
      return "Tepat Waktu";

    case "needs_reminder":
      return "Perlu Teguran";

    case "cheerful":
      return "Ceria";

    case "gloomy":
      return "Murung";

    case "quiet":
      return "Pendiam";

    case "homesick":
      return "Homesick";

    case "emotional":
      return "Emosional";

    case true:
      return "Ada";

    case false:
      return "Tidak Ada";

    default:
      return "-";
  }
}


function sessionLabel(
  value:
    "morning" | "evening",
): string {
  return value ===
    "morning"
    ? "Pagi"
    : "Sore";
}


function buildPageHref(
  data:
    PenanggungJawabCareConditionData,

  page:
    number,
): string {
  const params =
    new URLSearchParams();


  params.set(
    "condition",
    data.filters.condition,
  );

  params.set(
    "date",
    data.filters.effective_date,
  );


  if (
    data.filters.search
  ) {
    params.set(
      "search",
      data.filters.search,
    );
  }


  params.set(
    "page",
    String(
      page,
    ),
  );


  return `/penanggung-jawab/pengasuhan?${params.toString()}`;
}


function ConditionCard({
  item,
}: {
  item:
    PenanggungJawabCareConditionItem;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
      <div className="flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <p className="font-bold text-ink">
            {
              item.full_name
            }
          </p>

          <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-400">
            {item.nis && (
              <span>
                NIS{" "}
                {
                  item.nis
                }
              </span>
            )}

            {item.legacy_student_id && (
              <span>
                ID{" "}
                {
                  item.legacy_student_id
                }
              </span>
            )}

            {item.class && (
              <span>
                Kelas{" "}
                {
                  item.class
                    .name
                }
              </span>
            )}

            <span>
              {
                item
                  .care_group
                  .name
              }
            </span>

            <span>
              {sessionLabel(
                item.journal.session,
              )}
            </span>
          </div>
        </div>


        <div className="flex flex-wrap gap-2">
          {item.is_normal && (
            <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
              Normal
            </span>
          )}

          {item.needs_attention && (
            <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700">
              Perlu Perhatian
            </span>
          )}

          {item.parent_visit ===
            true && (
            <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">
              Ada Kunjungan
            </span>
          )}
        </div>
      </div>


      <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <div
          className={
            item.health_condition ===
            "unwell"
              ? "rounded-xl bg-red-50 p-3"
              : "rounded-xl bg-slate-50 p-3"
          }
        >
          <p className="text-xs text-muted">
            Kesehatan
          </p>

          <p className="mt-1 text-sm font-semibold text-ink">
            {readable(
              item.health_condition,
            )}
          </p>
        </div>

        <div
          className={
            item.sleep_compliance ===
            "needs_reminder"
              ? "rounded-xl bg-amber-50 p-3"
              : "rounded-xl bg-slate-50 p-3"
          }
        >
          <p className="text-xs text-muted">
            Jam Tidur
          </p>

          <p className="mt-1 text-sm font-semibold text-ink">
            {readable(
              item.sleep_compliance,
            )}
          </p>
        </div>

        <div
          className={
            item.psychological_condition !==
              null &&
            item.psychological_condition !==
              "cheerful"
              ? "rounded-xl bg-amber-50 p-3"
              : "rounded-xl bg-slate-50 p-3"
          }
        >
          <p className="text-xs text-muted">
            Psikologis
          </p>

          <p className="mt-1 text-sm font-semibold text-ink">
            {readable(
              item.psychological_condition,
            )}
          </p>
        </div>

        <div className="rounded-xl bg-slate-50 p-3">
          <p className="text-xs text-muted">
            Kunjungan Orang Tua
          </p>

          <p className="mt-1 text-sm font-semibold text-ink">
            {readable(
              item.parent_visit,
            )}
          </p>
        </div>
      </div>


      {item.has_notes && (
        <div className="mt-4 grid gap-3 lg:grid-cols-2">
          <div className="rounded-xl border border-amber-100 bg-amber-50 p-4">
            <p className="text-xs font-semibold text-amber-700">
              Kasus / Kejadian
            </p>

            <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-amber-900">
              {item.case_notes ??
                "-"}
            </p>
          </div>

          <div className="rounded-xl border border-brand-100 bg-brand-50 p-4">
            <p className="text-xs font-semibold text-brand-700">
              Penanganan
            </p>

            <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-brand-900">
              {item.handling_notes ??
                "-"}
            </p>
          </div>
        </div>
      )}
    </article>
  );
}


function SummaryCard({
  label,
  value,
}: {
  label:
    string;

  value:
    number;
}) {
  return (
    <div className="rounded-2xl border border-line bg-white p-4 shadow-soft">
      <p className="text-xs text-muted">
        {
          label
        }
      </p>

      <p className="mt-1 text-2xl font-bold text-ink">
        {
          value
        }
      </p>
    </div>
  );
}


export function PenanggungJawabCareConditionMonitoring({
  data,
}: Props) {
  const {
    summary,
    pagination,
  } =
    data;


  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Penanggung Jawab
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Kondisi Pengasuhan
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Monitoring read-only kondisi
          santri berdasarkan Jurnal
          Pengasuhan yang sudah dikirim
          ke dalam workflow resmi.
        </p>

        <p className="mt-2 text-sm font-semibold text-slate-600">
          Tahun Ajaran{" "}
          {
            data.academic_year
              .name
          }
        </p>
      </section>


      <section className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <SummaryCard
          label="Total Catatan"
          value={
            summary.total_count
          }
        />

        <SummaryCard
          label="Berbeda dari Normal"
          value={
            summary.exception_count
          }
        />

        <SummaryCard
          label="Perlu Perhatian"
          value={
            summary.attention_count
          }
        />

        <SummaryCard
          label="Kurang Fit"
          value={
            summary.unwell_count
          }
        />

        <SummaryCard
          label="Normal"
          value={
            summary.normal_count
          }
        />
      </section>


      <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          action="/penanggung-jawab/pengasuhan"
          method="get"
          className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_270px_190px_auto]"
        >
          <div>
            <label
              htmlFor="search"
              className="mb-2 block text-xs font-semibold text-slate-500"
            >
              Cari Santri
            </label>

            <input
              id="search"
              name="search"
              type="search"
              defaultValue={
                data.filters.search ??
                ""
              }
              placeholder="Nama, NIS, atau ID santri..."
              className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink"
            />
          </div>


          <div>
            <label
              htmlFor="condition"
              className="mb-2 block text-xs font-semibold text-slate-500"
            >
              Kondisi
            </label>

            <select
              id="condition"
              name="condition"
              defaultValue={
                data.filters.condition
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="all">
                Semua Kondisi
              </option>

              <option value="exception">
                Berbeda dari Normal
              </option>

              <option value="attention">
                Perlu Perhatian
              </option>

              <option value="unwell">
                Kurang Fit
              </option>

              <option value="needs_reminder">
                Perlu Teguran
              </option>

              <option value="psychological">
                Kondisi Psikologis
              </option>

              <option value="case_notes">
                Ada Catatan / Kejadian
              </option>

              <option value="parent_visit">
                Ada Kunjungan Orang Tua
              </option>

              <option value="normal">
                Normal
              </option>
            </select>
          </div>


          <div>
            <label
              htmlFor="date"
              className="mb-2 block text-xs font-semibold text-slate-500"
            >
              Tanggal Jurnal
            </label>

            <input
              id="date"
              name="date"
              type="date"
              defaultValue={
                data.filters.effective_date
              }
              min={
                data.academic_year
                  .start_date
              }
              max={
                data.academic_year
                  .end_date
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            />
          </div>


          <button
            type="submit"
            className="min-h-11 self-end rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white hover:bg-brand-800"
          >
            Tampilkan
          </button>
        </form>


        <div className="mt-4 flex flex-wrap items-center gap-3">
          <p className="text-sm font-semibold text-ink">
            {
              pagination.filtered_count
            }{" "}
            hasil ditemukan
          </p>

          <Link
            href="/penanggung-jawab/pengasuhan"
            className="text-sm font-semibold text-brand-700 hover:text-brand-800"
          >
            Reset Filter
          </Link>
        </div>
      </section>


      <section className="mt-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
        <SummaryCard
          label="Perlu Teguran"
          value={
            summary.sleep_attention_count
          }
        />

        <SummaryCard
          label="Psikologis"
          value={
            summary.psychological_count
          }
        />

        <SummaryCard
          label="Ada Catatan"
          value={
            summary.note_count
          }
        />

        <SummaryCard
          label="Kunjungan Orang Tua"
          value={
            summary.parent_visit_count
          }
        />
      </section>


      {data.items.length ===
      0 ? (
        <section className="mt-6 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
          <p className="font-semibold text-ink">
            Tidak ada kondisi santri
            yang sesuai filter.
          </p>
        </section>
      ) : (
        <section className="mt-6 space-y-4">
          {data.items.map(
            (
              item,
            ) => (
              <ConditionCard
                key={
                  item.id
                }
                item={
                  item
                }
              />
            ),
          )}
        </section>
      )}


      {pagination.total_pages >
        1 && (
        <section className="mt-6 flex flex-col gap-3 rounded-2xl border border-line bg-white p-4 shadow-soft sm:flex-row sm:items-center sm:justify-between">
          {pagination.page >
          1 ? (
            <Link
              href={
                buildPageHref(
                  data,
                  pagination.page -
                    1,
                )
              }
              className="min-h-10 rounded-xl border border-line px-4 py-2.5 text-center text-sm font-semibold text-slate-700"
            >
              ← Sebelumnya
            </Link>
          ) : (
            <span className="min-h-10 rounded-xl border border-line px-4 py-2.5 text-center text-sm font-semibold text-slate-300">
              ← Sebelumnya
            </span>
          )}


          <p className="text-center text-sm font-semibold text-slate-600">
            Halaman{" "}
            {
              pagination.page
            }{" "}
            dari{" "}
            {
              pagination.total_pages
            }
          </p>


          {pagination.page <
          pagination.total_pages ? (
            <Link
              href={
                buildPageHref(
                  data,
                  pagination.page +
                    1,
                )
              }
              className="min-h-10 rounded-xl border border-line px-4 py-2.5 text-center text-sm font-semibold text-slate-700"
            >
              Berikutnya →
            </Link>
          ) : (
            <span className="min-h-10 rounded-xl border border-line px-4 py-2.5 text-center text-sm font-semibold text-slate-300">
              Berikutnya →
            </span>
          )}
        </section>
      )}


      <section className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-5">
        <p className="font-semibold text-blue-900">
          Monitoring read-only
        </p>

        <p className="mt-2 text-sm leading-6 text-blue-700">
          Penanggung Jawab hanya
          membaca kondisi dari jurnal
          yang sudah Submitted, Perlu
          Revisi, atau Sudah Direview.
          Draft Pengasuh tidak
          ditampilkan dan tidak ada
          fungsi edit pada halaman ini.
        </p>
      </section>
    </div>
  );
}