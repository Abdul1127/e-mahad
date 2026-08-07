import type { Metadata } from "next";
import Link from "next/link";
import {
  notFound,
  redirect,
} from "next/navigation";

import { setAdminStaffRoles } from "@/features/admin/staff/actions/set-admin-staff-roles";
import { StaffRoleManagementForm } from "@/features/admin/staff/components/staff-role-management-form";
import { getAdminStaffDetail } from "@/features/admin/staff/data/get-admin-staff-detail";
import { getAdminStaffRoleOptions } from "@/features/admin/staff/data/get-admin-staff-role-options";
import { initialStaffRoleActionState } from "@/features/admin/staff/types/staff-account-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Kelola Role Staf",
};

type PageProps = {
  params: Promise<{
    staffId: string;
  }>;
};

export default async function StaffRolePage({
  params,
}: PageProps) {
  await requireRole("admin");

  const { staffId } =
    await params;

  const [
    data,
    roleOptions,
  ] = await Promise.all([
    getAdminStaffDetail(
      staffId,
    ),

    getAdminStaffRoleOptions(),
  ]);

  if (!data) {
    notFound();
  }

  if (
    !data.account.linked ||
    !data.account.login_id
  ) {
    redirect(
      `/admin/staf/${staffId}`,
    );
  }

  const detailHref =
    `/admin/staf/${staffId}`;

  const action =
    setAdminStaffRoles.bind(
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
        Kelola Role Staf
      </h1>

      <p className="mt-3 text-muted">
        Tambahkan atau hapus role aplikasi
        sesuai tugas staf.
      </p>

      <div className="mt-6">
        <StaffRoleManagementForm
          action={action}
          initialState={
            initialStaffRoleActionState
          }
          roleOptions={
            roleOptions
          }
          currentRoleCodes={
            data.roles.map(
              (role) =>
                role.code,
            )
          }
          staffName={
            data.staff.full_name
          }
          loginId={
            data.account.login_id
          }
          cancelHref={
            detailHref
          }
        />
      </div>
    </div>
  );
}