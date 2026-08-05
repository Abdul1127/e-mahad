import { redirect } from "next/navigation";

import { resolveDashboardPath } from "@/lib/auth/dashboard";
import { getActiveRole } from "@/lib/auth/get-active-role";
import { requireAccessContext } from "@/lib/auth/guards";

export default async function DashboardResolverPage() {
  const context = await requireAccessContext();
  const activeRole = await getActiveRole();

  redirect(
    resolveDashboardPath(context, activeRole),
  );
}