import Link from "next/link";

import type {
  PembinaTahfizStudentListData,
  PembinaTahfizStudentListItem,
} from "../schemas/pembina-tahfiz-student-list-schema";

type Props = {
  data:
    PembinaTahfizStudentListData;
};

function getGenderLabel(
  gender:
    "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

function getGenderClassName(
  gender:
    "male" | "female",
): string {
  return gender === "male"
    ? "bg-blue-50 text-blue-700"
    : "bg-pink-50 text-pink-700";
}

function StudentCard({
  student,
}: {
  student:
    PembinaTahfizStudentListItem;
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <div className="flex flex-wrap items-center gap-2">
            <h2 className="text-base font-bold text-ink sm:text-lg">
              {
                student.full_name
              }
            </h2>

            <span
              className={`rounded-full px-2.5 py-1 text-xs font-semibold ${getGenderClassName(
                student.gender,
              )}`}
            >
              {getGenderLabel(
                student.gender,
              )}
            </span>
          </div>

          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-slate-400">
            {student.nis && (
              <span>
                NIS{" "}
                {
                  student.nis
                }
              </span>
            )}

            {student.legacy_student_id && (
              <span>
                ID{" "}
                {
                  student.legacy_student_id
                }
              </span>
            )}
          </div>
        </div>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <div className="rounded-xl bg-brand-50 p-3">
          <p className="text-xs font-medium text-brand-600">
            Kelompok Tahfiz
          </p>

          <p className="mt-1 text-sm font-semibold text-brand-900">
            {
              student.tahfiz_group
                .name
            }
          </p>

          <p className="mt-1 text-xs text-brand-600">
            {
              student.tahfiz_group
                .code
            }
          </p>
        </div>

        <div className="rounded-xl bg-slate-50 p-3">
          <p className="text-xs text-muted">
            Kelas
          </p>

          <p className="mt-1 text-sm font-semibold text-ink">
            {student.class
              ?.name ??
              "Belum tersedia"}
          </p>
        </div>
      </div>
    </article>
  );
}

export function PembinaTahfizStudentList({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* =====================================================
          HEADER
      ===================================================== */}

      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pembina Tahfiz
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Santri Tahfiz Ampuan
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Daftar santri yang berada
          pada kelompok Tahfiz
          assignment Anda pada tahun
          ajaran berjalan.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
            Tahun Ajaran{" "}
            {
              data.academic_year
                .name
            }
          </span>

          <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
            {
              data.staff
                .full_name
            }
          </span>
        </div>
      </section>

      {/* =====================================================
          SUMMARY
      ===================================================== */}

      <section className="mt-6 grid gap-4 sm:grid-cols-3">
        <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <p className="text-xs font-medium text-brand-700">
            Kelompok Ampuan
          </p>

          <p className="mt-2 text-3xl font-bold text-brand-900">
            {
              data.summary
                .group_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Total Santri
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {
              data.summary
                .student_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Hasil Pencarian
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {
              data.summary
                .filtered_count
            }
          </p>
        </div>
      </section>

      {/* =====================================================
          SEARCH
      ===================================================== */}

      <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <form
          action="/pembina-tahfiz/santri"
          method="get"
          className="flex flex-col gap-3 sm:flex-row"
        >
          <div className="flex-1">
            <label
              htmlFor="search"
              className="mb-2 block text-xs font-semibold text-slate-600"
            >
              Cari Santri
            </label>

            <input
              id="search"
              name="search"
              type="search"
              defaultValue={
                data.filters.search ??
                ""
              }
              placeholder="Cari nama, NIS, ID santri, atau kelompok Tahfiz..."
              className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />
          </div>

          <button
            type="submit"
            className="min-h-11 self-end rounded-xl bg-brand-700 px-6 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            Cari
          </button>
        </form>

        {data.filters.search && (
          <div className="mt-3 flex flex-wrap items-center gap-2 text-sm">
            <span className="text-muted">
              Pencarian:
            </span>

            <span className="font-semibold text-ink">
              &quot;
              {
                data.filters.search
              }
              &quot;
            </span>

            <Link
              href="/pembina-tahfiz/santri"
              className="font-semibold text-brand-700 hover:text-brand-800"
            >
              Reset
            </Link>
          </div>
        )}
      </section>

      {/* =====================================================
          LIST
      ===================================================== */}

      <section className="mt-7">
        <div className="flex flex-col gap-1 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Assignment Tahfiz
            </p>

            <h2 className="mt-2 text-2xl font-bold text-ink">
              Daftar Santri
            </h2>
          </div>

          <p className="text-sm text-muted">
            {
              data.summary
                .filtered_count
            }{" "}
            santri ditampilkan
          </p>
        </div>

        {data.items.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Santri tidak ditemukan
            </h3>

            <p className="mt-2 text-sm text-muted">
              Tidak ada santri
              Tahfiz ampuan yang
              sesuai dengan
              pencarian.
            </p>

            {data.filters.search && (
              <Link
                href="/pembina-tahfiz/santri"
                className="mt-4 inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white"
              >
                Tampilkan Semua
              </Link>
            )}
          </div>
        ) : (
          <div className="mt-5 grid gap-4 xl:grid-cols-2">
            {data.items.map(
              (student) => (
                <StudentCard
                  key={
                    student.id
                  }
                  student={
                    student
                  }
                />
              ),
            )}
          </div>
        )}
      </section>

      {/* =====================================================
          INFO
      ===================================================== */}

      <section className="mt-6 rounded-2xl border border-blue-100 bg-blue-50 p-4 sm:p-5">
        <p className="font-semibold text-blue-800">
          Pengelolaan kelompok tetap
          dilakukan oleh Admin
        </p>

        <p className="mt-1 max-w-3xl text-sm leading-6 text-blue-700">
          Pembina Tahfiz hanya
          melihat santri berdasarkan
          assignment kelompoknya.
          Pemindahan santri atau
          perubahan assignment tidak
          dilakukan dari halaman ini.
        </p>
      </section>
    </div>
  );
}