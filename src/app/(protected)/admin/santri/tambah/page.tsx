import type { Metadata } from "next";

import { StudentForm } from "@/features/admin/students/components/student-form";
import { getAdminStudentFormOptions } from "@/features/admin/students/data/get-admin-student-form-options";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Tambah Santri",
  description:
    "Tambah data santri E-Ma'had.",
};

export default async function AddStudentPage() {
  await requireRole("admin");

  const options =
    await getAdminStudentFormOptions();

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Data master
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Tambah Santri
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Masukkan identitas dan tentukan
          penempatan santri pada tahun ajaran
          aktif.
        </p>
      </section>

      <StudentForm
        mode="create"
        options={options}
      />
    </div>
  );
}