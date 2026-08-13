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

/**
 * =========================================================
 * GET MOST SPECIFIC ACTIVE ITEM
 * =========================================================
 *
 * Contoh:
 *
 * /pembina-tahfiz/laporan
 *
 * cocok dengan:
 * - /pembina-tahfiz/laporan
 *
 * sedangkan:
 *
 * /pembina-tahfiz/laporan/riwayat
 *
 * sebenarnya cocok dengan:
 * - /pembina-tahfiz/laporan
 * - /pembina-tahfiz/laporan/riwayat
 *
 * Karena itu kita pilih href yang paling panjang /
 * paling spesifik.
 */
function getActiveNavigationHref(
  items:
    RoleNavigationItem[],

  pathname:
    string,
): string | null {
  const matchedItems =
    items
      .filter(
        (item) =>
          item.available &&
          (
            pathname ===
              item.href ||
            pathname.startsWith(
              `${item.href}/`,
            )
          ),
      )
      .sort(
        (
          firstItem,
          secondItem,
        ) =>
          secondItem.href.length -
          firstItem.href.length,
      );

  return (
    matchedItems[0]
      ?.href ??
    null
  );
}

export function SidebarNavigation({
  items,
  onNavigate,
}: SidebarNavigationProps) {
  const pathname =
    usePathname();

  const activeHref =
    getActiveNavigationHref(
      items,
      pathname,
    );

  return (
    <nav
      aria-label="Navigasi utama"
      className="space-y-1.5"
    >
      {items.map(
        (item) => {
          const isActive =
            item.available &&
            item.href ===
              activeHref;

          if (
            !item.available
          ) {
            return (
              <div
                key={
                  item.href
                }
                aria-disabled="true"
                className="flex min-h-11 items-center gap-3 rounded-xl px-3.5 py-2.5 text-sm font-medium text-white/45"
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