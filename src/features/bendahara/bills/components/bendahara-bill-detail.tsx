import {
  PreserveStateLink,
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import {
  BendaharaPaymentProofButton,
} from "@/features/bendahara/payments/components/bendahara-payment-proof-button";

import type {
  BendaharaBillDetailData,
} from "../schemas/bendahara-bill-detail-schema";

type Props = {
  data:
    BendaharaBillDetailData;
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

function statusLabel(
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

function statusClassName(
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
      return "bg-slate-100 text-slate-700";

    case "partial":
      return "bg-amber-50 text-amber-700";

    case "paid":
      return "bg-emerald-50 text-emerald-700";

    case "cancelled":
      return "bg-red-50 text-red-700";
  }
}

function paymentMethodLabel(
  value: string,
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

/*
 * =========================================================
 * AMOUNT CARD
 * =========================================================
 */

function AmountCard({
  label,
  value,
  variant = "default",
}: {
  label:
    string;

  value:
    number;

  variant?:
    | "default"
    | "success"
    | "warning";
}) {
  const className =
    variant ===
    "success"
      ? "border-emerald-100 bg-emerald-50"
      : variant ===
          "warning"
        ? "border-amber-100 bg-amber-50"
        : "border-line bg-white";

  const labelClassName =
    variant ===
    "success"
      ? "text-emerald-700"
      : variant ===
          "warning"
        ? "text-amber-700"
        : "text-muted";

  const valueClassName =
    variant ===
    "success"
      ? "text-emerald-900"
      : variant ===
          "warning"
        ? "text-amber-900"
        : "text-ink";

  return (
    <div
      className={`rounded-2xl border p-5 ${className}`}
    >
      <p
        className={`text-xs font-medium ${labelClassName}`}
      >
        {label}
      </p>

      <p
        className={`mt-2 text-2xl font-bold ${valueClassName}`}
      >
        {formatCurrency(
          value,
        )}
      </p>
    </div>
  );
}

/*
 * =========================================================
 * COMPONENT
 * =========================================================
 */

export function BendaharaBillDetail({
  data,
}: Props) {
  const {
    bill,
    summary,
    payments,
  } = data;

  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* ===================================================
          HEADER
      =================================================== */}

      <section>
        <ReturnLink
          fallbackHref="/bendahara/tagihan"
          allowedPrefixes={[
            "/bendahara/tagihan",
            "/bendahara/pembayaran",
          ]}
          className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
        >
          ← Kembali ke Daftar
        </ReturnLink>

        <div className="mt-6 flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Detail Tagihan
            </p>

            <h1 className="mt-2 text-3xl font-bold text-ink">
              {bill.title}
            </h1>

            <div className="mt-3 flex flex-wrap gap-2">
              <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                {bill.bill_code}
              </span>

              <span
                className={`rounded-full px-3 py-1 text-xs font-semibold ${statusClassName(
                  bill.status,
                )}`}
              >
                {statusLabel(
                  bill.status,
                )}
              </span>

              {bill.is_overdue && (
                <span className="rounded-full bg-red-50 px-3 py-1 text-xs font-semibold text-red-700">
                  Jatuh Tempo
                </span>
              )}
            </div>
          </div>

          {bill.can_record_payment && (
            <PreserveStateLink
              href={`/bendahara/tagihan/${bill.id}/pembayaran/baru`}
              className="inline-flex min-h-11 shrink-0 items-center justify-center rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
            >
              + Catat Pembayaran
            </PreserveStateLink>
          )}
        </div>
      </section>

      {/* ===================================================
          STUDENT
      =================================================== */}

      <section className="mt-7 rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Santri
        </p>

        <div className="mt-3 flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-ink">
              {
                bill.student
                  .full_name
              }
            </h2>

            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-sm text-muted">
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

              <span>
                {genderLabel(
                  bill.student
                    .gender,
                )}
              </span>

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
          </div>

          <span className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-600">
            Tahun Ajaran{" "}
            {
              data.academic_year
                .name
            }
          </span>
        </div>
      </section>

      {/* ===================================================
          AMOUNTS
      =================================================== */}

      <section className="mt-5 grid gap-4 sm:grid-cols-3">
        <AmountCard
          label="Total Tagihan"
          value={
            summary.bill_amount
          }
        />

        <AmountCard
          label="Sudah Dibayar"
          value={
            summary.paid_amount
          }
          variant="success"
        />

        <AmountCard
          label="Sisa Tagihan"
          value={
            summary.outstanding_amount
          }
          variant="warning"
        />
      </section>

      {/* ===================================================
          BILL INFORMATION
      =================================================== */}

      <section className="mt-6 rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Informasi Tagihan
        </p>

        <div className="mt-5 grid gap-x-8 gap-y-5 sm:grid-cols-2 lg:grid-cols-3">
          <div>
            <p className="text-xs text-muted">
              Kategori
            </p>

            <p className="mt-1 font-semibold text-ink">
              {bill.category}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Periode
            </p>

            <p className="mt-1 font-semibold text-ink">
              {bill.period_label ??
                "-"}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Jatuh Tempo
            </p>

            <p
              className={
                bill.is_overdue
                  ? "mt-1 font-semibold text-red-700"
                  : "mt-1 font-semibold text-ink"
              }
            >
              {formatDate(
                bill.due_date,
              )}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Mulai Periode
            </p>

            <p className="mt-1 font-semibold text-ink">
              {formatDate(
                bill.period_start,
              )}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Akhir Periode
            </p>

            <p className="mt-1 font-semibold text-ink">
              {formatDate(
                bill.period_end,
              )}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Dibuat
            </p>

            <p className="mt-1 font-semibold text-ink">
              {formatDateTime(
                bill.created_at,
              )}
            </p>
          </div>
        </div>

        {bill.description && (
          <div className="mt-6 border-t border-line pt-5">
            <p className="text-xs text-muted">
              Keterangan
            </p>

            <p className="mt-2 whitespace-pre-wrap text-sm leading-7 text-ink">
              {
                bill.description
              }
            </p>
          </div>
        )}

        {bill.status ===
          "cancelled" && (
          <div className="mt-6 rounded-xl border border-red-100 bg-red-50 p-4">
            <p className="text-sm font-semibold text-red-800">
              Tagihan Dibatalkan
            </p>

            <p className="mt-2 text-sm leading-6 text-red-700">
              {
                bill.cancellation_reason ??
                "Tidak ada alasan pembatalan."
              }
            </p>

            {bill.cancelled_at && (
              <p className="mt-2 text-xs text-red-600">
                Dibatalkan{" "}
                {formatDateTime(
                  bill.cancelled_at,
                )}
              </p>
            )}
          </div>
        )}
      </section>

      {/* ===================================================
          PAYMENT HISTORY
      =================================================== */}

      <section className="mt-7">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Transaksi
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Riwayat Pembayaran
            </h2>

            <p className="mt-2 text-sm text-muted">
              Semua pembayaran yang
              pernah dialokasikan ke
              tagihan ini.
            </p>
          </div>

          <div className="flex flex-wrap gap-2 text-xs">
            <span className="rounded-full bg-slate-100 px-3 py-1.5 font-semibold text-slate-600">
              Total{" "}
              {
                summary.payment_count
              }
            </span>

            <span className="rounded-full bg-emerald-50 px-3 py-1.5 font-semibold text-emerald-700">
              Aktif{" "}
              {
                summary.recorded_payment_count
              }
            </span>

            {summary.cancelled_payment_count >
              0 && (
              <span className="rounded-full bg-red-50 px-3 py-1.5 font-semibold text-red-700">
                Dibatalkan{" "}
                {
                  summary.cancelled_payment_count
                }
              </span>
            )}
          </div>
        </div>

        {payments.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-9 text-center">
            <h3 className="font-bold text-ink">
              Belum ada pembayaran
            </h3>

            <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-muted">
              Tagihan ini belum
              memiliki transaksi
              pembayaran.
            </p>

            {bill.can_record_payment && (
              <PreserveStateLink
                href={`/bendahara/tagihan/${bill.id}/pembayaran/baru`}
                className="mt-5 inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
              >
                + Catat Pembayaran
              </PreserveStateLink>
            )}
          </div>
        ) : (
          <div className="mt-5 space-y-4">
            {payments.map(
              (
                item,
              ) => {
                const payment =
                  item.payment;

                return (
                  <article
                    key={
                      item.allocation_id
                    }
                    className="rounded-2xl border border-line bg-white p-5 shadow-soft"
                  >
                    {/* =====================================
                        PAYMENT MAIN
                    ===================================== */}

                    <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                      <div>
                        <div className="flex flex-wrap items-center gap-2">
                          <p className="font-bold text-ink">
                            {
                              payment.payment_code
                            }
                          </p>

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

                          {payment.proof_path && (
                            <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">
                              Ada Bukti
                            </span>
                          )}
                        </div>

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

                      <div className="grid gap-3 sm:grid-cols-2 lg:min-w-[400px]">
                        <div className="rounded-xl bg-slate-50 p-4">
                          <p className="text-xs text-muted">
                            Nilai Transaksi
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
                              item.allocation_amount,
                            )}
                          </p>
                        </div>
                      </div>
                    </div>

                    {/* =====================================
                        NOTES
                    ===================================== */}

                    {payment.notes && (
                      <div className="mt-4 border-t border-line pt-4">
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

                    {/* =====================================
                        PROOF
                    ===================================== */}

                    {payment.proof_path ? (
                      <div className="mt-4 flex flex-col gap-3 rounded-xl border border-blue-100 bg-blue-50 p-4 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                          <p className="text-sm font-semibold text-blue-800">
                            Bukti pembayaran
                            tersedia
                          </p>

                          <p className="mt-1 text-xs leading-5 text-blue-700">
                            File disimpan pada
                            private Storage dan
                            dibuka melalui akses
                            sementara.
                          </p>
                        </div>

                        <BendaharaPaymentProofButton
                          proofPath={
                            payment.proof_path
                          }
                        />
                      </div>
                    ) : (
                      payment.status ===
                        "recorded" && (
                        <div className="mt-4 flex flex-col gap-3 rounded-xl border border-blue-100 bg-blue-50 p-4 sm:flex-row sm:items-center sm:justify-between">
                          <div>
                            <p className="text-sm font-semibold text-blue-800">
                              Belum ada bukti
                              pembayaran
                            </p>

                            <p className="mt-1 text-xs leading-5 text-blue-700">
                              Upload JPG, PNG,
                              WebP atau PDF
                              maksimal 5 MB.
                            </p>
                          </div>

                          <PreserveStateLink
                            href={`/bendahara/tagihan/${bill.id}/pembayaran/${payment.id}/bukti/unggah`}
                            className="inline-flex min-h-10 shrink-0 items-center justify-center rounded-xl bg-blue-600 px-4 text-sm font-semibold text-white transition hover:bg-blue-700"
                          >
                            Upload Bukti
                          </PreserveStateLink>
                        </div>
                      )
                    )}

                    {/* =====================================
                        CANCEL ACTION / AUDIT
                    ===================================== */}

                    {payment.status ===
                    "recorded" ? (
                      <div className="mt-4 flex justify-end border-t border-line pt-4">
                        <PreserveStateLink
                          href={`/bendahara/tagihan/${bill.id}/pembayaran/${payment.id}/batalkan`}
                          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-red-200 bg-red-50 px-4 text-sm font-semibold text-red-700 transition hover:bg-red-100"
                        >
                          Batalkan Pembayaran
                        </PreserveStateLink>
                      </div>
                    ) : (
                      <div className="mt-4 rounded-xl border border-red-100 bg-red-50 p-4">
                        <p className="text-sm font-semibold text-red-800">
                          Pembayaran
                          Dibatalkan
                        </p>

                        <p className="mt-1 text-sm text-red-700">
                          {
                            payment.cancellation_reason ??
                            "Tidak ada alasan pembatalan."
                          }
                        </p>

                        {payment.cancelled_at && (
                          <p className="mt-2 text-xs text-red-600">
                            {formatDateTime(
                              payment.cancelled_at,
                            )}
                          </p>
                        )}

                        {payment.proof_path && (
                          <p className="mt-2 text-xs leading-5 text-red-600">
                            Bukti pembayaran
                            tetap dipertahankan
                            sebagai audit trail.
                          </p>
                        )}
                      </div>
                    )}
                  </article>
                );
              },
            )}
          </div>
        )}
      </section>

      {/* ===================================================
          OUTSTANDING
      =================================================== */}

      {bill.can_record_payment && (
        <section className="mt-7 flex flex-col gap-4 rounded-2xl border border-brand-100 bg-brand-50 p-5 sm:flex-row sm:items-center sm:justify-between">
          <div>
            <p className="font-semibold text-brand-800">
              Tagihan masih memiliki
              sisa pembayaran
            </p>

            <p className="mt-1 text-sm leading-6 text-brand-700">
              Sisa tagihan saat ini{" "}
              <strong>
                {formatCurrency(
                  bill.outstanding_amount,
                )}
              </strong>
              .
            </p>
          </div>

          <PreserveStateLink
            href={`/bendahara/tagihan/${bill.id}/pembayaran/baru`}
            className="inline-flex min-h-11 shrink-0 items-center justify-center rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
          >
            + Catat Pembayaran
          </PreserveStateLink>
        </section>
      )}

      {bill.status ===
        "paid" && (
        <section className="mt-7 rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
          <p className="font-semibold text-emerald-800">
            Tagihan sudah lunas
          </p>

          <p className="mt-1 text-sm leading-6 text-emerald-700">
            Seluruh nominal tagihan
            telah dibayarkan.
          </p>
        </section>
      )}
    </div>
  );
}