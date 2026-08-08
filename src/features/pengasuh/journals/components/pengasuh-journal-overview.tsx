import Link from "next/link";

import type {
  CareJournalSession,
  CareJournalStatus,
  PengasuhJournalOverviewData,
  PengasuhJournalOverviewGroup,
  PengasuhJournalOverviewItem,
} from "../schemas/pengasuh-journal-overview-schema";

import {
  CreateJournalButton,
} from "./create-journal-button";

type PengasuhJournalOverviewProps = {
  data:
    PengasuhJournalOverviewData;
};

const numberFormatter =
  new Intl.NumberFormat(
    "id-ID",
  );

function formatDate(
  value: string,
): string {
  const [
    year,
    month,
    day,
  ] = value
    .split("-")
    .map(Number);

  if (
    !year ||
    !month ||
    !day
  ) {
    return value;
  }

  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle:
        "full",

      timeZone:
        "Asia/Jakarta",
    },
  ).format(
    new Date(
      Date.UTC(
        year,
        month - 1,
        day,
      ),
    ),
  );
}

function getSessionLabel(
  session:
    CareJournalSession,
): string {
  return session ===
    "morning"
    ? "Pagi"
    : "Sore";
}

function getStatusLabel(
  status:
    CareJournalStatus,
): string {
  switch (
    status
  ) {
    case "draft":
      return "Draft";

    case "submitted":
      return "Menunggu Review";

    case "revision_requested":
      return "Perlu Revisi";

    case "reviewed":
      return "Sudah Direview";
  }
}

function getStatusClassName(
  status:
    CareJournalStatus,
): string {
  switch (
    status
  ) {
    case "draft":
      return "bg-slate-100 text-slate-700";

    case "submitted":
      return "bg-blue-50 text-blue-700";

    case "revision_requested":
      return "bg-amber-50 text-amber-700";

    case "reviewed":
      return "bg-emerald-50 text-emerald-700";
  }
}

function ExistingJournalCard({
  journal,
  studentCount,
}: {
  journal:
    PengasuhJournalOverviewItem;

  studentCount:
    number;
}) {
  const isComplete =
    journal.complete_entry_count ===
      studentCount &&
    studentCount > 0;

  return (
    <div className="rounded-2xl border border-line bg-white p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
            Sesi{" "}
            {getSessionLabel(
              journal.session,
            )}
          </p>

          <p className="mt-2 text-sm font-semibold text-ink">
            Jurnal sudah dibuat
          </p>
        </div>

        <span
          className={`rounded-full px-2.5 py-1 text-[11px] font-semibold ${getStatusClassName(
            journal.status,
          )}`}
        >
          {getStatusLabel(
            journal.status,
          )}
        </span>
      </div>

      <div className="mt-4 rounded-xl bg-slate-50 p-3">
        <div className="flex items-end justify-between gap-3">
          <div>
            <p className="text-xs text-slate-500">
              Kelengkapan
            </p>

            <p className="mt-1 text-lg font-bold text-ink">
              {
                journal.complete_entry_count
              }
              {" / "}
              {
                studentCount
              }
            </p>
          </div>

          <p className="text-xs font-semibold text-slate-500">
            {isComplete
              ? "Lengkap"
              : "Belum lengkap"}
          </p>
        </div>

        <div className="mt-3 h-2 overflow-hidden rounded-full bg-slate-200">
          <div
            className="h-full rounded-full bg-brand-600"
            style={{
              width:
                studentCount >
                0
                  ? `${Math.min(
                      100,
                      Math.round(
                        (
                          journal.complete_entry_count /
                          studentCount
                        ) *
                          100,
                      ),
                    )}%`
                  : "0%",
            }}
          />
        </div>
      </div>

      <Link
        href={`/pengasuh/jurnal/${journal.id}`}
        className="mt-4 inline-flex min-h-11 w-full items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
      >
        {journal.status ===
        "submitted"
          ? "Lihat Jurnal"
          : journal.status ===
              "reviewed"
            ? "Lihat / Perbaiki"
            : "Lanjutkan Jurnal"}
      </Link>
    </div>
  );
}

function EmptyJournalCard({
  careGroupId,
  journalDate,
  session,
}: {
  careGroupId:
    string;

  journalDate:
    string;

  session:
    CareJournalSession;
}) {
  return (
    <div className="rounded-2xl border border-dashed border-line bg-slate-50/60 p-4">
      <p className="text-xs font-semibold uppercase tracking-[0.12em] text-slate-400">
        Sesi{" "}
        {getSessionLabel(
          session,
        )}
      </p>

      <h3 className="mt-2 font-semibold text-ink">
        Belum ada jurnal
      </h3>

      <p className="mt-2 text-sm leading-6 text-muted">
        Buat jurnal untuk
        mengisi kondisi
        seluruh santri pada
        sesi ini.
      </p>

      <div className="mt-4">
        <CreateJournalButton
          careGroupId={
            careGroupId
          }
          journalDate={
            journalDate
          }
          session={
            session
          }
        />
      </div>
    </div>
  );
}

