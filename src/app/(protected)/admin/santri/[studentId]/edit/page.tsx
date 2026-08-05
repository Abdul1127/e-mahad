import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { StudentForm } from "@/features/admin/students/components/student-form";
import { getAdminStudentDetail } from "@/features/admin/students/data/get-admin-student-detail";
import { getAdminStudentFormOptions } from "@/features/admin/students/data/get-admin-student-form-options";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Edit Santri",
  description:
    "Edit data santri E-Ma'had.",
};

type EditStudentPageProps = {
  params: Promise<{
    studentId: string;
  }>;
};

export default async function EditStudentPage({
  params,
}: EditStudentPageProps) {
  await requireRole("admin");

  const { studentId } = await params;

  const [data, options] =
    await Promise.all([
      getAdminStudentDetail(studentId),
      getAdminStudentFormOptions(),
    ]);

  if (!data) {
    notFound();
  }

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Data master
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Edit Santri
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Perbarui identitas atau penempatan
          santri. Penempatan lama akan tetap
          tersimpan sebagai riwayat.
        </p>
      </section>

      <StudentForm
        mode="edit"
        options={options}
        studentId={data.student.id}
        initialValues={{
          legacyStudentId:
            data.student
              .legacy_student_id ?? "",

          nis:
            data.student.nis ?? "",

          fullName:
            data.student.full_name,

          gender:
            data.student.gender,

          status:
            data.student.status,

          classId:
            data.current_placement
              .class?.id ?? "",

          careGroupId:
            data.current_placement
              .care_group?.id ?? "",

          tahfizGroupId:
            data.current_placement
              .tahfiz_group?.id ?? "",
        }}
      />
    </div>
  );
}