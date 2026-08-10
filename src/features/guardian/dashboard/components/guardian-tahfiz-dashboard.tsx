import Link from "next/link";

import type {
  GuardianTahfizDashboardChild,
  GuardianTahfizDashboardData,
} from "../schemas/guardian-tahfiz-dashboard-schema";

type Props = {
  data:
    GuardianTahfizDashboardData;
};

function formatDate(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day: "2-digit",
      month: "long",
      year: "numeric",
    },
  ).format(
    new Date(
      `${value}T00:00:00Z`,
    ),
  );
}

function formatDateTime(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle: "medium",
      timeStyle: "short",
    },
  ).format(
    new Date(
      value,
    ),
  );
}

function getGenderLabel(
  gender:
    "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

function getRatingLabel(
  rating:
    | "excellent"
    | "good"
    | "fair"
    | "needs_guidance"
    | null,
): string {
  switch (
    rating
  ) {
    case "excellent":
      return "Sangat Baik";

    case "good":
      return "Baik";

    case "fair":
      return "Cukup";

    case "needs_guidance":
      return "Perlu Bimbingan";

    default:
      return "-";
  }
}

function getRelationshipLabel(
  value:
    string,
): string {
  switch (
    value
      .trim()
      .toLowerCase()
  ) {
    case "father":
      return "Ayah";

    case "mother":
      return "Ibu";

    case "parent":
      return "Orang Tua";

    case "guardian":
      return "Wali";

    default:
      return value;
  }
}

function ChildCard({
  child,
}: {
  child:
    GuardianTahfizDashboardChild;
}) {
  const report =
    child.latest_report;

  return (
    <article className="overflow-hidden rounded-3xl border border-line bg-white shadow-soft">
      {/* STUDENT */}

      <div className="border-b border-line p-5 sm:p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <div className="flex flex-wrap items-center gap-2">
              <h2 className="text-2xl font-bold text-ink">
                {
                  child.student
                    .full_name
                }
              </h2>

              <span className="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-700">
                {getGenderLabel(
                  child.student
                    .gender,
                )}
              </span>

              {child.relationship
                .is_primary_contact && (
                <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">
                  Kontak Utama
                </span>
              )}
            </div>

            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-400">
              {child.student
                .nis && (
                <span>
                  NIS{" "}
                  {
                    child.student
                      .nis
                  }
                </span>
              )}

              {child.class && (
                <span>
                  Kelas{" "}
                  {
                    child.class
                      .name
                  }
                </span>
              )}

              <span>
                Hubungan:{" "}
                {getRelationshipLabel(
                  child.relationship
                    .type,
                )}
              </span>
            </div>
          </div>

          <div className="w-fit rounded-2xl bg-brand-50 px-4 py-3 text-right">
            <p className="text-xs font-medium text-brand-600">
              Laporan Published
            </p>

            <p className="mt-1 text-2xl font-bold text-brand-900">
              {
                child.summary
                  .published_report_count
              }
            </p>
          </div>
        </div>

        {/* TAHFIZ GROUP */}

        <div className="mt-5 rounded-2xl bg-slate-50 p-4">
          <p className="text-xs font-medium text-muted">
            Kelompok Tahfiz
          </p>

          {child.tahfiz_group ? (
            <>
              <p className="mt-1 font-semibold text-ink">
                {
                  child.tahfiz_group
                    .name
                }
              </p>

              <p className="mt-1 text-xs text-slate-400">
                {
                  child.tahfiz_group
                    .code
                }
              </p>
            </>
          ) : (
            <p className="mt-1 text-sm font-medium text-muted">
              Belum tersedia
            </p>
          )}
        </div>

        {/* HISTORY BUTTON */}

        <Link
          href={`/wali/tahfiz/${child.student.id}`}
          className="mt-4 inline-flex min-h-11 w-full items-center justify-center rounded-xl border border-brand-200 bg-white px-5 text-sm font-semibold text-brand-700 transition hover:bg-brand-50 sm:w-auto"
        >
          Lihat Semua Riwayat Tahfiz
        </Link>
      </div>

      {/* NO REPORT */}

      {report === null ? (
        <div className="p-5 sm:p-6">
          <div className="rounded-2xl border border-dashed border-line bg-slate-50 p-6 text-center">
            <h3 className="font-bold text-ink">
              Belum ada laporan Tahfiz yang dipublikasikan
            </h3>

            <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-muted">
              Laporan Tahfiz akan
              tampil di sini setelah
              Pembina Tahfiz
              mempublikasikannya.
            </p>
          </div>
        </div>
      ) : (
        <div className="p-5 sm:p-6">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
                Laporan Tahfiz Terbaru
              </p>

              <h3 className="mt-2 text-xl font-bold text-ink">
                {formatDate(
                  report.week_start,
                )}
                {" – "}
                {formatDate(
                  report.week_end,
                )}
              </h3>
            </div>

            <span className="w-fit rounded-full bg-emerald-50 px-3 py-1.5 text-xs font-semibold text-emerald-700">
              Published
            </span>
          </div>

          <div className="mt-5 grid gap-4 lg:grid-cols-2">
            <div className="rounded-2xl border border-line bg-white p-4">
              <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                Capaian Hafalan Baru
              </p>

              <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-ink">
                {
                  report
                    .memorization_achievement ??
                  "-"
                }
              </p>
            </div>

            <div className="rounded-2xl border border-line bg-white p-4">
              <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
                Capaian Murajaah
              </p>

              <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-ink">
                {
                  report
                    .murajaah_achievement ??
                  "-"
                }
              </p>
            </div>
          </div>

          <div className="mt-4 grid gap-3 sm:grid-cols-3">
            <div className="rounded-2xl bg-slate-50 p-4">
              <p className="text-xs text-muted">
                Kelancaran
              </p>

              <p className="mt-2 font-bold text-ink">
                {getRatingLabel(
                  report
                    .fluency_rating,
                )}
              </p>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <p className="text-xs text-muted">
                Tajwid
              </p>

              <p className="mt-2 font-bold text-ink">
                {getRatingLabel(
                  report
                    .tajwid_rating,
                )}
              </p>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <p className="text-xs text-muted">
                Konsistensi
              </p>

              <p className="mt-2 font-bold text-ink">
                {getRatingLabel(
                  report
                    .consistency_rating,
                )}
              </p>
            </div>
          </div>

          <div className="mt-4 grid gap-4 lg:grid-cols-2">
            <div className="rounded-2xl border border-line bg-white p-4">
              <p className="text-xs font-semibold text-slate-500">
                Catatan Pembina
              </p>

              <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-ink">
                {
                  report
                    .supervisor_notes ??
                  "-"
                }
              </p>
            </div>

            <div className="rounded-2xl border border-brand-100 bg-brand-50 p-4">
              <p className="text-xs font-semibold text-brand-700">
                Target Pekan Berikutnya
              </p>

              <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-brand-950">
                {
                  report
                    .next_week_target ??
                  "-"
                }
              </p>
            </div>
          </div>

          <div className="mt-4 border-t border-line pt-4">
            <p className="text-xs text-slate-400">
              Dipublikasikan{" "}
              {formatDateTime(
                report
                  .published_at,
              )}
            </p>
          </div>
        </div>
      )}
    </article>
  );
}

export function GuardianTahfizDashboard({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Orang Tua / Wali
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Selamat datang,{" "}
          {
            data.guardian
              .full_name
          }
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Pantau perkembangan Tahfiz
          anak melalui laporan yang
          telah dipublikasikan oleh
          Pembina Tahfiz.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
            Tahun Ajaran{" "}
            {
              data.academic_year
                .name
            }
          </span>

          {data.profile
            .login_id && (
            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              ID Login{" "}
              {
                data.profile
                  .login_id
              }
            </span>
          )}
        </div>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2">
        <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <p className="text-xs font-medium text-brand-700">
            Anak Terhubung
          </p>

          <p className="mt-2 text-3xl font-bold text-brand-900">
            {
              data.summary
                .child_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Laporan Tahfiz Published
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {
              data.summary
                .published_report_count
            }
          </p>
        </div>
      </section>

      <section className="mt-7">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Perkembangan Tahfiz
        </p>

        <h2 className="mt-2 text-2xl font-bold text-ink">
          Anak Saya
        </h2>

        {data.children.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Belum ada anak yang terhubung
            </h3>

            <p className="mx-auto mt-2 max-w-xl text-sm leading-6 text-muted">
              Akun Wali ini belum
              memiliki relasi dengan
              data santri.
            </p>
          </div>
        ) : (
          <div className="mt-5 space-y-5">
            {data.children.map(
              (child) => (
                <ChildCard
                  key={
                    child.student
                      .id
                  }
                  child={child}
                />
              ),
            )}
          </div>
        )}
      </section>

      <section className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-4 sm:p-5">
        <p className="font-semibold text-blue-800">
          Informasi yang ditampilkan
        </p>

        <p className="mt-1 max-w-4xl text-sm leading-6 text-blue-700">
          Dashboard Orang Tua/Wali
          hanya menampilkan
          perkembangan Tahfiz anak
          yang terhubung dengan akun
          ini dan hanya laporan yang
          sudah dipublikasikan oleh
          Pembina Tahfiz.
        </p>
      </section>
    </div>
  );
}