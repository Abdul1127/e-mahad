import Link from "next/link";

import type {
  PengasuhStudentListData,
  PengasuhStudentListItem,
} from "../schemas/pengasuh-student-list-schema";

type PengasuhStudentListProps = {
  data:
    PengasuhStudentListData;

  search:
    string;
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

function StudentCard({
  student,
}: {
  student:
    PengasuhStudentListItem;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-4 shadow-soft">
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <h2 className="font-semibold text-ink">
            {
              student.full_name
            }
          </h2>

          <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-400">
            <span>
              ID{" "}
              {student.legacy_student_id ??
                "-"}
            </span>

            {student.nis && (
              <span>
                NIS{" "}
                {
                  student.nis
                }
              </span>
            )}
          </div>
        </div>

        <span className="shrink-0 rounded-full bg-brand-50 px-2.5 py-1 text-[11px] font-semibold text-brand-700">
          {getGenderLabel(
            student.gender,
          )}
        </span>
      </div>

      <div className="mt-4 grid gap-2 sm:grid-cols-2">
        <div className="rounded-xl bg-slate-50 px-3 py-3">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
            Kelas
          </p>

          <p className="mt-1 text-sm font-semibold text-slate-700">
            {student.class?.name ??
              "Belum tersedia"}
          </p>

          {student.class && (
            <p className="mt-1 text-xs text-slate-400">
              Tingkat{" "}
              {
                student.class
                  .grade_level
              }
            </p>
          )}
        </div>

        <div className="rounded-xl bg-brand-50 px-3 py-3">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-brand-500">
            Kelompok
          </p>

          <p className="mt-1 text-sm font-semibold text-brand-800">
            {
              student.care_group
                .name
            }
          </p>

          <p className="mt-1 text-xs text-brand-600">
            {
              student.care_group
                .code
            }
          </p>
        </div>
      </div>
    </article>
  );
}

function StudentDesktopTable({
  students,
}: {
  students:
    PengasuhStudentListItem[];
}) {
  return (
    <div className="hidden overflow-hidden rounded-2xl border border-line bg-white shadow-soft lg:block">
      <div className="overflow-x-auto">
        <table className="w-full border-collapse text-left">
          <thead className="bg-slate-50">
            <tr className="border-b border-line">
              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Santri
              </th>

              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                NIS
              </th>

              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Gender
              </th>

              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Kelas
              </th>

              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Kelompok
              </th>
            </tr>
          </thead>

          <tbody>
            {students.map(
              (student) => (
                <tr
                  key={
                    student.membership_id
                  }
                  className="border-b border-line last:border-b-0"
                >
                  <td className="px-5 py-4">
                    <p className="font-semibold text-ink">
                      {
                        student.full_name
                      }
                    </p>

                    <p className="mt-1 text-xs text-slate-400">
                      ID{" "}
                      {student.legacy_student_id ??
                        "-"}
                    </p>
                  </td>

                  <td className="px-5 py-4 text-sm text-slate-600">
                    {student.nis ??
                      "-"}
                  </td>

                  <td className="px-5 py-4">
                    <span className="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-700">
                      {getGenderLabel(
                        student.gender,
                      )}
                    </span>
                  </td>

                  <td className="px-5 py-4">
                    <p className="text-sm font-semibold text-slate-700">
                      {student.class
                        ?.name ??
                        "-"}
                    </p>

                    {student.class && (
                      <p className="mt-1 text-xs text-slate-400">
                        Tingkat{" "}
                        {
                          student
                            .class
                            .grade_level
                        }
                      </p>
                    )}
                  </td>

                  <td className="px-5 py-4">
                    <p className="text-sm font-semibold text-slate-700">
                      {
                        student
                          .care_group
                          .name
                      }
                    </p>

                    <p className="mt-1 text-xs text-slate-400">
                      {
                        student
                          .care_group
                          .code
                      }
                    </p>
                  </td>
                </tr>
              ),
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

export function PengasuhStudentList({
  data,
  search,
}: PengasuhStudentListProps) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pengasuhan
        </p>

        <div className="mt-2 flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <h1 className="text-3xl font-bold tracking-tight text-ink">
              Santri Ampuan
            </h1>

            <p className="mt-3 max-w-2xl text-sm leading-7 text-muted">
              Daftar santri aktif
              yang berada dalam
              kelompok pengasuhan
              Anda.
            </p>

            <div className="mt-3 flex flex-wrap gap-2">
              <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                Tahun ajaran{" "}
                {
                  data.academic_year
                    .name
                }
              </span>

              <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
                {
                  data.summary
                    .group_count
                }{" "}
                kelompok
              </span>
            </div>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50 px-5 py-3">
            <p className="text-xs font-medium text-brand-600">
              Total santri
            </p>

            <p className="mt-1 text-3xl font-bold text-brand-900">
              {numberFormatter.format(
                data.summary
                  .student_count,
              )}
            </p>
          </div>
        </div>
      </section>

      <section className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          action="/pengasuh/santri"
          method="get"
          className="flex flex-col gap-3 sm:flex-row"
        >
          <div className="flex-1">
            <label
              htmlFor="q"
              className="sr-only"
            >
              Cari santri
            </label>

            <input
              id="q"
              name="q"
              type="search"
              defaultValue={
                search
              }
              placeholder="Cari nama, NIS, atau ID santri..."
              className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />
          </div>

          <button
            type="submit"
            className="min-h-11 rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100"
          >
            Cari
          </button>

          {search.length >
            0 && (
            <Link
              href="/pengasuh/santri"
              className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
            >
              Reset
            </Link>
          )}
        </form>
      </section>

      <div className="mt-5 flex flex-col gap-1 text-sm text-slate-500 sm:flex-row sm:items-center sm:justify-between">
        <p>
          {data.summary
            .student_count > 0
            ? (
              <>
                Menampilkan{" "}
                <strong className="text-slate-700">
                  {numberFormatter.format(
                    data.summary
                      .student_count,
                  )}
                </strong>{" "}
                santri.
              </>
            )
            : "Tidak ada santri yang sesuai dengan pencarian."}
        </p>

        <p className="text-xs">
          Pengasuh{" "}
          <strong className="text-slate-600">
            {
              data.staff
                .full_name
            }
          </strong>
        </p>
      </div>

      {data.items.length ===
      0 ? (
        <section className="mt-5 rounded-3xl border border-dashed border-line bg-white px-6 py-14 text-center shadow-soft">
          <h2 className="text-lg font-bold text-ink">
            Santri tidak
            ditemukan
          </h2>

          <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-muted">
            Tidak ada santri
            dalam cakupan
            assignment Anda yang
            sesuai dengan kata
            pencarian.
          </p>

          {search.length >
            0 && (
            <Link
              href="/pengasuh/santri"
              className="mt-6 inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
            >
              Tampilkan semua
            </Link>
          )}
        </section>
      ) : (
        <section className="mt-5">
          <StudentDesktopTable
            students={
              data.items
            }
          />

          <div className="grid gap-3 lg:hidden">
            {data.items.map(
              (student) => (
                <StudentCard
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
        </section>
      )}
    </div>
  );
}