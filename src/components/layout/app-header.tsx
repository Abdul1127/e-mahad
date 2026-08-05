import Link from "next/link";

import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";
import { LogoutButton } from "@/features/auth/components/logout-button";
import type { AccessContext } from "@/lib/auth/types";

type AppHeaderProps = {
  context: AccessContext;
  activeRole: RoleCode | null;
};

export function AppHeader({
  context,
  activeRole,
}: AppHeaderProps) {
  const fallbackRole =
    context.roles.length === 1
      ? context.roles[0].code
      : null;

  const displayedRole =
    activeRole ?? fallbackRole;

  return (
    <header className="border-b border-slate-200 bg-white">
      <div className="mx-auto flex max-w-7xl items-center justify-between gap-5 px-5 py-4 sm:px-8">
        <div className="min-w-0">
          <Link
            href="/dashboard"
            className="text-xl font-bold text-emerald-800"
          >
            E-Ma&apos;had
          </Link>

          <p className="mt-1 truncate text-sm text-slate-500">
            {displayedRole
              ? roleDefinitions[displayedRole].label
              : "Pilih role aktif"}
          </p>
        </div>

        <div className="flex items-center gap-3">
          {context.roles.length > 1 && (
            <Link
              href="/select-role"
              className="hidden rounded-lg px-3 py-2 text-sm font-semibold text-emerald-700 transition hover:bg-emerald-50 sm:inline-flex"
            >
              Ganti role
            </Link>
          )}

          <div className="hidden text-right md:block">
            <p className="text-sm font-semibold text-slate-800">
              {context.fullName}
            </p>

            <p className="text-xs text-slate-500">
              {context.email ?? "Email tidak tersedia"}
            </p>
          </div>

          <LogoutButton />
        </div>
      </div>
    </header>
  );
}