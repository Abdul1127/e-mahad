import Link from "next/link";

import type { AdminGuardianListQuery } from "../lib/parse-guardian-list-query";

type GuardianFilterFormProps = {
  query: AdminGuardianListQuery;
};

export function GuardianFilterForm({
  query,
}: GuardianFilterFormProps) {
  const statusValue =
    query.isActive === true
      ? "active"
      : query.isActive === false
        ? "inactive"
        : "";

  return (
    <form
      method="get"
      action="/admin/wali"
      className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6"
    >
      <div className="grid gap-4 lg:grid-cols-[minmax(260px,1.5fr)_minmax(180px,0.75fr)_minmax(180px,0.75fr)]">
        <div>
          <label
            htmlFor="guardian-search"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Cari wali
          </label>

          <input
            id="guardian-search"
            name="q"
            type="search"
            defaultValue={query.search}
            placeholder="Nama, ID Pengguna, ID wali, email, atau telepon"
            autoComplete="off"
            spellCheck={false}
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          />

          <p className="mt-2 text-xs leading-5 text-slate-400">
            Pencarian dapat menggunakan nama,
            ID Pengguna, ID wali lama, email
            kontak, atau nomor telepon.
          </p>
        </div>

        <div>
          <label
            htmlFor="guardian-status"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Status data
          </label>

          <select
            id="guardian-status"
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
            htmlFor="account-status"
            className="mb-2 block text-xs font-semibold uppercase tracking-wide text-slate-500"
          >
            Akun login
          </label>

          <select
            id="account-status"
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
      </div>

      <div className="mt-5 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
        <Link
          href="/admin/wali"
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