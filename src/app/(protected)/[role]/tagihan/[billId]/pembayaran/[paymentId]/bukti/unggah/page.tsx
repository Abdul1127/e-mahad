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
  BendaharaUploadPaymentProofForm,
} from "@/features/bendahara/payments/components/bendahara-upload-payment-proof-form";

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

export default async function BendaharaUploadPaymentProofPage({
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

  /*
   * =====================================================
   * CANCELLED PAYMENT
   * =====================================================
   */

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
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-red-600">
            Pembayaran Dibatalkan
          </p>

          <h1 className="mt-2 text-2xl font-bold text-red-900">
            Bukti tidak dapat
            ditambahkan
          </h1>

          <p className="mt-3 text-sm leading-7 text-red-700">
            Pembayaran{" "}
            <strong>
              {
                payment.payment_code
              }
            </strong>{" "}
            sudah dibatalkan.
            Pembayaran yang telah
            dibatalkan tidak dapat
            menerima bukti baru.
          </p>
        </section>
      </div>
    );
  }

  /*
   * =====================================================
   * EXISTING PROOF
   * =====================================================
   */

  if (
    payment.proof_path
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

        <section className="mt-6 rounded-2xl border border-emerald-100 bg-emerald-50 p-6">
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-emerald-700">
            Dokumen Tersimpan
          </p>

          <h1 className="mt-2 text-2xl font-bold text-emerald-900">
            Bukti pembayaran sudah
            tersedia
          </h1>

          <p className="mt-3 text-sm leading-7 text-emerald-700">
            Transaksi{" "}
            <strong>
              {
                payment.payment_code
              }
            </strong>{" "}
            sudah mempunyai bukti
            pembayaran yang
            tersimpan pada private
            Storage E-Ma&apos;had.
          </p>

          <p className="mt-3 text-sm leading-6 text-emerald-700">
            Bukti dapat dibuka
            melalui tombol{" "}
            <strong>
              Lihat Bukti
            </strong>{" "}
            pada Detail Tagihan.
          </p>

          <div className="mt-5">
            <ReturnLink
              fallbackHref={
                detailHref
              }
              allowedPrefixes={[
                detailHref,
              ]}
              className="inline-flex min-h-11 items-center justify-center rounded-xl bg-emerald-700 px-5 text-sm font-semibold text-white transition hover:bg-emerald-800"
            >
              Buka Detail Tagihan
            </ReturnLink>
          </div>
        </section>
      </div>
    );
  }

  /*
   * =====================================================
   * UPLOAD FORM
   * =====================================================
   */

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

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Dokumen Pembayaran
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Upload Bukti Pembayaran
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Simpan foto atau dokumen
          bukti pembayaran pada
          private Storage
          E-Ma&apos;had.
        </p>
      </section>

      <section className="mt-7">
        <BendaharaUploadPaymentProofForm
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
          paymentAmount={
            payment.amount
          }
          paymentDate={
            payment.payment_date
          }
          paymentMethod={
            payment.payment_method
          }
        />
      </section>
    </div>
  );
}