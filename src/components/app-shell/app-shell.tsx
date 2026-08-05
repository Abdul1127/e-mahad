"use client";

import type { ReactNode } from "react";
import { useEffect, useState } from "react";

import { AppTopbar } from "@/components/app-shell/app-topbar";
import { DesktopSidebar } from "@/components/app-shell/desktop-sidebar";
import { MobileDrawer } from "@/components/app-shell/mobile-drawer";
import { MobileNavigation } from "@/components/app-shell/mobile-navigation";
import type { RoleCode } from "@/config/roles";
import { LogoutButton } from "@/features/auth/components/logout-button";
import type { AccessContext } from "@/lib/auth/types";

type AppShellProps = {
  context: AccessContext;
  activeRole: RoleCode | null;
  children: ReactNode;
};

export function AppShell({
  context,
  activeRole,
  children,
}: AppShellProps) {
  const [mobileMenuOpen, setMobileMenuOpen] =
    useState(false);

  const fallbackRole =
    context.roles.length === 1
      ? context.roles[0].code
      : null;

  const resolvedRole =
    activeRole ?? fallbackRole;

  function openMobileMenu() {
    setMobileMenuOpen(true);
  }

  function closeMobileMenu() {
    setMobileMenuOpen(false);
  }

  useEffect(() => {
    if (!mobileMenuOpen) {
      return;
    }

    const previousOverflow =
      document.body.style.overflow;

    document.body.style.overflow = "hidden";

    return () => {
      document.body.style.overflow =
        previousOverflow;
    };
  }, [mobileMenuOpen]);

  if (!resolvedRole) {
    return (
      <div className="min-h-screen bg-canvas">
        <header className="border-b border-line bg-white">
          <div className="mx-auto flex min-h-18 max-w-6xl items-center justify-between gap-4 px-5 sm:px-8">
            <div>
              <p className="text-lg font-bold text-brand-900">
                E-Ma&apos;had
              </p>

              <p className="text-xs text-muted">
                Pilih konteks kerja
              </p>
            </div>

            <div className="flex items-center gap-3">
              <div className="hidden text-right sm:block">
                <p className="text-sm font-semibold text-ink">
                  {context.fullName}
                </p>

                <p className="text-xs text-muted">
                  {context.email ??
                    "Email tidak tersedia"}
                </p>
              </div>

              <LogoutButton />
            </div>
          </div>
        </header>

        {children}
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-canvas">
      <DesktopSidebar
        context={context}
        roleCode={resolvedRole}
      />

      <div className="min-w-0 lg:pl-72">
        <AppTopbar
          context={context}
          roleCode={resolvedRole}
          onOpenMenu={openMobileMenu}
        />

        <main className="min-w-0 pb-24 lg:pb-10">
          {children}
        </main>
      </div>

      <MobileDrawer
        context={context}
        roleCode={resolvedRole}
        open={mobileMenuOpen}
        onClose={closeMobileMenu}
      />

      <MobileNavigation
        context={context}
        roleCode={resolvedRole}
        onOpenMenu={openMobileMenu}
      />
    </div>
  );
}