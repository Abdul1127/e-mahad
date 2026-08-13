import Link from "next/link";

import {
  ReturnLink,
} from "@/components/navigation/navigation-state-link";

import type { AdminStudentDetailData } from "../schemas/admin-student-detail-schema";

import { StudentCurrentPlacement } from "./student-current-placement";
import { StudentGuardianPanel } from "./student-guardian-panel";
import { StudentHistorySection } from "./student-history-section";
import { StudentProfileCard } from "./student-profile-card";

type AdminStudentDetailProps = {
  data: AdminStudentDetailData;
};

export function AdminStudentDetail({
  data,
}: AdminStudentDetailProps) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="mb-6">
        <ReturnLink
          fallbackHref="/admin/santri"
          allowedPrefixes={["/admin/santri"]}
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          <span
            aria-hidden="true"
            className="mr-2"
          >
            ?
          </span>

          Kembali ke Data Santri
        </ReturnLink>

        <div className="mt-6 flex flex-col gap-4 sm:flex-row sm:items-end sm:justify-between">
          <div className="min-w-0">
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Data master santri
            </p>

            <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
              Detail Santri
            </h1>

            <p className="mt-3 max-w-2xl leading-7 text-muted">
              Informasi identitas, penempatan aktif,
              wali, dan riwayat santri.
            </p>
          </div>

          <Link
            href={`/admin/santri/${data.student.id}/edit`}
            className="inline-flex min-h-11 shrink-0 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 focus:outline-none focus:ring-4 focus:ring-brand-100"
          >
            Edit santri
          </Link>
        </div>
      </section>

      <div className="grid gap-6 xl:grid-cols-[minmax(320px,0.8fr)_minmax(0,1.2fr)]">
        <StudentProfileCard data={data} />

        <StudentGuardianPanel
          guardians={data.guardians}
        />
      </div>

      <div className="mt-6">
        <StudentCurrentPlacement
          data={data}
        />
      </div>

      <div className="mt-6">
        <StudentHistorySection
          data={data}
        />
      </div>
    </div>
  );
}