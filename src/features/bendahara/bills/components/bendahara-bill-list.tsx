import Link from "next/link";

import type {
  BendaharaBillFilterStatus,
  BendaharaBillListData,
} from "../schemas/bendahara-bill-list-schema";

type Props = {
  data: BendaharaBillListData;
  search: string | null;
  status: BendaharaBillFilterStatus | null;
};

/*
 * =========================================================
 * HELPERS
 * =========================================================
 */

function formatCurrency(
  value: number,
): string {
  return new Intl.NumberFormat(
    "id-ID",
    {
      style: "currency",
      currency: "IDR",
      maximumFractionDigits: 0,
    },
  ).format(value);
}

function formatDate(
  value: string | null,
): string {
  if (!value) {
    return "-";
  }

  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day: "2-digit",
      month: "long",
      year: "numeric",
    },
  ).format(
    new Date(
      `${value}T00:00:00Z`,
    ),
  );
}

function genderLabel(
  value: "male" | "female",
): string {
  return value === "male"
    ? "Putra"
    : "Putri";
}

function getStatusLabel(
  status:
    | "unpaid"
    | "partial"
    | "paid"
    | "cancelled",
): string {
  switch (status) {
    case "unpaid":
      return "Belum Dibayar";

    case "partial":
      return "Dibayar Sebagian";

    case "paid":
      return "Lunas";

    case "cancelled":
      return "Dibatalkan";
  }
}

function getStatusClassName(
  status:
    | "unpaid"
    | "partial"
    | "paid"
    | "cancelled",
): string {
  switch (status) {
    case "unpaid":
      return "bg-slate-100 text-slate-700";

    case "partial":
      return "bg-amber-50 text-amber-700";

    case "paid":
      return "bg-emerald-50 text-emerald-700";

    case "cancelled":
      return "bg-red-50 text-red-700";
  }
}

function buildHref({
  search,
  status,
  page,
}: {
  search: string | null;
  status: BendaharaBillFilterStatus | null;
  page: number;
}): string {
  const params =
    new URLSearchParams();

  if (search) {
    params.set(
      "q",
      search,
    );
  }

  if (status) {
    params.set(
      "status",
      status,
    );
  }

  if (page > 1) {
    params.set(
      "page",
      String(page),
    );
  }

  const query =
    params.toString();

  return query
    ? `/bendahara/tagihan?${query}`
    : "/bendahara/tagihan";
}

/*
 * =========================================================
 * SUMMARY CARD
 * =========================================================
 */

function SummaryCard({
  label,
  value,
  description,
}: {
  label: string;
  value: string | number;
  description?: string;
}) {
  return (
    <div className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
      <p className="text-xs font-medium text-muted">
        {label}
      </p>

      <p className="mt-2 text-2xl font-bold text-ink">
        {value}
      </p>

      {description && (
        <p className="mt-2 text-xs leading-5 text-muted">
          {description}
        </p>
      )}
    </div>
  );
}

/*
 * =========================================================
 * FILTERS
 * =========================================================
 */

const FILTERS: Array<{
  label: string;
  value: BendaharaBillFilterStatus | null;
}> = [
  {
    label: "Semua",
    value: null,
  },
  {
    label: "Belum Dibayar",
    value: "unpaid",
  },
  {
    label: "Sebagian",
    value: "partial",
  },
  {
    label: "Lunas",
    value: "paid",
  },
  {
    label: "Jatuh Tempo",
    value: "overdue",
  },
  {
    label: "Dibatalkan",
    value: "cancelled",
  },
];

/*
 * =========================================================
 * COMPONENT
 * =========================================================
 */

