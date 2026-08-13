"use client";

import {
  useActionState,
} from "react";

import {
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import {
  cancelBendaharaPaymentAction,
} from "../actions/cancel-bendahara-payment";

import {
  initialCancelBendaharaPaymentActionState,
} from "../types/cancel-bendahara-payment-action-state";

type Props = {
  billId:
    string;

  paymentId:
    string;

  paymentCode:
    string;

  studentName:
    string;

  billTitle:
    string;

  paymentDate:
    string;

  paymentAmount:
    number;

  paymentMethod:
    string;

  referenceNumber:
    string | null;
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

export function BendaharaCancelPaymentForm({
  billId,
  paymentId,
  paymentCode,
  studentName,
  billTitle,
  paymentDate,
  paymentAmount,
  paymentMethod,
  referenceNumber,
}: Props) {
  const [
    state,
    formAction,
    pending,
  ] =
    useActionState(
      cancelBendaharaPaymentAction,
      initialCancelBendaharaPaymentActionState,
    );

  const detailHref =
    `/bendahara/tagihan/${billId}`;

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

      <input
        type="hidden"
        name="paymentId"
        value={
          paymentId
        }
      />

      {/* ===============================================
          PAYMENT INFO
      =============================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-red-600">
          Pembayaran
        </p>

        <div className="mt-3 flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-ink">
              {
                paymentCode
              }
            </h2>

            <p className="mt-2 font-semibold text-ink">
              {
                studentName
              }
            </p>

            <p className="mt-1 text-sm text-muted">
              {
                billTitle
              }
            </p>
          </div>

          <div className="rounded-xl bg-slate-50 px-5 py-4">
            <p className="text-xs text-muted">
              Nominal Pembayaran
            </p>

            <p className="mt-1 text-xl font-bold text-ink">
              {formatCurrency(
                paymentAmount,
              )}
            </p>
          </div>
        </div>

        <div className="mt-5 grid gap-4 border-t border-line pt-5 sm:grid-cols-3">
          <div>
            <p className="text-xs text-muted">
              Tanggal
            </p>

            <p className="mt-1 text-sm font-semibold text-ink">
              {formatDate(
                paymentDate,
              )}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Metode
            </p>

            <p className="mt-1 text-sm font-semibold text-ink">
              {paymentMethodLabel(
                paymentMethod,
              )}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Referensi
            </p>

            <p className="mt-1 text-sm font-semibold text-ink">
              {referenceNumber ??
                "-"}
            </p>
          </div>
        </div>
      </section>

      {/* ===============================================
          WARNING
      =============================================== */}

      <section className="rounded-2xl border border-red-200 bg-red-50 p-5">
        <p className="font-semibold text-red-800">
          Perhatian
        </p>

        <p className="mt-2 text-sm leading-7 text-red-700">
          Pembayaran tidak akan
          dihapus dari database.
          Status transaksi akan
          berubah menjadi{" "}
          <strong>
            Dibatalkan
          </strong>{" "}
          dan tagihan yang terkait
          akan dihitung ulang secara
          otomatis.
        </p>
      </section>

      {/* ===============================================
          ERROR
      =============================================== */}

      {state.status ===
        "error" && (
        <section className="rounded-xl border border-red-200 bg-red-50 p-4">
          <p className="text-sm font-semibold text-red-800">
            Pembayaran belum
            dibatalkan
          </p>

          <p className="mt-1 text-sm leading-6 text-red-700">
            {
              state.message
            }
          </p>
        </section>
      )}

      {/* ===============================================
          REASON
      =============================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <label
          htmlFor="cancellationReason"
          className="text-sm font-semibold text-ink"
        >
          Alasan Pembatalan
        </label>

        <p className="mt-1 text-xs leading-5 text-muted">
          Jelaskan alasan transaksi
          harus dibatalkan agar
          riwayat koreksi dapat
          dipertanggungjawabkan.
        </p>

        <textarea
          id="cancellationReason"
          name="cancellationReason"
          rows={
            5
          }
          maxLength={
            1000
          }
          required
          defaultValue={
            state.values
              ?.cancellationReason ??
            ""
          }
          placeholder="Contoh: Salah input nominal pembayaran, seharusnya Rp300.000."
          className="mt-3 w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm leading-6 text-ink outline-none transition placeholder:text-muted focus:border-red-400 focus:ring-2 focus:ring-red-100"
        />

        {state.fieldErrors
          ?.cancellationReason &&
          state.fieldErrors
            .cancellationReason
            .length >
            0 && (
            <p className="mt-2 text-xs font-medium text-red-600">
              {
                state.fieldErrors
                  .cancellationReason[0]
              }
            </p>
          )}
      </section>

      {/* ===============================================
          ACTIONS
      =============================================== */}

      <section className="flex flex-col-reverse gap-3 border-t border-line pt-5 sm:flex-row sm:justify-end">
        <ReturnLink
          fallbackHref={
            detailHref
          }
          allowedPrefixes={[
            detailHref,
          ]}
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-muted transition hover:bg-slate-50 hover:text-ink"
        >
          Kembali
        </ReturnLink>

        <button
          type="submit"
          disabled={
            pending
          }
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-red-600 px-6 text-sm font-semibold text-white transition hover:bg-red-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {pending
            ? "Membatalkan..."
            : "Batalkan Pembayaran"}
        </button>
      </section>
    </form>
  );
}