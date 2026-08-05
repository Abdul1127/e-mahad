"use client";

import { AppIcon } from "@/components/app-shell/app-icon";
import { SidebarNavigation } from "@/components/app-shell/sidebar-navigation";
import { getRoleNavigation } from "@/config/navigation";
import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";
import { LogoutButton } from "@/features/auth/components/logout-button";
import type { AccessContext } from "@/lib/auth/types";

type MobileDrawerProps = {
  context: AccessContext;
  roleCode: RoleCode;
  open: boolean;
  onClose: () => void;
};

export function MobileDrawer({
  context,
  roleCode,
  open,
  onClose,
}: MobileDrawerProps) {
  if (!open) {
    return null;
  }

  const roleDefinition =
    roleDefinitions[roleCode];

  return (
    <div className="fixed inset-0 z-50 lg:hidden">
      <button
        type="button"
        aria-label="Tutup menu navigasi"
        onClick={onClose}
        className="absolute inset-0 bg-slate-950/45 backdrop-blur-[2px]"
      />

      <aside className="app-scrollbar relative z-10 flex h-full w-[min(88vw,22rem)] flex-col overflow-y-auto bg-white shadow-2xl">
        <div className="flex items-center justify-between border-b border-line px-5 py-5">
          <div className="flex items-center gap-3">
            <div className="grid size-10 place-items-center rounded-xl bg-brand-900 text-sm font-black text-white">
              EM
            </div>

            <div>
              <p className="font-bold text-ink">
                E-Ma&apos;had
              </p>

              <p className="text-xs text-muted">
                Pemantauan Asrama
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={onClose}
            aria-label="Tutup menu"
            className="grid size-10 place-items-center rounded-xl text-slate-500 transition hover:bg-slate-100"
          >
            <AppIcon
              name="close"
              className="size-5"
            />
          </button>
        </div>

        <div className="p-4">
          <div className="rounded-2xl bg-brand-50 p-4">
            <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-brand-600">
              Role aktif
            </p>

            <p className="mt-2 font-semibold text-brand-950">
              {roleDefinition.label}
            </p>

            <p className="mt-1 text-xs leading-5 text-brand-700">
              {roleDefinition.description}
            </p>
          </div>
        </div>

        <div className="flex-1 px-4 pb-5">
          <p className="mb-3 px-3 text-[11px] font-semibold uppercase tracking-[0.16em] text-slate-400">
            Menu utama
          </p>

          <div className="rounded-2xl bg-brand-900 p-2">
            <SidebarNavigation
              items={getRoleNavigation(roleCode)}
              onNavigate={onClose}
            />
          </div>
        </div>

        <div className="border-t border-line p-4">
          <div className="mb-3 rounded-2xl bg-slate-50 p-4">
            <p className="truncate text-sm font-semibold text-ink">
              {context.fullName}
            </p>

            <p className="mt-1 truncate text-xs text-muted">
              {context.email ?? "Email tidak tersedia"}
            </p>
          </div>

          <LogoutButton variant="menu" />
        </div>
      </aside>
    </div>
  );
}