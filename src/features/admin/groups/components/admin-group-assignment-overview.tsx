import type {
  AdminCareGroup,
  AdminGroupAssignmentOverviewData,
  AdminTahfizGroup,
} from "../schemas/admin-group-assignment-overview-schema";

type AdminGroupAssignmentOverviewProps = {
  data:
    AdminGroupAssignmentOverviewData;
};

const numberFormatter =
  new Intl.NumberFormat("id-ID");

function getGenderLabel(
  gender: "male" | "female",
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
      dateStyle: "medium",
      timeZone: "Asia/Jakarta",
    },
  ).format(date);
}

function CareGroupCard({
  group,
}: {
  group: AdminCareGroup;
}) {
  return (
    <article className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex flex-wrap items-center gap-2">
            <span className="rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700">
              {getGenderLabel(
                group.gender,
              )}
            </span>

            <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">
              {group.code}
            </span>
          </div>

          <h3 className="mt-3 text-xl font-bold text-ink">
            {group.name}
          </h3>

          <p className="mt-2 max-w-xl text-sm leading-6 text-muted">
            {group.description ??
              "Tidak ada deskripsi kelompok."}
          </p>
        </div>

        <span className="shrink-0 rounded-full bg-brand-100 px-3 py-1.5 text-xs font-semibold text-brand-700">
          {group.member_count} santri
        </span>
      </div>

      <div className="mt-5 grid gap-3 sm:grid-cols-3">
        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Anggota
          </p>

          <p className="mt-2 text-2xl font-bold text-ink">
            {numberFormatter.format(
              group.member_count,
            )}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Pengasuh
          </p>

          <p className="mt-2 text-2xl font-bold text-ink">
            {numberFormatter.format(
              group.caregiver_count,
            )}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Status
          </p>

          <p className="mt-2 text-sm font-bold text-brand-700">
            {group.caregiver_count >
            0
              ? "Assignment tersedia"
              : "Belum ada Pengasuh"}
          </p>
        </div>
      </div>

      <div className="mt-5 border-t border-line pt-5">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-400">
          Pengasuh aktif
        </p>

        {group.caregivers.length >
        0 ? (
          <div className="mt-3 grid gap-3 md:grid-cols-2">
            {group.caregivers.map(
              (caregiver) => (
                <div
                  key={
                    caregiver.assignment_id
                  }
                  className="rounded-2xl border border-line bg-slate-50/70 p-4"
                >
                  <div className="flex items-start justify-between gap-3">
                    <div className="min-w-0">
                      <p className="break-words text-sm font-bold text-slate-800">
                        {
                          caregiver.full_name
                        }
                      </p>

                      <p className="mt-1 text-xs text-slate-500">
                        ID Staf{" "}
                        {caregiver.legacy_staff_id ??
                          "-"}
                      </p>
                    </div>

                    {caregiver.is_primary && (
                      <span className="shrink-0 rounded-full bg-brand-100 px-2 py-1 text-[10px] font-bold uppercase tracking-wide text-brand-700">
                        Utama
                      </span>
                    )}
                  </div>

                  <p className="mt-3 text-xs text-slate-500">
                    Mulai assignment:{" "}
                    <strong className="text-slate-700">
                      {formatDate(
                        caregiver.assigned_at,
                      )}
                    </strong>
                  </p>
                </div>
              ),
            )}
          </div>
        ) : (
          <div className="mt-3 rounded-2xl border border-dashed border-amber-300 bg-amber-50 p-4 text-sm text-amber-700">
            Kelompok belum mempunyai
            Pengasuh aktif.
          </div>
        )}
      </div>
    </article>
  );
}

function TahfizGroupCard({
  group,
}: {
  group: AdminTahfizGroup;
}) {
  const primarySupervisor =
    group.supervisors.find(
      (supervisor) =>
        supervisor.is_primary,
    );

  return (
    <article className="rounded-3xl border border-line bg-white p-5 shadow-soft">
      <div className="flex items-start justify-between gap-4">
        <div>
          <div className="flex flex-wrap gap-2">
            <span className="rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700">
              {getGenderLabel(
                group.gender,
              )}
            </span>

            <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500">
              Kelas{" "}
              {group.grade_level ??
                "-"}
            </span>
          </div>

          <h3 className="mt-3 text-lg font-bold text-ink">
            {group.name}
          </h3>

          <p className="mt-1 text-xs text-slate-400">
            {group.code}
          </p>
        </div>

        <span className="shrink-0 rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
          {group.member_count} santri
        </span>
      </div>

      <p className="mt-4 text-sm leading-6 text-muted">
        {group.description ??
          "Tidak ada deskripsi kelompok."}
      </p>

      <div className="mt-5 grid grid-cols-2 gap-3">
        <div className="rounded-2xl bg-slate-50 p-3.5">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
            Anggota
          </p>

          <p className="mt-2 text-xl font-bold text-ink">
            {group.member_count}
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-3.5">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
            Pembina
          </p>

          <p className="mt-2 text-xl font-bold text-ink">
            {group.supervisor_count}
          </p>
        </div>
      </div>

      <div className="mt-5 border-t border-line pt-4">
        <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
          Pembina Tahfiz utama
        </p>

        {primarySupervisor ? (
          <div className="mt-3 rounded-2xl border border-brand-100 bg-brand-50 p-4">
            <p className="font-bold text-brand-900">
              {
                primarySupervisor.full_name
              }
            </p>

            <p className="mt-1 text-xs text-brand-700">
              ID Staf{" "}
              {primarySupervisor.legacy_staff_id ??
                "-"}
            </p>

            <p className="mt-2 text-xs text-brand-600">
              Sejak{" "}
              {formatDate(
                primarySupervisor.assigned_at,
              )}
            </p>
          </div>
        ) : (
          <div className="mt-3 rounded-2xl border border-dashed border-amber-300 bg-amber-50 p-4 text-sm text-amber-700">
            Pembina utama belum
            ditentukan.
          </div>
        )}

        {group.supervisors.length >
          1 && (
          <div className="mt-3 space-y-2">
            {group.supervisors
              .filter(
                (supervisor) =>
                  !supervisor.is_primary,
              )
              .map(
                (supervisor) => (
                  <div
                    key={
                      supervisor.assignment_id
                    }
                    className="rounded-xl border border-line px-3 py-2.5"
                  >
                    <p className="text-sm font-semibold text-slate-700">
                      {
                        supervisor.full_name
                      }
                    </p>

                    <p className="mt-1 text-xs text-slate-400">
                      Pembina tambahan
                    </p>
                  </div>
                ),
              )}
          </div>
        )}
      </div>
    </article>
  );
}

