import Link from "next/link";

import type {
  BendaharaDashboardData,
} from "../schemas/bendahara-dashboard-schema";

type Props = {
  data:
    BendaharaDashboardData;
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

function genderLabel(
  value:
    "male" | "female",
): string {
  return value === "male"
    ? "Putra"
    : "Putri";
}

function paymentMethodLabel(
  value: string,
): string {
  const normalized =
    value
      .trim()
      .toLowerCase();

  switch (
    normalized
  ) {
    case "cash":
      return "Tunai";

    case "transfer":
      return "Transfer";

    case "bank_transfer":
      return "Transfer Bank";

    default:
      return value;
  }
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

      <p className="mt-2 text-2xl font-bold text-ink sm:text-3xl">
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
 * MAIN
 * =========================================================
 */

export function BendaharaDashboard({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* =====================================================
          HEADER
      ===================================================== */}

      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Bendahara
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Dashboard Keuangan
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Pantau tagihan, pembayaran,
          tunggakan, dan posisi
          keuangan santri pada tahun
          ajaran berjalan.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
            Tahun Ajaran{" "}
            {
              data.academic_year
                .name
            }
          </span>

          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
            {
              data.staff
                .full_name
            }
          </span>
        </div>
      </section>

      {/* =====================================================
          QUICK ACTIONS
      ===================================================== */}

      <section className="mt-6 grid gap-3 sm:grid-cols-3">
        <Link
          href="/bendahara/tagihan"
          className="rounded-2xl border border-line bg-white p-4 shadow-soft transition hover:border-brand-200 hover:bg-brand-50/40"
        >
          <p className="text-sm font-semibold text-ink">
            Tagihan Santri
          </p>

          <p className="mt-1 text-xs leading-5 text-muted">
            Lihat seluruh tagihan,
            status pembayaran, dan
            sisa kewajiban.
          </p>

          <p className="mt-3 text-xs font-semibold text-brand-700">
            Buka tagihan →
          </p>
        </Link>

        <Link
          href="/bendahara/tagihan/baru"
          className="rounded-2xl border border-brand-100 bg-brand-50 p-4 shadow-soft transition hover:border-brand-300"
        >
          <p className="text-sm font-semibold text-brand-900">
            Buat Tagihan
          </p>

          <p className="mt-1 text-xs leading-5 text-brand-700">
            Tambahkan tagihan baru
            untuk santri pada tahun
            ajaran aktif.
          </p>

          <p className="mt-3 text-xs font-semibold text-brand-800">
            + Tagihan baru
          </p>
        </Link>

        <Link
          href="/bendahara/pembayaran"
          className="rounded-2xl border border-line bg-white p-4 shadow-soft transition hover:border-brand-200 hover:bg-brand-50/40"
        >
          <p className="text-sm font-semibold text-ink">
            Riwayat Pembayaran
          </p>

          <p className="mt-1 text-xs leading-5 text-muted">
            Pantau pembayaran tercatat,
            dibatalkan, dan metode
            transaksi.
          </p>

          <p className="mt-3 text-xs font-semibold text-brand-700">
            Buka pembayaran →
          </p>
        </Link>
      </section>

      {/* =====================================================
          BILL COUNTS
      ===================================================== */}

      <section className="mt-7">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Posisi Tagihan
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Status Tagihan Santri
          </h2>
        </div>

        <div className="mt-4 grid gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5">
          <SummaryCard
            label="Tagihan Aktif"
            value={
              data.summary
                .active_bill_count
            }
          />

          <div className="rounded-2xl border border-slate-200 bg-slate-50 p-5">
            <p className="text-xs font-medium text-slate-600">
              Belum Dibayar
            </p>

            <p className="mt-2 text-3xl font-bold text-slate-900">
              {
                data.summary
                  .unpaid_count
              }
            </p>
          </div>

          <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
            <p className="text-xs font-medium text-amber-700">
              Dibayar Sebagian
            </p>

            <p className="mt-2 text-3xl font-bold text-amber-900">
              {
                data.summary
                  .partial_count
              }
            </p>
          </div>

          <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
            <p className="text-xs font-medium text-emerald-700">
              Lunas
            </p>

            <p className="mt-2 text-3xl font-bold text-emerald-900">
              {
                data.summary
                  .paid_count
              }
            </p>
          </div>

          <div className="rounded-2xl border border-red-100 bg-red-50 p-5">
            <p className="text-xs font-medium text-red-700">
              Jatuh Tempo
            </p>

            <p className="mt-2 text-3xl font-bold text-red-900">
              {
                data.summary
                  .overdue_count
              }
            </p>
          </div>
        </div>

        {data.summary
          .cancelled_count >
          0 && (
          <p className="mt-3 text-xs text-muted">
            Terdapat{" "}
            <span className="font-semibold text-ink">
              {
                data.summary
                  .cancelled_count
              }
            </span>{" "}
            tagihan yang telah
            dibatalkan dan tidak
            dihitung sebagai
            kewajiban aktif.
          </p>
        )}
      </section>

      {/* =====================================================
          MONEY SUMMARY
      ===================================================== */}

      <section className="mt-7">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Ringkasan Nominal
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          Posisi Keuangan
        </h2>

        <div className="mt-4 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <SummaryCard
            label="Total Tagihan"
            value={formatCurrency(
              data.summary
                .billed_amount,
            )}
            description="Tidak termasuk tagihan yang dibatalkan."
          />

          <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
            <p className="text-xs font-medium text-emerald-700">
              Sudah Dibayar
            </p>

            <p className="mt-2 text-2xl font-bold text-emerald-900 sm:text-3xl">
              {formatCurrency(
                data.summary
                  .paid_amount,
              )}
            </p>

            <p className="mt-2 text-xs leading-5 text-emerald-700">
              Nominal pembayaran aktif
              yang sudah dialokasikan
              ke tagihan.
            </p>
          </div>

          <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
            <p className="text-xs font-medium text-amber-700">
              Sisa Tagihan
            </p>

            <p className="mt-2 text-2xl font-bold text-amber-900 sm:text-3xl">
              {formatCurrency(
                data.summary
                  .outstanding_amount,
              )}
            </p>

            <p className="mt-2 text-xs leading-5 text-amber-700">
              Kewajiban yang masih
              belum dilunasi.
            </p>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
            <p className="text-xs font-medium text-brand-700">
              Pembayaran Bulan Ini
            </p>

            <p className="mt-2 text-2xl font-bold text-brand-900 sm:text-3xl">
              {formatCurrency(
                data.summary
                  .payment_amount_this_month,
              )}
            </p>

            <p className="mt-2 text-xs leading-5 text-brand-700">
              {
                data.summary
                  .payment_count_this_month
              }{" "}
              transaksi pembayaran
              tercatat.
            </p>
          </div>
        </div>
      </section>

      {/* =====================================================
          OVERDUE
      ===================================================== */}

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-red-600">
            Perlu Perhatian
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Tagihan Jatuh Tempo
          </h2>

          <p className="mt-2 text-sm text-muted">
            Tagihan aktif yang telah
            melewati tanggal jatuh
            tempo.
          </p>
        </div>

        {data.overdue_bills.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-8 text-center">
            <h3 className="font-bold text-ink">
              Tidak ada tagihan jatuh
              tempo
            </h3>

            <p className="mt-2 text-sm text-muted">
              Belum terdapat tagihan
              aktif yang melewati jatuh
              tempo.
            </p>
          </div>
        ) : (
          <div className="mt-5 space-y-4">
            {data.overdue_bills.map(
              (bill) => (
                <article
                  key={
                    bill.id
                  }
                  className="rounded-2xl border border-red-100 bg-white p-5 shadow-soft"
                >
                  <div className="flex flex-col gap-5 lg:flex-row lg:items-center lg:justify-between">
                    <div className="min-w-0">
                      <div className="flex flex-wrap items-center gap-2">
                        <h3 className="text-lg font-bold text-ink">
                          {
                            bill.student
                              .full_name
                          }
                        </h3>

                        <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700">
                          Jatuh Tempo
                        </span>

                        <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                          {genderLabel(
                            bill.student
                              .gender,
                          )}
                        </span>
                      </div>

                      <p className="mt-2 font-semibold text-ink">
                        {
                          bill.title
                        }
                      </p>

                      <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                        <span>
                          Kode{" "}
                          {
                            bill.bill_code
                          }
                        </span>

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

                        {bill.period_label && (
                          <span>
                            {
                              bill.period_label
                            }
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="grid min-w-0 gap-3 sm:grid-cols-3 lg:min-w-[520px]">
                      <div className="rounded-xl bg-slate-50 p-3">
                        <p className="text-xs text-muted">
                          Tagihan
                        </p>

                        <p className="mt-1 font-bold text-ink">
                          {formatCurrency(
                            bill.amount,
                          )}
                        </p>
                      </div>

                      <div className="rounded-xl bg-emerald-50 p-3">
                        <p className="text-xs text-emerald-700">
                          Dibayar
                        </p>

                        <p className="mt-1 font-bold text-emerald-900">
                          {formatCurrency(
                            bill.paid_amount,
                          )}
                        </p>
                      </div>

                      <div className="rounded-xl bg-red-50 p-3">
                        <p className="text-xs text-red-700">
                          Sisa
                        </p>

                        <p className="mt-1 font-bold text-red-900">
                          {formatCurrency(
                            bill.outstanding_amount,
                          )}
                        </p>
                      </div>
                    </div>
                  </div>

                  <div className="mt-4 border-t border-line pt-3">
                    <p className="text-xs font-medium text-red-700">
                      Jatuh tempo{" "}
                      {formatDate(
                        bill.due_date,
                      )}
                    </p>
                  </div>
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {/* =====================================================
          RECENT PAYMENTS
      ===================================================== */}

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Aktivitas Terbaru
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Pembayaran Terbaru
          </h2>
        </div>

        {data.recent_payments.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-8 text-center">
            <h3 className="font-bold text-ink">
              Belum ada pembayaran
            </h3>

            <p className="mt-2 text-sm text-muted">
              Transaksi pembayaran
              santri yang dicatat
              Bendahara akan tampil di
              sini.
            </p>
          </div>
        ) : (
          <div className="mt-5 overflow-hidden rounded-2xl border border-line bg-white shadow-soft">
            <div className="divide-y divide-line">
              {data.recent_payments.map(
                (payment) => (
                  <article
                    key={
                      payment.id
                    }
                    className="p-5"
                  >
                    <div className="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
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

                        <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                          <span>
                            {
                              payment.payment_code
                            }
                          </span>

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

                      <div className="grid gap-3 sm:grid-cols-3 lg:min-w-[530px]">
                        <div className="rounded-xl bg-slate-50 p-3">
                          <p className="text-xs text-muted">
                            Pembayaran
                          </p>

                          <p className="mt-1 font-bold text-ink">
                            {formatCurrency(
                              payment.amount,
                            )}
                          </p>
                        </div>

                        <div className="rounded-xl bg-brand-50 p-3">
                          <p className="text-xs text-brand-700">
                            Dialokasikan
                          </p>

                          <p className="mt-1 font-bold text-brand-900">
                            {formatCurrency(
                              payment.allocated_amount,
                            )}
                          </p>
                        </div>

                        <div className="rounded-xl bg-amber-50 p-3">
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
                  </article>
                ),
              )}
            </div>
          </div>
        )}
      </section>

      {/* =====================================================
          INFORMATION
      ===================================================== */}

      <section className="mt-7 rounded-2xl border border-brand-100 bg-brand-50 p-4 sm:p-5">
        <p className="font-semibold text-brand-900">
          Keuangan E-Ma&apos;had
        </p>

        <p className="mt-1 max-w-4xl text-sm leading-6 text-brand-700">
          Tagihan dan pembayaran sudah
          dikelola langsung melalui
          aplikasi. Setiap transaksi
          tetap memiliki riwayat untuk
          mendukung penelusuran dan
          monitoring keuangan.
        </p>
      </section>
    </div>
  );
}