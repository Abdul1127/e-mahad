import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";

import type { AccessContext } from "./types";

export function resolveDashboardPath(
  context: AccessContext,
  activeRole: RoleCode | null,
): string {
  if (context.roles.length === 0) {
    return "/access-denied";
  }

  if (context.roles.length === 1) {
    const onlyRole = context.roles[0];

    return roleDefinitions[onlyRole.code]
      .dashboardPath;
  }

  const activeRoleIsAssigned =
    activeRole !== null &&
    context.roles.some(
      (role) => role.code === activeRole,
    );

  if (activeRoleIsAssigned && activeRole) {
    return roleDefinitions[activeRole].dashboardPath;
  }

  return "/select-role";
}