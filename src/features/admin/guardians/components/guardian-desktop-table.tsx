import Link from "next/link";

import type { AdminGuardianListItem } from "../schemas/admin-guardian-list-schema";

type GuardianDesktopTableProps = {
  guardians: AdminGuardianListItem[];
};

function getInitials(
  fullName: string,
): string {
  return fullName
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2)
    .map((word) =>
      word.charAt(0).toUpperCase(),
    )
    .join("");
}

function getAccountStatusLabel(
  guardian: AdminGuardianListItem,
): string {
  if (!guardian.account_linked) {
    return "Belum terhubung";
  }

  return guardian.account_active
    ? "Akun aktif"
    : "Akun nonaktif";
}

function getAccountStatusClassName(
  guardian: AdminGuardianListItem,
): string {
  if (!guardian.account_linked) {
    return "inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500";
  }

  if (guardian.account_active) {
    return "inline-flex rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700";
  }

  return "inline-flex rounded-full bg-amber-100 px-2.5 py-1 text-xs font-semibold text-amber-700";
}

export function GuardianDesktopTable({
  guardians,
}: GuardianDesktopTableProps) {
  return (
    <div className="hidden overflow-hidden rounded-3xl border border-line bg-white shadow-soft lg:block">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[1180px] border-collapse">
          <thead>
            <tr className="border-b border-line bg-slate-50/80 text-left">
              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Orang tua atau wali
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Kontak
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Anak
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Status data
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Akun login
              </th>

              <th className="px-5 py-4 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                Aksi
              </th>
            </tr>
          </thead>

          <tbody>
            {guardians.map((guardian) => (
              <tr
                key={guardian.id}
                className="border-b border-line/80 transition last:border-b-0 hover:bg-brand-50/30"
              >
                <td className="px-5 py-4">
                  <div className="flex items-center gap-3">
                    <div className="grid size-10 shrink-0 place-items-center rounded-2xl bg-brand-100 text-xs font-bold text-brand-700">
                      {getInitials(
                        guardian.full_name,
                      )}
                    </div>

                    <div className="min-w-0">
                      <p className="max-w-72 truncate text-sm font-semibold text-ink">
                        {guardian.full_name}
                      </p>

                      <p className="mt-1 text-xs text-slate-400">
                        ID Wali{" "}
                        {guardian.legacy_guardian_id ??
                          "-"}
                      </p>
                    </div>
                  </div>
                </td>

                <td className="px-4 py-4">
                  <p className="max-w-64 truncate text-sm font-medium text-slate-700">
                    {guardian.phone ??
                      "Telepon belum tersedia"}
                  </p>

                  <p className="mt-1 max-w-64 truncate text-xs text-slate-400">
                    {guardian.email ??
                      "Email kontak belum tersedia"}
                  </p>
                </td>

                <td className="px-4 py-4">
                  <p className="text-sm font-semibold text-slate-700">
                    {guardian.children_count} anak
                  </p>

                  <p className="mt-1 text-xs text-slate-400">
                    {
                      guardian.active_children_count
                    }{" "}
                    santri aktif
                  </p>

                  {guardian.primary_contact_count >
                    0 && (
                    <p className="mt-1 text-xs font-medium text-brand-700">
                      {
                        guardian.primary_contact_count
                      }{" "}
                      kontak utama
                    </p>
                  )}
                </td>

                <td className="px-4 py-4">
                  <span
                    className={
                      guardian.is_active
                        ? "inline-flex rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700"
                        : "inline-flex rounded-full bg-slate-200 px-2.5 py-1 text-xs font-semibold text-slate-600"
                    }
                  >
                    {guardian.is_active
                      ? "Aktif"
                      : "Tidak aktif"}
                  </span>
                </td>

                <td className="px-4 py-4">
                  <span
                    className={getAccountStatusClassName(
                      guardian,
                    )}
                  >
                    {getAccountStatusLabel(
                      guardian,
                    )}
                  </span>

                  {guardian.account_linked ? (
                    <div className="mt-2">
                      <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                        ID Pengguna
                      </p>

                      <p className="mt-1 max-w-56 break-all text-xs font-bold tracking-wide text-slate-700">
                        {guardian.account_login_id ??
                          "Belum tersedia"}
                      </p>
                    </div>
                  ) : (
                    <p className="mt-2 max-w-56 text-xs leading-5 text-slate-400">
                      Dibuat melalui detail wali.
                    </p>
                  )}
                </td>

                <td className="px-5 py-4 text-right">
                  <Link
                    href={`/admin/wali/${guardian.id}`}
                    className="inline-flex min-h-9 items-center justify-center rounded-xl border border-line bg-white px-3.5 text-xs font-semibold text-slate-600 transition hover:border-brand-200 hover:bg-brand-50 hover:text-brand-700"
                  >
                    Lihat detail
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}