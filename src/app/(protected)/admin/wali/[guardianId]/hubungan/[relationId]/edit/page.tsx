import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";

import { updateAdminGuardianStudentRelation } from "@/features/admin/guardians/actions/update-admin-guardian-student-relation";
import { GuardianStudentRelationEditForm } from "@/features/admin/guardians/components/guardian-student-relation-edit-form";
import { getAdminGuardianDetail } from "@/features/admin/guardians/data/get-admin-guardian-detail";
import type { GuardianStudentRelationEditActionState } from "@/features/admin/guardians/types/guardian-student-relation-mutation-state";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Edit Hubungan Wali",
  description:
    "Edit hubungan orang tua atau wali dengan santri E-Ma'had.",
};

type EditGuardianStudentRelationPageProps = {
  params: Promise<{
    guardianId: string;
    relationId: string;
  }>;
};

export default async function EditGuardianStudentRelationPage({
  params,
}: EditGuardianStudentRelationPageProps) {
  await requireRole("admin");

  const {
    guardianId,
    relationId,
  } = await params;

  const data =
    await getAdminGuardianDetail(
      guardianId,
    );

  if (!data) {
    notFound();
  }

  const relation =
    data.children.find(
      (child) =>
        child.relation_id === relationId,
    );

  if (!relation) {
    notFound();
  }

  const initialState: GuardianStudentRelationEditActionState =
    {
      status: "idle",
      message: null,
      fieldErrors: {},

      values: {
        relationship_type:
          relation.relationship_type,

        is_primary_contact:
          relation.is_primary_contact,
      },
    };

  const updateAction =
    updateAdminGuardianStudentRelation.bind(
      null,
      guardianId,
      relationId,
    );

  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <Link
          href={`/admin/wali/${guardianId}`}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          <span
            aria-hidden="true"
            className="mr-2"
          >
            ←
          </span>

          Kembali ke Detail Wali
        </Link>

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Hubungan wali dan santri
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Edit Hubungan
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Perbarui hubungan antara{" "}
          <strong className="text-slate-700">
            {data.guardian.full_name}
          </strong>{" "}
          dan{" "}
          <strong className="text-slate-700">
            {relation.full_name}
          </strong>
          .
        </p>
      </section>

      <GuardianStudentRelationEditForm
        action={updateAction}
        initialState={initialState}
        cancelHref={`/admin/wali/${guardianId}`}
        studentName={relation.full_name}
      />
    </div>
  );
}