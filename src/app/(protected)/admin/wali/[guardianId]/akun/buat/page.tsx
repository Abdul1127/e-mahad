import type { Metadata } from "next";
import Link from "next/link";
import {
  notFound,
  redirect,
} from "next/navigation";

import { createAdminGuardianAccount } from "@/features/admin/guardians/actions/create-admin-guardian-account";
import { GuardianAccountCreateForm } from "@/features/admin/guardians/components/guardian-account-create-form";
import { getAdminGuardianDetail } from "@/features/admin/guardians/data/get-admin-guardian-detail";
import { getAdminGuardianLoginIdentity } from "@/features/admin/guardians/data/get-admin-guardian-login-identity";
import { initialGuardianAccountActionState } from "@/features/admin/guardians/types/guardian-account-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Buat Akun Wali",

  description:
    "Membuat akun login orang tua atau wali menggunakan ID Pengguna.",
};

type CreateGuardianAccountPageProps = {
  params: Promise<{
    guardianId: string;
  }>;
};

export default async function CreateGuardianAccountPage({
  params,
}: CreateGuardianAccountPageProps) {
  await requireRole("admin");

  const { guardianId } =
    await params;

  const data =
    await getAdminGuardianDetail(
      guardianId,
    );

  if (!data) {
    notFound();
  }

  if (data.account.linked) {
    redirect(
      `/admin/wali/${guardianId}`,
    );
  }

  const detailHref =
    `/admin/wali/${guardianId}`;

  if (!data.guardian.is_active) {
    return (
      <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
        <Link
          href={detailHref}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600"
        >
          ← Kembali ke Detail Wali
        </Link>

        <section className="mt-6 rounded-3xl border border-amber-200 bg-amber-50 p-6 shadow-soft">
          <h1 className="text-lg font-bold text-amber-800">
            Data wali tidak aktif
          </h1>

          <p className="mt-2 text-sm leading-6 text-amber-700">
            Aktifkan data wali terlebih dahulu
            sebelum membuat akun login.
          </p>

          <Link
            href={`/admin/wali/${guardianId}/edit`}
            className="mt-5 inline-flex min-h-11 items-center justify-center rounded-xl bg-amber-700 px-5 text-sm font-semibold text-white"
          >
            Edit wali
          </Link>
        </section>
      </div>
    );
  }

  if (
    data.summary.children_count === 0
  ) {
    return (
      <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
        <Link
          href={detailHref}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600"
        >
          ← Kembali ke Detail Wali
        </Link>

        <section className="mt-6 rounded-3xl border border-amber-200 bg-amber-50 p-6 shadow-soft">
          <h1 className="text-lg font-bold text-amber-800">
            Belum ada santri terhubung
          </h1>

          <p className="mt-2 text-sm leading-6 text-amber-700">
            Hubungkan wali dengan minimal satu
            santri sebelum membuat akun login.
          </p>

          <Link
            href={`/admin/wali/${guardianId}/hubungkan`}
            className="mt-5 inline-flex min-h-11 items-center justify-center rounded-xl bg-amber-700 px-5 text-sm font-semibold text-white"
          >
            Hubungkan santri
          </Link>
        </section>
      </div>
    );
  }

  const loginIdentity =
    await getAdminGuardianLoginIdentity(
      guardianId,
    );

  if (
    loginIdentity.status ===
    "existing"
  ) {
    redirect(detailHref);
  }

  const createAccountAction =
    createAdminGuardianAccount.bind(
      null,
      guardianId,
    );

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <Link
          href={detailHref}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          ← Kembali ke Detail Wali
        </Link>

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Akun orang tua atau wali
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Buat Akun Login
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Buat ID Pengguna dan password untuk{" "}
          <strong className="text-slate-700">
            {data.guardian.full_name}
          </strong>
          .
        </p>
      </section>

      <GuardianAccountCreateForm
        guardian={data.guardian}
        loginIdentity={
          loginIdentity
        }
        action={
          createAccountAction
        }
        initialState={
          initialGuardianAccountActionState
        }
        cancelHref={detailHref}
      />
    </div>
  );
}