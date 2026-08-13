import Link from "next/link";

import type {
  PenanggungJawabCareRecentItem,
  PenanggungJawabDormitoryMonitoringData,
  PenanggungJawabTahfizGroupSummary,
} from "../schemas/penanggung-jawab-dormitory-monitoring-schema";

type Props = {
  data:
    PenanggungJawabDormitoryMonitoringData;
};

function formatDate(
  value:
    string | null,
): string {
  if (!value) {
    return "-";
  }

  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day:
        "2-digit",

      month:
        "long",

      year:
        "numeric",

      timeZone:
        "Asia/Makassar",
    },
  ).format(
    new Date(
      `${value}T00:00:00+08:00`,
    ),
  );
}

function formatDateTime(
  value:
    string | null,
): string {
  if (!value) {
    return "-";
  }

  const date =
    new Date(
      value,
    );

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return "-";
  }

  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle:
        "medium",

      timeStyle:
        "short",

      timeZone:
        "Asia/Makassar",
    },
  ).format(
    date,
  );
}

function genderLabel(
  value:
    "male" | "female",
): string {
  return value ===
    "male"
    ? "Putra"
    : "Putri";
}

function sessionLabel(
  value:
    string,
): string {
  switch (
    value
  ) {
    case "morning":
      return "Pagi";

    case "evening":
      return "Malam";

    default:
      return value;
  }
}

