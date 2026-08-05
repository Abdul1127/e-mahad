import Link from "next/link";

import type { AdminStudentListItem } from "../schemas/admin-student-list-schema";

import { StudentAvatar } from "./student-avatar";

type StudentDesktopTableProps = {
  students: AdminStudentListItem[];
};

function genderLabel(
  gender: "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

export function StudentDesktopTable({
  students,
}: StudentDesktopTableProps) {
  return (
    <div className="hidden overflow-hidden rounded-3xl border border-line bg-white shadow-soft lg:block">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[1080px] border-collapse">
          <thead>
            <tr className="border-b border-line bg-slate-50/80 text-left">
              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Santri
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                ID
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Kelas
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Pengasuhan
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Tahfiz
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Wali
              </th>

              <th className="px-5 py-4 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                Aksi
              </th>
            </tr>
          </thead>

          <tbody>
            {students.map((student) => (
              <tr
                key={student.id}
                className="border-b border-line/80 last:border-b-0 hover:bg-brand-50/30"
              >
                <td className="px-5 py-4">
                  <div className="flex items-center gap-3">
                    <StudentAvatar
                      fullName={student.full_name}
                      gender={student.gender}
                      size="small"
                    />

                    <div className="min-w-0">
                      <p className="max-w-72 truncate text-sm font-semibold text-ink">
                        {student.full_name}
                      </p>

                      <span
                        className={
                          student.gender === "male"
                            ? "mt-1 inline-flex rounded-full bg-sky-50 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-sky-700"
                            : "mt-1 inline-flex rounded-full bg-rose-50 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-rose-700"
                        }
                      >
                        {genderLabel(
                          student.gender,
                        )}
                      </span>
                    </div>
                  </div>
                </td>

                <td className="px-4 py-4">
                  <p className="text-sm font-medium text-slate-700">
                    {student.legacy_student_id ?? "-"}
                  </p>

                  {student.nis && (
                    <p className="mt-1 text-xs text-slate-400">
                      NIS {student.nis}
                    </p>
                  )}
                </td>

                <td className="px-4 py-4 text-sm text-slate-700">
                  {student.class_name ?? (
                    <span className="text-amber-700">
                      Belum tersedia
                    </span>
                  )}
                </td>

                <td className="px-4 py-4 text-sm text-slate-700">
                  {student.care_group_name ?? (
                    <span className="text-amber-700">
                      Belum tersedia
                    </span>
                  )}
                </td>

                <td className="px-4 py-4 text-sm text-slate-700">
                  {student.tahfiz_group_name ?? (
                    <span className="text-amber-700">
                      Belum tersedia
                    </span>
                  )}
                </td>

                <td className="px-4 py-4">
                  <span
                    className={
                      student.guardian_count > 0
                        ? "inline-flex rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700"
                        : "inline-flex rounded-full bg-amber-100 px-2.5 py-1 text-xs font-semibold text-amber-700"
                    }
                  >
                    {student.guardian_count > 0
                      ? `${student.guardian_count} wali`
                      : "Belum ada"}
                  </span>
                </td>

                <td className="px-5 py-4 text-right">
                  <Link
                    href={`/admin/santri/${student.id}`}
                    className="inline-flex min-h-9 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-3.5 text-xs font-semibold text-brand-700 transition hover:bg-brand-100"
                  >
                    Lihat detail
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}