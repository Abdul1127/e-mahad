import type {
  KepalaMahadFinanceRecentPayment,
  KepalaMahadFinanceSummaryData,
} from "../schemas/kepala-mahad-finance-summary-schema";

type Props = {
  data:
    KepalaMahadFinanceSummaryData;
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

function paymentStatusLabel(
  status:
    "recorded" | "cancelled",
): string {
  return status ===
    "recorded"
    ? "Tercatat"
    : "Dibatalkan";
}

function paymentStatusClassName(
  status:
    "recorded" | "cancelled",
): string {
  return status ===
    "recorded"
    ? "bg-emerald-50 text-emerald-700"
    : "bg-red-50 text-red-700";
}

function billStatusLabel(
  status:
    "unpaid" |
    "partial" |
    "paid" |
    "cancelled",
): string {
  switch (
    status
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
    | "success"
    | "warning"
    | "danger"
    | "brand";
}) {
  const containerClassName =
    variant ===
    "success"
      ? "border-emerald-100 bg-emerald-50"
      : variant ===
          "warning"
        ? "border-amber-100 bg-amber-50"
        : variant ===
            "danger"
          ? "border-red-100 bg-red-50"
          : variant ===
              "brand"
            ? "border-brand-100 bg-brand-50"
            : "border-line bg-white";

  const labelClassName =
    variant ===
    "success"
      ? "text-emerald-700"
      : variant ===
          "warning"
        ? "text-amber-700"
        : variant ===
            "danger"
          ? "text-red-700"
          : variant ===
              "brand"
            ? "text-brand-700"
            : "text-muted";

  const valueClassName =
    variant ===
    "success"
      ? "text-emerald-900"
      : variant ===
          "warning"
        ? "text-amber-900"
        : variant ===
            "danger"
          ? "text-red-900"
          : variant ===
              "brand"
            ? "text-brand-900"
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

function RecentPaymentCard({
  payment,
}: {
  payment:
    KepalaMahadFinanceRecentPayment;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <p className="font-bold text-ink">
              {
                payment
                  .student
                  .full_name
              }
            </p>

            <span
              className={`rounded-full px-2.5 py-1 text-xs font-semibold ${paymentStatusClassName(
                payment.status,
              )}`}
            >
              {paymentStatusLabel(
                payment.status,
              )}
            </span>
          </div>

          <p className="mt-2 text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
            {
              payment.payment_code
            }
          </p>

          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
            {payment.student
              .nis && (
              <span>
                NIS{" "}
                {
                  payment.student
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
        </div>

        <div className="shrink-0 rounded-xl bg-slate-50 px-4 py-3 sm:text-right">
          <p className="text-xs text-muted">
            Nominal
          </p>

          <p className="mt-1 font-bold text-ink">
            {formatCurrency(
              payment.amount,
            )}
          </p>
        </div>
      </div>

      {payment.reference_number && (
        <p className="mt-4 text-xs text-muted">
          Referensi:{" "}
          <span className="font-semibold text-ink">
            {
              payment.reference_number
            }
          </span>
        </p>
      )}

      {payment.status ===
        "recorded" && (
        <div className="mt-4 rounded-xl bg-brand-50 px-4 py-3">
          <p className="text-xs text-brand-700">
            Dialokasikan ke tagihan
          </p>

          <p className="mt-1 font-semibold text-brand-900">
            {formatCurrency(
              payment.allocated_amount,
            )}
          </p>
        </div>
      )}

      {payment.status ===
        "cancelled" && (
        <div className="mt-4 rounded-xl border border-red-100 bg-red-50 px-4 py-3">
          <p className="text-xs font-semibold text-red-700">
            Transaksi dibatalkan
          </p>

          <p className="mt-1 text-sm leading-6 text-red-700">
            {
              payment.cancellation_reason ??
              "Tidak ada alasan pembatalan."
            }
          </p>
        </div>
      )}
    </article>
  );
}

export function KepalaMahadFinanceSummary({
  data,
}: Props) {
  const {
    summary,
  } = data;

  const collectionPercentage =
    summary.billed_amount >
    0
      ? Math.min(
          100,
          Math.round(
            (
              summary.paid_amount /
              summary.billed_amount
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
                  Kepala Ma&apos;had
                </span>

                <span className="rounded-full bg-blue-50 px-3 py-1.5 text-xs font-semibold text-blue-700">
                  Read-only
                </span>
              </div>

              <h1 className="mt-4 text-3xl font-bold tracking-tight text-ink sm:text-4xl">
                Ringkasan Keuangan
              </h1>

              <p className="mt-3 max-w-3xl text-sm leading-7 text-muted sm:text-base">
                Monitoring kondisi
                tagihan dan penerimaan
                santri tanpa fungsi
                pengelolaan transaksi.
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
          MONEY SUMMARY
      =================================================== */}

      <section className="mt-6 grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <SummaryCard
          label="Total Tagihan Aktif"
          value={formatCurrency(
            summary.billed_amount,
          )}
          description={`${summary.active_bill_count} tagihan aktif`}
          variant="brand"
        />

        <SummaryCard
          label="Sudah Dibayar"
          value={formatCurrency(
            summary.paid_amount,
          )}
          description={`${collectionPercentage}% dari tagihan aktif`}
          variant="success"
        />

        <SummaryCard
          label="Sisa Tagihan"
          value={formatCurrency(
            summary.outstanding_amount,
          )}
          description="Kewajiban yang masih terbuka"
          variant="warning"
        />

        <SummaryCard
          label="Penerimaan Bulan Ini"
          value={formatCurrency(
            summary.payment_amount_this_month,
          )}
          description={`${summary.payment_count_this_month} transaksi aktif`}
        />
      </section>

      {/* ===================================================
          STATUS COUNTS
      =================================================== */}

      <section className="mt-6 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Status Tagihan
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Posisi Tahun Ajaran Berjalan
          </h2>
        </div>

        <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-5">
          <div className="rounded-2xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Belum Dibayar
            </p>

            <p className="mt-2 text-3xl font-bold text-ink">
              {
                summary.unpaid_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-amber-50 p-4">
            <p className="text-xs text-amber-700">
              Sebagian
            </p>

            <p className="mt-2 text-3xl font-bold text-amber-900">
              {
                summary.partial_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-emerald-50 p-4">
            <p className="text-xs text-emerald-700">
              Lunas
            </p>

            <p className="mt-2 text-3xl font-bold text-emerald-900">
              {
                summary.paid_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-red-50 p-4">
            <p className="text-xs text-red-700">
              Jatuh Tempo
            </p>

            <p className="mt-2 text-3xl font-bold text-red-900">
              {
                summary.overdue_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Dibatalkan
            </p>

            <p className="mt-2 text-3xl font-bold text-ink">
              {
                summary.cancelled_count
              }
            </p>
          </div>
        </div>

        <div className="mt-5">
          <div className="flex items-center justify-between gap-3">
            <p className="text-xs font-semibold text-slate-600">
              Realisasi Pembayaran
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
          OVERDUE
      =================================================== */}

      <section className="mt-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-red-600">
            Perhatian
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Tagihan Jatuh Tempo
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Maksimal 10 tagihan
            jatuh tempo ditampilkan
            sebagai bahan monitoring.
          </p>
        </div>

        {data.overdue_bills.length ===
        0 ? (
          <div className="mt-5 rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
            <p className="font-semibold text-emerald-800">
              Tidak ada tagihan jatuh
              tempo
            </p>

            <p className="mt-1 text-sm leading-6 text-emerald-700">
              Belum terdapat tagihan
              aktif yang melewati
              tanggal jatuh tempo.
            </p>
          </div>
        ) : (
          <div className="mt-5 grid gap-4 xl:grid-cols-2">
            {data.overdue_bills.map(
              (
                bill,
              ) => (
                <article
                  key={
                    bill.id
                  }
                  className="rounded-2xl border border-red-100 bg-white p-5 shadow-soft"
                >
                  <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <p className="text-xs font-semibold uppercase tracking-[0.12em] text-red-600">
                        {
                          bill.bill_code
                        }
                      </p>

                      <h3 className="mt-2 font-bold text-ink">
                        {
                          bill.student
                            .full_name
                        }
                      </h3>

                      <p className="mt-1 text-sm text-muted">
                        {
                          bill.title
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
                    </div>

                    <span className="w-fit rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700">
                      {billStatusLabel(
                        bill.status,
                      )}
                    </span>
                  </div>

                  <div className="mt-4 grid gap-3 sm:grid-cols-3">
                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Tagihan
                      </p>

                      <p className="mt-1 text-sm font-bold text-ink">
                        {formatCurrency(
                          bill.amount,
                        )}
                      </p>
                    </div>

                    <div className="rounded-xl bg-emerald-50 p-3">
                      <p className="text-xs text-emerald-700">
                        Dibayar
                      </p>

                      <p className="mt-1 text-sm font-bold text-emerald-900">
                        {formatCurrency(
                          bill.paid_amount,
                        )}
                      </p>
                    </div>

                    <div className="rounded-xl bg-red-50 p-3">
                      <p className="text-xs text-red-700">
                        Sisa
                      </p>

                      <p className="mt-1 text-sm font-bold text-red-900">
                        {formatCurrency(
                          bill.outstanding_amount,
                        )}
                      </p>
                    </div>
                  </div>

                  <p className="mt-4 text-xs font-semibold text-red-700">
                    Jatuh tempo{" "}
                    {formatDate(
                      bill.due_date,
                    )}
                  </p>
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {/* ===================================================
          RECENT PAYMENTS
      =================================================== */}

      <section className="mt-7">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Transaksi
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Pembayaran Terbaru
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Transaksi terbaru
            ditampilkan untuk
            monitoring. Transaksi
            yang dibatalkan tetap
            terlihat sebagai audit
            trail.
          </p>
        </div>

        {data.recent_payments.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-9 text-center">
            <p className="font-semibold text-ink">
              Belum ada transaksi
              pembayaran.
            </p>
          </div>
        ) : (
          <div className="mt-5 grid gap-4 xl:grid-cols-2">
            {data.recent_payments.map(
              (
                payment,
              ) => (
                <RecentPaymentCard
                  key={
                    payment.id
                  }
                  payment={
                    payment
                  }
                />
              ),
            )}
          </div>
        )}
      </section>

      {/* ===================================================
          READ ONLY NOTICE
      =================================================== */}

      <section className="mt-7 rounded-2xl border border-blue-100 bg-blue-50 p-5">
        <p className="font-semibold text-blue-800">
          Monitoring read-only
        </p>

        <p className="mt-1 max-w-4xl text-sm leading-6 text-blue-700">
          Kepala Ma&apos;had hanya
          dapat memantau ringkasan
          keuangan. Pembuatan
          tagihan, pencatatan
          pembayaran, pembatalan
          transaksi, serta
          pengelolaan bukti
          pembayaran tetap menjadi
          kewenangan Bendahara.
        </p>
      </section>
    </div>
  );
}