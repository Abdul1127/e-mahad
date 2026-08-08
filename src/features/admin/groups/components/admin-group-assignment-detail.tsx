import Link from "next/link";

import { getAdminGroupAssignmentCandidates } from "../data/get-admin-group-assignment-candidates";
import type {
  AdminGroupAssignmentDetailData,
  AdminGroupAssignmentHistory,
  AdminGroupMember,
} from "../schemas/admin-group-assignment-detail-schema";
import { AdminGroupAssignmentManager } from "./admin-group-assignment-manager";

type AdminGroupAssignmentDetailProps = {
  data:
    AdminGroupAssignmentDetailData;
};

const numberFormatter =
  new Intl.NumberFormat("id-ID");

function getGenderLabel(
  gender:
    "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

function formatDate(
  value: string | null,
): string {
  if (!value) {
    return "-";
  }

  const date =
    new Date(value);

  if (
    Number.isNaN(
      date.getTime(),
    )
  ) {
    return "-";
  }

  return new Intl.DateTimeFormat(
    "id-ID",
    {
      dateStyle:
        "medium",

      timeZone:
        "Asia/Jakarta",
    },
  ).format(date);
}

function MemberDesktopTable({
  members,
}: {
  members:
    AdminGroupMember[];
}) {
  return (
    <div className="hidden overflow-hidden rounded-2xl border border-line lg:block">
      <div className="overflow-x-auto">
        <table className="w-full min-w-[900px] border-collapse">
          <thead>
            <tr className="border-b border-line bg-slate-50">
              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Santri
              </th>

              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Kelas
              </th>

              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Bergabung
              </th>

              <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-slate-500">
                Status
              </th>

              <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-slate-500">
                Aksi
              </th>
            </tr>
          </thead>

          <tbody>
            {members.map(
              (member) => (
                <tr
                  key={
                    member.membership_id
                  }
                  className="border-b border-line last:border-b-0"
                >
                  <td className="px-4 py-4">
                    <p className="font-semibold text-ink">
                      {
                        member.full_name
                      }
                    </p>

                    <p className="mt-1 text-xs text-slate-400">
                      ID{" "}
                      {member.legacy_student_id ??
                        "-"}

                      {member.nis
                        ? ` • NIS ${member.nis}`
                        : ""}
                    </p>
                  </td>

                  <td className="px-4 py-4">
                    <p className="text-sm font-semibold text-slate-700">
                      {member.class_name ??
                        "Belum tersedia"}
                    </p>

                    {member.grade_level !==
                      null && (
                      <p className="mt-1 text-xs text-slate-400">
                        Tingkat{" "}
                        {
                          member.grade_level
                        }
                      </p>
                    )}
                  </td>

                  <td className="px-4 py-4 text-sm text-slate-600">
                    {formatDate(
                      member.joined_at,
                    )}
                  </td>

                  <td className="px-4 py-4">
                    <span className="rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700">
                      Aktif
                    </span>
                  </td>

                  <td className="px-4 py-4 text-right">
                    <Link
                      href={`/admin/santri/${member.student_id}`}
                      className="inline-flex min-h-9 items-center justify-center rounded-xl border border-line bg-white px-3 text-xs font-semibold text-slate-600 transition hover:bg-slate-50"
                    >
                      Lihat Santri
                    </Link>
                  </td>
                </tr>
              ),
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function MemberMobileList({
  members,
}: {
  members:
    AdminGroupMember[];
}) {
  return (
    <div className="space-y-3 lg:hidden">
      {members.map(
        (member) => (
          <article
            key={
              member.membership_id
            }
            className="rounded-2xl border border-line bg-white p-4"
          >
            <h3 className="font-bold text-ink">
              {member.full_name}
            </h3>

            <p className="mt-1 text-xs text-slate-400">
              ID{" "}
              {member.legacy_student_id ??
                "-"}

              {member.nis
                ? ` • NIS ${member.nis}`
                : ""}
            </p>

            <dl className="mt-4 grid grid-cols-2 gap-3">
              <div className="rounded-xl bg-slate-50 p-3">
                <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                  Kelas
                </dt>

                <dd className="mt-1 text-sm font-semibold text-slate-700">
                  {member.class_name ??
                    "-"}
                </dd>
              </div>

              <div className="rounded-xl bg-slate-50 p-3">
                <dt className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                  Bergabung
                </dt>

                <dd className="mt-1 text-sm font-semibold text-slate-700">
                  {formatDate(
                    member.joined_at,
                  )}
                </dd>
              </div>
            </dl>

            <Link
              href={`/admin/santri/${member.student_id}`}
              className="mt-4 inline-flex min-h-10 w-full items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600"
            >
              Lihat Santri
            </Link>
          </article>
        ),
      )}
    </div>
  );
}

function AssignmentHistoryRow({
  history,
  groupType,
}: {
  history:
    AdminGroupAssignmentHistory;

  groupType:
    "care" | "tahfiz";
}) {
  return (
    <article className="rounded-2xl border border-line bg-white p-4">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <p className="font-semibold text-ink">
            {history.full_name}
          </p>

          <p className="mt-1 text-xs text-slate-400">
            {groupType ===
            "care"
              ? "Pengasuh"
              : history.is_primary
                ? "Pembina Tahfiz Utama"
                : "Pembina Tahfiz"}

            {" • ID Staf "}

            {history.legacy_staff_id ??
              "-"}
          </p>
        </div>

        <span
          className={
            history.is_active
              ? "w-fit rounded-full bg-brand-100 px-2.5 py-1 text-xs font-semibold text-brand-700"
              : "w-fit rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-500"
          }
        >
          {history.is_active
            ? "Aktif"
            : "Selesai"}
        </span>
      </div>

      <div className="mt-3 flex flex-wrap gap-x-6 gap-y-2 text-xs text-slate-500">
        <p>
          Mulai:{" "}
          <strong className="text-slate-700">
            {formatDate(
              history.assigned_at,
            )}
          </strong>
        </p>

        <p>
          Selesai:{" "}
          <strong className="text-slate-700">
            {history.is_active
              ? "Masih aktif"
              : formatDate(
                  history.ended_at,
                )}
          </strong>
        </p>
      </div>
    </article>
  );
}

export async function AdminGroupAssignmentDetail({
  data,
}: AdminGroupAssignmentDetailProps) {
  const {
    group,
    academic_year:
      academicYear,
    summary,
  } = data;

  const isCare =
    data.group_type ===
    "care";

  const groupCategoryLabel =
    isCare
      ? "Kelompok Pengasuhan"
      : "Kelompok Tahfiz";

  const candidateData =
    await getAdminGroupAssignmentCandidates(
      data.group_type,
      group.id,
    );

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <Link
          href="/admin/kelompok"
          className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 shadow-sm transition hover:bg-slate-50"
        >
          ← Kembali ke Kelompok
        </Link>

        <div className="mt-6 flex flex-col gap-5 xl:flex-row xl:items-start xl:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              {groupCategoryLabel}
            </p>

            <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
              {group.name}
            </h1>

            <div className="mt-3 flex flex-wrap gap-2">
              <span className="rounded-full bg-brand-100 px-3 py-1 text-xs font-semibold text-brand-700">
                {getGenderLabel(
                  group.gender,
                )}
              </span>

              {!isCare &&
                group.grade_level !==
                  null && (
                  <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                    Kelas{" "}
                    {
                      group.grade_level
                    }
                  </span>
                )}

              <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
                {group.code}
              </span>
            </div>

            <p className="mt-4 max-w-3xl leading-7 text-muted">
              {group.description ??
                "Tidak ada deskripsi kelompok."}
            </p>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50 px-4 py-3">
            <p className="text-xs font-semibold text-brand-600">
              Tahun Ajaran
            </p>

            <p className="mt-1 font-bold text-brand-900">
              {
                academicYear.name
              }
            </p>

            {academicYear.is_current && (
              <p className="mt-1 text-xs text-brand-600">
                Tahun ajaran aktif
              </p>
            )}
          </div>
        </div>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm text-muted">
            Anggota aktif
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_member_count,
            )}
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm text-muted">
            {isCare
              ? "Pengasuh aktif"
              : "Pembina aktif"}
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.active_assignment_count,
            )}
          </p>
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm text-muted">
            Assignment utama
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.primary_assignment_count,
            )}
          </p>

          {isCare && (
            <p className="mt-2 text-xs text-slate-400">
              Tidak digunakan untuk
              kelompok pengasuhan.
            </p>
          )}
        </article>

        <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-sm text-muted">
            Riwayat assignment
          </p>

          <p className="mt-3 text-3xl font-bold text-ink">
            {numberFormatter.format(
              summary.assignment_history_count,
            )}
          </p>
        </article>
      </section>

      <section className="mt-8 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div className="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Kelola assignment
            </p>

            <h2 className="mt-2 text-xl font-bold text-ink">
              {isCare
                ? "Pengasuh Kelompok"
                : "Pembina Tahfiz"}
            </h2>

            <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
              {isCare
                ? "Tambah atau akhiri penugasan Pengasuh pada kelompok ini."
                : "Tambah Pembina Tahfiz, tentukan Pembina utama, atau akhiri penugasan Pembina non-utama."}
            </p>
          </div>
        </div>

        {candidateData ? (
          <AdminGroupAssignmentManager
            candidateData={
              candidateData
            }
            activeAssignments={
              data.active_assignments
            }
          />
        ) : (
          <div className="mt-5 rounded-2xl border border-dashed border-red-200 bg-red-50 p-5 text-sm text-red-700">
            Data kandidat assignment
            tidak dapat ditemukan untuk
            kelompok ini.
          </div>
        )}
      </section>

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Anggota kelompok
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Santri Aktif
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Menampilkan santri yang
            saat ini tercatat aktif pada
            kelompok ini.
          </p>
        </div>

        {data.members.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-8 text-center text-sm text-muted">
            Belum ada santri aktif
            pada kelompok ini.
          </div>
        ) : (
          <div className="mt-5">
            <MemberDesktopTable
              members={
                data.members
              }
            />

            <MemberMobileList
              members={
                data.members
              }
            />
          </div>
        )}
      </section>

      <section className="mt-8 rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Riwayat
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Riwayat Assignment
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Riwayat staf yang pernah
            atau masih ditugaskan pada
            kelompok ini.
          </p>
        </div>

        {data.assignment_history.length ===
        0 ? (
          <div className="mt-5 rounded-2xl border border-dashed border-line p-5 text-sm text-muted">
            Belum ada riwayat
            assignment.
          </div>
        ) : (
          <div className="mt-5 space-y-3">
            {data.assignment_history.map(
              (history) => (
                <AssignmentHistoryRow
                  key={
                    history.assignment_id
                  }
                  history={
                    history
                  }
                  groupType={
                    data.group_type
                  }
                />
              ),
            )}
          </div>
        )}
      </section>
    </div>
  );
}