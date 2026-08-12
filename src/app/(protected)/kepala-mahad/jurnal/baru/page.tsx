import type {
  Metadata,
} from "next";

import Link from "next/link";

import {
  CreateKepalaMahadJournalForm,
} from "@/features/kepala-mahad/journal/components/create-kepala-mahad-journal-form";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Buat Jurnal Kepala Ma'had",
};

function getTodayWita(): string {
  const parts =
    new Intl.DateTimeFormat(
      "en-US",
      {
        timeZone:
          "Asia/Makassar",

        year:
          "numeric",

        month:
          "2-digit",

        day:
          "2-digit",
      },
    ).formatToParts(
      new Date(),
    );

  const year =
    parts.find(
      (part) =>
        part.type ===
        "year",
    )?.value;

  const month =
    parts.find(
      (part) =>
        part.type ===
        "month",
    )?.value;

  const day =
    parts.find(
      (part) =>
        part.type ===
        "day",
    )?.value;

  return `${year}-${month}-${day}`;
}

export default async function CreateKepalaMahadJournalPage() {
  await requireRole(
    "kepala_mahad",
  );

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <Link
        href="/kepala-mahad/jurnal"
        className="text-sm font-semibold text-brand-700"
      >
        ← Kembali ke Jurnal
      </Link>

      <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
        Jurnal Operasional
      </p>

      <h1 className="mt-2 text-3xl font-bold text-ink">
        Buat atau Buka Jurnal
      </h1>

      <p className="mt-3 mb-6 text-sm leading-7 text-muted">
        Pilih tanggal pelaksanaan.
        Apabila jurnal pada tanggal
        tersebut sudah tersedia,
        sistem akan membuka jurnal
        yang sama.
      </p>

      <CreateKepalaMahadJournalForm
        defaultDate={
          getTodayWita()
        }
      />
    </div>
  );
}