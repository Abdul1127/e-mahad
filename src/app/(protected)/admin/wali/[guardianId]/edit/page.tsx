import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { updateAdminGuardian } from "@/features/admin/guardians/actions/update-admin-guardian";
import { GuardianForm } from "@/features/admin/guardians/components/guardian-form";
import { getAdminGuardianDetail } from "@/features/admin/guardians/data/get-admin-guardian-detail";
import type { GuardianFormActionState } from "@/features/admin/guardians/types/guardian-form-action-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Edit Wali",
  description:
    "Perbarui orang tua atau wali E-Ma'had.",
};

type EditGuardianPageProps = {
  params: Promise<{
    guardianId: string;
  }>;
};

export default async function EditGuardianPage({
  params,
}: EditGuardianPageProps) {
  await requireRole("admin");

  const { guardianId } = await params;

  const data =
    await getAdminGuardianDetail(
      guardianId,
    );

  if (!data) {
    notFound();
  }

  const initialState: GuardianFormActionState =
    {
      status: "idle",
      message: null,
      fieldErrors: {},

      values: {
        legacy_guardian_id:
          data.guardian
            .legacy_guardian_id ?? "",

        full_name:
          data.guardian.full_name,

        phone:
          data.guardian.phone ?? "",

        email:
          data.guardian.email ?? "",

        is_active:
          data.guardian.is_active,
      },
    };

  const updateAction =
    updateAdminGuardian.bind(
      null,
      guardianId,
    );

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Data orang tua atau wali
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Edit Wali
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Perbarui identitas dan status data
          wali.
        </p>
      </section>

      <GuardianForm
        mode="edit"
        action={updateAction}
        initialState={initialState}
        cancelHref={`/admin/wali/${guardianId}`}
      />
    </div>
  );
}