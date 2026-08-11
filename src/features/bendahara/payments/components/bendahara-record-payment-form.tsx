"use client";

import Link from "next/link";

import {
  useActionState,
} from "react";

import {
  recordBendaharaBillPaymentAction,
} from "../actions/record-bendahara-bill-payment";

import {
  initialRecordBendaharaPaymentActionState,
} from "../types/record-bendahara-payment-action-state";

type Props = {
  billId: string;

  studentName: string;

  billTitle: string;

  billCode: string;

  billAmount: number;

  paidAmount: number;

  outstandingAmount: number;

  today: string;
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

function FieldError({
  messages,
}: {
  messages?:
    string[];
}) {
  if (
    !messages ||
    messages.length ===
      0
  ) {
    return null;
  }

  return (
    <p className="mt-1 text-xs font-medium text-red-600">
      {messages[0]}
    </p>
  );
}

export function BendaharaRecordPaymentForm({
  billId,
  studentName,
  billTitle,
  billCode,
  billAmount,
  paidAmount,
  outstandingAmount,
  today,
}: Props) {
  const [
    state,
    formAction,
    pending,
  ] = useActionState(
    recordBendaharaBillPaymentAction,
    initialRecordBendaharaPaymentActionState,
  );

  return (
    <form
      action={
        formAction
      }
      className="space-y-6"
    >
      <input
        type="hidden"
        name="billId"
        value={
          billId
        }
      />

      {/* ===============================================
          BILL
      =============================================== */}

      <section className="rounded-2xl border border-brand-100 bg-brand-50 p-5 sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Tagihan
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          {billTitle}
        </h2>

        <p className="mt-1 text-sm text-muted">
          {billCode}
        </p>

        <div className="mt-4">
          <p className="font-semibold text-ink">
            {studentName}
          </p>
        </div>

        <div className="mt-5 grid gap-3 sm:grid-cols-3">
          <div className="rounded-xl bg-white p-4">
            <p className="text-xs text-muted">
              Total Tagihan
            </p>

            <p className="mt-1 font-bold text-ink">
              {formatCurrency(
                billAmount,
              )}
            </p>
          </div>

          <div className="rounded-xl bg-white p-4">
            <p className="text-xs text-emerald-700">
              Sudah Dibayar
            </p>

            <p className="mt-1 font-bold text-emerald-900">
              {formatCurrency(
                paidAmount,
              )}
            </p>
          </div>

          <div className="rounded-xl bg-white p-4">
            <p className="text-xs text-amber-700">
              Sisa Tagihan
            </p>

            <p className="mt-1 font-bold text-amber-900">
              {formatCurrency(
                outstandingAmount,
              )}
            </p>
          </div>
        </div>
      </section>

      {/* ===============================================
          ERROR
      =============================================== */}

      {state.status ===
        "error" && (
        <section className="rounded-xl border border-red-200 bg-red-50 p-4">
          <p className="text-sm font-semibold text-red-800">
            Pembayaran belum
            tersimpan
          </p>

          <p className="mt-1 text-sm leading-6 text-red-700">
            {state.message}
          </p>
        </section>
      )}

      {/* ===============================================
          FORM
      =============================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Transaksi
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          Data Pembayaran
        </h2>

        <div className="mt-5 grid gap-5 sm:grid-cols-2">
          {/* PAYMENT DATE */}

          <div>
            <label
              htmlFor="paymentDate"
              className="text-sm font-semibold text-ink"
            >
              Tanggal Pembayaran
            </label>

            <input
              id="paymentDate"
              name="paymentDate"
              type="date"
              max={
                today
              }
              defaultValue={
                state.values
                  ?.paymentDate ??
                today
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />

            <FieldError
              messages={
                state.fieldErrors
                  ?.paymentDate
              }
            />
          </div>

          {/* METHOD */}

          <div>
            <label
              htmlFor="paymentMethod"
              className="text-sm font-semibold text-ink"
            >
              Metode Pembayaran
            </label>

            <select
              id="paymentMethod"
              name="paymentMethod"
              defaultValue={
                state.values
                  ?.paymentMethod ??
                "transfer"
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            >
              <option value="transfer">
                Transfer
              </option>

              <option value="bank_transfer">
                Transfer Bank
              </option>

              <option value="cash">
                Tunai
              </option>

              <option value="other">
                Lainnya
              </option>
            </select>

            <FieldError
              messages={
                state.fieldErrors
                  ?.paymentMethod
              }
            />
          </div>

          {/* AMOUNT */}

          <div>
            <label
              htmlFor="amount"
              className="text-sm font-semibold text-ink"
            >
              Nominal Pembayaran
            </label>

            <div className="mt-2 flex min-h-11 overflow-hidden rounded-xl border border-line bg-white focus-within:border-brand-400 focus-within:ring-2 focus-within:ring-brand-100">
              <span className="flex items-center border-r border-line bg-slate-50 px-4 text-sm font-semibold text-muted">
                Rp
              </span>

              <input
                id="amount"
                name="amount"
                type="number"
                min="1"
                max={
                  outstandingAmount
                }
                step="1"
                inputMode="numeric"
                defaultValue={
                  state.values
                    ?.amount ??
                  ""
                }
                placeholder={String(
                  outstandingAmount,
                )}
                className="min-w-0 flex-1 bg-white px-4 text-sm text-ink outline-none"
              />
            </div>

            <p className="mt-1 text-xs text-muted">
              Maksimal pembayaran{" "}
              <strong className="text-ink">
                {formatCurrency(
                  outstandingAmount,
                )}
              </strong>
              .
            </p>

            <FieldError
              messages={
                state.fieldErrors
                  ?.amount
              }
            />
          </div>

          {/* REFERENCE */}

          <div>
            <label
              htmlFor="referenceNumber"
              className="text-sm font-semibold text-ink"
            >
              Nomor Referensi
            </label>

            <input
              id="referenceNumber"
              name="referenceNumber"
              type="text"
              maxLength={
                150
              }
              defaultValue={
                state.values
                  ?.referenceNumber ??
                ""
              }
              placeholder="Contoh: TRX-20260811-001"
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />

            <p className="mt-1 text-xs text-muted">
              Opsional. Bisa diisi
              nomor referensi bank
              atau transaksi.
            </p>

            <FieldError
              messages={
                state.fieldErrors
                  ?.referenceNumber
              }
            />
          </div>
        </div>

        {/* NOTES */}

        <div className="mt-5">
          <label
            htmlFor="notes"
            className="text-sm font-semibold text-ink"
          >
            Catatan Pembayaran
          </label>

          <textarea
            id="notes"
            name="notes"
            rows={
              4
            }
            maxLength={
              1000
            }
            defaultValue={
              state.values
                ?.notes ??
              ""
            }
            placeholder="Catatan tambahan mengenai pembayaran..."
            className="mt-2 w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm leading-6 text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
          />

          <FieldError
            messages={
              state.fieldErrors
                ?.notes
            }
          />
        </div>
      </section>

      {/* ===============================================
          INFO
      =============================================== */}

      <section className="rounded-xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-sm font-semibold text-blue-800">
          Pencatatan pembayaran
        </p>

        <p className="mt-1 text-sm leading-6 text-blue-700">
          Setelah pembayaran
          disimpan, nominal tersebut
          langsung dialokasikan ke
          tagihan ini. Status tagihan
          akan berubah otomatis
          menjadi Dibayar Sebagian
          atau Lunas.
        </p>
      </section>

      {/* ===============================================
          ACTION
      =============================================== */}

      <section className="flex flex-col-reverse gap-3 border-t border-line pt-5 sm:flex-row sm:justify-end">
        <Link
          href={`/bendahara/tagihan/${billId}`}
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-muted transition hover:bg-slate-50 hover:text-ink"
        >
          Batal
        </Link>

        <button
          type="submit"
          disabled={
            pending
          }
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-600 px-6 text-sm font-semibold text-white transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {pending
            ? "Menyimpan..."
            : "Simpan Pembayaran"}
        </button>
      </section>
    </form>
  );
}