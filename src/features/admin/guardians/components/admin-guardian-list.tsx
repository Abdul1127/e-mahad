import Link from "next/link";

import type { AdminGuardianListQuery } from "../lib/parse-guardian-list-query";
import type { AdminGuardianListData } from "../schemas/admin-guardian-list-schema";

import { GuardianDesktopTable } from "./guardian-desktop-table";
import { GuardianFilterForm } from "./guardian-filter-form";
import { GuardianMobileList } from "./guardian-mobile-list";
import { GuardianPagination } from "./guardian-pagination";

type AdminGuardianListProps = {
  data: AdminGuardianListData;
  query: AdminGuardianListQuery;
};

const numberFormatter =
  new Intl.NumberFormat("id-ID");

export function AdminGuardianList({
  data,
  query,
}: AdminGuardianListProps) {
  const pagination = data.pagination;
  const summary = data.summary;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
        <div className="min-w-0">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Data master
          </p>

          <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
            Orang Tua dan Wali
          </h1>

          <p className="mt-3 max-w-2xl leading-7 text-muted">
            Kelola data keluarga, hubungan dengan
            santri, serta kesiapan akun orang tua.
          </p>
        </div>

        <Link
          href="/admin/wali/tambah"
          className="inline-flex min-h-11 shrink-0 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100"
        >
          Tambah wali
        </Link>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Total wali
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.total_guardians,
            )}
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Wali aktif
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_guardians,
            )}
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Akun terhubung
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.linked_accounts,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            {numberFormatter.format(
              summary.unlinked_accounts,
            )}{" "}
            belum memiliki akun
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Hubungan anak
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.total_child_links,
            )}
          </p>
        </article>
      </section>

      <div className="mt-6">
        <GuardianFilterForm query={query} />
      </div>

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
              wali.
            </>
          ) : (
            "Belum terdapat data wali."
          )}
        </p>
      </div>

      {data.items.length === 0 ? (
        <section className="mt-5 rounded-3xl border border-dashed border-line bg-white px-6 py-14 text-center shadow-soft">
          <div className="mx-auto grid size-14 place-items-center rounded-2xl bg-brand-50 text-xl font-bold text-brand-700">
            W
          </div>

          <h2 className="mt-5 text-lg font-bold text-ink">
            Belum ada data orang tua atau wali
          </h2>

          <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-muted">
            Tambahkan data orang tua atau wali,
            kemudian hubungkan dengan satu atau
            beberapa santri.
          </p>

          <Link
            href="/admin/wali/tambah"
            className="mt-6 inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            Tambah wali pertama
          </Link>
        </section>
      ) : (
        <div className="mt-5">
          <GuardianDesktopTable
            guardians={data.items}
          />

          <GuardianMobileList
            guardians={data.items}
          />
        </div>
      )}

      <div className="mt-5">
        <GuardianPagination
          query={query}
          pagination={pagination}
        />
      </div>
    </div>
  );
}