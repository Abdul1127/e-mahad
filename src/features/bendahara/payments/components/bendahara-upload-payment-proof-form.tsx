"use client";

import Link from "next/link";

import {
  ChangeEvent,
  FormEvent,
  useState,
} from "react";

import {
  useRouter,
} from "next/navigation";

import {
  createClient,
} from "@/lib/supabase/client";

type Props = {
  billId: string;

  paymentId: string;

  paymentCode: string;

  studentName: string;

  billTitle: string;

  paymentAmount: number;

  paymentDate: string;

  paymentMethod: string;
};

const MAX_FILE_SIZE =
  5 * 1024 * 1024;

const ALLOWED_TYPES = [
  "image/jpeg",
  "image/png",
  "image/webp",
  "application/pdf",
] as const;

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

function getExtensionFromMimeType(
  mimeType: string,
): string | null {
  switch (
    mimeType
  ) {
    case "image/jpeg":
      return "jpg";

    case "image/png":
      return "png";

    case "image/webp":
      return "webp";

    case "application/pdf":
      return "pdf";

    default:
      return null;
  }
}

function formatFileSize(
  size: number,
): string {
  if (
    size <
    1024
  ) {
    return `${size} B`;
  }

  if (
    size <
    1024 * 1024
  ) {
    return `${(
      size / 1024
    ).toFixed(
      1,
    )} KB`;
  }

  return `${(
    size /
    (1024 * 1024)
  ).toFixed(
    2,
  )} MB`;
}

