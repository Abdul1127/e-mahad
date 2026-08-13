import {
  notFound,
} from "next/navigation";

import {
  z,
} from "zod";

import {
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  getBendaharaBillDetailData,
} from "@/features/bendahara/bills/data/get-bendahara-bill-detail-data";

import {
  BendaharaCancelPaymentForm,
} from "@/features/bendahara/payments/components/bendahara-cancel-payment-form";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  params:
    Promise<{
      role:
        string;

      billId:
        string;

      paymentId:
        string;
    }>;
};

export default async function BendaharaCancelPaymentPage({
  params,
}: PageProps) {
  const {
    role,
    billId,
    paymentId,
  } =
    await params;

  const roleCode =
    getRoleCodeBySlug(
      role,
    );

  if (
    roleCode !==
    "bendahara"
  ) {
    notFound();
  }

  const billIdValidation =
    z.string()
      .uuid()
      .safeParse(
        billId,
      );

  const paymentIdValidation =
    z.string()
      .uuid()
      .safeParse(
        paymentId,
      );

  if (
    !billIdValidation.success ||
    !paymentIdValidation.success
  ) {
    notFound();
  }

  await requireRole(
    "bendahara",
  );

  const data =
    await getBendaharaBillDetailData(
      billIdValidation.data,
    );

  const paymentItem =
    data.payments.find(
      (
        item,
      ) =>
        item.payment.id ===
        paymentIdValidation.data,
    );

  if (!paymentItem) {
    notFound();
  }

  const payment =
    paymentItem.payment;

  const detailHref =
    `/bendahara/tagihan/${data.bill.id}`;

  if (
    payment.status ===
    "cancelled"
  ) {
    return (
      <div className="mx-auto w-full max-w-4xl px-4 py-8 sm:px-6 lg:px-8">
        <ReturnLink
          fallbackHref={
            detailHref
          }
          allowedPrefixes={[
            detailHref,
          ]}
          className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
        >
          ← Kembali ke Detail Tagihan
        </ReturnLink>

        <section className="mt-6 rounded-2xl border border-red-100 bg-red-50 p-6">
          <h1 className="text-2xl font-bold text-red-900">
            Pembayaran sudah
            dibatalkan
          </h1>

          <p className="mt-3 text-sm leading-7 text-red-700">
            Transaksi{" "}
            <strong>
              {
                payment.payment_code
              }
            </strong>{" "}
            sudah berstatus
            Dibatalkan dan tidak
            dapat dibatalkan
            kembali.
          </p>

          {payment.cancellation_reason && (
            <div className="mt-4 rounded-xl bg-white p-4">
              <p className="text-xs text-muted">
                Alasan pembatalan
              </p>

              <p className="mt-1 text-sm text-ink">
                {
                  payment.cancellation_reason
                }
              </p>
            </div>
          )}
        </section>
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <ReturnLink
          fallbackHref={
            detailHref
          }
          allowedPrefixes={[
            detailHref,
          ]}
          className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
        >
          ← Kembali ke Detail Tagihan
        </ReturnLink>

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-red-600">
          Koreksi Transaksi
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Batalkan Pembayaran
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Batalkan transaksi yang
          salah tanpa menghapus
          riwayat pembayaran dari
          sistem.
        </p>
      </section>

      <section className="mt-7">
        <BendaharaCancelPaymentForm
          billId={
            data.bill.id
          }
          paymentId={
            payment.id
          }
          paymentCode={
            payment.payment_code
          }
          studentName={
            data.bill.student
              .full_name
          }
          billTitle={
            data.bill.title
          }
          paymentDate={
            payment.payment_date
          }
          paymentAmount={
            payment.amount
          }
          paymentMethod={
            payment.payment_method
          }
          referenceNumber={
            payment.reference_number
          }
        />
      </section>
    </div>
  );
}