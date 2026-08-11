import Link from "next/link";

import {
  GuardianPaymentProofButton,
} from "./guardian-payment-proof-button";

import type {
  GuardianPaymentHistoryData,
} from "../schemas/guardian-finance-schema";

type Props = {
  data:
    GuardianPaymentHistoryData;
};

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

function methodLabel(
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

function buildPageHref(
  studentId:
    string | null,
  page:
    number,
): string {
  const params =
    new URLSearchParams();

  if (studentId) {
    params.set(
      "student",
      studentId,
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
    ? `/wali/pembayaran?${query}`
    : "/wali/pembayaran";
}

export function GuardianPaymentHistory({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Keuangan Anak
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Riwayat Pembayaran
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Riwayat transaksi pembayaran
          anak pada tahun ajaran{" "}
          <span className="font-semibold text-ink">
            {
              data.academic_year
                .name
            }
          </span>
          .
        </p>
      </section>

      {/* CHILD FILTER */}

      {data.children.length >
        1 && (
        <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft">
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-muted">
            Pilih Anak
          </p>

          <div className="mt-3 flex flex-wrap gap-2">
            <Link
              href="/wali/pembayaran"
              className={
                data.selected_student_id ===
                null
                  ? "rounded-full bg-brand-600 px-4 py-2 text-xs font-semibold text-white"
                  : "rounded-full bg-slate-100 px-4 py-2 text-xs font-semibold text-slate-600"
              }
            >
              Semua Anak
            </Link>

            {data.children.map(
              (
                child,
              ) => (
                <Link
                  key={
                    child.id
                  }
                  href={`/wali/pembayaran?student=${child.id}`}
                  className={
                    data.selected_student_id ===
                    child.id
                      ? "rounded-full bg-brand-600 px-4 py-2 text-xs font-semibold text-white"
                      : "rounded-full bg-slate-100 px-4 py-2 text-xs font-semibold text-slate-600"
                  }
                >
                  {
                    child.full_name
                  }
                </Link>
              ),
            )}
          </div>
        </section>
      )}

      {/* SUMMARY */}

      <section className="mt-6 grid gap-3 sm:grid-cols-3">
        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Total Transaksi
          </p>

          <p className="mt-2 text-2xl font-bold text-ink">
            {
              data.summary
                .total_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
          <p className="text-xs text-emerald-700">
            Total Pembayaran Aktif
          </p>

          <p className="mt-2 text-2xl font-bold text-emerald-900">
            {formatCurrency(
              data.summary
                .recorded_amount,
            )}
          </p>
        </div>

        <div className="rounded-2xl border border-red-100 bg-red-50 p-5">
          <p className="text-xs text-red-700">
            Transaksi Dibatalkan
          </p>

          <p className="mt-2 text-2xl font-bold text-red-900">
            {
              data.summary
                .cancelled_count
            }
          </p>
        </div>
      </section>

      {/* PAYMENT LIST */}

      <section className="mt-7">
        {data.items.length ===
        0 ? (
          <div className="rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h2 className="text-lg font-bold text-ink">
              Belum ada pembayaran
            </h2>

            <p className="mt-2 text-sm text-muted">
              Belum terdapat transaksi
              pembayaran untuk anak
              yang dipilih.
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
                  <div className="flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between">
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

                        {payment.has_proof && (
                          <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">
                            Ada Bukti
                          </span>
                        )}
                      </div>

                      <p className="mt-2 text-sm font-semibold text-ink">
                        {
                          payment.student
                            .full_name
                        }
                      </p>

                      <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                        <span>
                          {formatDate(
                            payment.payment_date,
                          )}
                        </span>

                        <span>
                          {methodLabel(
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

                    <div className="rounded-xl bg-emerald-50 px-5 py-4 sm:min-w-[210px]">
                      <p className="text-xs text-emerald-700">
                        Nilai Pembayaran
                      </p>

                      <p className="mt-1 text-xl font-bold text-emerald-900">
                        {formatCurrency(
                          payment.amount,
                        )}
                      </p>
                    </div>
                  </div>

                  {payment.allocations.length >
                    0 && (
                    <div className="mt-5 border-t border-line pt-4">
                      <p className="text-xs font-semibold uppercase tracking-[0.12em] text-muted">
                        Untuk Tagihan
                      </p>

                      <div className="mt-3 space-y-2">
                        {payment.allocations.map(
                          (
                            allocation,
                          ) => (
                            <div
                              key={
                                allocation.allocation_id
                              }
                              className="rounded-xl bg-slate-50 p-4"
                            >
                              <p className="font-semibold text-ink">
                                {
                                  allocation
                                    .bill
                                    .title
                                }
                              </p>

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
                                {formatCurrency(
                                  allocation.amount,
                                )}
                              </p>
                            </div>
                          ),
                        )}
                      </div>
                    </div>
                  )}

                  {payment.status ===
                    "cancelled" && (
                    <div className="mt-4 rounded-xl border border-red-100 bg-red-50 p-4">
                      <p className="text-sm font-semibold text-red-800">
                        Transaksi dibatalkan
                      </p>

                      <p className="mt-1 text-xs leading-5 text-red-700">
                        Transaksi ini tidak
                        dihitung sebagai
                        pembayaran aktif.
                      </p>
                    </div>
                  )}

                  {payment.proof_path && (
                    <div className="mt-4 flex flex-col gap-3 rounded-xl border border-blue-100 bg-blue-50 p-4 sm:flex-row sm:items-center sm:justify-between">
                      <div>
                        <p className="text-sm font-semibold text-blue-800">
                          Bukti pembayaran
                          tersedia
                        </p>

                        <p className="mt-1 text-xs text-blue-700">
                          File dibuka melalui
                          akses private
                          sementara.
                        </p>
                      </div>

                      <GuardianPaymentProofButton
                        proofPath={
                          payment.proof_path
                        }
                      />
                    </div>
                  )}
                </article>
              ),
            )}
          </div>
        )}
      </section>

      {/* PAGINATION */}

      {(data.pagination
        .has_previous ||
        data.pagination
          .has_next) && (
        <section className="mt-7 flex items-center justify-between gap-4">
          <div>
            {data.pagination
              .has_previous ? (
              <Link
                href={buildPageHref(
                  data.selected_student_id,
                  data.pagination.page -
                    1,
                )}
                className="inline-flex min-h-10 items-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-ink"
              >
                ← Sebelumnya
              </Link>
            ) : (
              <span />
            )}
          </div>

          <p className="text-xs text-muted">
            Halaman{" "}
            <strong className="text-ink">
              {
                data.pagination
                  .page
              }
            </strong>
          </p>

          <div>
            {data.pagination
              .has_next ? (
              <Link
                href={buildPageHref(
                  data.selected_student_id,
                  data.pagination.page +
                    1,
                )}
                className="inline-flex min-h-10 items-center rounded-xl bg-brand-600 px-4 text-sm font-semibold text-white"
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