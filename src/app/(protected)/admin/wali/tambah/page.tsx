import type { Metadata } from "next";

import { createAdminGuardian } from "@/features/admin/guardians/actions/create-admin-guardian";
import { GuardianForm } from "@/features/admin/guardians/components/guardian-form";
import { initialGuardianFormActionState } from "@/features/admin/guardians/types/guardian-form-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Tambah Wali",
  description:
    "Tambah orang tua atau wali E-Ma'had.",
};

export default async function AddGuardianPage() {
  await requireRole("admin");

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Data orang tua atau wali
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Tambah Wali
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Masukkan identitas orang tua atau
          wali. Hubungan dengan santri dapat
          ditambahkan setelah data disimpan.
        </p>
      </section>

      <GuardianForm
        mode="create"
        action={createAdminGuardian}
        initialState={
          initialGuardianFormActionState
        }
        cancelHref="/admin/wali"
      />
    </div>
  );
}