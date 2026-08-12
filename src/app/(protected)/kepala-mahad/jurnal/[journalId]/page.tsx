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
  saveKepalaMahadJournalAction,
} from "@/features/kepala-mahad/journal/actions/save-kepala-mahad-journal-action";

import {
  KepalaMahadJournalForm,
} from "@/features/kepala-mahad/journal/components/kepala-mahad-journal-form";

import {
  MahadHeadJournalEvidenceUpload,
} from "@/features/kepala-mahad/journal/components/mahad-head-journal-evidence-upload";

import {
  MahadHeadJournalReadOnly,
} from "@/features/kepala-mahad/journal/components/mahad-head-journal-read-only";

import {
  createMahadHeadJournalEvidenceSignedUrl,
} from "@/features/kepala-mahad/journal/data/create-mahad-head-journal-evidence-signed-url";

import {
  getKepalaMahadJournalDetail,
} from "@/features/kepala-mahad/journal/data/get-kepala-mahad-journal-detail";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Detail Jurnal Kepala Ma'had",
};

type PageProps = {
  params:
    Promise<{
      journalId:
        string;
    }>;

  searchParams:
    Promise<{
      submitted?:
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

export default async function KepalaMahadJournalDetailPage({
  params,
  searchParams,
}: PageProps) {
  await requireRole(
    "kepala_mahad",
  );

  const {
    journalId,
  } =
    await params;

  const idValidation =
    z.string()
      .uuid()
      .safeParse(
        journalId,
      );

  if (
    !idValidation.success
  ) {
    notFound();
  }

  let data;

  try {
    data =
      await getKepalaMahadJournalDetail(
        idValidation.data,
      );
  } catch {
    notFound();
  }

  const query =
    await searchParams;

  const evidenceUrl =
    await createMahadHeadJournalEvidenceSignedUrl(
      data.journal.evidence_path,
    );

  const editable =
    data.journal.status ===
    "draft";

  const saveAction =
    saveKepalaMahadJournalAction.bind(
      null,
      data.journal.id,
    );

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <Link
        href="/kepala-mahad/jurnal"
        className="text-sm font-semibold text-brand-700"
      >
        ← Kembali ke Jurnal
      </Link>

      <section className="mt-6 flex flex-col gap-4 rounded-3xl border border-line bg-white p-6 shadow-soft sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Jurnal Kepala Ma&apos;had
          </p>

          <h1 className="mt-2 text-2xl font-bold text-ink">
            {formatDate(
              data.journal.journal_date,
            )}
          </h1>
        </div>

        <span
          className={
            editable
              ? "w-fit rounded-full bg-amber-50 px-3 py-1.5 text-xs font-semibold text-amber-700"
              : "w-fit rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700"
          }
        >
          {editable
            ? "Draft"
            : "Sudah Dikirim"}
        </span>
      </section>

      {query.submitted ===
        "1" && (
        <div className="mt-5 rounded-2xl border border-emerald-100 bg-emerald-50 p-4 text-sm text-emerald-700">
          Jurnal berhasil dikirim dan
          sekarang tersedia untuk
          monitoring Penanggung Jawab.
        </div>
      )}

      <section className="mt-6 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Bukti Kinerja
        </p>

        {data.journal.has_evidence ? (
          <div className="mt-3">
            <p className="text-sm text-muted">
              Bukti kinerja sudah
              tersimpan secara private.
            </p>

            {evidenceUrl ? (
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
              <p className="mt-3 text-xs text-red-600">
                Signed URL tidak dapat
                dibuat saat ini.
              </p>
            )}
          </div>
        ) : editable ? (
          <div className="mt-4">
            <MahadHeadJournalEvidenceUpload
              journalId={
                data.journal.id
              }
            />
          </div>
        ) : (
          <p className="mt-3 text-sm text-muted">
            Tidak ada bukti kinerja
            yang diunggah.
          </p>
        )}
      </section>

      <div className="mt-6">
        {editable ? (
          <KepalaMahadJournalForm
            data={
              data
            }
            action={
              saveAction
            }
          />
        ) : (
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
        )}
      </div>
    </div>
  );
}