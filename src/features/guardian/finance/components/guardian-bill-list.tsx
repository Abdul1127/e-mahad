import Link from "next/link";

import type {
  GuardianBillListData,
} from "../schemas/guardian-finance-schema";

type Props = {
  data:
    GuardianBillListData;
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

function statusLabel(
  status:
    | "unpaid"
    | "partial"
    | "paid",
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
  }
}

function statusClassName(
  status:
    | "unpaid"
    | "partial"
    | "paid",
): string {
  switch (
    status
  ) {
    case "unpaid":
      return "bg-slate-100 text-slate-700";

    case "partial":
      return "bg-amber-50 text-amber-700";

    case "paid":
      return "bg-emerald-50 text-emerald-700";
  }
}

export function GuardianBillList({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Keuangan Anak
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Tagihan
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Informasi tagihan anak pada
          tahun ajaran{" "}
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
              href="/wali/tagihan"
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
                  href={`/wali/tagihan?student=${child.id}`}
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
            Total Tagihan
          </p>

          <p className="mt-2 text-2xl font-bold text-ink">
            {formatCurrency(
              data.summary
                .billed_amount,
            )}
          </p>
        </div>

        <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
          <p className="text-xs text-emerald-700">
            Sudah Dibayar
          </p>

          <p className="mt-2 text-2xl font-bold text-emerald-900">
            {formatCurrency(
              data.summary
                .paid_amount,
            )}
          </p>
        </div>

        <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
          <p className="text-xs text-amber-700">
            Sisa Tagihan
          </p>

          <p className="mt-2 text-2xl font-bold text-amber-900">
            {formatCurrency(
              data.summary
                .outstanding_amount,
            )}
          </p>
        </div>
      </section>

      <section className="mt-4 flex flex-wrap gap-2 text-xs">
        <span className="rounded-full bg-slate-100 px-3 py-1.5 font-semibold text-slate-600">
          Belum Dibayar{" "}
          {
            data.summary
              .unpaid_count
          }
        </span>

        <span className="rounded-full bg-amber-50 px-3 py-1.5 font-semibold text-amber-700">
          Sebagian{" "}
          {
            data.summary
              .partial_count
          }
        </span>

        <span className="rounded-full bg-emerald-50 px-3 py-1.5 font-semibold text-emerald-700">
          Lunas{" "}
          {
            data.summary
              .paid_count
          }
        </span>

        {data.summary
          .overdue_count >
          0 && (
          <span className="rounded-full bg-red-50 px-3 py-1.5 font-semibold text-red-700">
            Jatuh Tempo{" "}
            {
              data.summary
                .overdue_count
            }
          </span>
        )}
      </section>

      {/* BILLS */}

      <section className="mt-7">
        {data.items.length ===
        0 ? (
          <div className="rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h2 className="text-lg font-bold text-ink">
              Belum ada tagihan
            </h2>

            <p className="mt-2 text-sm text-muted">
              Belum terdapat tagihan
              pada tahun ajaran aktif.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {data.items.map(
              (
                bill,
              ) => (
                <article
                  key={
                    bill.id
                  }
                  className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6"
                >
                  <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                    <div>
                      <div className="flex flex-wrap items-center gap-2">
                        <h2 className="text-lg font-bold text-ink">
                          {
                            bill.title
                          }
                        </h2>

                        <span
                          className={`rounded-full px-2.5 py-1 text-xs font-semibold ${statusClassName(
                            bill.status,
                          )}`}
                        >
                          {statusLabel(
                            bill.status,
                          )}
                        </span>

                        {bill.is_overdue && (
                          <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700">
                            Jatuh Tempo
                          </span>
                        )}
                      </div>

                      <p className="mt-2 text-sm font-semibold text-ink">
                        {
                          bill.student
                            .full_name
                        }
                      </p>

                      <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
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
                          {
                            bill.bill_code
                          }
                        </span>
                      </div>

                      <div className="mt-3 flex flex-wrap gap-2">
                        <span className="rounded-full bg-slate-100 px-3 py-1 text-xs text-slate-600">
                          {
                            bill.category
                          }
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

                    <div className="grid gap-3 sm:grid-cols-3 lg:min-w-[520px]">
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

                  <div className="mt-5 flex flex-col gap-3 border-t border-line pt-4 sm:flex-row sm:items-center sm:justify-between">
                    <p className="text-xs text-muted">
                      Jatuh tempo:{" "}
                      <span
                        className={
                          bill.is_overdue
                            ? "font-semibold text-red-700"
                            : "font-semibold text-ink"
                        }
                      >
                        {formatDate(
                          bill.due_date,
                        )}
                      </span>
                    </p>

                    <Link
                      href={`/wali/pembayaran?student=${bill.student.id}`}
                      className="text-sm font-semibold text-brand-700 hover:text-brand-800"
                    >
                      Lihat Riwayat Pembayaran →
                    </Link>
                  </div>
                </article>
              ),
            )}
          </div>
        )}
      </section>
    </div>
  );
}