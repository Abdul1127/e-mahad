import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { createAdminGuardianStudentRelation } from "@/features/admin/guardians/actions/create-admin-guardian-student-relation";
import { GuardianStudentRelationForm } from "@/features/admin/guardians/components/guardian-student-relation-form";
import { getAdminGuardianDetail } from "@/features/admin/guardians/data/get-admin-guardian-detail";
import { getAdminGuardianStudentOptions } from "@/features/admin/guardians/data/get-admin-guardian-student-options";
import { initialGuardianStudentRelationActionState } from "@/features/admin/guardians/types/guardian-student-relation-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Hubungkan Santri",
  description:
    "Hubungkan orang tua atau wali dengan santri E-Ma'had.",
};

type SearchParams = Record<
  string,
  string | string[] | undefined
>;

type LinkGuardianStudentPageProps = {
  params: Promise<{
    guardianId: string;
  }>;

  searchParams: Promise<SearchParams>;
};

function getFirstValue(
  value: string | string[] | undefined,
): string {
  if (Array.isArray(value)) {
    return value[0] ?? "";
  }

  return value ?? "";
}

export default async function LinkGuardianStudentPage({
  params,
  searchParams,
}: LinkGuardianStudentPageProps) {
  await requireRole("admin");

  const { guardianId } = await params;

  const resolvedSearchParams =
    await searchParams;

  const search = getFirstValue(
    resolvedSearchParams.q,
  )
    .trim()
    .slice(0, 100);

  const guardianData =
    await getAdminGuardianDetail(
      guardianId,
    );

  if (!guardianData) {
    notFound();
  }

  const guardian =
    guardianData.guardian;

  const options =
    await getAdminGuardianStudentOptions(
      guardianId,
      search,
    );

  const relationAction =
    createAdminGuardianStudentRelation.bind(
      null,
      guardianId,
    );

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <Link
          href={`/admin/wali/${guardianId}`}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          <span
            aria-hidden="true"
            className="mr-2"
          >
            ←
          </span>

          Kembali ke Detail Wali
        </Link>

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Hubungan wali dan santri
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Hubungkan Santri
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Pilih santri yang akan dihubungkan
          dengan{" "}
          <strong className="text-slate-700">
            {guardian.full_name}
          </strong>
          .
        </p>
      </section>

      {!guardian.is_active ? (
        <section className="rounded-3xl border border-amber-200 bg-amber-50 p-6 shadow-soft">
          <h2 className="text-lg font-bold text-amber-800">
            Data wali tidak aktif
          </h2>

          <p className="mt-2 text-sm leading-6 text-amber-700">
            Aktifkan kembali data wali melalui
            halaman edit sebelum menghubungkan
            santri.
          </p>

          <Link
            href={`/admin/wali/${guardianId}/edit`}
            className="mt-5 inline-flex min-h-11 items-center justify-center rounded-xl bg-amber-700 px-5 text-sm font-semibold text-white transition hover:bg-amber-800"
          >
            Edit wali
          </Link>
        </section>
      ) : (
        <>
          <form
            method="get"
            action={`/admin/wali/${guardianId}/hubungkan`}
            className="mb-5 rounded-3xl border border-line bg-white p-5 shadow-soft"
          >
            <label
              htmlFor="student-search"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              Cari santri
            </label>

            <div className="flex flex-col gap-3 sm:flex-row">
              <input
                id="student-search"
                name="q"
                type="search"
                defaultValue={search}
                placeholder="Nama, ID santri, atau NIS"
                className="min-h-11 flex-1 rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
              />

              <button
                type="submit"
                className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
              >
                Cari santri
              </button>

              <Link
                href={`/admin/wali/${guardianId}/hubungkan`}
                className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
              >
                Reset
              </Link>
            </div>
          </form>

          <GuardianStudentRelationForm
            guardianId={guardianId}
            options={options.items}
            action={relationAction}
            initialState={
              initialGuardianStudentRelationActionState
            }
          />
        </>
      )}
    </div>
  );
}