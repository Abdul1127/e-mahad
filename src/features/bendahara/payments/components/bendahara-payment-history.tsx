import Link from "next/link";

import {
  PreserveStateLink,
} from "@/components/navigation/navigation-state-link";

import type {
  BendaharaPaymentHistoryData,
  BendaharaPaymentMethod,
  BendaharaPaymentStatus,
} from "../schemas/bendahara-payment-history-schema";

type Props = {
  data:
    BendaharaPaymentHistoryData;

  search:
    string | null;

  status:
    BendaharaPaymentStatus | null;

  method:
    BendaharaPaymentMethod | null;
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
      style:
        "currency",

      currency:
        "IDR",

      maximumFractionDigits:
        0,
    },
  ).format(
    value,
  );
}

function formatDate(
  value: string,
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

function formatDateTime(
  value:
    string | null,
): string {
  if (!value) {
    return "-";
  }

  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day:
        "2-digit",

      month:
        "long",

      year:
        "numeric",

      hour:
        "2-digit",

      minute:
        "2-digit",
    },
  ).format(
    new Date(
      value,
    ),
  );
}

function genderLabel(
  value:
    "male" | "female",
): string {
  return value ===
    "male"
    ? "Putra"
    : "Putri";
}

function paymentMethodLabel(
  value:
    BendaharaPaymentMethod,
): string {
  switch (
    value
  ) {
    case "cash":
      return "Tunai";

    case "transfer":
      return "Transfer";

    case "bank_transfer":
      return "Transfer Bank";

    case "other":
      return "Lainnya";
  }
}