function careStatusLabel(
  value:
    PenanggungJawabCareRecentItem["status"],
): string {
  switch (
    value
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

function careStatusClassName(
  value:
    PenanggungJawabCareRecentItem["status"],
): string {
  switch (
    value
  ) {
    case "draft":
      return "bg-slate-100 text-slate-600";

    case "submitted":
      return "bg-blue-50 text-blue-700";

    case "revision_requested":
      return "bg-amber-50 text-amber-700";

    case "reviewed":
      return "bg-emerald-50 text-emerald-700";
  }
}

function SummaryCard({
  label,
  value,
  helper,
}: {
  label:
    string;

  value:
    string | number;

  helper?:
    string;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
      <p className="text-xs font-semibold uppercase tracking-[0.12em] text-slate-400">
        {label}
      </p>

      <p className="mt-3 text-3xl font-bold tracking-tight text-ink">
        {value}
      </p>

      {helper && (
        <p className="mt-2 text-xs leading-5 text-muted">
          {helper}
        </p>
      )}
    </article>
  );
}

function ProgressBar({
  value,
}: {
  value:
    number;
}) {
  const normalizedValue =
    Math.min(
      Math.max(
        value,
        0,
      ),
      100,
    );

  return (
    <div
      className="h-2 overflow-hidden rounded-full bg-slate-100"
      aria-label={`Progres ${normalizedValue}%`}
    >
      <div
        className="h-full rounded-full bg-brand-600 transition-all"
        style={{
          width:
            `${normalizedValue}%`,
        }}
      />
    </div>
  );
}

function CareJournalItem({
  item,
}: {
  item:
    PenanggungJawabCareRecentItem;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <p className="font-bold text-ink">
              {
                item.care_group
                  .name
              }
            </p>

            <span className="rounded-full bg-slate-100 px-2.5 py-1 text-[11px] font-semibold text-slate-600">
              {genderLabel(
                item.care_group
                  .gender,
              )}
            </span>
          </div>

          <p className="mt-2 text-sm text-muted">
            {formatDate(
              item.journal_date,
            )}
            {" · "}
            {sessionLabel(
              item.session,
            )}
          </p>
        </div>

        <span
          className={`w-fit rounded-full px-3 py-1 text-xs font-semibold ${careStatusClassName(
            item.status,
          )}`}
        >
          {careStatusLabel(
            item.status,
          )}
        </span>
      </div>

      <div className="mt-4 grid grid-cols-2 gap-3">
        <div className="rounded-xl bg-slate-50 p-3">
          <p className="text-xs text-muted">
            Santri tercatat
          </p>

          <p className="mt-1 text-lg font-bold text-ink">
            {
              item.entry_count
            }
          </p>
        </div>

        <div
          className={
            item.attention_student_count >
            0
              ? "rounded-xl bg-amber-50 p-3"
              : "rounded-xl bg-emerald-50 p-3"
          }
        >
          <p
            className={
              item.attention_student_count >
              0
                ? "text-xs text-amber-700"
                : "text-xs text-emerald-700"
            }
          >
            Perlu perhatian
          </p>

          <p
            className={
              item.attention_student_count >
              0
                ? "mt-1 text-lg font-bold text-amber-900"
                : "mt-1 text-lg font-bold text-emerald-900"
            }
          >
            {
              item.attention_student_count
            }
          </p>
        </div>
      </div>
    </article>
  );
}

function TahfizGroupItem({
  group,
}: {
  group:
    PenanggungJawabTahfizGroupSummary;
}) {
  const percentage =
    group.student_count >
    0
      ? Math.round(
          (
            group.published_count /
            group.student_count
          ) *
            100,
        )
      : 0;

  return (
    <article className="rounded-2xl border border-line bg-white p-4">
      <div className="flex items-start justify-between gap-3">
        <div>
          <p className="font-bold text-ink">
            {
              group.name
            }
          </p>

          <p className="mt-1 text-xs text-muted">
            {genderLabel(
              group.gender,
            )}

            {group.grade_level !==
              null &&
              ` · Kelas ${group.grade_level}`}
          </p>
        </div>

        <span
          className={
            group.missing_count >
            0
              ? "rounded-full bg-amber-50 px-2.5 py-1 text-xs font-semibold text-amber-700"
              : "rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700"
          }
        >
          {percentage}%
        </span>
      </div>

      <div className="mt-4">
        <ProgressBar
          value={
            percentage
          }
        />
      </div>

      <div className="mt-3 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
        <span>
          Published{" "}
          <strong className="text-ink">
            {
              group.published_count
            }
          </strong>
          /
          {
            group.student_count
          }
        </span>

        <span>
          Belum{" "}
          <strong
            className={
              group.missing_count >
              0
                ? "text-amber-700"
                : "text-emerald-700"
            }
          >
            {
              group.missing_count
            }
          </strong>
        </span>
      </div>
    </article>
  );
}

export function PenanggungJawabDormitoryMonitoring({
  data,
}: Props) {
  const careSummary =
    data.care.summary;

  const headSummary =
    data.mahad_head_journal
      .summary;

  const tahfizSummary =
    data.tahfiz.summary;

  const latestHeadJournal =
    data.mahad_head_journal
      .latest_item;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* ===================================================
          HEADER
      =================================================== */}

      <section className="overflow-hidden rounded-3xl border border-brand-100 bg-white shadow-soft">
        <div className="grid gap-6 p-6 sm:p-8 xl:grid-cols-[minmax(0,1fr)_320px]">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Penanggung Jawab
            </p>

            <h1 className="mt-3 text-3xl font-bold tracking-tight text-ink sm:text-4xl">
              Monitoring Asrama
            </h1>

            <p className="mt-4 max-w-3xl leading-7 text-muted">
              Ringkasan kondisi
              operasional Ma&apos;had
              berdasarkan Jurnal
              Pengasuhan, Jurnal Kepala
              Ma&apos;had, dan laporan
              Tahfiz yang telah
              dipublikasikan.
            </p>

            <div className="mt-5 flex flex-wrap gap-2 text-xs font-semibold">
              <span className="rounded-full bg-brand-50 px-3 py-1.5 text-brand-700">
                Tahun Ajaran{" "}
                {
                  data.academic_year
                    .name
                }
              </span>

              <span className="rounded-full bg-slate-100 px-3 py-1.5 text-slate-600">
                {formatDate(
                  data.week.start,
                )}
                {" – "}
                {formatDate(
                  data.week.end,
                )}
              </span>
            </div>
          </div>

          <div className="rounded-2xl border border-blue-100 bg-blue-50 p-5">
            <p className="text-sm font-bold text-blue-900">
              Monitoring read-only
            </p>

            <p className="mt-2 text-sm leading-6 text-blue-700">
              Halaman ini tidak
              menyediakan fungsi input,
              edit, review, publish,
              maupun transaksi
              keuangan.
            </p>
          </div>
        </div>
      </section>

      {/* ===================================================
          EXECUTIVE SNAPSHOT
      =================================================== */}

      <section className="mt-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Ringkasan pekan berjalan
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Kondisi Operasional
          </h2>
        </div>

        <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <SummaryCard
            label="Jurnal Pengasuhan"
            value={
              careSummary.journal_count
            }
            helper={`${careSummary.group_count} kelompok pengasuhan aktif`}
          />

          <SummaryCard
            label="Perlu Tindak Lanjut"
            value={
              careSummary.follow_up_count
            }
            helper={`${careSummary.attention_student_count} santri terindikasi perlu perhatian`}
          />

          <SummaryCard
            label="Jurnal Kepala Ma'had"
            value={
              headSummary.submitted_count
            }
            helper="Jurnal submitted pekan berjalan"
          />

          <SummaryCard
            label="Laporan Tahfiz"
            value={`${tahfizSummary.completion_percentage}%`}
            helper={`${tahfizSummary.published_count} dari ${tahfizSummary.student_count} santri sudah published`}
          />
        </div>
      </section>

      {/* ===================================================
          CARE
      =================================================== */}

      <section className="mt-7 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Pengasuhan
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Monitoring Jurnal
              Pengasuhan
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
              Penanggung Jawab melihat
              status dan ringkasan
              operasional tanpa membuka
              catatan individual santri.
            </p>
          </div>

          <p className="text-sm text-muted">
            Jurnal terakhir:{" "}
            <strong className="text-ink">
              {formatDate(
                careSummary.latest_journal_date,
              )}
            </strong>
          </p>
        </div>

        <div className="mt-5 grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
          <div className="rounded-2xl bg-slate-50 p-4">
            <p className="text-xs text-muted">
              Draft
            </p>

            <p className="mt-1 text-2xl font-bold text-ink">
              {
                careSummary.draft_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-blue-50 p-4">
            <p className="text-xs text-blue-700">
              Menunggu Review
            </p>

            <p className="mt-1 text-2xl font-bold text-blue-900">
              {
                careSummary.pending_review_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-amber-50 p-4">
            <p className="text-xs text-amber-700">
              Perlu Revisi
            </p>

            <p className="mt-1 text-2xl font-bold text-amber-900">
              {
                careSummary.revision_requested_count
              }
            </p>
          </div>

          <div className="rounded-2xl bg-emerald-50 p-4">
            <p className="text-xs text-emerald-700">
              Sudah Direview
            </p>

            <p className="mt-1 text-2xl font-bold text-emerald-900">
              {
                careSummary.reviewed_count
              }
            </p>
          </div>

          <div
            className={
              careSummary.attention_student_count >
              0
                ? "rounded-2xl bg-red-50 p-4"
                : "rounded-2xl bg-emerald-50 p-4"
            }
          >
            <p
              className={
                careSummary.attention_student_count >
                0
                  ? "text-xs text-red-700"
                  : "text-xs text-emerald-700"
              }
            >
              Santri Perlu Perhatian
            </p>

            <p
              className={
                careSummary.attention_student_count >
                0
                  ? "mt-1 text-2xl font-bold text-red-900"
                  : "mt-1 text-2xl font-bold text-emerald-900"
              }
            >
              {
                careSummary.attention_student_count
              }
            </p>
          </div>
        </div>

        {data.care
          .recent_items.length >
        0 ? (
          <div className="mt-5 grid gap-4 lg:grid-cols-2">
            {data.care.recent_items.map(
              (
                item,
              ) => (
                <CareJournalItem
                  key={
                    item.id
                  }
                  item={
                    item
                  }
                />
              ),
            )}
          </div>
        ) : (
          <div className="mt-5 rounded-2xl border border-dashed border-line bg-slate-50 p-6 text-center">
            <p className="font-semibold text-ink">
              Belum ada jurnal
              pengasuhan pekan ini
            </p>

            <p className="mt-2 text-sm text-muted">
              Ringkasan akan muncul
              setelah Pengasuh mulai
              membuat jurnal.
            </p>
          </div>
        )}
      </section>

      {/* ===================================================
          HEAD JOURNAL
      =================================================== */}

      <section className="mt-7 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Kepala Ma&apos;had
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Jurnal Kepala
              Ma&apos;had
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
              Hanya jurnal yang sudah
              dikirim oleh Kepala
              Ma&apos;had yang
              ditampilkan kepada
              Penanggung Jawab.
            </p>
          </div>

          <Link
            href="/penanggung-jawab/jurnal"
            className="inline-flex min-h-10 w-fit items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
          >
            Buka Semua Jurnal
          </Link>
        </div>

        {latestHeadJournal ? (
          <div className="mt-5 grid gap-5 lg:grid-cols-[minmax(0,1fr)_320px]">
            <article className="rounded-2xl bg-slate-50 p-5">
              <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p className="text-xs font-semibold uppercase tracking-[0.12em] text-slate-400">
                    Jurnal terbaru
                  </p>

                  <p className="mt-2 text-xl font-bold text-ink">
                    {formatDate(
                      latestHeadJournal.journal_date,
                    )}
                  </p>

                  <p className="mt-2 text-sm text-muted">
                    {
                      latestHeadJournal
                        .staff
                        .full_name
                    }
                  </p>

                  {latestHeadJournal
                    .staff
                    .position && (
                    <p className="mt-1 text-xs text-muted">
                      {
                        latestHeadJournal
                          .staff
                          .position
                      }
                    </p>
                  )}
                </div>

                <span className="w-fit rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700">
                  Sudah Dikirim
                </span>
              </div>

              <div className="mt-5 grid gap-3 sm:grid-cols-2">
                <div className="rounded-xl bg-white p-4">
                  <p className="text-xs text-muted">
                    Dikirim
                  </p>

                  <p className="mt-1 text-sm font-bold text-ink">
                    {formatDateTime(
                      latestHeadJournal.submitted_at,
                    )}
                  </p>
                </div>

                <div className="rounded-xl bg-white p-4">
                  <p className="text-xs text-muted">
                    Bukti Kinerja
                  </p>

                  <p className="mt-1 text-sm font-bold text-ink">
                    {latestHeadJournal.has_evidence
                      ? "Tersedia"
                      : "Tidak ada"}
                  </p>
                </div>
              </div>

              <Link
                href={`/penanggung-jawab/jurnal/${latestHeadJournal.id}`}
                className="mt-5 inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
              >
                Lihat Detail Jurnal
              </Link>
            </article>

            <article className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
              <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                Penyelesaian Checklist
              </p>

              <div className="mt-4 flex items-end justify-between gap-4">
                <p className="text-4xl font-bold text-brand-950">
                  {
                    headSummary.latest_completion_percentage
                  }
                  %
                </p>

                <p className="text-sm font-semibold text-brand-700">
                  {
                    headSummary.latest_checked_count
                  }
                  /
                  {
                    headSummary.total_checklist_count
                  }
                </p>
              </div>

              <div className="mt-4">
                <ProgressBar
                  value={
                    headSummary.latest_completion_percentage
                  }
                />
              </div>

              <p className="mt-4 text-xs leading-5 text-brand-700">
                Progres dihitung dari
                checklist aktif yang
                ditandai pada jurnal
                terbaru.
              </p>
            </article>
          </div>
        ) : (
          <div className="mt-5 rounded-2xl border border-dashed border-line bg-slate-50 p-6 text-center">
            <p className="font-semibold text-ink">
              Belum ada jurnal yang
              dikirim pekan ini
            </p>

            <p className="mt-2 text-sm text-muted">
              Draft Kepala
              Ma&apos;had tidak
              ditampilkan kepada
              Penanggung Jawab.
            </p>
          </div>
        )}
      </section>

      {/* ===================================================
          TAHFIZ
      =================================================== */}

      <section className="mt-7 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Tahfiz
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Pelaporan Mingguan
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
              Monitoring kelengkapan
              laporan Tahfiz seluruh
              santri pada pekan
              berjalan.
            </p>
          </div>

          <Link
            href="/penanggung-jawab/tahfiz"
            className="inline-flex min-h-10 w-fit items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
          >
            Buka Monitoring Tahfiz
          </Link>
        </div>

        <div className="mt-5 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          <SummaryCard
            label="Santri Tahfiz"
            value={
              tahfizSummary.student_count
            }
            helper={`${tahfizSummary.group_count} kelompok aktif`}
          />

          <SummaryCard
            label="Sudah Published"
            value={
              tahfizSummary.published_count
            }
          />

          <SummaryCard
            label="Belum Published"
            value={
              tahfizSummary.missing_count
            }
          />

          <SummaryCard
            label="Perlu Bimbingan"
            value={
              tahfizSummary.attention_count
            }
          />
        </div>

        <div className="mt-5 rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <div className="flex items-end justify-between gap-4">
            <div>
              <p className="text-sm font-semibold text-brand-800">
                Kelengkapan laporan
                pekan ini
              </p>

              <p className="mt-1 text-xs text-brand-700">
                {
                  tahfizSummary.published_count
                }{" "}
                dari{" "}
                {
                  tahfizSummary.student_count
                }{" "}
                santri
              </p>
            </div>

            <p className="text-3xl font-bold text-brand-950">
              {
                tahfizSummary.completion_percentage
              }
              %
            </p>
          </div>

          <div className="mt-4">
            <ProgressBar
              value={
                tahfizSummary.completion_percentage
              }
            />
          </div>
        </div>

        {data.tahfiz
          .groups.length >
        0 && (
          <div className="mt-5 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {data.tahfiz.groups.map(
              (
                group,
              ) => (
                <TahfizGroupItem
                  key={
                    group.id
                  }
                  group={
                    group
                  }
                />
              ),
            )}
          </div>
        )}
      </section>

      {/* ===================================================
          SECURITY
      =================================================== */}

      <section className="mt-7 rounded-2xl border border-blue-100 bg-blue-50 p-5">
        <p className="font-semibold text-blue-900">
          Batas akses Penanggung Jawab
        </p>

        <p className="mt-2 max-w-4xl text-sm leading-6 text-blue-700">
          Monitoring Asrama hanya
          memberikan ringkasan
          Pengasuhan, jurnal Kepala
          Ma&apos;had yang sudah
          dikirim, dan laporan Tahfiz
          yang sudah dipublikasikan.
          Tidak ada informasi keuangan
          pada halaman ini.
        </p>
      </section>
    </div>
  );
}