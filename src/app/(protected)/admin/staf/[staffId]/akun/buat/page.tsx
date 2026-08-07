import type { Metadata } from "next";
import Link from "next/link";
import {
  notFound,
  redirect,
} from "next/navigation";

import { createAdminStaffAccount } from "@/features/admin/staff/actions/create-admin-staff-account";
import { StaffAccountCreateForm } from "@/features/admin/staff/components/staff-account-create-form";
import { getAdminStaffDetail } from "@/features/admin/staff/data/get-admin-staff-detail";
import { getAdminStaffLoginIdentity } from "@/features/admin/staff/data/get-admin-staff-login-identity";
import { getAdminStaffRoleOptions } from "@/features/admin/staff/data/get-admin-staff-role-options";
import { initialStaffAccountActionState } from "@/features/admin/staff/types/staff-account-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Buat Akun Staf",
  description:
    "Membuat akun login dan menetapkan role staf E-Ma'had.",
};

type CreateStaffAccountPageProps = {
  params: Promise<{
    staffId: string;
  }>;
};

export default async function CreateStaffAccountPage({
  params,
}: CreateStaffAccountPageProps) {
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

  const detailHref =
    `/admin/staf/${staffId}`;

  if (data.account.linked) {
    redirect(detailHref);
  }

  if (!data.staff.is_active) {
    return (
      <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
        <Link
          href={detailHref}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600"
        >
          ← Kembali ke Detail Staf
        </Link>

        <section className="mt-6 rounded-3xl border border-amber-200 bg-amber-50 p-6 shadow-soft">
          <h1 className="text-lg font-bold text-amber-800">
            Data staf tidak aktif
          </h1>

          <p className="mt-2 text-sm leading-6 text-amber-700">
            Staf harus berstatus aktif sebelum
            dibuatkan akun login.
          </p>
        </section>
      </div>
    );
  }

  const [
    loginIdentity,
    roleOptions,
  ] = await Promise.all([
    getAdminStaffLoginIdentity(
      staffId,
    ),

    getAdminStaffRoleOptions(),
  ]);

  if (
    loginIdentity.status ===
    "existing"
  ) {
    redirect(detailHref);
  }

  const createAccountAction =
    createAdminStaffAccount.bind(
      null,
      staffId,
    );

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <Link
          href={detailHref}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          ← Kembali ke Detail Staf
        </Link>

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pengelolaan akun staf
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Buat Akun Login
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Buat ID Pengguna, password, dan role
          aplikasi untuk{" "}
          <strong className="text-slate-700">
            {data.staff.full_name}
          </strong>
          .
        </p>
      </section>

      <StaffAccountCreateForm
        staff={data.staff}
        loginIdentity={
          loginIdentity
        }
        roleOptions={
          roleOptions
        }
        action={
          createAccountAction
        }
        initialState={
          initialStaffAccountActionState
        }
        cancelHref={
          detailHref
        }
      />
    </div>
  );
}