"use client";

import {
  useState,
} from "react";

import {
  createClient,
} from "@/lib/supabase/client";

type Props = {
  proofPath:
    string;
};

const SIGNED_URL_EXPIRES_IN =
  300;

export function GuardianPaymentProofButton({
  proofPath,
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

  async function handleOpen() {
    if (loading) {
      return;
    }

    setLoading(
      true,
    );

    setErrorMessage(
      null,
    );

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
          "Bukti pembayaran tidak tersedia.",
        );
      }

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

  return (
    <div>
      <button
        type="button"
        disabled={
          loading
        }
        onClick={
          handleOpen
        }
        className="inline-flex min-h-10 items-center justify-center rounded-xl border border-blue-200 bg-white px-4 text-sm font-semibold text-blue-700 transition hover:bg-blue-50 disabled:cursor-not-allowed disabled:opacity-60"
      >
        {loading
          ? "Membuka..."
          : "Lihat Bukti"}
      </button>

      {errorMessage && (
        <p className="mt-2 max-w-sm text-xs font-medium text-red-600">
          {errorMessage}
        </p>
      )}
    </div>
  );
}