"use server";

import { cookies } from "next/headers";
import { redirect } from "next/navigation";

import {
  isRoleCode,
  roleDefinitions,
} from "@/config/roles";
import { ACTIVE_ROLE_COOKIE_NAME } from "@/lib/auth/constants";
import {
  getAccessContext,
  hasAssignedRole,
} from "@/lib/auth/get-access-context";

export async function selectActiveRoleAction(
  formData: FormData,
): Promise<void> {
  const requestedRole = formData.get("role");

  if (!isRoleCode(requestedRole)) {
    redirect("/access-denied");
  }

  const context = await getAccessContext();

  if (
    !context ||
    !context.isActive ||
    !hasAssignedRole(context, requestedRole)
  ) {
    redirect("/access-denied");
  }

  const cookieStore = await cookies();

  cookieStore.set(
    ACTIVE_ROLE_COOKIE_NAME,
    requestedRole,
    {
      httpOnly: true,
      sameSite: "lax",
      secure:
        process.env.NODE_ENV === "production",
      path: "/",
    },
  );

  redirect(
    roleDefinitions[requestedRole]
      .dashboardPath,
  );
}