import Link from "next/link";

import type { AdminStaffListQuery } from "../lib/parse-staff-list-query";
import type { AdminStaffListData } from "../schemas/admin-staff-list-schema";

type StaffPaginationProps = {
  query: AdminStaffListQuery;

  pagination:
    AdminStaffListData["pagination"];
};

function buildPageHref(
  query: AdminStaffListQuery,
  page: number,
): string {
  const parameters =
    new URLSearchParams();

  if (query.search) {
    parameters.set(
      "q",
      query.search,
    );
  }

  if (query.isActive === true) {
    parameters.set(
      "status",
      "active",
    );
  }

  if (query.isActive === false) {
    parameters.set(
      "status",
      "inactive",
    );
  }

  if (query.accountStatus) {
    parameters.set(
      "account",
      query.accountStatus,
    );
  }

  if (query.roleCode) {
    parameters.set(
      "role",
      query.roleCode,
    );
  }

  parameters.set(
    "page",
    page.toString(),
  );

  return `/admin/staf?${parameters.toString()}`;
}

export function StaffPagination({
  query,
  pagination,
}: StaffPaginationProps) {
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
      aria-label="Pagination staf"
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