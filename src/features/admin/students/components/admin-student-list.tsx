import Link from "next/link";

import type { AdminStudentListQuery } from "../lib/parse-student-list-query";
import type { AdminStudentListData } from "../schemas/admin-student-list-schema";

import { StudentDesktopTable } from "./student-desktop-table";
import { StudentFilterForm } from "./student-filter-form";
import { StudentMobileList } from "./student-mobile-list";
import { StudentPagination } from "./student-pagination";

type AdminStudentListProps = {
  data: AdminStudentListData;
  query: AdminStudentListQuery;
};

const numberFormatter = new Intl.NumberFormat("id-ID");

export function AdminStudentList({
  data,
  query,
}: AdminStudentListProps) {
  const pagination = data.pagination;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <div className="flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div className="min-w-0">
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Data master
            </p>

            <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
              Data Santri
            </h1>

            <p className="mt-3 max-w-2xl leading-7 text-muted">
              Cari dan pantau penempatan kelas, kelompok
              pengasuhan, kelompok tahfiz, serta relasi wali
              santri.
            </p>
          </div>

          <div className="flex shrink-0 flex-col gap-3 sm:items-end">
            <Link
              href="/admin/santri/tambah"
              className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100"
            >
              Tambah santri
            </Link>

            <div className="rounded-2xl border border-brand-100 bg-brand-50 px-4 py-3">
              <p className="text-xs font-medium text-brand-600">
                Total hasil
              </p>

              <p className="mt-1 text-2xl font-bold text-brand-900">
                {numberFormatter.format(
                  pagination.total_items,
                )}
              </p>
            </div>
          </div>
        </div>
      </section>

      <StudentFilterForm
        query={query}
        options={data.filter_options}
      />

      <div className="mt-5 flex flex-col gap-1 text-sm text-slate-500 sm:flex-row sm:items-center sm:justify-between">
        <p>
          {pagination.total_items > 0 ? (
            <>
              Menampilkan{" "}
              <strong className="text-slate-700">
                {pagination.from_item}
              </strong>
              –
              <strong className="text-slate-700">
                {pagination.to_item}
              </strong>{" "}
              dari{" "}
              <strong className="text-slate-700">
                {pagination.total_items}
              </strong>{" "}
              santri.
            </>
          ) : (
            "Tidak ada santri yang sesuai dengan filter."
          )}
        </p>

        {data.academic_year && (
          <p className="text-xs">
            Tahun ajaran{" "}
            <strong className="text-slate-600">
              {data.academic_year.name}
            </strong>
          </p>
        )}
      </div>

      {data.items.length === 0 ? (
        <section className="mt-5 rounded-3xl border border-dashed border-line bg-white px-6 py-14 text-center shadow-soft">
          <h2 className="text-lg font-bold text-ink">
            Data santri tidak ditemukan
          </h2>

          <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-muted">
            Coba ubah kata pencarian atau hapus sebagian
            filter yang sedang digunakan.
          </p>

          <Link
            href="/admin/santri"
            className="mt-6 inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
          >
            Reset pencarian
          </Link>
        </section>
      ) : (
        <div className="mt-5">
          <StudentDesktopTable
            students={data.items}
          />

          <StudentMobileList
            students={data.items}
          />
        </div>
      )}

      <div className="mt-5">
        <StudentPagination
          query={query}
          pagination={pagination}
        />
      </div>
    </div>
  );
}