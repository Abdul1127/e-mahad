import type {
  PengasuhDashboardData,
  PengasuhDashboardGroup,
  PengasuhDashboardMemberPreview,
} from "../schemas/pengasuh-dashboard-schema";

type PengasuhDashboardProps = {
  data:
    PengasuhDashboardData;
};

const numberFormatter =
  new Intl.NumberFormat(
    "id-ID",
  );

function getGenderLabel(
  gender:
    "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

function formatDate(
  value: string,
): string {
  const date =
    new Date(value);

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

      timeZone:
        "Asia/Jakarta",
    },
  ).format(date);
}

function StudentPreviewCard({
  student,
}: {
  student:
    PengasuhDashboardMemberPreview;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-4">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="font-semibold text-ink">
            {
              student.full_name
            }
          </p>

          <p className="mt-1 text-xs text-slate-400">
            ID{" "}
            {student.legacy_student_id ??
              "-"}

            {student.nis
              ? ` • NIS ${student.nis}`
              : ""}
          </p>
        </div>

        <span className="shrink-0 rounded-full bg-brand-50 px-2.5 py-1 text-[10px] font-semibold text-brand-700">
          {getGenderLabel(
            student.gender,
          )}
        </span>
      </div>

      <div className="mt-3 rounded-xl bg-slate-50 px-3 py-2.5">
        <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
          Kelas
        </p>

        <p className="mt-1 text-sm font-semibold text-slate-700">
          {student.class_name ??
            "Belum tersedia"}
        </p>

        {student.grade_level !==
          null && (
          <p className="mt-1 text-xs text-slate-400">
            Tingkat{" "}
            {
              student.grade_level
            }
          </p>
        )}
      </div>
    </article>
  );
}

function CareGroupCard({
  group,
}: {
  group:
    PengasuhDashboardGroup;
}) {
  return (
    <article className="overflow-hidden rounded-3xl border border-line bg-white shadow-soft">
      <div className="p-5 sm:p-6">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <div className="flex flex-wrap gap-2">
              <span className="rounded-full bg-brand-100 px-3 py-1 text-xs font-semibold text-brand-700">
                {getGenderLabel(
                  group.gender,
                )}
              </span>

              <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-500">
                {group.code}
              </span>
            </div>

            <h2 className="mt-3 text-xl font-bold text-ink">
              {group.name}
            </h2>

            <p className="mt-2 max-w-2xl text-sm leading-6 text-muted">
              {group.description ??
                "Kelompok pengasuhan yang menjadi tanggung jawab Anda."}
            </p>
          </div>

          <div className="rounded-2xl bg-brand-50 px-4 py-3 text-center">
            <p className="text-2xl font-bold text-brand-800">
              {numberFormatter.format(
                group.active_member_count,
              )}
            </p>

            <p className="mt-1 text-xs font-medium text-brand-600">
              Santri aktif
            </p>
          </div>
        </div>

        <div className="mt-5 border-t border-line pt-4">
          <p className="text-xs text-slate-500">
            Ditugaskan sejak{" "}
            <strong className="text-slate-700">
              {formatDate(
                group.assigned_at,
              )}
            </strong>
          </p>
        </div>
      </div>

      <div className="border-t border-line bg-slate-50/60 p-5 sm:p-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Santri Ampuan
          </p>

          <h3 className="mt-2 text-lg font-bold text-ink">
            Preview Santri
          </h3>

          <p className="mt-1 text-sm text-muted">
            Menampilkan beberapa santri
            aktif dari kelompok Anda.
          </p>
        </div>

        {group.member_preview.length ===
        0 ? (
          <div className="mt-4 rounded-2xl border border-dashed border-line bg-white p-5 text-sm text-muted">
            Belum ada santri aktif pada
            kelompok ini.
          </div>
        ) : (
          <div className="mt-4 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {group.member_preview.map(
              (student) => (
                <StudentPreviewCard
                  key={
                    student.membership_id
                  }
                  student={
                    student
                  }
                />
              ),
            )}
          </div>
        )}
      </div>
    </article>
  );
}

