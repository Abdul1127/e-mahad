import type { Metadata } from "next";
import Link from "next/link";
import {
  notFound,
  redirect,
} from "next/navigation";

import { resetAdminGuardianAccountPassword } from "@/features/admin/guardians/actions/reset-admin-guardian-account-password";
import { GuardianAccountResetPasswordForm } from "@/features/admin/guardians/components/guardian-account-reset-password-form";
import { getAdminGuardianDetail } from "@/features/admin/guardians/data/get-admin-guardian-detail";
import { initialGuardianAccountResetPasswordActionState } from "@/features/admin/guardians/types/guardian-account-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Reset Password Wali",

  description:
    "Mengganti password akun orang tua atau wali E-Ma'had.",
};

type ResetGuardianPasswordPageProps = {
  params: Promise<{
    guardianId: string;
  }>;
};

export default async function ResetGuardianPasswordPage({
  params,
}: ResetGuardianPasswordPageProps) {
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

  if (
    !data.account.linked ||
    !data.account.profile_id ||
    !data.account.login_id
  ) {
    redirect(
      `/admin/wali/${guardianId}`,
    );
  }

  const resetPasswordAction =
    resetAdminGuardianAccountPassword.bind(
      null,
      guardianId,
    );

  const detailHref =
    `/admin/wali/${guardianId}`;

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <Link
          href={detailHref}
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
          Pengelolaan akun wali
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Reset Password
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Tetapkan password baru untuk akun{" "}
          <strong className="text-slate-700">
            {data.guardian.full_name}
          </strong>
          .
        </p>
      </section>

      <GuardianAccountResetPasswordForm
        action={resetPasswordAction}
        initialState={
          initialGuardianAccountResetPasswordActionState
        }
        cancelHref={detailHref}
        guardianName={
          data.guardian.full_name
        }
        loginId={
          data.account.login_id
        }
      />
    </div>
  );
}