import { SidebarNavigation } from "@/components/app-shell/sidebar-navigation";
import { getRoleNavigation } from "@/config/navigation";
import {
  roleDefinitions,
  type RoleCode,
} from "@/config/roles";
import type { AccessContext } from "@/lib/auth/types";

type DesktopSidebarProps = {
  context: AccessContext;
  roleCode: RoleCode;
};

export function DesktopSidebar({
  context,
  roleCode,
}: DesktopSidebarProps) {
  const definition = roleDefinitions[roleCode];
  const navigationItems =
    getRoleNavigation(roleCode);

  return (
    <aside className="fixed inset-y-0 left-0 z-40 hidden w-72 flex-col overflow-hidden bg-brand-900 text-white lg:flex">
      <div className="border-b border-white/10 px-6 py-6">
        <div className="flex items-center gap-3">
          <div className="grid size-11 shrink-0 place-items-center rounded-2xl bg-white font-black text-brand-900 shadow-sm">
            EM
          </div>

          <div className="min-w-0">
            <p className="truncate text-xl font-bold tracking-tight">
              E-Ma&apos;had
            </p>

            <p className="mt-0.5 text-xs text-white/55">
              Pemantauan Asrama
            </p>
          </div>
        </div>
      </div>

      <div className="px-4 pt-5">
        <div className="rounded-2xl border border-white/10 bg-white/6 p-4">
          <p className="text-[11px] font-semibold uppercase tracking-[0.16em] text-brand-200">
            Role aktif
          </p>

          <p className="mt-2 font-semibold text-white">
            {definition.label}
          </p>

          <p className="mt-1 line-clamp-2 text-xs leading-5 text-white/55">
            {definition.description}
          </p>
        </div>
      </div>

      <div className="app-scrollbar flex-1 overflow-y-auto px-4 py-5">
        <p className="mb-3 px-3 text-[11px] font-semibold uppercase tracking-[0.16em] text-white/35">
          Menu utama
        </p>

        <SidebarNavigation
          items={navigationItems}
        />
      </div>

      <div className="border-t border-white/10 px-5 py-5">
        <p className="truncate text-sm font-semibold text-white">
          {context.fullName}
        </p>

        <p className="mt-1 truncate text-xs text-white/45">
          {context.email ?? "Email tidak tersedia"}
        </p>

        <p className="mt-4 text-[11px] leading-5 text-white/35">
          Sistem informasi internal untuk kegiatan
          asrama pesantren.
        </p>
      </div>
    </aside>
  );
}