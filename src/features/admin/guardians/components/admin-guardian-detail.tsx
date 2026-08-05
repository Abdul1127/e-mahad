import Link from "next/link";

import { deleteAdminGuardianStudentRelation } from "../actions/delete-admin-guardian-student-relation";
import type { AdminGuardianDetailData } from "../schemas/admin-guardian-detail-schema";

import { GuardianStudentRelationDeleteButton } from "./guardian-student-relation-delete-button";

type AdminGuardianDetailProps = {
  data: AdminGuardianDetailData;
};

const relationshipLabels: Record<
  string,
  string
> = {
  father: "Ayah",
  mother: "Ibu",
  guardian: "Wali",
  other: "Lainnya",
};

function formatDateTime(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle: "long",
      timeStyle: "short",
      timeZone: "Asia/Jakarta",
    },
  ).format(new Date(value));
}

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

export function AdminGuardianDetail({
  data,
}: AdminGuardianDetailProps) {
  const guardian = data.guardian;
  const account = data.account;
  const summary = data.summary;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <Link
          href="/admin/wali"
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          <span
            aria-hidden="true"
            className="mr-2"
          >
            ←
          </span>

          Kembali ke Data Wali
        </Link>

        <div className="mt-6 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Orang tua atau wali
            </p>

            <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
              Detail Wali
            </h1>

            <p className="mt-3 max-w-2xl leading-7 text-muted">
              Informasi identitas, akun login,
              serta santri yang terhubung.
            </p>
          </div>

          <div className="flex flex-col gap-3 sm:flex-row">
            {guardian.is_active && (
              <Link
                href={`/admin/wali/${guardian.id}/hubungkan`}
                className="inline-flex min-h-11 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-5 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
              >
                Hubungkan santri
              </Link>
            )}

            <Link
              href={`/admin/wali/${guardian.id}/edit`}
              className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
            >
              Edit wali
            </Link>
          </div>
        </div>
      </section>

      <section className="grid gap-6 xl:grid-cols-[minmax(320px,0.85fr)_minmax(0,1.15fr)]">
        <article className="rounded-3xl border border-line bg-white p-6 shadow-soft">
          <div className="flex items-start gap-4">
            <div className="grid size-14 shrink-0 place-items-center rounded-2xl bg-brand-100 text-base font-bold text-brand-700">
              {getInitials(
                guardian.full_name,
              )}
            </div>

            <div className="min-w-0">
              <div className="flex flex-wrap items-center gap-2">
                <h2 className="text-xl font-bold text-ink">
                  {guardian.full_name}
                </h2>

                <span
                  className={
                    guardian.is_active
                      ? "rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700"
                      : "rounded-full bg-slate-200 px-2.5 py-1 text-xs font-semibold text-slate-600"
                  }
                >
                  {guardian.is_active
                    ? "Aktif"
                    : "Tidak aktif"}
                </span>
              </div>

              <p className="mt-2 text-sm text-slate-500">
                ID Wali{" "}
                <strong className="text-slate-700">
                  {guardian.legacy_guardian_id ??
                    "-"}
                </strong>
              </p>
            </div>
          </div>

          <dl className="mt-6 grid gap-3 sm:grid-cols-2">
            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Nomor telepon
              </dt>

              <dd className="mt-2 break-words text-sm font-semibold text-slate-700">
                {guardian.phone ??
                  "Belum tersedia"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Email data
              </dt>

              <dd className="mt-2 break-all text-sm font-semibold text-slate-700">
                {guardian.email ??
                  "Belum tersedia"}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Dibuat
              </dt>

              <dd className="mt-2 text-sm font-semibold text-slate-700">
                {formatDateTime(
                  guardian.created_at,
                )}
              </dd>
            </div>

            <div className="rounded-2xl bg-slate-50 p-4">
              <dt className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Diperbarui
              </dt>

              <dd className="mt-2 text-sm font-semibold text-slate-700">
                {formatDateTime(
                  guardian.updated_at,
                )}
              </dd>
            </div>
          </dl>
        </article>

        <article className="rounded-3xl border border-line bg-white p-6 shadow-soft">
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Akun keluarga
          </p>

          <div className="mt-4 flex flex-col gap-4 rounded-2xl bg-slate-50 p-5 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="text-lg font-bold text-ink">
                {account.linked
                  ? "Akun sudah terhubung"
                  : "Belum memiliki akun login"}
              </h2>

              <p className="mt-2 text-sm leading-6 text-muted">
                {account.linked
                  ? account.login_email ??
                    "Email login belum tersedia."
                  : "Pembuatan akun login wali akan dilakukan pada tahap akun orang tua."}
              </p>
            </div>

            <span
              className={
                account.linked
                  ? account.active
                    ? "shrink-0 rounded-full bg-brand-100 px-3 py-1.5 text-xs font-semibold text-brand-700"
                    : "shrink-0 rounded-full bg-amber-100 px-3 py-1.5 text-xs font-semibold text-amber-700"
                  : "shrink-0 rounded-full bg-slate-200 px-3 py-1.5 text-xs font-semibold text-slate-600"
              }
            >
              {account.linked
                ? account.active
                  ? "Akun aktif"
                  : "Akun nonaktif"
                : "Belum terhubung"}
            </span>
          </div>

          <div className="mt-5 grid gap-3 sm:grid-cols-3">
            <div className="rounded-2xl border border-line p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Total anak
              </p>

              <p className="mt-2 text-2xl font-bold text-ink">
                {summary.children_count}
              </p>
            </div>

            <div className="rounded-2xl border border-line p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Santri aktif
              </p>

              <p className="mt-2 text-2xl font-bold text-ink">
                {
                  summary.active_children_count
                }
              </p>
            </div>

            <div className="rounded-2xl border border-line p-4">
              <p className="text-xs font-semibold uppercase tracking-wide text-slate-400">
                Kontak utama
              </p>

              <p className="mt-2 text-2xl font-bold text-ink">
                {
                  summary.primary_contact_count
                }
              </p>
            </div>
          </div>
        </article>
      </section>

      <section className="mt-6 rounded-3xl border border-line bg-white p-6 shadow-soft">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Hubungan santri
            </p>

            <h2 className="mt-2 text-xl font-bold text-ink">
              Anak yang Terhubung
            </h2>

            <p className="mt-2 text-sm text-muted">
              {summary.children_count} hubungan
              wali dan santri.
            </p>
          </div>

          {guardian.is_active && (
            <Link
              href={`/admin/wali/${guardian.id}/hubungkan`}
              className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-700 px-4 text-sm font-semibold text-white transition hover:bg-brand-800"
            >
              Hubungkan santri
            </Link>
          )}
        </div>

        {data.children.length === 0 ? (
          <div className="mt-5 rounded-2xl border border-dashed border-amber-300 bg-amber-50 px-5 py-8 text-center">
            <h3 className="font-bold text-amber-800">
              Belum ada santri terhubung
            </h3>

            <p className="mt-2 text-sm leading-6 text-amber-700">
              Hubungkan wali dengan satu atau
              beberapa santri agar data keluarga
              dapat digunakan.
            </p>

            {guardian.is_active && (
              <Link
                href={`/admin/wali/${guardian.id}/hubungkan`}
                className="mt-5 inline-flex min-h-10 items-center justify-center rounded-xl bg-amber-700 px-4 text-sm font-semibold text-white transition hover:bg-amber-800"
              >
                Hubungkan santri pertama
              </Link>
            )}
          </div>
        ) : (
          <div className="mt-5 grid gap-3">
            {data.children.map((child) => {
              const deleteAction =
                deleteAdminGuardianStudentRelation.bind(
                  null,
                  guardian.id,
                  child.relation_id,
                );

              return (
                <article
                  key={child.relation_id}
                  className="flex flex-col gap-4 rounded-2xl border border-line p-4 lg:flex-row lg:items-center lg:justify-between"
                >
                  <div className="min-w-0">
                    <div className="flex flex-wrap items-center gap-2">
                      <h3 className="font-bold text-ink">
                        {child.full_name}
                      </h3>

                      <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                        {relationshipLabels[
                          child.relationship_type
                        ] ??
                          child.relationship_type}
                      </span>

                      {child.is_primary_contact && (
                        <span className="rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700">
                          Kontak utama
                        </span>
                      )}
                    </div>

                    <p className="mt-2 text-sm text-muted">
                      {child.class_name ??
                        "Belum ada kelas aktif"}

                      {child.academic_year_name
                        ? ` · ${child.academic_year_name}`
                        : ""}
                    </p>

                    <p className="mt-1 text-xs text-slate-400">
                      NIS: {child.nis ?? "-"}
                    </p>
                  </div>

                  <div className="flex flex-col gap-2 sm:flex-row lg:shrink-0">
                    <Link
                      href={`/admin/santri/${child.student_id}`}
                      className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
                    >
                      Lihat santri
                    </Link>

                    <Link
                      href={`/admin/wali/${guardian.id}/hubungan/${child.relation_id}/edit`}
                      className="inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
                    >
                      Edit hubungan
                    </Link>

                    <GuardianStudentRelationDeleteButton
                      action={deleteAction}
                      studentName={
                        child.full_name
                      }
                    />
                  </div>
                </article>
              );
            })}
          </div>
        )}
      </section>
    </div>
  );
}