function GroupJournalCard({
  group,
  selectedDate,
}: {
  group:
    PengasuhJournalOverviewGroup;

  selectedDate:
    string;
}) {
  const morningJournal =
    group.journals.find(
      (journal) =>
        journal.session ===
        "morning",
    );

  const eveningJournal =
    group.journals.find(
      (journal) =>
        journal.session ===
        "evening",
    );

  return (
    <article className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex flex-wrap gap-2">
            <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
              {group.gender ===
              "male"
                ? "Putra"
                : "Putri"}
            </span>

            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-500">
              {
                group.code
              }
            </span>
          </div>

          <h2 className="mt-3 text-xl font-bold text-ink">
            {
              group.name
            }
          </h2>

          <p className="mt-2 text-sm text-muted">
            {
              numberFormatter.format(
                group.active_student_count,
              )
            }{" "}
            santri aktif
          </p>
        </div>

        <div className="rounded-2xl bg-brand-50 px-4 py-3">
          <p className="text-xs font-medium text-brand-600">
            Jurnal tanggal ini
          </p>

          <p className="mt-1 text-xl font-bold text-brand-900">
            {
              group.journals
                .length
            }
            {" / 2"}
          </p>
        </div>
      </div>

      <div className="mt-5 grid gap-4 md:grid-cols-2">
        {morningJournal ? (
          <ExistingJournalCard
            journal={
              morningJournal
            }
            studentCount={
              group.active_student_count
            }
          />
        ) : (
          <EmptyJournalCard
            careGroupId={
              group.id
            }
            journalDate={
              selectedDate
            }
            session="morning"
          />
        )}

        {eveningJournal ? (
          <ExistingJournalCard
            journal={
              eveningJournal
            }
            studentCount={
              group.active_student_count
            }
          />
        ) : (
          <EmptyJournalCard
            careGroupId={
              group.id
            }
            journalDate={
              selectedDate
            }
            session="evening"
          />
        )}
      </div>
    </article>
  );
}

export function PengasuhJournalOverview({
  data,
}: PengasuhJournalOverviewProps) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pengasuhan
        </p>

        <div className="mt-2 flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight text-ink">
              Jurnal Pengasuhan
            </h1>

            <p className="mt-3 max-w-2xl text-sm leading-7 text-muted">
              Catat kondisi
              harian santri pada
              sesi pagi dan sore
              sesuai kelompok
              pengasuhan Anda.
            </p>

            <p className="mt-2 text-sm font-semibold text-slate-600">
              {formatDate(
                data.selected_date,
              )}
            </p>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50 px-5 py-3">
            <p className="text-xs font-medium text-brand-600">
              Tahun Ajaran
            </p>

            <p className="mt-1 font-bold text-brand-900">
              {
                data.academic_year
                  .name
              }
            </p>
          </div>
        </div>
      </section>

      <section className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          action="/pengasuh/jurnal"
          method="get"
          className="flex flex-col gap-3 sm:flex-row sm:items-end"
        >
          <div className="flex-1">
            <label
              htmlFor="date"
              className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
            >
              Tanggal Jurnal
            </label>

            <input
              id="date"
              name="date"
              type="date"
              defaultValue={
                data.selected_date
              }
              min={
                data.academic_year
                  .start_date
              }
              max={
                data.academic_year
                  .end_date
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />
          </div>

          <button
            type="submit"
            className="min-h-11 rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100"
          >
            Tampilkan
          </button>
        </form>
      </section>

      <section className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <article className="rounded-2xl border border-line bg-white p-4 shadow-soft">
          <p className="text-xs text-muted">
            Total Jurnal
          </p>

          <p className="mt-2 text-2xl font-bold text-ink">
            {
              data.summary
                .journal_count
            }
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-4 shadow-soft">
          <p className="text-xs text-muted">
            Draft
          </p>

          <p className="mt-2 text-2xl font-bold text-slate-700">
            {
              data.summary
                .draft_count
            }
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-4 shadow-soft">
          <p className="text-xs text-muted">
            Menunggu Review
          </p>

          <p className="mt-2 text-2xl font-bold text-blue-700">
            {
              data.summary
                .submitted_count
            }
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-4 shadow-soft">
          <p className="text-xs text-muted">
            Perlu Revisi
          </p>

          <p className="mt-2 text-2xl font-bold text-amber-700">
            {
              data.summary
                .revision_requested_count
            }
          </p>
        </article>
      </section>

      {data.groups.length ===
      0 ? (
        <section className="mt-6 rounded-3xl border border-dashed border-amber-300 bg-amber-50 p-8 text-center">
          <h2 className="font-bold text-amber-800">
            Belum ada
            assignment kelompok
          </h2>

          <p className="mt-2 text-sm text-amber-700">
            Hubungi Admin untuk
            menentukan kelompok
            pengasuhan.
          </p>
        </section>
      ) : (
        <section className="mt-6 space-y-5">
          {data.groups.map(
            (group) => (
              <GroupJournalCard
                key={
                  group.id
                }
                group={
                  group
                }
                selectedDate={
                  data.selected_date
                }
              />
            ),
          )}
        </section>
      )}
    </div>
  );
}