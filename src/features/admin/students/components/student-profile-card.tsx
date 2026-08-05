import { StudentAvatar } from "./student-avatar";

import type { AdminStudentDetailData } from "../schemas/admin-student-detail-schema";

type StudentProfileCardProps = {
  data: AdminStudentDetailData;
};

function genderLabel(
  gender: "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

function statusLabel(
  status:
    | "active"
    | "inactive"
    | "graduated"
    | "withdrawn",
): string {
  switch (status) {
    case "active":
      return "Aktif";

    case "inactive":
      return "Tidak aktif";

    case "graduated":
      return "Lulus";

    case "withdrawn":
      return "Keluar";
  }
}

function formatDateTime(
  value: string,
): string {
  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "long",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  }).format(new Date(value));
}

export function StudentProfileCard({
  data,
}: StudentProfileCardProps) {
  const student = data.student;

  return (
    <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
      <div className="flex flex-col gap-5 sm:flex-row sm:items-start">
        <StudentAvatar
          fullName={student.full_name}
          gender={student.gender}
        />

        <div className="min-w-0 flex-1">
          <div className="flex flex-wrap items-center gap-2">
            <span
              className={
                student.gender === "male"
                  ? "rounded-full bg-sky-50 px-2.5 py-1 text-xs font-semibold text-sky-700"
                  : "rounded-full bg-rose-50 px-2.5 py-1 text-xs font-semibold text-rose-700"
              }
            >
              {genderLabel(student.gender)}
            </span>

            <span
              className={
                student.status === "active"
                  ? "rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700"
                  : "rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600"
              }
            >
              {statusLabel(student.status)}
            </span>
          </div>

          <h2 className="mt-3 text-2xl font-bold tracking-tight text-ink">
            {student.full_name}
          </h2>

          <p className="mt-2 text-sm text-muted">
            ID Santri{" "}
            <strong className="text-slate-700">
              {student.legacy_student_id ?? "-"}
            </strong>
          </p>
        </div>
      </div>

      <dl className="mt-7 grid gap-3 sm:grid-cols-2">
        <div className="rounded-2xl bg-slate-50 p-4">
          <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            ID santri
          </dt>

          <dd className="mt-2 text-sm font-semibold text-slate-800">
            {student.legacy_student_id ?? "-"}
          </dd>
        </div>

        <div className="rounded-2xl bg-slate-50 p-4">
          <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            NIS
          </dt>

          <dd className="mt-2 text-sm font-semibold text-slate-800">
            {student.nis ?? "Belum tersedia"}
          </dd>
        </div>

        <div className="rounded-2xl bg-slate-50 p-4">
          <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Dibuat
          </dt>

          <dd className="mt-2 text-sm font-semibold text-slate-800">
            {formatDateTime(
              student.created_at,
            )}
          </dd>
        </div>

        <div className="rounded-2xl bg-slate-50 p-4">
          <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
            Terakhir diperbarui
          </dt>

          <dd className="mt-2 text-sm font-semibold text-slate-800">
            {formatDateTime(
              student.updated_at,
            )}
          </dd>
        </div>
      </dl>
    </section>
  );
}