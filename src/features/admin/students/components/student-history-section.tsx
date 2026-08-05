import type { AdminStudentDetailData } from "../schemas/admin-student-detail-schema";

type StudentHistorySectionProps = {
  data: AdminStudentDetailData;
};

type HistoryRecord = {
  id: string;
  title: string;
  academicYear: string;
  startedAt: string;
  endedAt: string | null;
  isActive: boolean;
};

function formatDate(
  value: string | null,
): string {
  if (!value) {
    return "Sekarang";
  }

  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(new Date(`${value}T00:00:00`));
}

function HistoryList({
  title,
  description,
  records,
}: {
  title: string;
  description: string;
  records: HistoryRecord[];
}) {
  return (
    <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Riwayat
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          {title}
        </h2>

        <p className="mt-2 text-sm leading-6 text-muted">
          {description}
        </p>
      </div>

      {records.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-dashed border-line bg-slate-50 p-5 text-sm text-muted">
          Belum terdapat riwayat.
        </div>
      ) : (
        <div className="mt-6 space-y-3">
          {records.map((record) => (
            <article
              key={record.id}
              className="relative rounded-2xl border border-line bg-slate-50/70 p-4"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <h3 className="font-semibold text-slate-800">
                    {record.title}
                  </h3>

                  <p className="mt-1 text-xs text-slate-500">
                    Tahun ajaran{" "}
                    {record.academicYear}
                  </p>
                </div>

                <span
                  className={
                    record.isActive
                      ? "rounded-full bg-brand-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-brand-700"
                      : "rounded-full bg-slate-200 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-slate-500"
                  }
                >
                  {record.isActive
                    ? "Aktif"
                    : "Selesai"}
                </span>
              </div>

              <p className="mt-4 text-sm text-slate-600">
                {formatDate(
                  record.startedAt,
                )}{" "}
                –{" "}
                {formatDate(
                  record.endedAt,
                )}
              </p>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}

export function StudentHistorySection({
  data,
}: StudentHistorySectionProps) {
  const classRecords: HistoryRecord[] =
    data.history.classes.map(
      (history) => ({
        id: history.id,
        title: history.class_name,
        academicYear:
          history.academic_year_name,
        startedAt: history.enrolled_at,
        endedAt: history.left_at,
        isActive: history.is_active,
      }),
    );

  const careRecords: HistoryRecord[] =
    data.history.care_groups.map(
      (history) => ({
        id: history.id,
        title: history.care_group_name,
        academicYear:
          history.academic_year_name,
        startedAt: history.joined_at,
        endedAt: history.left_at,
        isActive: history.is_active,
      }),
    );

  const tahfizRecords: HistoryRecord[] =
    data.history.tahfiz_groups.map(
      (history) => ({
        id: history.id,
        title: history.tahfiz_group_name,
        academicYear:
          history.academic_year_name,
        startedAt: history.joined_at,
        endedAt: history.left_at,
        isActive: history.is_active,
      }),
    );

  return (
    <div className="grid gap-6 xl:grid-cols-3">
      <HistoryList
        title="Kelas"
        description="Riwayat kelas santri pada setiap tahun ajaran."
        records={classRecords}
      />

      <HistoryList
        title="Pengasuhan"
        description="Riwayat kelompok pengasuhan santri."
        records={careRecords}
      />

      <HistoryList
        title="Tahfiz"
        description="Riwayat kelompok tahfiz santri."
        records={tahfizRecords}
      />
    </div>
  );
}