function billStatusLabel(
  value:
    | "unpaid"
    | "partial"
    | "paid"
    | "cancelled",
): string {
  switch (
    value
  ) {
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

function buildHref({
  search,
  status,
  method,
  page,
}: {
  search:
    string | null;

  status:
    BendaharaPaymentStatus | null;

  method:
    BendaharaPaymentMethod | null;

  page:
    number;
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

  if (method) {
    params.set(
      "method",
      method,
    );
  }

  if (page > 1) {
    params.set(
      "page",
      String(
        page,
      ),
    );
  }

  const query =
    params.toString();

  return query
    ? `/bendahara/pembayaran?${query}`
    : "/bendahara/pembayaran";
}

/*
 * =========================================================
 * SUMMARY
 * =========================================================
 */

function SummaryCard({
  label,
  value,
  description,
}: {
  label:
    string;

  value:
    string | number;

  description?:
    string;
}) {
  return (
    <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
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
 * FILTER OPTIONS
 * =========================================================
 */

const STATUS_FILTERS: Array<{
  label:
    string;

  value:
    BendaharaPaymentStatus | null;
}> = [
  {
    label:
      "Semua",
    value:
      null,
  },
  {
    label:
      "Tercatat",
    value:
      "recorded",
  },
  {
    label:
      "Dibatalkan",
    value:
      "cancelled",
  },
];

const METHOD_FILTERS: Array<{
  label:
    string;

  value:
    BendaharaPaymentMethod | null;
}> = [
  {
    label:
      "Semua Metode",
    value:
      null,
  },
  {
    label:
      "Transfer",
    value:
      "transfer",
  },
  {
    label:
      "Transfer Bank",
    value:
      "bank_transfer",
  },
  {
    label:
      "Tunai",
    value:
      "cash",
  },
  {
    label:
      "Lainnya",
    value:
      "other",
  },
];

/*
 * =========================================================
 * COMPONENT
 * =========================================================
 */

export function BendaharaPaymentHistory({
  data,
  search,
  status,
  method,
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
            Riwayat Pembayaran
          </h1>

          <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
            Pantau seluruh transaksi
            pembayaran santri pada
            tahun ajaran{" "}
            <span className="font-semibold text-ink">
              {
                data.academic_year
                  .name
              }
            </span>
            .
          </p>
        </div>

        <Link
          href="/bendahara/tagihan"
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-ink transition hover:bg-slate-50"
        >
          Lihat Tagihan
        </Link>
      </section>

      {/* ===================================================
          SUMMARY COUNTS
      =================================================== */}

      <section className="mt-6 grid gap-3 sm:grid-cols-3">
        <SummaryCard
          label="Total Transaksi"
          value={
            summary.total_count
          }
        />

        <SummaryCard
          label="Transaksi Aktif"
          value={
            summary.recorded_count
          }
        />

        <SummaryCard
          label="Dibatalkan"
          value={
            summary.cancelled_count
          }
        />
      </section>

      {/* ===================================================
          SUMMARY NOMINAL
      =================================================== */}

      <section className="mt-4 grid gap-3 sm:grid-cols-3">
        <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
          <p className="text-xs font-medium text-emerald-700">
            Total Penerimaan Aktif
          </p>

          <p className="mt-2 text-2xl font-bold text-emerald-900">
            {formatCurrency(
              summary.recorded_amount,
            )}
          </p>
        </div>

        <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <p className="text-xs font-medium text-brand-700">
            Dialokasikan
          </p>

          <p className="mt-2 text-2xl font-bold text-brand-900">
            {formatCurrency(
              summary.active_allocated_amount,
            )}
          </p>
        </div>

        <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
          <p className="text-xs font-medium text-amber-700">
            Belum Dialokasikan
          </p>

          <p className="mt-2 text-2xl font-bold text-amber-900">
            {formatCurrency(
              summary.unallocated_amount,
            )}
          </p>
        </div>
      </section>

      {/* ===================================================
          FILTERS
      =================================================== */}

      <section className="mt-7 rounded-2xl border border-line bg-white p-4 shadow-soft">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-muted">
            Status
          </p>

          <div className="mt-2 flex flex-wrap gap-2">
            {STATUS_FILTERS.map(
              (
                filter,
              ) => {
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
                      method,
                      page:
                        1,
                    })}
                    className={
                      active
                        ? "rounded-full bg-brand-600 px-4 py-2 text-xs font-semibold text-white"
                        : "rounded-full bg-slate-100 px-4 py-2 text-xs font-semibold text-slate-600 transition hover:bg-slate-200"
                    }
                  >
                    {
                      filter.label
                    }
                  </Link>
                );
              },
            )}
          </div>
        </div>

        <div className="mt-4">
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-muted">
            Metode Pembayaran
          </p>

          <div className="mt-2 flex flex-wrap gap-2">
            {METHOD_FILTERS.map(
              (
                filter,
              ) => {
                const active =
                  method ===
                  filter.value;

                return (
                  <Link
                    key={
                      filter.value ??
                      "all-method"
                    }
                    href={buildHref({
                      search,
                      status,
                      method:
                        filter.value,
                      page:
                        1,
                    })}
                    className={
                      active
                        ? "rounded-full bg-brand-600 px-4 py-2 text-xs font-semibold text-white"
                        : "rounded-full bg-slate-100 px-4 py-2 text-xs font-semibold text-slate-600 transition hover:bg-slate-200"
                    }
                  >
                    {
                      filter.label
                    }
                  </Link>
                );
              },
            )}
          </div>
        </div>

        <form
          method="GET"
          action="/bendahara/pembayaran"
          className="mt-5 flex flex-col gap-3 sm:flex-row"
        >
          {status && (
            <input
              type="hidden"
              name="status"
              value={
                status
              }
            />
          )}

          {method && (
            <input
              type="hidden"
              name="method"
              value={
                method
              }
            />
          )}

          <input
            type="search"
            name="q"
            defaultValue={
              search ?? ""
            }
            placeholder="Cari kode pembayaran, referensi, nama atau NIS santri..."
            className="min-h-11 flex-1 rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
          />

          <button
            type="submit"
            className="min-h-11 rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
          >
            Cari
          </button>

          {(search ||
            status ||
            method) && (
            <Link
              href="/bendahara/pembayaran"
              className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-muted transition hover:bg-slate-50 hover:text-ink"
            >
              Reset
            </Link>
          )}
        </form>

        <p className="mt-3 text-xs text-muted">
          Menampilkan{" "}
          <span className="font-semibold text-ink">
            {
              summary.filtered_count
            }
          </span>{" "}
          dari{" "}
          <span className="font-semibold text-ink">
            {
              summary.total_count
            }
          </span>{" "}
          transaksi.
        </p>
      </section>

      {/* ===================================================
          HISTORY
      =================================================== */}

      <section className="mt-6">
        {data.items.length ===
        0 ? (
          <div className="rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h2 className="text-lg font-bold text-ink">
              Belum ada transaksi
            </h2>

            <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-muted">
              Tidak ditemukan
              pembayaran yang sesuai
              dengan pencarian atau
              filter yang digunakan.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {data.items.map(
              (
                payment,
              ) => (
                <article
                  key={
                    payment.id
                  }
                  className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6"
                >
                  {/* =======================================
                      TOP
                  ======================================= */}

                  <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <h2 className="text-lg font-bold text-ink">
                          {
                            payment
                              .student
                              .full_name
                          }
                        </h2>

                        <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                          {genderLabel(
                            payment
                              .student
                              .gender,
                          )}
                        </span>

                        {payment.status ===
                        "recorded" ? (
                          <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                            Tercatat
                          </span>
                        ) : (
                          <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700">
                            Dibatalkan
                          </span>
                        )}
                      </div>

                      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                        {payment
                          .student
                          .nis && (
                          <span>
                            NIS{" "}
                            {
                              payment
                                .student
                                .nis
                            }
                          </span>
                        )}

                        <span>
                          {formatDate(
                            payment.payment_date,
                          )}
                        </span>

                        <span>
                          {paymentMethodLabel(
                            payment.payment_method,
                          )}
                        </span>
                      </div>

                      <p className="mt-4 text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                        {
                          payment.payment_code
                        }
                      </p>

                      {payment.reference_number && (
                        <p className="mt-1 text-sm text-muted">
                          Referensi:{" "}
                          <span className="font-medium text-ink">
                            {
                              payment.reference_number
                            }
                          </span>
                        </p>
                      )}
                    </div>

                    {/* =====================================
                        AMOUNTS
                    ===================================== */}

                    <div className="grid gap-3 sm:grid-cols-3 lg:min-w-[570px]">
                      <div className="rounded-xl bg-slate-50 p-4">
                        <p className="text-xs text-muted">
                          Pembayaran
                        </p>

                        <p className="mt-1 font-bold text-ink">
                          {formatCurrency(
                            payment.amount,
                          )}
                        </p>
                      </div>

                      <div className="rounded-xl bg-brand-50 p-4">
                        <p className="text-xs text-brand-700">
                          Dialokasikan
                        </p>

                        <p className="mt-1 font-bold text-brand-900">
                          {formatCurrency(
                            payment.allocated_amount,
                          )}
                        </p>
                      </div>

                      <div className="rounded-xl bg-amber-50 p-4">
                        <p className="text-xs text-amber-700">
                          Belum Dialokasikan
                        </p>

                        <p className="mt-1 font-bold text-amber-900">
                          {formatCurrency(
                            payment.unallocated_amount,
                          )}
                        </p>
                      </div>
                    </div>
                  </div>

                  {/* =======================================
                      ALLOCATIONS
                  ======================================= */}

                  <div className="mt-5 border-t border-line pt-5">
                    <p className="text-xs font-semibold uppercase tracking-[0.12em] text-muted">
                      Dialokasikan ke Tagihan
                    </p>

                    {payment.allocations.length ===
                    0 ? (
                      <p className="mt-3 text-sm text-muted">
                        Transaksi belum
                        memiliki alokasi
                        tagihan.
                      </p>
                    ) : (
                      <div className="mt-3 space-y-3">
                        {payment.allocations.map(
                          (
                            allocation,
                          ) => (
                            <div
                              key={
                                allocation.allocation_id
                              }
                              className="flex flex-col gap-3 rounded-xl border border-line bg-slate-50 p-4 sm:flex-row sm:items-center sm:justify-between"
                            >
                              <div>
                                <div className="flex flex-wrap items-center gap-2">
                                  <p className="font-semibold text-ink">
                                    {
                                      allocation
                                        .bill
                                        .title
                                    }
                                  </p>

                                  <span className="rounded-full bg-white px-2.5 py-1 text-xs font-medium text-muted">
                                    {billStatusLabel(
                                      allocation
                                        .bill
                                        .status,
                                    )}
                                  </span>
                                </div>

                                <p className="mt-1 text-xs text-muted">
                                  {
                                    allocation
                                      .bill
                                      .bill_code
                                  }

                                  {allocation
                                    .bill
                                    .period_label
                                    ? ` • ${allocation.bill.period_label}`
                                    : ""}
                                </p>

                                <p className="mt-2 text-sm font-semibold text-brand-700">
                                  Alokasi{" "}
                                  {formatCurrency(
                                    allocation.amount,
                                  )}
                                </p>
                              </div>

                              <PreserveStateLink
                                href={`/bendahara/tagihan/${allocation.bill.id}`}
                                className="inline-flex min-h-10 shrink-0 items-center justify-center rounded-xl border border-brand-200 bg-white px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-50"
                              >
                                Lihat Tagihan
                              </PreserveStateLink>
                            </div>
                          ),
                        )}
                      </div>
                    )}
                  </div>

                  {/* =======================================
                      NOTES
                  ======================================= */}

                  {payment.notes && (
                    <div className="mt-5 border-t border-line pt-4">
                      <p className="text-xs text-muted">
                        Catatan
                      </p>

                      <p className="mt-1 whitespace-pre-wrap text-sm leading-6 text-ink">
                        {
                          payment.notes
                        }
                      </p>
                    </div>
                  )}

                  {/* =======================================
                      CANCELLED
                  ======================================= */}

                  {payment.status ===
                    "cancelled" && (
                    <div className="mt-5 rounded-xl border border-red-100 bg-red-50 p-4">
                      <p className="text-sm font-semibold text-red-800">
                        Pembayaran
                        Dibatalkan
                      </p>

                      <p className="mt-1 text-sm leading-6 text-red-700">
                        {
                          payment.cancellation_reason ??
                          "Tidak ada alasan pembatalan."
                        }
                      </p>

                      {payment.cancelled_at && (
                        <p className="mt-2 text-xs text-red-600">
                          Dibatalkan{" "}
                          {formatDateTime(
                            payment.cancelled_at,
                          )}
                        </p>
                      )}

                      {payment.historical_allocated_amount >
                        0 && (
                        <p className="mt-2 text-xs text-red-600">
                          Riwayat alokasi
                          sebelum pembatalan:{" "}
                          <strong>
                            {formatCurrency(
                              payment.historical_allocated_amount,
                            )}
                          </strong>
                        </p>
                      )}
                    </div>
                  )}

                  {/* =======================================
                      PROOF
                  ======================================= */}

                  {payment.has_proof && (
                    <div className="mt-5 rounded-xl border border-emerald-100 bg-emerald-50 p-4">
                      <p className="text-sm font-semibold text-emerald-800">
                        Bukti pembayaran
                        tersedia
                      </p>

                      <p className="mt-1 text-xs leading-5 text-emerald-700">
                        Bukti transaksi
                        tersimpan pada
                        private Storage
                        pembayaran.
                      </p>
                    </div>
                  )}
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
                  method,
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
              {
                pagination.page
              }
            </span>
          </p>

          <div>
            {pagination.has_next ? (
              <Link
                href={buildHref({
                  search,
                  status,
                  method,
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