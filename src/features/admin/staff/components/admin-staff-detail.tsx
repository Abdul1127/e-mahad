import Link from "next/link";

import {
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import { setAdminStaffAccountStatus } from "../actions/set-admin-staff-account-status";
import type { AdminStaffDetailData } from "../schemas/admin-staff-detail-schema";

import { StaffAccountStatusButton } from "./staff-account-status-button";

type AdminStaffDetailProps = {
  data: AdminStaffDetailData;
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

function formatDateTime(
  value: string,
): string {
  const date = new Date(value);

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return "-";
  }

  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle: "long",
      timeStyle: "short",
      timeZone: "Asia/Jakarta",
    },
  ).format(date);
}

function getAccountStatusLabel(
  account:
    AdminStaffDetailData["account"],
): string {
  if (!account.linked) {
    return "Belum terhubung";
  }

  return account.active
    ? "Akun aktif"
    : "Akun nonaktif";
}

function getAccountStatusClassName(
  account:
    AdminStaffDetailData["account"],
): string {
  if (!account.linked) {
    return "rounded-full bg-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-600";
  }

  if (account.active) {
    return "rounded-full bg-brand-100 px-3 py-1.5 text-xs font-semibold text-brand-700";
  }

  return "rounded-full bg-amber-100 px-3 py-1.5 text-xs font-semibold text-amber-700";
}

