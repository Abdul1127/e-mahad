"use client";

import Link from "next/link";

import {
  usePathname,
} from "next/navigation";

import {
  AppIcon,
} from "@/components/app-shell/app-icon";

import type {
  RoleNavigationItem,
} from "@/config/navigation";

type SidebarNavigationProps = {
  items:
    RoleNavigationItem[];

  onNavigate?:
    () => void;
};

export function SidebarNavigation({
  items,
  onNavigate,
}: SidebarNavigationProps) {
  const pathname =
    usePathname();

  return (
    <nav
      aria-label="Navigasi utama"
      className="space-y-1.5"
    >
      {items.map(
        (item) => {
          const isActive =
            item.available &&
            (
              pathname ===
                item.href ||
              pathname.startsWith(
                `${item.href}/`,
              )
            );

          /*
           * =================================================
           * FALLBACK UNTUK FITUR BELUM TERSEDIA
           *
           * Normalnya menu seperti ini tidak dimasukkan ke
           * navigation sampai modul benar-benar siap.
           *
           * Ini hanya safeguard.
           * =================================================
           */

          if (
            !item.available
          ) {
            return (
              <div
                key={
                  item.href
                }
                aria-disabled="true"
                title="Fitur belum tersedia"
                className="flex min-h-11 items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-medium text-white/40"
              >
                <AppIcon
                  name={
                    item.icon
                  }
                  className="size-5 shrink-0"
                />

                <span className="min-w-0 flex-1 truncate">
                  {
                    item.label
                  }
                </span>

                <span className="rounded-full bg-white/8 px-2 py-0.5 text-[9px] font-semibold uppercase tracking-wide text-white/40">
                  Belum tersedia
                </span>
              </div>
            );
          }

          return (
            <Link
              key={
                item.href
              }
              href={
                item.href
              }
              onClick={
                onNavigate
              }
              aria-current={
                isActive
                  ? "page"
                  : undefined
              }
              className={
                isActive
                  ? "flex min-h-11 items-center gap-3 rounded-xl bg-white px-3.5 py-2.5 text-sm font-semibold text-brand-900 shadow-sm"
                  : "flex min-h-11 items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-medium text-white/75 transition hover:bg-white/8 hover:text-white"
              }
            >
              <AppIcon
                name={
                  item.icon
                }
                className="size-5 shrink-0"
              />

              <span className="min-w-0 flex-1 truncate">
                {
                  item.label
                }
              </span>

              {isActive && (
                <AppIcon
                  name="chevron-right"
                  className="size-4 shrink-0 text-brand-600"
                />
              )}
            </Link>
          );
        },
      )}
    </nav>
  );
}