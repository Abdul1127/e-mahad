import Link from "next/link";

import {
  PengasuhActivityAttendanceForm,
} from "./pengasuh-activity-attendance-form";

import type {
  PengasuhActivityScheduleDetailData,
} from "../schemas/pengasuh-activity-schema";

type Props = {
  data:
    PengasuhActivityScheduleDetailData;

  saved:
    boolean;
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

export function PengasuhActivityScheduleDetail({
  data,
  saved,
}: Props) {
  const {
    schedule,
    summary,
    students,
  } = data;

  return (
    <div className="mx-auto w-full max-w-6xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <Link
        href="/pengasuh/jadwal"
        className="text-sm font-semibold text-brand-700 transition hover:text-brand-800"
      >
        ← Kembali ke Jadwal
      </Link>

      {saved && (
        <div className="mt-5 rounded-xl border border-emerald-100 bg-emerald-50 p-4">
          <p className="text-sm font-semibold text-emerald-800">
            Absensi berhasil disimpan.
          </p>
        </div>
      )}

      <section className="mt-6 rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Jadwal Kegiatan
            </p>

            <h1 className="mt-2 text-3xl font-bold text-ink">
              {
                schedule.activity_name
              }
            </h1>

            <p className="mt-3 text-sm font-semibold text-ink">
              {formatDate(
                schedule.activity_date,
              )}
            </p>
          </div>

          <span className="rounded-full bg-brand-50 px-3 py-1.5 text-xs font-semibold text-brand-700">
            {statusLabel(
              schedule.status,
            )}
          </span>
        </div>

        <div className="mt-6 grid gap-4 border-t border-line pt-5 sm:grid-cols-2 lg:grid-cols-4">
          <div>
            <p className="text-xs text-muted">
              Kelompok
            </p>

            <p className="mt-1 font-semibold text-ink">
              {
                schedule.care_group
                  .name
              }
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Waktu
            </p>

            <p className="mt-1 font-semibold text-ink">
              {formatTime(
                schedule.start_time,
              )}

              {schedule.end_time
                ? ` – ${formatTime(
                    schedule.end_time,
                  )}`
                : ""}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Lokasi
            </p>

            <p className="mt-1 font-semibold text-ink">
              {schedule.location ??
                "-"}
            </p>
          </div>

          <div>
            <p className="text-xs text-muted">
              Jumlah Santri
            </p>

            <p className="mt-1 font-semibold text-ink">
              {
                summary.eligible_count
              }
            </p>
          </div>
        </div>

        {schedule.notes && (
          <div className="mt-5 border-t border-line pt-5">
            <p className="text-xs text-muted">
              Catatan Kegiatan
            </p>

            <p className="mt-2 whitespace-pre-wrap text-sm leading-7 text-ink">
              {
                schedule.notes
              }
            </p>
          </div>
        )}
      </section>

      <section className="mt-5 grid gap-3 sm:grid-cols-5">
        <div className="rounded-xl border border-line bg-white p-4">
          <p className="text-xs text-muted">
            Tercatat
          </p>

          <p className="mt-1 text-xl font-bold text-ink">
            {
              summary.recorded_count
            }
            /
            {
              summary.eligible_count
            }
          </p>
        </div>

        <div className="rounded-xl border border-emerald-100 bg-emerald-50 p-4">
          <p className="text-xs text-emerald-700">
            Hadir
          </p>

          <p className="mt-1 text-xl font-bold text-emerald-900">
            {
              summary.present_count
            }
          </p>
        </div>

        <div className="rounded-xl border border-blue-100 bg-blue-50 p-4">
          <p className="text-xs text-blue-700">
            Izin
          </p>

          <p className="mt-1 text-xl font-bold text-blue-900">
            {
              summary.permission_count
            }
          </p>
        </div>

        <div className="rounded-xl border border-amber-100 bg-amber-50 p-4">
          <p className="text-xs text-amber-700">
            Sakit
          </p>

          <p className="mt-1 text-xl font-bold text-amber-900">
            {
              summary.sick_count
            }
          </p>
        </div>

        <div className="rounded-xl border border-red-100 bg-red-50 p-4">
          <p className="text-xs text-red-700">
            Alpa
          </p>

          <p className="mt-1 text-xl font-bold text-red-900">
            {
              summary.absent_count
            }
          </p>
        </div>
      </section>

      <section className="mt-7">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Santri
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Absensi Kegiatan
          </h2>
        </div>

        {schedule.status ===
        "cancelled" ? (
          <div className="mt-5 rounded-2xl border border-red-100 bg-red-50 p-5">
            <p className="font-semibold text-red-800">
              Jadwal dibatalkan
            </p>

            <p className="mt-1 text-sm text-red-700">
              Absensi tidak dapat
              dicatat pada kegiatan
              yang dibatalkan.
            </p>
          </div>
        ) : !schedule.can_record_attendance ? (
          <div className="mt-5 rounded-2xl border border-blue-100 bg-blue-50 p-5">
            <p className="font-semibold text-blue-800">
              Absensi belum dapat diisi
            </p>

            <p className="mt-1 text-sm leading-6 text-blue-700">
              Kegiatan ini belum
              berlangsung. Absensi
              dapat diisi pada tanggal
              kegiatan atau setelahnya.
            </p>
          </div>
        ) : students.length ===
          0 ? (
          <div className="mt-5 rounded-2xl border border-dashed border-line bg-white p-8 text-center">
            <p className="font-semibold text-ink">
              Tidak ada santri dalam
              kelompok ini.
            </p>
          </div>
        ) : (
          <div className="mt-5">
            <PengasuhActivityAttendanceForm
              scheduleId={
                schedule.id
              }
              students={
                students
              }
            />
          </div>
        )}
      </section>
    </div>
  );
}