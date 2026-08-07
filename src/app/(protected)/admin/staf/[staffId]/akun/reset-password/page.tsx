import type { Metadata } from "next";
import Link from "next/link";
import {
  notFound,
  redirect,
} from "next/navigation";

import { resetAdminStaffAccountPassword } from "@/features/admin/staff/actions/reset-admin-staff-account-password";
import { StaffAccountResetPasswordForm } from "@/features/admin/staff/components/staff-account-reset-password-form";
import { getAdminStaffDetail } from "@/features/admin/staff/data/get-admin-staff-detail";
import { initialStaffAccountResetPasswordActionState } from "@/features/admin/staff/types/staff-account-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Reset Password Staf",
};

type PageProps = {
  params: Promise<{
    staffId: string;
  }>;
};

export default async function ResetStaffPasswordPage({
  params,
}: PageProps) {
  await requireRole("admin");

  const { staffId } =
    await params;

  const data =
    await getAdminStaffDetail(
      staffId,
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
      `/admin/staf/${staffId}`,
    );
  }

  const detailHref =
    `/admin/staf/${staffId}`;

  const action =
    resetAdminStaffAccountPassword.bind(
      null,
      staffId,
    );

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <Link
        href={detailHref}
        className="inline-flex min-h-10 items-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600"
      >
        ← Kembali ke Detail Staf
      </Link>

      <h1 className="mt-6 text-3xl font-bold text-ink">
        Reset Password
      </h1>

      <p className="mt-3 text-muted">
        Tetapkan password baru untuk{" "}
        <strong>
          {data.staff.full_name}
        </strong>
        .
      </p>

      <div className="mt-6">
        <StaffAccountResetPasswordForm
          action={action}
          initialState={
            initialStaffAccountResetPasswordActionState
          }
          cancelHref={detailHref}
          staffName={
            data.staff.full_name
          }
          loginId={
            data.account.login_id
          }
        />
      </div>
    </div>
  );
}