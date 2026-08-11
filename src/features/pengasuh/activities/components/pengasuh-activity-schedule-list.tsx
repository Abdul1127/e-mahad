import Link from "next/link";

import type {
  PengasuhActivityScheduleListData,
} from "../schemas/pengasuh-activity-schema";

type Props = {
  data:
    PengasuhActivityScheduleListData;
};

function formatDate(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      weekday:
        "long",

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

function formatTime(
  value:
    string | null,
): string {
  if (!value) {
    return "-";
  }

  return value.slice(
    0,
    5,
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

function statusLabel(
  value:
    | "scheduled"
    | "completed"
    | "cancelled",
): string {
  switch (
    value
  ) {
    case "scheduled":
      return "Terjadwal";

    case "completed":
      return "Absensi Selesai";

    case "cancelled":
      return "Dibatalkan";
  }
}

function statusClassName(
  value:
    | "scheduled"
    | "completed"
    | "cancelled",
): string {
  switch (
    value
  ) {
    case "scheduled":
      return "bg-blue-50 text-blue-700";

    case "completed":
      return "bg-emerald-50 text-emerald-700";

    case "cancelled":
      return "bg-red-50 text-red-700";
  }
}

export function PengasuhActivityScheduleList({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="flex flex-col gap-5 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Pengasuhan
          </p>

          <h1 className="mt-2 text-3xl font-bold text-ink">
            Jadwal & Absensi
          </h1>

          <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
            Kelola kegiatan asrama dan
            absensi santri kelompok yang
            menjadi tanggung jawab Anda.
          </p>
        </div>

        <Link
          href="/pengasuh/jadwal/baru"
          className="inline-flex min-h-11 shrink-0 items-center justify-center rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
        >
          + Buat Jadwal
        </Link>
      </section>

      <section className="mt-6 grid gap-3 sm:grid-cols-4">
        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Jadwal Ditampilkan
          </p>

          <p className="mt-2 text-2xl font-bold text-ink">
            {
              data.summary
                .total_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-blue-100 bg-blue-50 p-5">
          <p className="text-xs text-blue-700">
            Hari Ini
          </p>

          <p className="mt-2 text-2xl font-bold text-blue-900">
            {
              data.summary
                .today_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
          <p className="text-xs text-emerald-700">
            Absensi Selesai
          </p>

          <p className="mt-2 text-2xl font-bold text-emerald-900">
            {
              data.summary
                .completed_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-red-100 bg-red-50 p-5">
          <p className="text-xs text-red-700">
            Dibatalkan
          </p>

          <p className="mt-2 text-2xl font-bold text-red-900">
            {
              data.summary
                .cancelled_count
            }
          </p>
        </div>
      </section>

      <section className="mt-4 rounded-xl bg-slate-50 px-4 py-3 text-xs text-muted">
        Periode yang ditampilkan:{" "}
        <strong className="text-ink">
          {formatDate(
            data.filters
              .date_from,
          )}
        </strong>{" "}
        sampai{" "}
        <strong className="text-ink">
          {formatDate(
            data.filters
              .date_to,
          )}
        </strong>
      </section>

      <section className="mt-7">
        {data.items.length ===
        0 ? (
          <div className="rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h2 className="text-lg font-bold text-ink">
              Belum ada jadwal
            </h2>

            <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-muted">
              Belum terdapat kegiatan
              pada periode yang sedang
              ditampilkan.
            </p>

            <Link
              href="/pengasuh/jadwal/baru"
              className="mt-5 inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white"
            >
              + Buat Jadwal Pertama
            </Link>
          </div>
        ) : (
          <div className="space-y-4">
            {data.items.map(
              (
                schedule,
              ) => {
                const attendanceComplete =
                  schedule.attendance
                    .eligible_count >
                    0 &&
                  schedule.attendance
                    .recorded_count >=
                    schedule.attendance
                      .eligible_count;

                return (
                  <article
                    key={
                      schedule.id
                    }
                    className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6"
                  >
                    <div className="flex flex-col gap-5 lg:flex-row lg:items-start lg:justify-between">
                      <div>
                        <div className="flex flex-wrap items-center gap-2">
                          <h2 className="text-lg font-bold text-ink">
                            {
                              schedule.activity_name
                            }
                          </h2>

                          <span
                            className={`rounded-full px-2.5 py-1 text-xs font-semibold ${statusClassName(
                              schedule.status,
                            )}`}
                          >
                            {statusLabel(
                              schedule.status,
                            )}
                          </span>
                        </div>

                        <p className="mt-2 text-sm font-semibold text-ink">
                          {formatDate(
                            schedule.activity_date,
                          )}
                        </p>

                        <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                          <span>
                            {formatTime(
                              schedule.start_time,
                            )}

                            {schedule.end_time
                              ? ` – ${formatTime(
                                  schedule.end_time,
                                )}`
                              : ""}
                          </span>

                          <span>
                            {
                              schedule.care_group
                                .name
                            }{" "}
                            (
                            {genderLabel(
                              schedule.care_group
                                .gender,
                            )}
                            )
                          </span>

                          {schedule.location && (
                            <span>
                              {
                                schedule.location
                              }
                            </span>
                          )}
                        </div>
                      </div>

                      <div className="rounded-xl bg-slate-50 p-4 lg:min-w-[220px]">
                        <p className="text-xs text-muted">
                          Absensi
                        </p>

                        <p className="mt-1 text-lg font-bold text-ink">
                          {
                            schedule.attendance
                              .recorded_count
                          }
                          {" / "}
                          {
                            schedule.attendance
                              .eligible_count
                          }
                        </p>

                        <p
                          className={
                            attendanceComplete
                              ? "mt-1 text-xs font-semibold text-emerald-700"
                              : "mt-1 text-xs text-muted"
                          }
                        >
                          {attendanceComplete
                            ? "Absensi lengkap"
                            : "Belum lengkap"}
                        </p>
                      </div>
                    </div>

                    {schedule.notes && (
                      <p className="mt-4 border-t border-line pt-4 text-sm leading-6 text-muted">
                        {
                          schedule.notes
                        }
                      </p>
                    )}

                    <div className="mt-5 flex justify-end border-t border-line pt-4">
                      <Link
                        href={`/pengasuh/jadwal/${schedule.id}`}
                        className="inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
                      >
                        Lihat Detail & Absensi
                      </Link>
                    </div>
                  </article>
                );
              },
            )}
          </div>
        )}
      </section>
    </div>
  );
}