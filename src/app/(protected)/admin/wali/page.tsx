import type { Metadata } from "next";

import { AdminGuardianList } from "@/features/admin/guardians/components/admin-guardian-list";
import { getAdminGuardianList } from "@/features/admin/guardians/data/get-admin-guardian-list";
import {
  parseGuardianListQuery,
  type GuardianListSearchParams,
} from "@/features/admin/guardians/lib/parse-guardian-list-query";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Orang Tua dan Wali",
  description:
    "Daftar orang tua dan wali E-Ma'had.",
};

type AdminGuardiansPageProps = {
  searchParams: Promise<GuardianListSearchParams>;
};

export default async function AdminGuardiansPage({
  searchParams,
}: AdminGuardiansPageProps) {
  await requireRole("admin");

  const resolvedSearchParams =
    await searchParams;

  const query = parseGuardianListQuery(
    resolvedSearchParams,
  );

  const data =
    await getAdminGuardianList(query);

  return (
    <AdminGuardianList
      data={data}
      query={query}
    />
  );
}