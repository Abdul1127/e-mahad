import Link from "next/link";

import {
  notFound,
} from "next/navigation";

import {
  z,
} from "zod";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  getBendaharaBillDetailData,
} from "@/features/bendahara/bills/data/get-bendahara-bill-detail-data";

import {
  BendaharaRecordPaymentForm,
} from "@/features/bendahara/payments/components/bendahara-record-payment-form";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  params:
    Promise<{
      role: string;
      billId: string;
    }>;
};

function getTodayInputValue(): string {
  const now =
    new Date();

  const year =
    now.getFullYear();

  const month =
    String(
      now.getMonth() + 1,
    ).padStart(
      2,
      "0",
    );

  const day =
    String(
      now.getDate(),
    ).padStart(
      2,
      "0",
    );

  return `${year}-${month}-${day}`;
}

export default async function BendaharaRecordPaymentPage({
  params,
}: PageProps) {
  const {
    role,
    billId,
  } = await params;

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

  if (
    !billIdValidation.success
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

  if (
    !data.bill
      .can_record_payment
  ) {
    return (
      <div className="mx-auto w-full max-w-4xl px-4 py-8 sm:px-6 lg:px-8">
        <Link
          href={`/bendahara/tagihan/${billIdValidation.data}`}
          className="text-sm font-semibold text-brand-700 hover:text-brand-800"
        >
          ← Kembali ke Detail Tagihan
        </Link>

        <div className="mt-6 rounded-2xl border border-line bg-white p-8 shadow-soft">
          <h1 className="text-2xl font-bold text-ink">
            Pembayaran tidak dapat dicatat
          </h1>

          <p className="mt-3 text-sm leading-7 text-muted">
            Tagihan ini sudah lunas,
            telah dibatalkan, atau
            tidak memiliki sisa
            pembayaran.
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <Link
          href={`/bendahara/tagihan/${data.bill.id}`}
          className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
        >
          ← Kembali ke Detail Tagihan
        </Link>

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Bendahara
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Catat Pembayaran
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Catat pembayaran santri
          untuk tagihan yang dipilih.
        </p>
      </section>

      <section className="mt-7">
        <BendaharaRecordPaymentForm
          billId={
            data.bill.id
          }
          studentName={
            data.bill.student
              .full_name
          }
          billTitle={
            data.bill.title
          }
          billCode={
            data.bill.bill_code
          }
          billAmount={
            data.bill.amount
          }
          paidAmount={
            data.bill.paid_amount
          }
          outstandingAmount={
            data.bill.outstanding_amount
          }
          today={
            getTodayInputValue()
          }
        />
      </section>
    </div>
  );
}