export function AdminGroupAssignmentOverview({
  data,
}: AdminGroupAssignmentOverviewProps) {
  const summary =
    data.summary;

  const totalAssignments =
    summary.active_caregiver_assignments +
    summary.active_tahfiz_assignments;

  const totalWarnings =
    summary.students_without_care_group +
    summary.students_without_tahfiz_group +
    summary.care_groups_without_caregiver +
    summary.tahfiz_groups_without_primary_supervisor;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Data master
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Kelompok & Assignment
        </h1>

        <p className="mt-3 max-w-3xl leading-7 text-muted">
          Pantau kelompok pengasuhan,
          kelompok tahfiz, jumlah santri,
          Pengasuh, dan Pembina Tahfiz
          pada tahun ajaran aktif.
        </p>

        <div className="mt-4 inline-flex rounded-full border border-brand-100 bg-brand-50 px-3 py-1.5 text-xs font-semibold text-brand-700">
          Tahun Ajaran{" "}
          {data.academic_year.name}
        </div>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Santri aktif
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_students,
            )}
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Kelompok pengasuhan
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_care_groups,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            {
              summary.active_caregiver_assignments
            }{" "}
            assignment Pengasuh
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Kelompok tahfiz
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_tahfiz_groups,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            {
              summary.active_tahfiz_assignments
            }{" "}
            assignment Pembina
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Assignment aktif
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              totalAssignments,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            Pengasuh dan Pembina Tahfiz
          </p>
        </article>
      </section>

      <section
        className={
          totalWarnings === 0
            ? "mt-6 rounded-3xl border border-brand-200 bg-brand-50 p-5 sm:p-6"
            : "mt-6 rounded-3xl border border-amber-200 bg-amber-50 p-5 sm:p-6"
        }
      >
        <div className="flex flex-col gap-5 xl:flex-row xl:items-center xl:justify-between">
          <div>
            <p
              className={
                totalWarnings === 0
                  ? "text-xs font-semibold uppercase tracking-[0.14em] text-brand-600"
                  : "text-xs font-semibold uppercase tracking-[0.14em] text-amber-700"
              }
            >
              Kesiapan assignment
            </p>

            <h2
              className={
                totalWarnings === 0
                  ? "mt-2 text-xl font-bold text-brand-900"
                  : "mt-2 text-xl font-bold text-amber-900"
              }
            >
              {totalWarnings === 0
                ? "Seluruh penempatan utama lengkap"
                : `${totalWarnings} perhatian ditemukan`}
            </h2>
          </div>

          <div className="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
            <div className="rounded-2xl bg-white/80 px-4 py-3">
              <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Tanpa Pengasuhan
              </p>

              <p className="mt-1 text-xl font-bold text-ink">
                {
                  summary.students_without_care_group
                }
              </p>
            </div>

            <div className="rounded-2xl bg-white/80 px-4 py-3">
              <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Tanpa Tahfiz
              </p>

              <p className="mt-1 text-xl font-bold text-ink">
                {
                  summary.students_without_tahfiz_group
                }
              </p>
            </div>

            <div className="rounded-2xl bg-white/80 px-4 py-3">
              <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Tanpa Pengasuh
              </p>

              <p className="mt-1 text-xl font-bold text-ink">
                {
                  summary.care_groups_without_caregiver
                }
              </p>
            </div>

            <div className="rounded-2xl bg-white/80 px-4 py-3">
              <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Tanpa Pembina Utama
              </p>

              <p className="mt-1 text-xl font-bold text-ink">
                {
                  summary.tahfiz_groups_without_primary_supervisor
                }
              </p>
            </div>
          </div>
        </div>
      </section>

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Pengasuhan
          </p>

          <h2 className="mt-2 text-2xl font-bold tracking-tight text-ink">
            Kelompok Pengasuhan
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Assignment Pengasuh berdasarkan
            kelompok santri Putra dan Putri.
          </p>
        </div>

        <div className="mt-5 grid gap-5 xl:grid-cols-2">
          {data.care_groups.map(
            (group) => (
              <CareGroupCard
                key={group.id}
                group={group}
              />
            ),
          )}
        </div>
      </section>

      <section className="mt-10">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Tahfiz
          </p>

          <h2 className="mt-2 text-2xl font-bold tracking-tight text-ink">
            Kelompok Tahfiz
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Kelompok tahfiz berdasarkan kelas
            dan gender beserta Pembina Tahfiz
            yang ditugaskan.
          </p>
        </div>

        <div className="mt-5 grid gap-5 md:grid-cols-2 xl:grid-cols-3">
          {data.tahfiz_groups.map(
            (group) => (
              <TahfizGroupCard
                key={group.id}
                group={group}
              />
            ),
          )}
        </div>
      </section>
    </div>
  );
}