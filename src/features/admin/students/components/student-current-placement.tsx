import type {
  AdminStudentDetailData,
  StudentPlacementStaff,
} from "../schemas/admin-student-detail-schema";

type StudentCurrentPlacementProps = {
  data: AdminStudentDetailData;
};

function StaffList({
  staff,
  emptyLabel,
}: {
  staff: StudentPlacementStaff[];
  emptyLabel: string;
}) {
  if (staff.length === 0) {
    return (
      <p className="mt-3 text-sm font-medium text-amber-700">
        {emptyLabel}
      </p>
    );
  }

  return (
    <div className="mt-3 space-y-2">
      {staff.map((person) => (
        <div
          key={person.id}
          className="flex items-center justify-between gap-3 rounded-xl bg-white px-3 py-2.5"
        >
          <p className="min-w-0 truncate text-sm font-semibold text-slate-700">
            {person.full_name}
          </p>

          {person.is_primary && (
            <span className="shrink-0 rounded-full bg-brand-100 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-brand-700">
              Utama
            </span>
          )}
        </div>
      ))}
    </div>
  );
}

export function StudentCurrentPlacement({
  data,
}: StudentCurrentPlacementProps) {
  const placement =
    data.current_placement;

  return (
    <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Penempatan aktif
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          Tahun ajaran{" "}
          {data.academic_year?.name ?? "-"}
        </h2>
      </div>

      <div className="mt-6 grid gap-4 xl:grid-cols-3">
        <article className="rounded-2xl border border-line bg-slate-50/70 p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Kelas
          </p>

          <h3 className="mt-3 text-lg font-bold text-slate-800">
            {placement.class?.name ??
              "Belum tersedia"}
          </h3>

          {placement.class && (
            <p className="mt-2 text-sm text-slate-500">
              Tingkat{" "}
              {placement.class.grade_level}
            </p>
          )}
        </article>

        <article className="rounded-2xl border border-line bg-slate-50/70 p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Pengasuhan
          </p>

          <h3 className="mt-3 text-lg font-bold text-slate-800">
            {placement.care_group?.name ??
              "Belum tersedia"}
          </h3>

          <StaffList
            staff={
              placement.care_group
                ?.caregivers ?? []
            }
            emptyLabel="Pengasuh belum tersedia."
          />
        </article>

        <article className="rounded-2xl border border-line bg-slate-50/70 p-5">
          <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Kelompok tahfiz
          </p>

          <h3 className="mt-3 text-lg font-bold text-slate-800">
            {placement.tahfiz_group?.name ??
              "Belum tersedia"}
          </h3>

          <StaffList
            staff={
              placement.tahfiz_group
                ?.supervisors ?? []
            }
            emptyLabel="Pembina Tahfiz belum tersedia."
          />
        </article>
      </div>
    </section>
  );
}