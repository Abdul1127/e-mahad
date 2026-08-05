import { redirect } from "next/navigation";

import type { RoleCode } from "@/config/roles";

import {
  getAccessContext,
  hasAssignedRole,
} from "./get-access-context";
import { getActiveRole } from "./get-active-role";
import type { AccessContext } from "./types";

export async function requireAccessContext(): Promise<AccessContext> {
  const context = await getAccessContext();

  if (!context) {
    redirect("/login");
  }

  if (!context.isActive) {
    redirect("/access-denied");
  }

  if (context.roles.length === 0) {
    redirect("/access-denied");
  }

  return context;
}

export async function requireRole(
  requiredRole: RoleCode,
): Promise<AccessContext> {
  const context = await requireAccessContext();

  if (!hasAssignedRole(context, requiredRole)) {
    redirect("/access-denied");
  }

  if (context.roles.length > 1) {
    const activeRole = await getActiveRole();

    const activeRoleIsAssigned =
      activeRole !== null &&
      hasAssignedRole(context, activeRole);

    if (!activeRoleIsAssigned) {
      redirect("/select-role");
    }

    if (activeRole !== requiredRole) {
      redirect("/dashboard");
    }
  }

  return context;
}