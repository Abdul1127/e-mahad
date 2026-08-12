import type {
  Metadata,
} from "next";

import Link from "next/link";

import {
  notFound,
} from "next/navigation";

import {
  z,
} from "zod";

import {
  MahadHeadJournalReadOnly,
} from "@/features/kepala-mahad/journal/components/mahad-head-journal-read-only";

import {
  createMahadHeadJournalEvidenceSignedUrl,
} from "@/features/kepala-mahad/journal/data/create-mahad-head-journal-evidence-signed-url";

import {
  getPenanggungJawabMahadHeadJournalDetail,
} from "@/features/kepala-mahad/journal/data/get-penanggung-jawab-mahad-head-journal-detail";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Detail Monitoring Jurnal Kepala Ma'had",
};

type PageProps = {
  params:
    Promise<{
      journalId:
        string;
    }>;
};

function formatDate(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle:
        "long",

      timeZone:
        "Asia/Makassar",
    },
  ).format(
    new Date(
      `${value}T00:00:00+08:00`,
    ),
  );
}

export default async function PenanggungJawabJournalDetailPage({
  params,
}: PageProps) {
  await requireRole(
    "penanggung_jawab",
  );

  const {
    journalId,
  } =
    await params;

  const validation =
    z.string()
      .uuid()
      .safeParse(
        journalId,
      );

  if (
    !validation.success
  ) {
    notFound();
  }

  let data;

  try {
    data =
      await getPenanggungJawabMahadHeadJournalDetail(
        validation.data,
      );
  } catch {
    notFound();
  }

  const evidenceUrl =
    await createMahadHeadJournalEvidenceSignedUrl(
      data.journal.evidence_path,
    );

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <Link
        href="/penanggung-jawab/jurnal"
        className="text-sm font-semibold text-brand-700"
      >
        ← Kembali ke Monitoring
      </Link>

      <section className="mt-6 rounded-3xl border border-line bg-white p-6 shadow-soft">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Monitoring Read-only
        </p>

        <h1 className="mt-2 text-2xl font-bold text-ink">
          {formatDate(
            data.journal.journal_date,
          )}
        </h1>

        <p className="mt-3 text-sm font-semibold text-slate-700">
          {
            data.journal.staff.full_name
          }
        </p>

        {data.journal.staff.position && (
          <p className="mt-1 text-xs text-muted">
            {
              data.journal.staff.position
            }
          </p>
        )}

        <span className="mt-4 inline-flex rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
          Sudah Dikirim
        </span>
      </section>

      <section className="mt-6 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Bukti Kinerja
        </p>

        {data.journal.has_evidence ? (
          evidenceUrl ? (
            <a
              href={
                evidenceUrl
              }
              target="_blank"
              rel="noreferrer"
              className="mt-4 inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white"
            >
              Lihat Bukti
            </a>
          ) : (
            <p className="mt-3 text-sm text-red-600">
              Bukti tersedia tetapi
              tidak dapat dibuka saat
              ini.
            </p>
          )
        ) : (
          <p className="mt-3 text-sm text-muted">
            Kepala Ma&apos;had tidak
            mengunggah bukti pada
            jurnal ini.
          </p>
        )}
      </section>

      <div className="mt-6">
        <MahadHeadJournalReadOnly
          checklist={
            data.checklist
          }
          performanceNotes={
            data.journal.performance_notes
          }
          obstaclesFollowUp={
            data.journal.obstacles_follow_up
          }
        />
      </div>
    </div>
  );
}