export function BendaharaUploadPaymentProofForm({
  billId,
  paymentId,
  paymentCode,
  studentName,
  billTitle,
  paymentAmount,
  paymentDate,
  paymentMethod,
}: Props) {
  const router =
    useRouter();

  const [
    selectedFile,
    setSelectedFile,
  ] = useState<File | null>(
    null,
  );

  const [
    errorMessage,
    setErrorMessage,
  ] = useState<
    string | null
  >(
    null,
  );

  const [
    isUploading,
    setIsUploading,
  ] = useState(
    false,
  );

  function validateFile(
    file: File,
  ): string | null {
    if (
      !ALLOWED_TYPES.includes(
        file.type as
          (typeof ALLOWED_TYPES)[number],
      )
    ) {
      return "Format file tidak didukung. Gunakan JPG, PNG, WebP, atau PDF.";
    }

    if (
      file.size <=
      0
    ) {
      return "File bukti pembayaran kosong.";
    }

    if (
      file.size >
      MAX_FILE_SIZE
    ) {
      return "Ukuran file maksimal 5 MB.";
    }

    return null;
  }

  function handleFileChange(
    event:
      ChangeEvent<HTMLInputElement>,
  ) {
    setErrorMessage(
      null,
    );

    const file =
      event.target.files
        ?.item(
          0,
        ) ??
      null;

    if (!file) {
      setSelectedFile(
        null,
      );

      return;
    }

    const validationError =
      validateFile(
        file,
      );

    if (
      validationError
    ) {
      setSelectedFile(
        null,
      );

      setErrorMessage(
        validationError,
      );

      event.target.value =
        "";

      return;
    }

    setSelectedFile(
      file,
    );
  }

  async function handleSubmit(
    event:
      FormEvent<HTMLFormElement>,
  ) {
    event.preventDefault();

    setErrorMessage(
      null,
    );

    if (!selectedFile) {
      setErrorMessage(
        "Pilih file bukti pembayaran terlebih dahulu.",
      );

      return;
    }

    const validationError =
      validateFile(
        selectedFile,
      );

    if (
      validationError
    ) {
      setErrorMessage(
        validationError,
      );

      return;
    }

    const extension =
      getExtensionFromMimeType(
        selectedFile.type,
      );

    if (!extension) {
      setErrorMessage(
        "Format file bukti pembayaran tidak valid.",
      );

      return;
    }

    setIsUploading(
      true,
    );

    const supabase =
      createClient();

    const objectPath =
      `${paymentId}/${crypto.randomUUID()}.${extension}`;

    try {
      /*
       * ===============================================
       * 1. UPLOAD TO PRIVATE STORAGE
       * ===============================================
       */

      const {
        error:
          uploadError,
      } =
        await supabase.storage
          .from(
            "payment-proofs",
          )
          .upload(
            objectPath,
            selectedFile,
            {
              cacheControl:
                "3600",

              contentType:
                selectedFile.type,

              upsert:
                false,
            },
          );

      if (
        uploadError
      ) {
        throw new Error(
          `Upload gagal: ${uploadError.message}`,
        );
      }

      /*
       * ===============================================
       * 2. ATTACH PATH TO PAYMENT
       * ===============================================
       */

      const {
        error:
          attachError,
      } =
        await supabase.rpc(
          "attach_bendahara_payment_proof",
          {
            p_payment_id:
              paymentId,

            p_proof_path:
              objectPath,
          },
        );

      if (
        attachError
      ) {
        /*
         * File sudah ter-upload tetapi DB attach gagal.
         *
         * Coba cleanup object supaya tidak orphan.
         */

        const {
          error:
            cleanupError,
        } =
          await supabase.storage
            .from(
              "payment-proofs",
            )
            .remove([
              objectPath,
            ]);

        if (
          cleanupError
        ) {
          throw new Error(
            `${attachError.message} File berhasil ter-upload tetapi gagal dihubungkan ke transaksi, dan cleanup Storage juga gagal: ${cleanupError.message}`,
          );
        }

        throw new Error(
          attachError.message,
        );
      }

      /*
       * ===============================================
       * 3. RETURN TO BILL DETAIL
       * ===============================================
       */

      router.replace(
        `/bendahara/tagihan/${billId}`,
      );

      router.refresh();
    } catch (
      error
    ) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : "Terjadi kesalahan saat meng-upload bukti pembayaran.",
      );

      setIsUploading(
        false,
      );
    }
  }

  return (
    <form
      onSubmit={
        handleSubmit
      }
      className="space-y-6"
    >
      {/* ===============================================
          PAYMENT INFO
      =============================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Transaksi Pembayaran
        </p>

        <div className="mt-4 flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <h2 className="text-xl font-bold text-ink">
              {paymentCode}
            </h2>

            <p className="mt-2 font-semibold text-ink">
              {studentName}
            </p>

            <p className="mt-1 text-sm text-muted">
              {billTitle}
            </p>
          </div>

          <div className="rounded-xl bg-emerald-50 px-5 py-4">
            <p className="text-xs text-emerald-700">
              Nilai Pembayaran
            </p>

            <p className="mt-1 text-xl font-bold text-emerald-900">
              {formatCurrency(
                paymentAmount,
              )}
            </p>
          </div>
        </div>

        <div className="mt-5 grid gap-4 border-t border-line pt-5 sm:grid-cols-2">
          <div>
            <p className="text-xs text-muted">
              Tanggal Pembayaran
            </p>

            <p className="mt-1 text-sm font-semibold text-ink">
              {formatDate(
                paymentDate,
              )}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Metode Pembayaran
            </p>

            <p className="mt-1 text-sm font-semibold text-ink">
              {paymentMethodLabel(
                paymentMethod,
              )}
            </p>
          </div>
        </div>
      </section>

      {/* ===============================================
          UPLOAD
      =============================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Bukti Pembayaran
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          Upload File
        </h2>

        <p className="mt-2 text-sm leading-6 text-muted">
          Pilih foto atau dokumen
          bukti pembayaran untuk
          transaksi ini.
        </p>

        <label
          htmlFor="paymentProof"
          className="mt-5 block cursor-pointer rounded-2xl border border-dashed border-brand-300 bg-brand-50 p-6 text-center transition hover:bg-brand-100"
        >
          <span className="block text-sm font-semibold text-brand-800">
            {selectedFile
              ? "Ganti file"
              : "Pilih bukti pembayaran"}
          </span>

          <span className="mt-2 block text-xs leading-5 text-brand-700">
            JPG, PNG, WebP atau PDF
            • Maksimal 5 MB
          </span>

          <input
            id="paymentProof"
            name="paymentProof"
            type="file"
            accept="image/jpeg,image/png,image/webp,application/pdf"
            disabled={
              isUploading
            }
            onChange={
              handleFileChange
            }
            className="sr-only"
          />
        </label>

        {selectedFile && (
          <div className="mt-4 rounded-xl border border-line bg-slate-50 p-4">
            <p className="text-sm font-semibold text-ink">
              {
                selectedFile.name
              }
            </p>

            <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
              <span>
                {
                  selectedFile.type
                }
              </span>

              <span>
                {formatFileSize(
                  selectedFile.size,
                )}
              </span>
            </div>
          </div>
        )}
      </section>

      {/* ===============================================
          PRIVATE STORAGE INFO
      =============================================== */}

      <section className="rounded-xl border border-blue-100 bg-blue-50 p-4">
        <p className="text-sm font-semibold text-blue-800">
          File disimpan secara
          privat
        </p>

        <p className="mt-1 text-sm leading-6 text-blue-700">
          Bukti pembayaran disimpan
          pada private Storage
          E-Ma&apos;had dan tidak
          menggunakan public URL.
        </p>
      </section>

      {/* ===============================================
          ERROR
      =============================================== */}

      {errorMessage && (
        <section className="rounded-xl border border-red-200 bg-red-50 p-4">
          <p className="text-sm font-semibold text-red-800">
            Bukti pembayaran belum
            tersimpan
          </p>

          <p className="mt-1 break-words text-sm leading-6 text-red-700">
            {errorMessage}
          </p>
        </section>
      )}

      {/* ===============================================
          ACTIONS
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
            isUploading ||
            !selectedFile
          }
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-600 px-6 text-sm font-semibold text-white transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isUploading
            ? "Meng-upload..."
            : "Simpan Bukti Pembayaran"}
        </button>
      </section>
    </form>
  );
}