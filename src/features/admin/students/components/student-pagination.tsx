import Link from "next/link";

import type { AdminStudentListQuery } from "../lib/parse-student-list-query";
import type { AdminStudentListData } from "../schemas/admin-student-list-schema";

type StudentPaginationProps = {
  query: AdminStudentListQuery;
  pagination: AdminStudentListData["pagination"];
};

function buildPageHref(
  query: AdminStudentListQuery,
  page: number,
): string {
  const parameters =
    new URLSearchParams();

  if (query.search) {
    parameters.set("q", query.search);
  }

  if (query.gradeLevel) {
    parameters.set(
      "grade",
      query.gradeLevel.toString(),
    );
  }

  if (query.gender) {
    parameters.set(
      "gender",
      query.gender,
    );
  }

  if (query.careGroupId) {
    parameters.set(
      "care_group",
      query.careGroupId,
    );
  }

  if (query.tahfizGroupId) {
    parameters.set(
      "tahfiz_group",
      query.tahfizGroupId,
    );
  }

  parameters.set(
    "page",
    page.toString(),
  );

  return `/admin/santri?${parameters.toString()}`;
}

export function StudentPagination({
  query,
  pagination,
}: StudentPaginationProps) {
  if (
    pagination.total_items === 0 ||
    pagination.total_pages <= 1
  ) {
    return null;
  }

  const canGoPrevious =
    pagination.current_page > 1;

  const canGoNext =
    pagination.current_page <
    pagination.total_pages;

  return (
    <nav
      aria-label="Pagination santri"
      className="flex flex-col gap-3 rounded-2xl border border-line bg-white p-4 shadow-soft sm:flex-row sm:items-center sm:justify-between"
    >
      <p className="text-center text-sm text-slate-500 sm:text-left">
        Halaman{" "}
        <strong className="text-slate-700">
          {pagination.current_page}
        </strong>{" "}
        dari{" "}
        <strong className="text-slate-700">
          {pagination.total_pages}
        </strong>
      </p>

      <div className="grid grid-cols-2 gap-3">
        {canGoPrevious ? (
          <Link
            href={buildPageHref(
              query,
              pagination.current_page - 1,
            )}
            className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
          >
            Sebelumnya
          </Link>
        ) : (
          <span className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-slate-50 px-4 text-sm font-semibold text-slate-300">
            Sebelumnya
          </span>
        )}

        {canGoNext ? (
          <Link
            href={buildPageHref(
              query,
              pagination.current_page + 1,
            )}
            className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            Berikutnya
          </Link>
        ) : (
          <span className="inline-flex min-h-10 items-center justify-center rounded-xl bg-slate-200 px-4 text-sm font-semibold text-slate-400">
            Berikutnya
          </span>
        )}
      </div>
    </nav>
  );
}