export function PengasuhDashboard({
  data,
}: PengasuhDashboardProps) {
  const {
    staff,
    academic_year:
      academicYear,
    summary,
  } = data;

  const hasOnlyMaleStudents =
    summary.male_student_count >
      0 &&
    summary.female_student_count ===
      0;

  const hasOnlyFemaleStudents =
    summary.female_student_count >
      0 &&
    summary.male_student_count ===
      0;

  const scopeLabel =
    hasOnlyMaleStudents
      ? "Santri Putra"
      : hasOnlyFemaleStudents
        ? "Santri Putri"
        : "Santri Ampuan";

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="overflow-hidden rounded-3xl border border-brand-100 bg-gradient-to-br from-brand-50 via-white to-white shadow-soft">
        <div className="p-6 sm:p-8 lg:p-10">
          <div className="flex flex-col gap-6 lg:flex-row lg:items-end lg:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
                Dashboard Pengasuh
              </p>

              <h1 className="mt-3 text-3xl font-bold tracking-tight text-ink sm:text-4xl">
                Assalamu&apos;alaikum,{" "}
                {staff.full_name}
              </h1>

              <p className="mt-3 max-w-2xl text-sm leading-7 text-muted sm:text-base">
                Pantau santri dan
                kelompok pengasuhan
                yang menjadi tanggung
                jawab Anda.
              </p>

              <div className="mt-5 flex flex-wrap gap-2">
                {data.profile.login_id && (
                  <span className="rounded-full border border-brand-100 bg-white px-3 py-1.5 text-xs font-semibold text-brand-700">
                    {
                      data.profile.login_id
                    }
                  </span>
                )}

                {staff.position && (
                  <span className="rounded-full border border-line bg-white px-3 py-1.5 text-xs font-semibold text-slate-600">
                    {
                      staff.position
                    }
                  </span>
                )}
              </div>
            </div>

            <div className="rounded-2xl border border-brand-100 bg-white/80 px-5 py-4 backdrop-blur">
              <p className="text-xs font-semibold text-brand-600">
                Tahun Ajaran Aktif
              </p>

              <p className="mt-1 text-lg font-bold text-brand-900">
                {
                  academicYear.name
                }
              </p>

              <p className="mt-1 text-xs text-brand-600">
                {formatDate(
                  academicYear.start_date,
                )}
                {" – "}
                {formatDate(
                  academicYear.end_date,
                )}
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Kelompok Saya
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.assigned_group_count,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            Assignment aktif
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Santri Ampuan
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_student_count,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            {scopeLabel}
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Santri Putra
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.male_student_count,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            Dalam kelompok Anda
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Santri Putri
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.female_student_count,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            Dalam kelompok Anda
          </p>
        </article>
      </section>

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Tanggung Jawab Saya
          </p>

          <h2 className="mt-2 text-2xl font-bold tracking-tight text-ink">
            Kelompok Pengasuhan
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
            Hanya kelompok yang
            mempunyai assignment aktif
            untuk akun Anda yang
            ditampilkan di sini.
          </p>
        </div>

        {data.groups.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-amber-300 bg-amber-50 p-8 text-center">
            <p className="font-semibold text-amber-800">
              Belum ada kelompok
              pengasuhan aktif.
            </p>

            <p className="mt-2 text-sm text-amber-700">
              Hubungi Admin apabila
              assignment kelompok belum
              ditentukan.
            </p>
          </div>
        ) : (
          <div className="mt-5 space-y-5">
            {data.groups.map(
              (group) => (
                <CareGroupCard
                  key={
                    group.assignment_id
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

      <section className="mt-8 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Tahap Berikutnya
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          Jurnal Pengasuhan
        </h2>

        <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
          Setelah dashboard ini selesai
          diverifikasi, modul berikutnya
          akan digunakan untuk mencatat
          kegiatan dan perkembangan
          pengasuhan santri.
        </p>
      </section>
    </div>
  );
}