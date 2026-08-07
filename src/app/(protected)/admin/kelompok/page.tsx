import type { Metadata } from "next";

import { AdminGroupAssignmentOverview } from "@/features/admin/groups/components/admin-group-assignment-overview";
import { getAdminGroupAssignmentOverview } from "@/features/admin/groups/data/get-admin-group-assignment-overview";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Kelompok & Assignment",

  description:
    "Kelompok pengasuhan, kelompok tahfiz, dan assignment staf E-Ma'had.",
};

export default async function AdminGroupAssignmentPage() {
  await requireRole("admin");

  const data =
    await getAdminGroupAssignmentOverview();

  return (
    <AdminGroupAssignmentOverview
      data={data}
    />
  );
}