import { cookies } from "next/headers";

import {
  isRoleCode,
  type RoleCode,
} from "@/config/roles";

import { ACTIVE_ROLE_COOKIE_NAME } from "./constants";

export async function getActiveRole(): Promise<RoleCode | null> {
  const cookieStore = await cookies();

  const value = cookieStore.get(
    ACTIVE_ROLE_COOKIE_NAME,
  )?.value;

  return isRoleCode(value) ? value : null;
}