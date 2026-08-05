import Link from "next/link";

import type { AdminStudentListItem } from "../schemas/admin-student-list-schema";

import { StudentAvatar } from "./student-avatar";

type StudentMobileListProps = {
  students: AdminStudentListItem[];
};

function genderLabel(
  gender: "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

export function StudentMobileList({
  students,
}: StudentMobileListProps) {
  return (
    <div className="space-y-3 lg:hidden">
      {students.map((student) => (
        <article
          key={student.id}
          className="rounded-3xl border border-line bg-white p-5 shadow-soft"
        >
          <div className="flex items-start gap-3">
            <StudentAvatar
              fullName={student.full_name}
              gender={student.gender}
            />

            <div className="min-w-0 flex-1">
              <h2 className="text-base font-bold leading-6 text-ink">
                {student.full_name}
              </h2>

              <div className="mt-1.5 flex flex-wrap items-center gap-2">
                <span className="text-xs font-medium text-slate-500">
                  ID{" "}
                  {student.legacy_student_id ?? "-"}
                </span>

                <span
                  className={
                    student.gender === "male"
                      ? "rounded-full bg-sky-50 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-sky-700"
                      : "rounded-full bg-rose-50 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-rose-700"
                  }
                >
                  {genderLabel(student.gender)}
                </span>
              </div>
            </div>
          </div>

          <dl className="mt-5 grid gap-3 sm:grid-cols-2">
            <div className="rounded-2xl bg-slate-50 p-3.5">
              <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Kelas
              </dt>

              <dd className="mt-1.5 text-sm font-semibold text-slate-700">
                {student.class_name ??
                  "Belum tersedia"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-3.5">
              <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Pengasuhan
              </dt>

              <dd className="mt-1.5 text-sm font-semibold text-slate-700">
                {student.care_group_name ??
                  "Belum tersedia"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-3.5">
              <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Tahfiz
              </dt>

              <dd className="mt-1.5 text-sm font-semibold text-slate-700">
                {student.tahfiz_group_name ??
                  "Belum tersedia"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-3.5">
              <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                Wali terhubung
              </dt>

              <dd
                className={
                  student.guardian_count > 0
                    ? "mt-1.5 text-sm font-semibold text-brand-700"
                    : "mt-1.5 text-sm font-semibold text-amber-700"
                }
              >
                {student.guardian_count > 0
                  ? `${student.guardian_count} wali`
                  : "Belum ada"}
              </dd>
            </div>
          </dl>

          <Link
            href={`/admin/santri/${student.id}`}
            className="mt-5 inline-flex min-h-11 w-full items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            Lihat detail santri
          </Link>
        </article>
      ))}
    </div>
  );
}