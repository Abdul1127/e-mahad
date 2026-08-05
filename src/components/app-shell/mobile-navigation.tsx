"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { AppIcon } from "@/components/app-shell/app-icon";
import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";
import type { AccessContext } from "@/lib/auth/types";

type MobileNavigationProps = {
  context: AccessContext;
  roleCode: RoleCode;
  onOpenMenu: () => void;
};

export function MobileNavigation({
  context,
  roleCode,
  onOpenMenu,
}: MobileNavigationProps) {
  const pathname = usePathname();
  const dashboardPath =
    roleDefinitions[roleCode].dashboardPath;

  const dashboardIsActive =
    pathname === dashboardPath;

  const gridClassName =
    context.roles.length > 1
      ? "grid-cols-3"
      : "grid-cols-2";

  return (
    <nav
      aria-label="Navigasi mobile"
      className="fixed inset-x-0 bottom-0 z-40 border-t border-line bg-white/96 px-3 pt-2 shadow-[0_-8px_24px_rgba(15,23,42,0.06)] backdrop-blur lg:hidden"
    >
      <div
        className={`grid ${gridClassName} gap-1 pb-[calc(0.5rem+env(safe-area-inset-bottom))]`}
      >
        <Link
          href={dashboardPath}
          aria-current={
            dashboardIsActive ? "page" : undefined
          }
          className={
            dashboardIsActive
              ? "flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl bg-brand-50 text-brand-700"
              : "flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl text-slate-500 transition hover:bg-slate-50"
          }
        >
          <AppIcon
            name="home"
            className="size-5"
          />

          <span className="text-[11px] font-semibold">
            Beranda
          </span>
        </Link>

        {context.roles.length > 1 && (
          <Link
            href="/select-role"
            className="flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl text-slate-500 transition hover:bg-slate-50"
          >
            <AppIcon
              name="switch"
              className="size-5"
            />

            <span className="text-[11px] font-semibold">
              Ganti role
            </span>
          </Link>
        )}

        <button
          type="button"
          onClick={onOpenMenu}
          className="flex min-h-14 flex-col items-center justify-center gap-1 rounded-xl text-slate-500 transition hover:bg-slate-50"
        >
          <AppIcon
            name="menu"
            className="size-5"
          />

          <span className="text-[11px] font-semibold">
            Menu
          </span>
        </button>
      </div>
    </nav>
  );
}