import Link from "next/link";

import type { AdminGuardianListQuery } from "../lib/parse-guardian-list-query";
import type { AdminGuardianListData } from "../schemas/admin-guardian-list-schema";

type GuardianPaginationProps = {
  query: AdminGuardianListQuery;
  pagination:
    AdminGuardianListData["pagination"];
};

function buildPageHref(
  query: AdminGuardianListQuery,
  page: number,
): string {
  const parameters =
    new URLSearchParams();

  if (query.search) {
    parameters.set("q", query.search);
  }

  if (query.isActive === true) {
    parameters.set("status", "active");
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

  parameters.set(
    "page",
    page.toString(),
  );

  return `/admin/wali?${parameters.toString()}`;
}

export function GuardianPagination({
  query,
  pagination,
}: GuardianPaginationProps) {
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
      aria-label="Pagination wali"
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