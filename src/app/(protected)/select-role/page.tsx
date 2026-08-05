import { redirect } from "next/navigation";

import { roleDefinitions } from "@/config/roles";
import { RoleSelectionForm } from "@/features/auth/components/role-selection-form";
import { requireAccessContext } from "@/lib/auth/guards";

export default async function SelectRolePage() {
  const context = await requireAccessContext();

  if (context.roles.length === 1) {
    redirect(
      roleDefinitions[context.roles[0].code]
        .dashboardPath,
    );
  }

  return (
    <main className="mx-auto max-w-5xl px-5 py-10 sm:px-8">
      <section className="mb-8">
        <p className="text-sm font-bold uppercase tracking-[0.18em] text-emerald-700">
          Pilih konteks kerja
        </p>

        <h1 className="mt-3 text-3xl font-bold tracking-tight text-slate-900">
          Gunakan E-Ma&apos;had sebagai
        </h1>

        <p className="mt-4 max-w-2xl leading-7 text-slate-600">
          Akunmu mempunyai beberapa role. Pilih role
          yang akan digunakan pada sesi kerja ini.
        </p>
      </section>

      <RoleSelectionForm
        roles={context.roles}
      />
    </main>
  );
}