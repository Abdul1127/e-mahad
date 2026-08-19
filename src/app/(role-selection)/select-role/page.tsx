import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { roleDefinitions } from "@/config/roles";
import { LogoutButton } from "@/features/auth/components/logout-button";
import { RoleSelectionForm } from "@/features/auth/components/role-selection-form";
import { requireAccessContext } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Pilih Role",

  description:
    "Pilih konteks kerja yang akan digunakan pada E-Ma'had.",
};

export default async function SelectRolePage() {
  const context =
    await requireAccessContext();

  if (context.roles.length === 1) {
    redirect(
      roleDefinitions[
        context.roles[0].code
      ].dashboardPath,
    );
  }

  return (
    <main className="min-h-screen bg-slate-50">
      <header className="border-b border-slate-200 bg-white">
        <div className="mx-auto flex min-h-20 w-full max-w-6xl items-center justify-between gap-4 px-5 sm:px-8">
          <div className="flex min-w-0 items-center gap-3">
            <div className="grid size-11 shrink-0 place-items-center rounded-2xl bg-emerald-800 text-sm font-bold text-white shadow-sm">
              EM
            </div>

            <div className="min-w-0">
              <p className="truncate text-lg font-bold text-slate-900">
                E-Ma&apos;had
              </p>

              <p className="truncate text-xs text-slate-500">
                Pemantauan Asrama
              </p>
            </div>
          </div>

          <div className="flex shrink-0 items-center gap-4">
            <div className="hidden text-right sm:block">
              <p className="max-w-56 truncate text-sm font-semibold text-slate-800">
                {context.fullName}
              </p>

              <p className="mt-0.5 text-xs text-slate-500">
                Pilih konteks kerja
              </p>
            </div>

            <LogoutButton />
          </div>
        </div>
      </header>

      <section className="mx-auto w-full max-w-6xl px-5 py-10 sm:px-8 sm:py-14 lg:py-16">
        <div className="mb-8 sm:mb-10">
          <p className="text-xs font-bold uppercase tracking-[0.2em] text-emerald-700">
            Pilih konteks kerja
          </p>

          <h1 className="mt-3 max-w-3xl text-3xl font-bold tracking-tight text-slate-900 sm:text-4xl">
            Gunakan E-Ma&apos;had sebagai
          </h1>

          <p className="mt-4 max-w-2xl text-sm leading-7 text-slate-600 sm:text-base">
            Akun ini mempunyai beberapa role.
            Pilih peran yang akan digunakan
            untuk sesi kerja saat ini.
          </p>
        </div>

        <RoleSelectionForm
          roles={context.roles}
        />

        <div className="mt-8 rounded-2xl border border-emerald-100 bg-emerald-50 px-5 py-4">
          <p className="text-sm leading-6 text-emerald-800">
            Setelah memilih role, menu dan
            dashboard akan disesuaikan dengan
            kewenangan role tersebut.
          </p>
        </div>
      </section>
    </main>
  );
}