export function AdminStaffDetail({
  data,
}: AdminStaffDetailProps) {
  const staff = data.staff;
  const account = data.account;
  const summary = data.summary;

  const accountStatusAction =
    account.linked
      ? setAdminStaffAccountStatus.bind(
          null,
          staff.id,
          !account.active,
        )
      : null;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <ReturnLink
          fallbackHref="/admin/staf"
          allowedPrefixes={["/admin/staf"]}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          <span
            aria-hidden="true"
            className="mr-2"
          >
            ?
          </span>

          Kembali ke Data Staf
        </ReturnLink>

        <div className="mt-6">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Staf pesantren
          </p>

          <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
            Detail Staf
          </h1>

          <p className="mt-3 max-w-2xl leading-7 text-muted">
            Informasi identitas staf, akun
            login, dan role aplikasi yang
            diberikan.
          </p>
        </div>
      </section>

      <section className="grid gap-6 xl:grid-cols-[minmax(320px,0.85fr)_minmax(0,1.15fr)]">
        <article className="rounded-3xl border border-line bg-white p-6 shadow-soft">
          <div className="flex items-start gap-4">
            <div className="grid size-14 shrink-0 place-items-center rounded-2xl bg-brand-100 text-base font-bold text-brand-700">
              {getInitials(
                staff.full_name,
              )}
            </div>

            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="break-words text-xl font-bold text-ink">
                  {staff.full_name}
                </h2>

                <span
                  className={
                    staff.is_active
                      ? "rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700"
                      : "rounded-full bg-slate-200 px-2.5 py-1 text-xs font-semibold text-slate-600"
                  }
                >
                  {staff.is_active
                    ? "Aktif"
                    : "Tidak aktif"}
                </span>
              </div>

              <p className="mt-2 text-sm text-slate-500">
                ID Staf{" "}
                <strong className="text-slate-700">
                  {staff.legacy_staff_id ??
                    "-"}
                </strong>
              </p>
            </div>
          </div>

          <dl className="mt-6 grid gap-3 sm:grid-cols-2">
            <div className="rounded-2xl bg-slate-50 p-4 sm:col-span-2">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Jabatan
              </dt>

              <dd className="mt-2 break-words text-sm font-semibold text-slate-700">
                {staff.position ??
                  "Belum tersedia"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Nomor telepon
              </dt>

              <dd className="mt-2 break-words text-sm font-semibold text-slate-700">
                {staff.phone ??
                  "Belum tersedia"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Status data
              </dt>

              <dd className="mt-2 text-sm font-semibold text-slate-700">
                {staff.is_active
                  ? "Staf aktif"
                  : "Staf tidak aktif"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Dibuat
              </dt>

              <dd className="mt-2 text-sm font-semibold leading-6 text-slate-700">
                {formatDateTime(
                  staff.created_at,
                )}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Diperbarui
              </dt>

              <dd className="mt-2 text-sm font-semibold leading-6 text-slate-700">
                {formatDateTime(
                  staff.updated_at,
                )}
              </dd>
            </div>
          </dl>
        </article>

        <article className="rounded-3xl border border-line bg-white p-6 shadow-soft">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div>
              <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
                Akun staf
              </p>

              <h2 className="mt-2 text-xl font-bold text-ink">
                {account.linked
                  ? "Akun sudah terhubung"
                  : "Belum memiliki akun login"}
              </h2>
            </div>

            <span
              className={getAccountStatusClassName(
                account,
              )}
            >
              {getAccountStatusLabel(
                account,
              )}
            </span>
          </div>

          {account.linked ? (
            <div className="mt-5">
              <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
                <p className="text-xs font-semibold uppercase tracking-wide text-brand-600">
                  ID Pengguna
                </p>

                <p className="mt-2 break-all text-lg font-bold tracking-wide text-brand-900">
                  {account.login_id ??
                    "ID Pengguna belum tersedia"}
                </p>

                <p className="mt-3 text-sm leading-6 text-brand-700">
                  Staf menggunakan ID Pengguna
                  tersebut bersama password untuk
                  masuk ke E-Ma&apos;had.
                </p>
              </div>

              {account.login_id ? (
                <div className="mt-5 flex flex-col gap-3 border-t border-line pt-5 sm:flex-row sm:flex-wrap">
                  <Link
                    href={`/admin/staf/${staff.id}/akun/reset-password`}
                    className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
                  >
                    Reset Password
                  </Link>

                  <Link
                    href={`/admin/staf/${staff.id}/akun/role`}
                    className="inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
                  >
                    Kelola Role
                  </Link>

                  {!account.active &&
                  !staff.is_active ? (
                    <div className="rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-5 text-amber-700">
                      Data staf sedang tidak aktif.
                      Aktifkan data staf terlebih
                      dahulu sebelum mengaktifkan
                      kembali akun login.
                    </div>
                  ) : (
                    accountStatusAction && (
                      <StaffAccountStatusButton
                        action={
                          accountStatusAction
                        }
                        targetIsActive={
                          !account.active
                        }
                        staffName={
                          staff.full_name
                        }
                      />
                    )
                  )}
                </div>
              ) : (
                <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm leading-6 text-amber-700">
                  Akun sudah terhubung, tetapi ID
                  Pengguna belum tersedia. Periksa
                  data profile akun staf.
                </div>
              )}
            </div>
          ) : (
            <div className="mt-5">
              <div className="rounded-2xl border border-amber-200 bg-amber-50 p-5">
                <p className="text-sm font-bold text-amber-800">
                  Akun belum dibuat
                </p>

                <p className="mt-2 text-sm leading-6 text-amber-700">
                  ID Pengguna akan dibentuk dari
                  ID staf dengan format{" "}
                  <strong>
                    STF-
                    {staff.legacy_staff_id ??
                      "ID-STAF"}
                  </strong>
                  .
                </p>
              </div>

              {staff.is_active ? (
                <Link
                  href={`/admin/staf/${staff.id}/akun/buat`}
                  className="mt-5 inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
                >
                  Buat akun login
                </Link>
              ) : (
                <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-xs leading-5 text-amber-700">
                  Aktifkan data staf terlebih
                  dahulu sebelum membuat akun
                  login.
                </div>
              )}
            </div>
          )}

          <div className="mt-5 grid gap-3 sm:grid-cols-2">
            <div className="rounded-2xl border border-line p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Jumlah role
              </p>

              <p className="mt-2 text-2xl font-bold text-ink">
                {summary.role_count}
              </p>
            </div>

            <div className="rounded-2xl border border-line p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Status akun
              </p>

              <p className="mt-2 text-sm font-bold text-slate-700">
                {getAccountStatusLabel(
                  account,
                )}
              </p>
            </div>
          </div>
        </article>
      </section>

      <section className="mt-6 rounded-3xl border border-line bg-white p-6 shadow-soft">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Hak akses
            </p>

            <h2 className="mt-2 text-xl font-bold text-ink">
              Role Staf
            </h2>

            <p className="mt-2 max-w-2xl text-sm leading-6 text-muted">
              Satu staf dapat memiliki lebih dari
              satu role aplikasi sesuai tugas dan
              tanggung jawabnya.
            </p>
          </div>

          {account.linked &&
            account.login_id && (
              <Link
                href={`/admin/staf/${staff.id}/akun/role`}
                className="inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
              >
                Kelola Role
              </Link>
            )}
        </div>

        {data.roles.length === 0 ? (
          <div className="mt-5 rounded-2xl border border-dashed border-amber-300 bg-amber-50 px-5 py-8 text-center">
            <h3 className="font-bold text-amber-800">
              Belum mempunyai role
            </h3>

            <p className="mt-2 text-sm leading-6 text-amber-700">
              {account.linked
                ? "Akun staf belum mempunyai role operasional."
                : "Role akan dipilih ketika Admin membuat akun login staf."}
            </p>
          </div>
        ) : (
          <div className="mt-5 grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {data.roles.map(
              (role) => (
                <article
                  key={role.code}
                  className="rounded-2xl border border-brand-100 bg-brand-50 p-4"
                >
                  <p className="text-xs font-semibold uppercase tracking-wide text-brand-600">
                    {role.code}
                  </p>

                  <h3 className="mt-2 font-bold text-brand-900">
                    {role.name}
                  </h3>
                </article>
              ),
            )}
          </div>
        )}
      </section>
    </div>
  );
}