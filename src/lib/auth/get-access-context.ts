import type { RoleCode } from "@/config/roles";
import { isRoleCode } from "@/config/roles";
import { createClient } from "@/lib/supabase/server";

import type {
  AccessContext,
  UserRole,
} from "./types";

type ServerSupabaseClient = Awaited<
  ReturnType<typeof createClient>
>;

function isRecord(
  value: unknown,
): value is Record<string, unknown> {
  return (
    typeof value === "object" &&
    value !== null &&
    !Array.isArray(value)
  );
}

function parseNullableString(
  value: unknown,
): string | null {
  return typeof value === "string" ? value : null;
}

function parseRole(value: unknown): UserRole | null {
  if (!isRecord(value)) {
    return null;
  }

  const code = value.code;
  const name = value.name;

  if (!isRoleCode(code) || typeof name !== "string") {
    return null;
  }

  return {
    code,
    name,
  };
}

function parseRoles(value: unknown): UserRole[] {
  if (!Array.isArray(value)) {
    return [];
  }

  return value.reduce<UserRole[]>((roles, item) => {
    const parsedRole = parseRole(item);

    if (parsedRole) {
      roles.push(parsedRole);
    }

    return roles;
  }, []);
}

function parseAccessContext(
  value: unknown,
): AccessContext | null {
  if (!isRecord(value)) {
    return null;
  }

  if (
    typeof value.user_id !== "string" ||
    typeof value.full_name !== "string" ||
    typeof value.is_active !== "boolean"
  ) {
    return null;
  }

  return {
    userId: value.user_id,
    email: parseNullableString(value.email),
    fullName: value.full_name,
    isActive: value.is_active,
    staffId: parseNullableString(value.staff_id),
    guardianId: parseNullableString(
      value.guardian_id,
    ),
    roles: parseRoles(value.roles),
  };
}

export async function getAccessContextWithClient(
  supabase: ServerSupabaseClient,
): Promise<AccessContext | null> {
  const {
    data: claimsData,
    error: claimsError,
  } = await supabase.auth.getClaims();

  const subject = claimsData?.claims?.sub;

  if (
    claimsError ||
    typeof subject !== "string" ||
    !subject
  ) {
    return null;
  }

  const {
    data: contextData,
    error: contextError,
  } = await supabase.rpc("get_my_access_context");

  if (contextError) {
    throw new Error(
      `Gagal membaca konteks akses: ${contextError.message}`,
    );
  }

  const context = parseAccessContext(contextData);

  if (!context || context.userId !== subject) {
    return null;
  }

  return context;
}

export async function getAccessContext(): Promise<AccessContext | null> {
  const supabase = await createClient();

  return getAccessContextWithClient(supabase);
}

export function hasAssignedRole(
  context: AccessContext,
  roleCode: RoleCode,
): boolean {
  return context.roles.some(
    (role) => role.code === roleCode,
  );
}