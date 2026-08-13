import {
  PreserveStateLink,
} from "@/components/navigation/navigation-state-link";

import type { AdminStaffListItem } from "../schemas/admin-staff-list-schema";

type StaffMobileListProps = {
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
    return "mt-1.5 text-sm font-semibold text-slate-500";
  }

  if (staff.account_active) {
    return "mt-1.5 text-sm font-semibold text-brand-700";
  }

  return "mt-1.5 text-sm font-semibold text-amber-700";
}

export function StaffMobileList({
  staffItems,
}: StaffMobileListProps) {
  return (
    <div className="space-y-3 lg:hidden">
      {staffItems.map(
        (staff) => (
          <article
            key={staff.id}
            className="rounded-3xl border border-line bg-white p-5 shadow-soft"
          >
            <div className="flex items-start gap-3">
              <div className="grid size-11 shrink-0 place-items-center rounded-2xl bg-brand-100 text-sm font-bold text-brand-700">
                {getInitials(
                  staff.full_name,
                )}
              </div>

              <div className="min-w-0 flex-1">
                <h2 className="break-words text-base font-bold leading-6 text-ink">
                  {staff.full_name}
                </h2>

                <p className="mt-1 text-xs text-slate-500">
                  ID Staf{" "}
                  {staff.legacy_staff_id ??
                    "-"}
                </p>
              </div>

              <span
                className={
                  staff.is_active
                    ? "shrink-0 rounded-full bg-brand-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-brand-700"
                    : "shrink-0 rounded-full bg-slate-200 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-slate-600"
                }
              >
                {staff.is_active
                  ? "Aktif"
                  : "Nonaktif"}
              </span>
            </div>

            <dl className="mt-5 grid gap-3 sm:grid-cols-2">
              <div className="rounded-2xl bg-slate-50 p-3.5">
                <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                  Jabatan
                </dt>

                <dd className="mt-1.5 break-words text-sm font-semibold text-slate-700">
                  {staff.position ??
                    "Belum tersedia"}
                </dd>
              </div>

              <div className="rounded-2xl bg-slate-50 p-3.5">
                <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                  Telepon
                </dt>

                <dd className="mt-1.5 break-words text-sm font-semibold text-slate-700">
                  {staff.phone ??
                    "Belum tersedia"}
                </dd>
              </div>

              <div className="rounded-2xl bg-slate-50 p-3.5 sm:col-span-2">
                <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                  Role
                </dt>

                <dd className="mt-2">
                  {staff.roles.length > 0 ? (
                    <div className="flex flex-wrap gap-1.5">
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
                    <span className="text-sm font-semibold text-slate-500">
                      Belum mempunyai role
                    </span>
                  )}
                </dd>
              </div>

              <div className="rounded-2xl bg-slate-50 p-3.5 sm:col-span-2">
                <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                  Akun login
                </dt>

                <dd
                  className={getAccountStatusClassName(
                    staff,
                  )}
                >
                  {getAccountStatusLabel(
                    staff,
                  )}
                </dd>

                {staff.account_linked ? (
                  <div className="mt-2 border-t border-slate-200 pt-2">
                    <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                      ID Pengguna
                    </p>

                    <p className="mt-1 break-all text-xs font-bold tracking-wide text-slate-700">
                      {staff.account_login_id ??
                        "Belum tersedia"}
                    </p>
                  </div>
                ) : (
                  <p className="mt-2 text-xs text-slate-400">
                    Belum dibuatkan akun.
                  </p>
                )}
              </div>
            </dl>

            <PreserveStateLink
              href={`/admin/staf/${staff.id}`}
              className="mt-4 inline-flex min-h-10 w-full items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 transition hover:border-brand-200 hover:bg-brand-50 hover:text-brand-700"
            >
              Lihat detail staf
            </PreserveStateLink>
          </article>
        ),
      )}
    </div>
  );
}