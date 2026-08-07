import type { AdminStaffListQuery } from "../lib/parse-staff-list-query";
import type { AdminStaffListData } from "../schemas/admin-staff-list-schema";
import type { AdminStaffRoleOption } from "../schemas/admin-staff-role-options-schema";

import { StaffDesktopTable } from "./staff-desktop-table";
import { StaffFilterForm } from "./staff-filter-form";
import { StaffMobileList } from "./staff-mobile-list";
import { StaffPagination } from "./staff-pagination";

type AdminStaffListProps = {
  data: AdminStaffListData;
  query: AdminStaffListQuery;

  roleOptions:
    AdminStaffRoleOption[];
};

const numberFormatter =
  new Intl.NumberFormat("id-ID");

export function AdminStaffList({
  data,
  query,
  roleOptions,
}: AdminStaffListProps) {
  const pagination =
    data.pagination;

  const summary =
    data.summary;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Data master
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Staf Pesantren
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Kelola identitas staf, akun login,
          status akun, dan role yang diberikan
          kepada setiap staf.
        </p>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Total staf
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.total_staff,
            )}
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm font-medium text-muted">
            Staf aktif
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_staff,
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
            Penetapan role
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.total_role_assignments,
            )}
          </p>

          <p className="mt-2 text-xs text-slate-400">
            {numberFormatter.format(
              summary.active_accounts,
            )}{" "}
            akun aktif dan{" "}
            {numberFormatter.format(
              summary.inactive_accounts,
            )}{" "}
            akun nonaktif
          </p>
        </article>
      </section>

      <div className="mt-6">
        <StaffFilterForm
          query={query}
          roleOptions={roleOptions}
        />
      </div>

      <div className="mt-5 text-sm text-slate-500">
        {pagination.total_items > 0 ? (
          <p>
            Menampilkan{" "}
            <strong className="text-slate-700">
              {pagination.from_item}
            </strong>
            {"–"}
            <strong className="text-slate-700">
              {pagination.to_item}
            </strong>{" "}
            dari{" "}
            <strong className="text-slate-700">
              {pagination.total_items}
            </strong>{" "}
            staf.
          </p>
        ) : (
          <p>
            Tidak ada data staf yang sesuai
            dengan filter.
          </p>
        )}
      </div>

      {data.items.length === 0 ? (
        <section className="mt-5 rounded-3xl border border-dashed border-line bg-white px-6 py-14 text-center shadow-soft">
          <div className="mx-auto grid size-14 place-items-center rounded-2xl bg-brand-50 text-xl font-bold text-brand-700">
            S
          </div>

          <h2 className="mt-5 text-lg font-bold text-ink">
            Data staf tidak ditemukan
          </h2>

          <p className="mx-auto mt-2 max-w-md text-sm leading-6 text-muted">
            Ubah kata pencarian atau reset
            filter untuk menampilkan kembali
            seluruh data staf.
          </p>
        </section>
      ) : (
        <div className="mt-5">
          <StaffDesktopTable
            staffItems={data.items}
          />

          <StaffMobileList
            staffItems={data.items}
          />
        </div>
      )}

      <div className="mt-5">
        <StaffPagination
          query={query}
          pagination={pagination}
        />
      </div>
    </div>
  );
}