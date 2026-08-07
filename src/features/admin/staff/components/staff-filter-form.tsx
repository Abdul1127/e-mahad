import Link from "next/link";

import type { AdminStaffListQuery } from "../lib/parse-staff-list-query";
import type { AdminStaffRoleOption } from "../schemas/admin-staff-role-options-schema";

type StaffFilterFormProps = {
  query: AdminStaffListQuery;

  roleOptions:
    AdminStaffRoleOption[];
};

export function StaffFilterForm({
  query,
  roleOptions,
}: StaffFilterFormProps) {
  const statusValue =
    query.isActive === true
      ? "active"
      : query.isActive === false
        ? "inactive"
        : "";

  return (
    <form
      method="get"
      action="/admin/staf"
      className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6"
    >
      <div className="grid gap-4 xl:grid-cols-[minmax(280px,1.5fr)_minmax(160px,0.7fr)_minmax(180px,0.8fr)_minmax(190px,0.9fr)]">
        <div>
          <label
            htmlFor="staff-search"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Cari staf
          </label>

          <input
            id="staff-search"
            name="q"
            type="search"
            defaultValue={query.search}
            placeholder="Nama, ID staf, ID Pengguna, telepon, atau jabatan"
            autoComplete="off"
            spellCheck={false}
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <p className="mt-2 text-xs leading-5 text-slate-400">
            Pencarian mendukung nama, ID
            staf, ID Pengguna, telepon, dan
            jabatan.
          </p>
        </div>

        <div>
          <label
            htmlFor="staff-status"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Status data
          </label>

          <select
            id="staff-status"
            name="status"
            defaultValue={statusValue}
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="">
              Semua status
            </option>

            <option value="active">
              Aktif
            </option>

            <option value="inactive">
              Tidak aktif
            </option>
          </select>
        </div>

        <div>
          <label
            htmlFor="staff-account-status"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Akun login
          </label>

          <select
            id="staff-account-status"
            name="account"
            defaultValue={
              query.accountStatus ?? ""
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="">
              Semua akun
            </option>

            <option value="linked">
              Sudah terhubung
            </option>

            <option value="unlinked">
              Belum terhubung
            </option>
          </select>
        </div>

        <div>
          <label
            htmlFor="staff-role"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Role
          </label>

          <select
            id="staff-role"
            name="role"
            defaultValue={
              query.roleCode ?? ""
            }
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option value="">
              Semua role
            </option>

            {roleOptions.map(
              (role) => (
                <option
                  key={role.code}
                  value={role.code}
                >
                  {role.name}
                </option>
              ),
            )}
          </select>
        </div>
      </div>

      <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
        <Link
          href="/admin/staf"
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