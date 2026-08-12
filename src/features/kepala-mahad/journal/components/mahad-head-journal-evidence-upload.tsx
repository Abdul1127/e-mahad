"use client";

import {
  createBrowserClient,
} from "@supabase/ssr";

import {
  useRouter,
} from "next/navigation";

import {
  useState,
} from "react";

const BUCKET =
  "mahad-head-journal-evidence";

const MAX_FILE_SIZE =
  5 * 1024 * 1024;

const ALLOWED_TYPES =
  new Set([
    "image/jpeg",
    "image/png",
    "image/webp",
    "application/pdf",
  ]);

function sanitizeFileName(
  value: string,
): string {
  return value
    .replace(
      /[^a-zA-Z0-9._-]+/g,
      "-",
    )
    .replace(
      /-+/g,
      "-",
    )
    .replace(
      /^-|-$/g,
      "",
    );
}

export function MahadHeadJournalEvidenceUpload({
  journalId,
}: {
  journalId:
    string;
}) {
  const router =
    useRouter();

  const [
    pending,
    setPending,
  ] =
    useState(
      false,
    );

  const [
    message,
    setMessage,
  ] =
    useState<
      string | null
    >(
      null,
    );

  const [
    isError,
    setIsError,
  ] =
    useState(
      false,
    );

  async function handleSubmit(
    event:
      React.FormEvent<HTMLFormElement>,
  ) {
    event.preventDefault();

    const form =
      event.currentTarget;

    const input =
      form.elements.namedItem(
        "evidence",
      ) as HTMLInputElement | null;

    const file =
      input?.files?.[0];

    if (!file) {
      setIsError(
        true,
      );

      setMessage(
        "Pilih file bukti kinerja terlebih dahulu.",
      );

      return;
    }

    if (
      !ALLOWED_TYPES.has(
        file.type,
      )
    ) {
      setIsError(
        true,
      );

      setMessage(
        "Format file harus JPG, PNG, WebP, atau PDF.",
      );

      return;
    }

    if (
      file.size >
      MAX_FILE_SIZE
    ) {
      setIsError(
        true,
      );

      setMessage(
        "Ukuran file maksimal 5 MB.",
      );

      return;
    }

    setPending(
      true,
    );

    setMessage(
      null,
    );

    setIsError(
      false,
    );

    const supabase =
      createBrowserClient(
        process.env
          .NEXT_PUBLIC_SUPABASE_URL!,
        process.env
          .NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      );

    const safeName =
      sanitizeFileName(
        file.name,
      ) ||
      "evidence";

    const objectPath =
      `${journalId}/${crypto.randomUUID()}-${safeName}`;

    const {
      error: uploadError,
    } =
      await supabase.storage
        .from(
          BUCKET,
        )
        .upload(
          objectPath,
          file,
          {
            cacheControl:
              "3600",

            upsert:
              false,

            contentType:
              file.type,
          },
        );

    if (uploadError) {
      setPending(
        false,
      );

      setIsError(
        true,
      );

      setMessage(
        `Upload gagal: ${uploadError.message}`,
      );

      return;
    }

    const {
      error: attachError,
    } =
      await supabase.rpc(
        "attach_kepala_mahad_journal_evidence",
        {
          p_journal_id:
            journalId,

          p_evidence_path:
            objectPath,
        },
      );

    if (attachError) {
      await supabase.storage
        .from(
          BUCKET,
        )
        .remove([
          objectPath,
        ]);

      setPending(
        false,
      );

      setIsError(
        true,
      );

      setMessage(
        `File berhasil diunggah tetapi gagal dihubungkan ke jurnal: ${attachError.message}`,
      );

      return;
    }

    setPending(
      false,
    );

    setIsError(
      false,
    );

    setMessage(
      "Bukti kinerja berhasil disimpan.",
    );

    form.reset();

    router.refresh();
  }

  return (
    <form
      onSubmit={
        handleSubmit
      }
      className="rounded-2xl border border-line bg-slate-50 p-4"
    >
      <p className="text-sm font-semibold text-ink">
        Bukti Kinerja
      </p>

      <p className="mt-1 text-xs leading-5 text-muted">
        Upload screenshot, foto,
        atau PDF. Maksimal 5 MB.
      </p>

      <input
        type="file"
        name="evidence"
        accept="image/jpeg,image/png,image/webp,application/pdf"
        disabled={
          pending
        }
        className="mt-4 block w-full text-sm text-muted file:mr-4 file:rounded-xl file:border-0 file:bg-white file:px-4 file:py-2.5 file:text-sm file:font-semibold file:text-brand-700"
      />

      {message && (
        <div
          className={
            isError
              ? "mt-3 rounded-xl border border-red-100 bg-red-50 p-3 text-xs text-red-700"
              : "mt-3 rounded-xl border border-emerald-100 bg-emerald-50 p-3 text-xs text-emerald-700"
          }
        >
          {message}
        </div>
      )}

      <button
        type="submit"
        disabled={
          pending
        }
        className="mt-4 inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-white px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-50 disabled:opacity-60"
      >
        {pending
          ? "Mengunggah..."
          : "Upload Bukti"}
      </button>
    </form>
  );
}