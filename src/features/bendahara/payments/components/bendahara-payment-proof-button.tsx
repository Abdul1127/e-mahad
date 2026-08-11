"use client";

import {
  useState,
} from "react";

import {
  createClient,
} from "@/lib/supabase/client";

type Props = {
  proofPath: string;

  label?: string;

  variant?:
    | "primary"
    | "secondary";
};

const SIGNED_URL_EXPIRES_IN =
  300;

export function BendaharaPaymentProofButton({
  proofPath,
  label = "Lihat Bukti",
  variant = "primary",
}: Props) {
  const [
    loading,
    setLoading,
  ] = useState(
    false,
  );

  const [
    errorMessage,
    setErrorMessage,
  ] = useState<
    string | null
  >(
    null,
  );

  async function handleOpenProof() {
    if (loading) {
      return;
    }

    setLoading(
      true,
    );

    setErrorMessage(
      null,
    );

    /*
     * Buka tab kosong terlebih dahulu.
     *
     * Ini membantu supaya browser tidak menganggap
     * tab baru sebagai popup yang muncul setelah
     * proses async selesai.
     */
    const proofWindow =
      window.open(
        "about:blank",
        "_blank",
      );

    if (proofWindow) {
      proofWindow.opener =
        null;

      proofWindow.document.title =
        "Membuka bukti pembayaran...";
    }

    try {
      const supabase =
        createClient();

      const {
        data,
        error,
      } =
        await supabase.storage
          .from(
            "payment-proofs",
          )
          .createSignedUrl(
            proofPath,
            SIGNED_URL_EXPIRES_IN,
          );

      if (error) {
        if (proofWindow) {
          proofWindow.close();
        }

        throw new Error(
          error.message,
        );
      }

      if (
        !data?.signedUrl
      ) {
        if (proofWindow) {
          proofWindow.close();
        }

        throw new Error(
          "Signed URL bukti pembayaran tidak tersedia.",
        );
      }

      /*
       * Jika browser mengizinkan tab baru,
       * arahkan tab tersebut ke signed URL.
       *
       * Jika popup diblokir, fallback membuka
       * file pada tab aplikasi saat ini.
       */
      if (proofWindow) {
        proofWindow.location.replace(
          data.signedUrl,
        );
      } else {
        window.location.assign(
          data.signedUrl,
        );
      }
    } catch (
      error
    ) {
      setErrorMessage(
        error instanceof Error
          ? error.message
          : "Gagal membuka bukti pembayaran.",
      );
    } finally {
      setLoading(
        false,
      );
    }
  }

  const buttonClassName =
    variant ===
    "secondary"
      ? "inline-flex min-h-10 items-center justify-center rounded-xl border border-blue-200 bg-white px-4 text-sm font-semibold text-blue-700 transition hover:bg-blue-50 disabled:cursor-not-allowed disabled:opacity-60"
      : "inline-flex min-h-10 items-center justify-center rounded-xl bg-blue-600 px-4 text-sm font-semibold text-white transition hover:bg-blue-700 disabled:cursor-not-allowed disabled:opacity-60";

  return (
    <div>
      <button
        type="button"
        disabled={
          loading
        }
        onClick={
          handleOpenProof
        }
        className={
          buttonClassName
        }
      >
        {loading
          ? "Membuka..."
          : label}
      </button>

      {errorMessage && (
        <p className="mt-2 max-w-sm break-words text-xs font-medium text-red-600">
          {errorMessage}
        </p>
      )}
    </div>
  );
}