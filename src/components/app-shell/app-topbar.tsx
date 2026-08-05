"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { AppIcon } from "@/components/app-shell/app-icon";
import { getCurrentNavigationItem } from "@/config/navigation";
import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";
import { LogoutButton } from "@/features/auth/components/logout-button";
import type { AccessContext } from "@/lib/auth/types";

type AppTopbarProps = {
  context: AccessContext;
  roleCode: RoleCode;
  onOpenMenu: () => void;
};

function getInitials(fullName: string): string {
  const words = fullName
    .trim()
    .split(/\s+/)
    .filter(Boolean);

  if (words.length === 0) {
    return "EM";
  }

  return words
    .slice(0, 2)
    .map((word) => word.charAt(0).toUpperCase())
    .join("");
}

export function AppTopbar({
  context,
  roleCode,
  onOpenMenu,
}: AppTopbarProps) {
  const pathname = usePathname();
  const roleDefinition =
    roleDefinitions[roleCode];

  const currentNavigationItem =
    getCurrentNavigationItem(
      roleCode,
      pathname,
    );

  const pageTitle =
    currentNavigationItem?.label ??
    roleDefinition.label;

  return (
    <header className="sticky top-0 z-30 border-b border-line/80 bg-white/95 backdrop-blur">
      <div className="flex min-h-18 items-center justify-between gap-4 px-4 sm:px-6 lg:px-8">
        <div className="flex min-w-0 items-center gap-3">
          <button
            type="button"
            onClick={onOpenMenu}
            aria-label="Buka menu navigasi"
            className="grid size-10 shrink-0 place-items-center rounded-xl border border-line bg-white text-slate-700 transition hover:bg-slate-50 lg:hidden"
          >
            <AppIcon
              name="menu"
              className="size-5"
            />
          </button>

          <div className="min-w-0">
            <div className="hidden items-center gap-2 text-xs font-medium text-slate-400 sm:flex">
              <span>E-Ma&apos;had</span>
              <span>/</span>
              <span>{roleDefinition.label}</span>
            </div>

            <h1 className="truncate text-lg font-bold tracking-tight text-ink sm:mt-1 sm:text-xl">
              {pageTitle}
            </h1>
          </div>
        </div>

        <div className="flex shrink-0 items-center gap-2 sm:gap-3">
          {context.roles.length > 1 && (
            <Link
              href="/select-role"
              className="hidden min-h-10 items-center gap-2 rounded-xl border border-line bg-white px-3.5 text-sm font-semibold text-brand-700 transition hover:border-brand-200 hover:bg-brand-50 sm:inline-flex"
            >
              <AppIcon
                name="switch"
                className="size-4.5"
              />

              <span>Ganti role</span>
            </Link>
          )}

          <div className="flex items-center gap-2.5 rounded-xl py-1 sm:pl-2">
            <div className="grid size-10 shrink-0 place-items-center rounded-full bg-brand-100 text-sm font-bold text-brand-800">
              {getInitials(context.fullName)}
            </div>

            <div className="hidden max-w-48 text-right md:block">
              <p className="truncate text-sm font-semibold text-ink">
                {context.fullName}
              </p>

              <p className="truncate text-xs text-muted">
                {roleDefinition.label}
              </p>
            </div>
          </div>

          <div className="hidden lg:block">
            <LogoutButton />
          </div>
        </div>
      </div>
    </header>
  );
}