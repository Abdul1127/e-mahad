"use client";

import { AppIcon } from "@/components/app-shell/app-icon";

import { logoutAction } from "../actions/logout";

type LogoutButtonProps = {
  variant?: "compact" | "menu";
};

export function LogoutButton({
  variant = "compact",
}: LogoutButtonProps) {
  const buttonClassName =
    variant === "menu"
      ? "flex w-full items-center gap-3 rounded-xl px-3.5 py-3 text-left text-sm font-semibold text-red-700 transition hover:bg-red-50"
      : "inline-flex min-h-10 items-center gap-2 rounded-xl border border-line bg-white px-3.5 py-2 text-sm font-semibold text-slate-700 transition hover:border-slate-300 hover:bg-slate-50";

  return (
    <form action={logoutAction}>
      <button
        type="submit"
        className={buttonClassName}
      >
        <AppIcon
          name="logout"
          className="size-4.5"
        />

        <span>Keluar</span>
      </button>
    </form>
  );
}