import Link from "next/link";

import type { AdminStaffListItem } from "../schemas/admin-staff-list-schema";

type StaffDesktopTableProps = {
  staffItems:
    AdminStaffListItem[];
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
      word
        .charAt(0)
        .toUpperCase(),
    )
    .join("");
}

function getAccountStatusLabel(
  staff: AdminStaffListItem,
): string {
  if (!staff.account_linked) {
    return "Belum terhubung";
  }

  return staff.account_active
    ? "Akun aktif"
    : "Akun nonaktif";
}

function getAccountStatusClassName(
  staff: AdminStaffListItem,
): string {
  if (!staff.account_linked) {
    return "inline-flex rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500";
  }

  if (staff.account_active) {
    return "inline-flex rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700";
  }

  return "inline-flex rounded-full bg-amber-100 px-2.5 py-1 text-xs font-semibold text-amber-700";
}

export function StaffDesktopTable({
  staffItems,
}: StaffDesktopTableProps) {
  return (
    <div className="hidden overflow-hidden rounded-3xl border border-line bg-white shadow-soft lg:block">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[1180px] border-collapse">
          <thead>
            <tr className="border-b border-line bg-slate-50/80 text-left">
              <th className="px-5 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Staf
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Kontak dan jabatan
              </th>

              <th className="px-4 py-4 text-xs font-semibold uppercase tracking-wide text-slate-500">
                Role
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
            {staffItems.map(
              (staff) => (
                <tr
                  key={staff.id}
                  className="border-b border-line/80 transition last:border-b-0 hover:bg-brand-50/30"
                >
                  <td className="px-5 py-4">
                    <div className="flex items-center gap-3">
                      <div className="grid size-10 shrink-0 place-items-center rounded-2xl bg-brand-100 text-xs font-bold text-brand-700">
                        {getInitials(
                          staff.full_name,
                        )}
                      </div>

                      <div className="min-w-0">
                        <p className="max-w-72 truncate text-sm font-semibold text-ink">
                          {staff.full_name}
                        </p>

                        <p className="mt-1 text-xs text-slate-400">
                          ID Staf{" "}
                          {staff.legacy_staff_id ??
                            "-"}
                        </p>
                      </div>
                    </div>
                  </td>

                  <td className="px-4 py-4">
                    <p className="max-w-64 truncate text-sm font-semibold text-slate-700">
                      {staff.position ??
                        "Jabatan belum tersedia"}
                    </p>

                    <p className="mt-1 max-w-64 truncate text-xs text-slate-400">
                      {staff.phone ??
                        "Telepon belum tersedia"}
                    </p>
                  </td>

                  <td className="px-4 py-4">
                    {staff.roles.length > 0 ? (
                      <div className="flex max-w-72 flex-wrap gap-1.5">
                        {staff.roles.map(
                          (role) => (
                            <span
                              key={role.code}
                              className="rounded-full border border-brand-100 bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-700"
                            >
                              {role.name}
                            </span>
                          ),
                        )}
                      </div>
                    ) : (
                      <span className="text-xs text-slate-400">
                        Belum mempunyai role
                      </span>
                    )}
                  </td>

                  <td className="px-4 py-4">
                    <span
                      className={
                        staff.is_active
                          ? "inline-flex rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700"
                          : "inline-flex rounded-full bg-slate-200 px-2.5 py-1 text-xs font-semibold text-slate-600"
                      }
                    >
                      {staff.is_active
                        ? "Aktif"
                        : "Tidak aktif"}
                    </span>
                  </td>

                  <td className="px-4 py-4">
                    <span
                      className={getAccountStatusClassName(
                        staff,
                      )}
                    >
                      {getAccountStatusLabel(
                        staff,
                      )}
                    </span>

                    {staff.account_linked ? (
                      <div className="mt-2">
                        <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                          ID Pengguna
                        </p>

                        <p className="mt-1 max-w-56 break-all text-xs font-bold tracking-wide text-slate-700">
                          {staff.account_login_id ??
                            "Belum tersedia"}
                        </p>
                      </div>
                    ) : (
                      <p className="mt-2 text-xs text-slate-400">
                        Belum dibuatkan akun.
                      </p>
                    )}
                  </td>

                  <td className="px-5 py-4 text-right">
                    <Link
                      href={`/admin/staf/${staff.id}`}
                      className="inline-flex min-h-9 items-center justify-center rounded-xl border border-line bg-white px-3.5 text-xs font-semibold text-slate-600 transition hover:border-brand-200 hover:bg-brand-50 hover:text-brand-700"
                    >
                      Lihat detail
                    </Link>
                  </td>
                </tr>
              ),
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}