export function BendaharaBillList({
  data,
  search,
  status,
}: Props) {
  const {
    summary,
    pagination,
  } = data;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* ===================================================
          HEADER
      =================================================== */}

      <section className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Keuangan Santri
          </p>

          <h1 className="mt-2 text-3xl font-bold text-ink">
            Tagihan Santri
          </h1>

          <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
            Kelola dan pantau seluruh tagihan santri
            pada tahun ajaran{" "}
            <span className="font-semibold text-ink">
              {data.academic_year.name}
            </span>
            .
          </p>
        </div>

        <Link
          href="/bendahara/tagihan/baru"
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
        >
          + Buat Tagihan
        </Link>
      </section>

      {/* ===================================================
          SUMMARY COUNTS
      =================================================== */}

      <section className="mt-6 grid gap-3 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <SummaryCard
          label="Total"
          value={summary.total_count}
        />

        <SummaryCard
          label="Belum Dibayar"
          value={summary.unpaid_count}
        />

        <SummaryCard
          label="Sebagian"
          value={summary.partial_count}
        />

        <SummaryCard
          label="Lunas"
          value={summary.paid_count}
        />

        <SummaryCard
          label="Jatuh Tempo"
          value={summary.overdue_count}
        />

        <SummaryCard
          label="Dibatalkan"
          value={summary.cancelled_count}
        />
      </section>

      {/* ===================================================
          NOMINAL SUMMARY
      =================================================== */}

      <section className="mt-4 grid gap-3 sm:grid-cols-3">
        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Total Tagihan Aktif
          </p>

          <p className="mt-2 text-xl font-bold text-ink sm:text-2xl">
            {formatCurrency(
              summary.billed_amount,
            )}
          </p>
        </div>

        <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
          <p className="text-xs text-emerald-700">
            Sudah Dibayar
          </p>

          <p className="mt-2 text-xl font-bold text-emerald-900 sm:text-2xl">
            {formatCurrency(
              summary.paid_amount,
            )}
          </p>
        </div>

        <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
          <p className="text-xs text-amber-700">
            Sisa Tagihan
          </p>

          <p className="mt-2 text-xl font-bold text-amber-900 sm:text-2xl">
            {formatCurrency(
              summary.outstanding_amount,
            )}
          </p>
        </div>
      </section>

      {/* ===================================================
          FILTER + SEARCH
      =================================================== */}

      <section className="mt-7 rounded-2xl border border-line bg-white p-4 shadow-soft">
        <div className="flex flex-wrap gap-2">
          {FILTERS.map(
            (filter) => {
              const active =
                status ===
                filter.value;

              return (
                <Link
                  key={
                    filter.value ??
                    "all"
                  }
                  href={buildHref({
                    search,
                    status:
                      filter.value,
                    page: 1,
                  })}
                  className={
                    active
                      ? "rounded-full bg-brand-600 px-4 py-2 text-xs font-semibold text-white"
                      : "rounded-full bg-slate-100 px-4 py-2 text-xs font-semibold text-slate-600 transition hover:bg-slate-200"
                  }
                >
                  {filter.label}
                </Link>
              );
            },
          )}
        </div>

        <form
          method="GET"
          action="/bendahara/tagihan"
          className="mt-4 flex flex-col gap-3 sm:flex-row"
        >
          {status && (
            <input
              type="hidden"
              name="status"
              value={status}
            />
          )}

          <input
            type="search"
            name="q"
            defaultValue={
              search ?? ""
            }
            placeholder="Cari nama santri, NIS, kode atau nama tagihan..."
            className="min-h-11 flex-1 rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
          />

          <button
            type="submit"
            className="min-h-11 rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
          >
            Cari
          </button>

          {(search ||
            status) && (
            <Link
              href="/bendahara/tagihan"
              className="flex min-h-11 items-center justify-center rounded-xl border border-line px-5 text-sm font-semibold text-muted transition hover:bg-slate-50 hover:text-ink"
            >
              Reset
            </Link>
          )}
        </form>

        <p className="mt-3 text-xs text-muted">
          Menampilkan{" "}
          <span className="font-semibold text-ink">
            {summary.filtered_count}
          </span>{" "}
          dari{" "}
          <span className="font-semibold text-ink">
            {summary.total_count}
          </span>{" "}
          tagihan.
        </p>
      </section>

      {/* ===================================================
          LIST
      =================================================== */}

      <section className="mt-6">
        {data.items.length ===
        0 ? (
          <div className="rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h2 className="text-lg font-bold text-ink">
              Belum ada tagihan
            </h2>

            <p className="mx-auto mt-2 max-w-lg text-sm leading-6 text-muted">
              Tidak ditemukan tagihan yang sesuai
              dengan pencarian atau filter yang
              digunakan.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {data.items.map(
              (bill) => (
                <article
                  key={bill.id}
                  className="rounded-2xl border border-line bg-white p-5 shadow-soft"
                >
                  {/* =======================================
                      MAIN CONTENT
                  ======================================= */}

                  <div className="flex flex-col gap-5 xl:flex-row xl:items-start xl:justify-between">
                    {/* =====================================
                        STUDENT + BILL
                    ===================================== */}

                    <div className="min-w-0 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <h2 className="text-lg font-bold text-ink">
                          {
                            bill.student
                              .full_name
                          }
                        </h2>

                        <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                          {genderLabel(
                            bill.student
                              .gender,
                          )}
                        </span>

                        <span
                          className={`rounded-full px-2.5 py-1 text-xs font-semibold ${getStatusClassName(
                            bill.status,
                          )}`}
                        >
                          {getStatusLabel(
                            bill.status,
                          )}
                        </span>

                        {bill.is_overdue && (
                          <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700">
                            Jatuh Tempo
                          </span>
                        )}
                      </div>

                      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                        {bill.student
                          .nis && (
                          <span>
                            NIS{" "}
                            {
                              bill.student
                                .nis
                            }
                          </span>
                        )}

                        {bill.class && (
                          <span>
                            Kelas{" "}
                            {
                              bill.class
                                .name
                            }
                          </span>
                        )}
                      </div>

                      <div className="mt-4">
                        <p className="text-xs font-medium uppercase tracking-[0.12em] text-brand-600">
                          {bill.bill_code}
                        </p>

                        <h3 className="mt-1 text-base font-bold text-ink">
                          {bill.title}
                        </h3>

                        {bill.description && (
                          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
                            {
                              bill.description
                            }
                          </p>
                        )}

                        <div className="mt-3 flex flex-wrap gap-2">
                          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs text-slate-600">
                            {bill.category}
                          </span>

                          {bill.period_label && (
                            <span className="rounded-full bg-brand-50 px-3 py-1 text-xs text-brand-700">
                              {
                                bill.period_label
                              }
                            </span>
                          )}
                        </div>
                      </div>
                    </div>

                    {/* =====================================
                        FINANCIAL SUMMARY
                    ===================================== */}

                    <div className="grid gap-3 sm:grid-cols-3 xl:min-w-[560px]">
                      <div className="rounded-xl bg-slate-50 p-4">
                        <p className="text-xs text-muted">
                          Tagihan
                        </p>

                        <p className="mt-1 font-bold text-ink">
                          {formatCurrency(
                            bill.amount,
                          )}
                        </p>
                      </div>

                      <div className="rounded-xl bg-emerald-50 p-4">
                        <p className="text-xs text-emerald-700">
                          Dibayar
                        </p>

                        <p className="mt-1 font-bold text-emerald-900">
                          {formatCurrency(
                            bill.paid_amount,
                          )}
                        </p>
                      </div>

                      <div className="rounded-xl bg-amber-50 p-4">
                        <p className="text-xs text-amber-700">
                          Sisa
                        </p>

                        <p className="mt-1 font-bold text-amber-900">
                          {formatCurrency(
                            bill.outstanding_amount,
                          )}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* =======================================
                      FOOTER
                  ======================================= */}

                  <div className="mt-5 flex flex-col gap-4 border-t border-line pt-4 sm:flex-row sm:items-center sm:justify-between">
                    <div className="flex flex-col gap-2 text-xs text-muted sm:flex-row sm:flex-wrap sm:items-center sm:gap-x-5">
                      <span>
                        Jatuh tempo:{" "}
                        <strong
                          className={
                            bill.is_overdue
                              ? "text-red-700"
                              : "text-ink"
                          }
                        >
                          {formatDate(
                            bill.due_date,
                          )}
                        </strong>
                      </span>

                      {bill.period_start && (
                        <span>
                          Periode mulai:{" "}
                          {formatDate(
                            bill.period_start,
                          )}
                        </span>
                      )}

                      {bill.period_end && (
                        <span>
                          Periode akhir:{" "}
                          {formatDate(
                            bill.period_end,
                          )}
                        </span>
                      )}

                      {bill.status ===
                        "cancelled" &&
                        bill.cancellation_reason && (
                          <span className="text-red-700">
                            Alasan:{" "}
                            {
                              bill.cancellation_reason
                            }
                          </span>
                        )}
                    </div>

                    <Link
                      href={`/bendahara/tagihan/${bill.id}`}
                      className="inline-flex min-h-10 shrink-0 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
                    >
                      Lihat Detail
                    </Link>
                  </div>
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {/* ===================================================
          PAGINATION
      =================================================== */}

      {(pagination.has_previous ||
        pagination.has_next) && (
        <section className="mt-7 flex items-center justify-between gap-4">
          <div>
            {pagination.has_previous ? (
              <Link
                href={buildHref({
                  search,
                  status,
                  page:
                    pagination.page -
                    1,
                })}
                className="inline-flex min-h-10 items-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-ink transition hover:bg-slate-50"
              >
                ← Sebelumnya
              </Link>
            ) : (
              <span />
            )}
          </div>

          <p className="text-xs text-muted">
            Halaman{" "}
            <span className="font-semibold text-ink">
              {pagination.page}
            </span>
          </p>

          <div>
            {pagination.has_next ? (
              <Link
                href={buildHref({
                  search,
                  status,
                  page:
                    pagination.page +
                    1,
                })}
                className="inline-flex min-h-10 items-center rounded-xl bg-brand-600 px-4 text-sm font-semibold text-white transition hover:bg-brand-700"
              >
                Berikutnya →
              </Link>
            ) : (
              <span />
            )}
          </div>
        </section>
      )}
    </div>
  );
}