import Link from "next/link";

import type { AdminStudentListQuery } from "../lib/parse-student-list-query";
import type { StudentFilterOptions } from "../schemas/admin-student-list-schema";

type StudentFilterFormProps = {
  query: AdminStudentListQuery;
  options: StudentFilterOptions;
};

export function StudentFilterForm({
  query,
  options,
}: StudentFilterFormProps) {
  const gradeLevels = Array.from(
    new Set(
      options.classes.map(
        (item) => item.grade_level,
      ),
    ),
  ).sort(
    (firstGrade, secondGrade) =>
      firstGrade - secondGrade,
  );

  return (
    <form
      method="get"
      action="/admin/santri"
      className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6"
    >
      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-[minmax(240px,1.4fr)_repeat(4,minmax(150px,1fr))]">
        <div>
          <label
            htmlFor="student-search"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Cari santri
          </label>

          <input
            id="student-search"
            name="q"
            type="search"
            defaultValue={query.search}
            placeholder="Nama, ID santri, atau NIS"
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />
        </div>

        <div>
          <label
            htmlFor="grade-filter"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Kelas
          </label>

          <select
            id="grade-filter"
            name="grade"
            defaultValue={
              query.gradeLevel?.toString() ??
              ""
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="">
              Semua kelas
            </option>

            {gradeLevels.map(
              (gradeLevel) => (
                <option
                  key={gradeLevel}
                  value={gradeLevel}
                >
                  Kelas {gradeLevel}
                </option>
              ),
            )}
          </select>
        </div>

        <div>
          <label
            htmlFor="gender-filter"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Gender
          </label>

          <select
            id="gender-filter"
            name="gender"
            defaultValue={
              query.gender ?? ""
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="">
              Putra dan Putri
            </option>

            <option value="male">
              Putra
            </option>

            <option value="female">
              Putri
            </option>
          </select>
        </div>

        <div>
          <label
            htmlFor="care-group-filter"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Pengasuhan
          </label>

          <select
            id="care-group-filter"
            name="care_group"
            defaultValue={
              query.careGroupId ?? ""
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="">
              Semua pengasuhan
            </option>

            {options.care_groups.map(
              (group) => (
                <option
                  key={group.id}
                  value={group.id}
                >
                  {group.name}
                </option>
              ),
            )}
          </select>
        </div>

        <div>
          <label
            htmlFor="tahfiz-group-filter"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Kelompok tahfiz
          </label>

          <select
            id="tahfiz-group-filter"
            name="tahfiz_group"
            defaultValue={
              query.tahfizGroupId ?? ""
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="">
              Semua kelompok
            </option>

            {options.tahfiz_groups.map(
              (group) => (
                <option
                  key={group.id}
                  value={group.id}
                >
                  {group.name}
                </option>
              ),
            )}
          </select>
        </div>
      </div>

      <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
        <Link
          href="/admin/santri"
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
        >
          Reset filter
        </Link>

        <button
          type="submit"
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
        >
          Terapkan filter
        </button>
      </div>
    </form>
  );
}