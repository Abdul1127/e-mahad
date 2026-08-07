import type { Metadata } from "next";

import { AdminStaffList } from "@/features/admin/staff/components/admin-staff-list";
import { getAdminStaffList } from "@/features/admin/staff/data/get-admin-staff-list";
import { getAdminStaffRoleOptions } from "@/features/admin/staff/data/get-admin-staff-role-options";
import {
  parseStaffListQuery,
  type StaffListSearchParams,
} from "@/features/admin/staff/lib/parse-staff-list-query";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Staf Pesantren",

  description:
    "Daftar staf, akun login, dan role staf E-Ma'had.",
};

type AdminStaffPageProps = {
  searchParams: Promise<StaffListSearchParams>;
};

export default async function AdminStaffPage({
  searchParams,
}: AdminStaffPageProps) {
  await requireRole("admin");

  const resolvedSearchParams =
    await searchParams;

  const parsedQuery =
    parseStaffListQuery(
      resolvedSearchParams,
    );

  const roleOptions =
    await getAdminStaffRoleOptions();

  const roleCodeIsValid =
    parsedQuery.roleCode === null ||
    roleOptions.some(
      (role) =>
        role.code ===
        parsedQuery.roleCode,
    );

  const query = {
    ...parsedQuery,

    roleCode:
      roleCodeIsValid
        ? parsedQuery.roleCode
        : null,
  };

  const data =
    await getAdminStaffList(
      query,
    );

  return (
    <AdminStaffList
      data={data}
      query={query}
      roleOptions={roleOptions}
    />
  );
}