import Link from "next/link";

import type {
  BendaharaFinanceReportData,
} from "../schemas/bendahara-finance-report-schema";

type Props = {
  data:
    BendaharaFinanceReportData;
};

function formatCurrency(
  value:
    number,
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
    },
  ).format(
    new Date(
      `${value}T00:00:00Z`,
    ),
  );
}

function formatDateTime(
  value:
    string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle:
        "medium",

      timeStyle:
        "short",
    },
  ).format(
    new Date(
      value,
    ),
  );
}

function paymentMethodLabel(
  value:
    string,
): string {
  switch (
    value
      .trim()
      .toLowerCase()
  ) {
    case "cash":
      return "Tunai";

    case "transfer":
      return "Transfer";

    case "bank_transfer":
      return "Transfer Bank";

    case "other":
      return "Lainnya";

    default:
      return value;
  }
}

function billStatusLabel(
  value:
    "unpaid" |
    "partial" |
    "paid" |
    "cancelled",
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

function billStatusClassName(
  value:
    "unpaid" |
    "partial" |
    "paid" |
    "cancelled",
): string {
  switch (
    value
  ) {
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

function categoryLabel(
  value:
    string,
): string {
  return value
    .replaceAll(
      "_",
      " ",
    )
    .replace(
      /\b\w/g,
      (
        character,
      ) =>
        character.toUpperCase(),
    );
}

function SummaryCard({
  label,
  value,
  description,
  variant =
    "default",
}: {
  label:
    string;

  value:
    string | number;

  description?:
    string;

  variant?:
    | "default"
    | "brand"
    | "success"
    | "warning"
    | "danger";
}) {
  const containerClassName =
    variant ===
    "brand"
      ? "border-brand-100 bg-brand-50"
      : variant ===
          "success"
        ? "border-emerald-100 bg-emerald-50"
        : variant ===
            "warning"
          ? "border-amber-100 bg-amber-50"
          : variant ===
              "danger"
            ? "border-red-100 bg-red-50"
            : "border-line bg-white";

  const labelClassName =
    variant ===
    "brand"
      ? "text-brand-700"
      : variant ===
          "success"
        ? "text-emerald-700"
        : variant ===
            "warning"
          ? "text-amber-700"
          : variant ===
              "danger"
            ? "text-red-700"
            : "text-muted";

  const valueClassName =
    variant ===
    "brand"
      ? "text-brand-900"
      : variant ===
          "success"
        ? "text-emerald-900"
        : variant ===
            "warning"
          ? "text-amber-900"
          : variant ===
              "danger"
            ? "text-red-900"
            : "text-ink";

  return (
    <article
      className={`rounded-2xl border p-5 shadow-soft ${containerClassName}`}
    >
      <p
        className={`text-xs font-medium ${labelClassName}`}
      >
        {label}
      </p>

      <p
        className={`mt-2 text-2xl font-bold ${valueClassName}`}
      >
        {value}
      </p>

      {description && (
        <p
          className={`mt-2 text-xs leading-5 ${labelClassName}`}
        >
          {description}
        </p>
      )}
    </article>
  );
}

export function BendaharaFinanceReport({
  data,
}: Props) {
  const {
    bill_summary:
      billSummary,

    payment_summary:
      paymentSummary,
  } = data;

  const collectionPercentage =
    billSummary.billed_amount >
    0
      ? Math.min(
          100,
          Math.round(
            (
              billSummary.paid_amount /
              billSummary.billed_amount
            ) *
              100,
          ),
        )
      : 0;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* ===================================================
          HEADER
      =================================================== */}

      <section className="overflow-hidden rounded-3xl border border-brand-100 bg-white shadow-soft">
        <div className="p-6 sm:p-8">
          <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
            <div>
              <div className="flex flex-wrap items-center gap-2">
                <span className="rounded-full bg-brand-50 px-3 py-1.5 text-xs font-semibold text-brand-700">
                  Bendahara
                </span>

                <span className="rounded-full bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700">
                  Laporan Read-only
                </span>
              </div>

              <h1 className="mt-4 text-3xl font-bold tracking-tight text-ink sm:text-4xl">
                Laporan Keuangan
              </h1>

              <p className="mt-3 max-w-3xl text-sm leading-7 text-muted sm:text-base">
                Rekap tagihan dan
                pembayaran santri
                berdasarkan periode
                laporan.
              </p>

              <p className="mt-3 text-sm font-semibold text-slate-600">
                Tahun Ajaran{" "}
                {
                  data.academic_year
                    .name
                }
              </p>
            </div>

            <div className="rounded-2xl border border-line bg-slate-50 px-5 py-4">
              <p className="text-xs text-muted">
                Data diperbarui
              </p>

              <p className="mt-1 text-sm font-semibold text-ink">
                {formatDateTime(
                  data.generated_at,
                )}
              </p>
            </div>
          </div>
        </div>
      </section>

      {/* ===================================================
          PERIOD FILTER
      =================================================== */}

      <section className="mt-6 rounded-2xl border border-line bg-white p-5 shadow-soft">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Periode Laporan
        </p>

        <form
          action="/bendahara/laporan"
          method="GET"
          className="mt-4 grid gap-4 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_auto_auto]"
        >
          <div>
            <label
              htmlFor="start"
              className="text-sm font-semibold text-ink"
            >
              Tanggal Awal
            </label>

            <input
              id="start"
              name="start"
              type="date"
              min={
                data.academic_year
                  .start_date
              }
              max={
                data.academic_year
                  .end_date
              }
              defaultValue={
                data.period
                  .start_date
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>

          <div>
            <label
              htmlFor="end"
              className="text-sm font-semibold text-ink"
            >
              Tanggal Akhir
            </label>

            <input
              id="end"
              name="end"
              type="date"
              min={
                data.academic_year
                  .start_date
              }
              max={
                data.academic_year
                  .end_date
              }
              defaultValue={
                data.period
                  .end_date
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />
          </div>

          <button
            type="submit"
            className="min-h-11 self-end rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
          >
            Tampilkan
          </button>

          <Link
            href="/bendahara/laporan"
            className="inline-flex min-h-11 self-end items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-muted transition hover:bg-slate-50 hover:text-ink"
          >
            Bulan Berjalan
          </Link>
        </form>

        <div className="mt-4 rounded-xl bg-slate-50 px-4 py-3">
          <p className="text-sm text-muted">
            Periode aktif:{" "}
            <strong className="text-ink">
              {formatDate(
                data.period
                  .start_date,
              )}
            </strong>
            {" — "}
            <strong className="text-ink">
              {formatDate(
                data.period
                  .end_date,
              )}
            </strong>
          </p>
        </div>
      </section>

      {/* ===================================================
          BILL MONEY SUMMARY
      =================================================== */}

      <section className="mt-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Tagihan
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Posisi Tagihan Periode
          </h2>
        </div>

        <div className="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <SummaryCard
            label="Total Tagihan"
            value={formatCurrency(
              billSummary.billed_amount,
            )}
            description={`${billSummary.active_count} tagihan aktif`}
            variant="brand"
          />

          <SummaryCard
            label="Sudah Dibayar"
            value={formatCurrency(
              billSummary.paid_amount,
            )}
            description={`${collectionPercentage}% realisasi`}
            variant="success"
          />

          <SummaryCard
            label="Sisa Tagihan"
            value={formatCurrency(
              billSummary.outstanding_amount,
            )}
            description="Outstanding tagihan periode"
            variant="warning"
          />

          <SummaryCard
            label="Jatuh Tempo"
            value={
              billSummary.overdue_count
            }
            description="Tagihan aktif melewati jatuh tempo"
            variant={
              billSummary.overdue_count >
              0
                ? "danger"
                : "default"
            }
          />
        </div>
      </section>

      {/* ===================================================
          BILL STATUS
      =================================================== */}

      <section className="mt-5 rounded-2xl border border-line bg-white p-5 shadow-soft">
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
          <div className="rounded-xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Belum Dibayar
            </p>

            <p className="mt-2 text-2xl font-bold text-ink">
              {
                billSummary.unpaid_count
              }
            </p>
          </div>

          <div className="rounded-xl bg-amber-50 p-4">
            <p className="text-xs text-amber-700">
              Sebagian
            </p>

            <p className="mt-2 text-2xl font-bold text-amber-900">
              {
                billSummary.partial_count
              }
            </p>
          </div>

          <div className="rounded-xl bg-emerald-50 p-4">
            <p className="text-xs text-emerald-700">
              Lunas
            </p>

            <p className="mt-2 text-2xl font-bold text-emerald-900">
              {
                billSummary.paid_count
              }
            </p>
          </div>

          <div className="rounded-xl bg-red-50 p-4">
            <p className="text-xs text-red-700">
              Jatuh Tempo
            </p>

            <p className="mt-2 text-2xl font-bold text-red-900">
              {
                billSummary.overdue_count
              }
            </p>
          </div>

          <div className="rounded-xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Dibatalkan
            </p>

            <p className="mt-2 text-2xl font-bold text-ink">
              {
                billSummary.cancelled_count
              }
            </p>
          </div>
        </div>

        <div className="mt-5">
          <div className="flex items-center justify-between gap-3">
            <p className="text-xs font-semibold text-slate-600">
              Realisasi Tagihan
            </p>

            <p className="text-xs font-bold text-brand-700">
              {
                collectionPercentage
              }
              %
            </p>
          </div>

          <div className="mt-2 h-2.5 overflow-hidden rounded-full bg-slate-100">
            <div
              className="h-full rounded-full bg-brand-600"
              style={{
                width:
                  `${collectionPercentage}%`,
              }}
            />
          </div>
        </div>
      </section>

      {/* ===================================================
          PAYMENT SUMMARY
      =================================================== */}

      <section className="mt-7">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Pembayaran
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Penerimaan Periode
          </h2>
        </div>

        <div className="mt-4 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          <SummaryCard
            label="Penerimaan Aktif"
            value={formatCurrency(
              paymentSummary.recorded_amount,
            )}
            description={`${paymentSummary.recorded_count} transaksi tercatat`}
            variant="success"
          />

          <SummaryCard
            label="Dialokasikan"
            value={formatCurrency(
              paymentSummary.allocated_amount,
            )}
            description="Nominal pembayaran yang telah dialokasikan"
            variant="brand"
          />

          <SummaryCard
            label="Belum Dialokasikan"
            value={formatCurrency(
              paymentSummary.unallocated_amount,
            )}
            description="Nominal pembayaran aktif tanpa alokasi"
            variant="warning"
          />

          <SummaryCard
            label="Transaksi Dibatalkan"
            value={
              paymentSummary.cancelled_count
            }
            description={`${paymentSummary.total_count} total histori transaksi`}
          />
        </div>
      </section>

      {/* ===================================================
          BREAKDOWN
      =================================================== */}

      <section className="mt-7 grid gap-5 xl:grid-cols-2">
        {/* CATEGORY */}

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Komposisi Tagihan
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Berdasarkan Kategori
          </h2>

          {data.category_summary.length ===
          0 ? (
            <p className="mt-5 text-sm text-muted">
              Tidak ada tagihan pada
              periode ini.
            </p>
          ) : (
            <div className="mt-5 space-y-3">
              {data.category_summary.map(
                (
                  item,
                ) => (
                  <div
                    key={
                      item.category
                    }
                    className="flex items-center justify-between gap-4 rounded-xl bg-slate-50 px-4 py-3"
                  >
                    <div>
                      <p className="font-semibold text-ink">
                        {categoryLabel(
                          item.category,
                        )}
                      </p>

                      <p className="mt-1 text-xs text-muted">
                        {
                          item.bill_count
                        }{" "}
                        tagihan aktif
                      </p>
                    </div>

                    <p className="text-sm font-bold text-ink">
                      {formatCurrency(
                        item.billed_amount,
                      )}
                    </p>
                  </div>
                ),
              )}
            </div>
          )}
        </article>

        {/* METHODS */}

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Penerimaan
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Berdasarkan Metode
          </h2>

          {data.payment_method_summary.length ===
          0 ? (
            <p className="mt-5 text-sm text-muted">
              Tidak ada pembayaran
              aktif pada periode ini.
            </p>
          ) : (
            <div className="mt-5 space-y-3">
              {data.payment_method_summary.map(
                (
                  item,
                ) => (
                  <div
                    key={
                      item.payment_method
                    }
                    className="flex items-center justify-between gap-4 rounded-xl bg-slate-50 px-4 py-3"
                  >
                    <div>
                      <p className="font-semibold text-ink">
                        {paymentMethodLabel(
                          item.payment_method,
                        )}
                      </p>

                      <p className="mt-1 text-xs text-muted">
                        {
                          item.payment_count
                        }{" "}
                        transaksi
                      </p>
                    </div>

                    <p className="text-sm font-bold text-emerald-800">
                      {formatCurrency(
                        item.amount,
                      )}
                    </p>
                  </div>
                ),
              )}
            </div>
          )}
        </article>
      </section>

      {/* ===================================================
          BILL LIST
      =================================================== */}

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Detail Laporan
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Tagihan Periode
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Maksimal 100 tagihan
            ditampilkan pada satu
            laporan periode.
          </p>
        </div>

        {data.bills.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-9 text-center">
            <p className="font-semibold text-ink">
              Tidak ada tagihan pada
              periode ini.
            </p>
          </div>
        ) : (
          <div className="mt-5 overflow-hidden rounded-2xl border border-line bg-white shadow-soft">
            <div className="overflow-x-auto">
              <table className="min-w-[1000px] w-full text-left">
                <thead className="bg-slate-50">
                  <tr>
                    <th className="px-4 py-3 text-xs font-semibold text-muted">
                      Tanggal
                    </th>

                    <th className="px-4 py-3 text-xs font-semibold text-muted">
                      Santri
                    </th>

                    <th className="px-4 py-3 text-xs font-semibold text-muted">
                      Tagihan
                    </th>

                    <th className="px-4 py-3 text-xs font-semibold text-muted">
                      Status
                    </th>

                    <th className="px-4 py-3 text-right text-xs font-semibold text-muted">
                      Nominal
                    </th>

                    <th className="px-4 py-3 text-right text-xs font-semibold text-muted">
                      Dibayar
                    </th>

                    <th className="px-4 py-3 text-right text-xs font-semibold text-muted">
                      Sisa
                    </th>
                  </tr>
                </thead>

                <tbody className="divide-y divide-line">
                  {data.bills.map(
                    (
                      bill,
                    ) => (
                      <tr
                        key={
                          bill.id
                        }
                        className="align-top"
                      >
                        <td className="px-4 py-4 text-sm text-muted">
                          {formatDate(
                            bill.report_date,
                          )}
                        </td>

                        <td className="px-4 py-4">
                          <p className="text-sm font-semibold text-ink">
                            {
                              bill.student
                                .full_name
                            }
                          </p>

                          {bill.student
                            .nis && (
                            <p className="mt-1 text-xs text-muted">
                              NIS{" "}
                              {
                                bill.student
                                  .nis
                              }
                            </p>
                          )}
                        </td>

                        <td className="px-4 py-4">
                          <p className="text-sm font-semibold text-ink">
                            {
                              bill.title
                            }
                          </p>

                          <p className="mt-1 text-xs text-muted">
                            {
                              bill.bill_code
                            }
                          </p>

                          <p className="mt-1 text-xs text-muted">
                            {categoryLabel(
                              bill.category,
                            )}

                            {bill.period_label
                              ? ` • ${bill.period_label}`
                              : ""}
                          </p>
                        </td>

                        <td className="px-4 py-4">
                          <span
                            className={`inline-flex rounded-full px-2.5 py-1 text-xs font-semibold ${billStatusClassName(
                              bill.status,
                            )}`}
                          >
                            {billStatusLabel(
                              bill.status,
                            )}
                          </span>

                          {bill.due_date && (
                            <p className="mt-2 text-xs text-muted">
                              Jatuh tempo{" "}
                              {formatDate(
                                bill.due_date,
                              )}
                            </p>
                          )}
                        </td>

                        <td className="px-4 py-4 text-right text-sm font-semibold text-ink">
                          {formatCurrency(
                            bill.amount,
                          )}
                        </td>

                        <td className="px-4 py-4 text-right text-sm font-semibold text-emerald-700">
                          {formatCurrency(
                            bill.paid_amount,
                          )}
                        </td>

                        <td className="px-4 py-4 text-right text-sm font-semibold text-amber-700">
                          {formatCurrency(
                            bill.outstanding_amount,
                          )}
                        </td>
                      </tr>
                    ),
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </section>

      {/* ===================================================
          PAYMENT LIST
      =================================================== */}

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Detail Laporan
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Pembayaran Periode
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Transaksi dibatalkan
            tetap ditampilkan sebagai
            audit trail tetapi tidak
            dihitung sebagai
            penerimaan aktif.
          </p>
        </div>

        {data.payments.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-9 text-center">
            <p className="font-semibold text-ink">
              Tidak ada pembayaran
              pada periode ini.
            </p>
          </div>
        ) : (
          <div className="mt-5 space-y-3">
            {data.payments.map(
              (
                payment,
              ) => (
                <article
                  key={
                    payment.id
                  }
                  className="rounded-2xl border border-line bg-white p-5 shadow-soft"
                >
                  <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <h3 className="font-bold text-ink">
                          {
                            payment.student
                              .full_name
                          }
                        </h3>

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

                      <p className="mt-2 text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                        {
                          payment.payment_code
                        }
                      </p>

                      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
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

                        {payment.reference_number && (
                          <span>
                            Ref.{" "}
                            {
                              payment.reference_number
                            }
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="grid gap-3 sm:grid-cols-2 lg:min-w-[380px]">
                      <div className="rounded-xl bg-slate-50 p-4">
                        <p className="text-xs text-muted">
                          Nominal
                        </p>

                        <p className="mt-1 font-bold text-ink">
                          {formatCurrency(
                            payment.amount,
                          )}
                        </p>
                      </div>

                      <div
                        className={
                          payment.status ===
                          "recorded"
                            ? "rounded-xl bg-brand-50 p-4"
                            : "rounded-xl bg-red-50 p-4"
                        }
                      >
                        <p
                          className={
                            payment.status ===
                            "recorded"
                              ? "text-xs text-brand-700"
                              : "text-xs text-red-700"
                          }
                        >
                          {payment.status ===
                          "recorded"
                            ? "Dialokasikan"
                            : "Alokasi Historis"}
                        </p>

                        <p
                          className={
                            payment.status ===
                            "recorded"
                              ? "mt-1 font-bold text-brand-900"
                              : "mt-1 font-bold text-red-900"
                          }
                        >
                          {formatCurrency(
                            payment.historical_allocated_amount,
                          )}
                        </p>
                      </div>
                    </div>
                  </div>
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {/* ===================================================
          REPORT NOTES
      =================================================== */}

      <section className="mt-8 rounded-2xl border border-blue-100 bg-blue-50 p-5">
        <p className="font-semibold text-blue-800">
          Dasar pembacaan laporan
        </p>

        <p className="mt-2 max-w-5xl text-sm leading-7 text-blue-700">
          Tagihan masuk ke periode
          berdasarkan tanggal mulai
          periode tagihan, kemudian
          tanggal jatuh tempo, dan
          terakhir tanggal pembuatan
          apabila tanggal periode
          tidak tersedia. Pembayaran
          masuk berdasarkan tanggal
          pembayaran. Transaksi yang
          dibatalkan tetap tersimpan
          sebagai histori tetapi
          tidak dihitung sebagai
          penerimaan aktif.
        </p>
      </section>
    </div>
  );
}