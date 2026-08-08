"use client";

import type {
  MouseEvent,
} from "react";
import {
  useActionState,
} from "react";
import {
  useFormStatus,
} from "react-dom";
import Link from "next/link";

import {
  addAdminGroupAssignment,
  endAdminGroupAssignment,
  setAdminTahfizPrimaryAssignment,
} from "../actions/admin-group-assignment-actions";
import type { AdminGroupAssignmentCandidatesData } from "../schemas/admin-group-assignment-candidates-schema";
import type { AdminGroupActiveAssignment } from "../schemas/admin-group-assignment-detail-schema";
import {
  initialAdminGroupAssignmentActionState,
  type AdminGroupAssignmentActionState,
} from "../types/admin-group-assignment-action-state";

type AdminGroupAssignmentManagerProps = {
  candidateData:
    AdminGroupAssignmentCandidatesData;

  activeAssignments:
    AdminGroupActiveAssignment[];
};

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
      dateStyle: "medium",
      timeZone:
        "Asia/Jakarta",
    },
  ).format(date);
}

function ActionError({
  state,
}: {
  state:
    AdminGroupAssignmentActionState;
}) {
  if (
    state.status !== "error" ||
    !state.message
  ) {
    return null;
  }

  return (
    <div
      role="alert"
      className="mt-3 rounded-xl border border-red-200 bg-red-50 px-3 py-2.5 text-xs font-medium leading-5 text-red-700"
    >
      {state.message}
    </div>
  );
}

function AddSubmitButton({
  groupType,
}: {
  groupType:
    "care" | "tahfiz";
}) {
  const { pending } =
    useFormStatus();

  return (
    <button
      type="submit"
      disabled={pending}
      className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Menambahkan..."
        : groupType === "care"
          ? "Tambah Pengasuh"
          : "Tambah Pembina"}
    </button>
  );
}

function EndSubmitButton({
  staffName,
  groupType,
}: {
  staffName: string;

  groupType:
    "care" | "tahfiz";
}) {
  const { pending } =
    useFormStatus();

  function handleClick(
    event:
      MouseEvent<HTMLButtonElement>,
  ) {
    const roleLabel =
      groupType === "care"
        ? "Pengasuh"
        : "Pembina Tahfiz";

    const confirmed =
      window.confirm(
        `Akhiri assignment ${roleLabel} untuk ${staffName}? Riwayat assignment tetap disimpan.`,
      );

    if (!confirmed) {
      event.preventDefault();
    }
  }

  return (
    <button
      type="submit"
      disabled={pending}
      onClick={handleClick}
      className="inline-flex min-h-9 items-center justify-center rounded-xl border border-red-200 bg-white px-3 text-xs font-semibold text-red-600 transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Memproses..."
        : "Akhiri Assignment"}
    </button>
  );
}

function PrimarySubmitButton({
  staffName,
}: {
  staffName: string;
}) {
  const { pending } =
    useFormStatus();

  function handleClick(
    event:
      MouseEvent<HTMLButtonElement>,
  ) {
    const confirmed =
      window.confirm(
        `Jadikan ${staffName} sebagai Pembina Tahfiz utama? Pembina utama sebelumnya akan menjadi Pembina biasa.`,
      );

    if (!confirmed) {
      event.preventDefault();
    }
  }

  return (
    <button
      type="submit"
      disabled={pending}
      onClick={handleClick}
      className="inline-flex min-h-9 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-3 text-xs font-semibold text-brand-700 transition hover:bg-brand-100 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Memproses..."
        : "Jadikan Utama"}
    </button>
  );
}

function AddAssignmentForm({
  data,
}: {
  data:
    AdminGroupAssignmentCandidatesData;
}) {
  const [
    state,
    formAction,
  ] = useActionState(
    addAdminGroupAssignment,
    initialAdminGroupAssignmentActionState,
  );

  const availableCandidates =
    data.candidates.filter(
      (candidate) =>
        !candidate.assigned_to_target,
    );

  const isCare =
    data.group_type === "care";

  return (
    <section className="rounded-2xl border border-brand-100 bg-brand-50/60 p-4 sm:p-5">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Tambah assignment
        </p>

        <h3 className="mt-2 text-lg font-bold text-brand-900">
          {isCare
            ? "Tambah Pengasuh"
            : "Tambah Pembina Tahfiz"}
        </h3>

        <p className="mt-2 text-sm leading-6 text-brand-700">
          Kandidat hanya menampilkan
          staf aktif yang mempunyai
          akun aktif dan role{" "}
          <strong>
            {isCare
              ? "Pengasuh"
              : "Pembina Tahfiz"}
          </strong>
          .
        </p>
      </div>

      {availableCandidates.length ===
      0 ? (
        <div className="mt-4 rounded-xl border border-dashed border-brand-200 bg-white/70 p-4 text-sm text-brand-700">
          Tidak ada kandidat lain yang
          dapat ditambahkan ke kelompok
          ini.
        </div>
      ) : (
        <form
          action={formAction}
          className="mt-5"
        >
          <input
            type="hidden"
            name="group_type"
            value={
              data.group_type
            }
          />

          <input
            type="hidden"
            name="group_id"
            value={
              data.group.id
            }
          />

          <label
            htmlFor="staff_id"
            className="mb-2 block text-sm font-semibold text-slate-700"
          >
            Pilih staf
          </label>

          <select
            id="staff_id"
            name="staff_id"
            required
            defaultValue=""
            className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100"
          >
            <option
              value=""
              disabled
            >
              {isCare
                ? "Pilih Pengasuh"
                : "Pilih Pembina Tahfiz"}
            </option>

            {availableCandidates.map(
              (candidate) => (
                <option
                  key={
                    candidate.staff_id
                  }
                  value={
                    candidate.staff_id
                  }
                >
                  {candidate.full_name}
                  {" — "}
                  {candidate.login_id ??
                    candidate.legacy_staff_id ??
                    "Tanpa ID"}
                  {candidate.active_assignment_count >
                  0
                    ? ` (${candidate.active_assignment_count} assignment aktif)`
                    : ""}
                </option>
              ),
            )}
          </select>

          <p className="mt-2 text-xs leading-5 text-slate-500">
            Staf dapat memiliki
            assignment lain. Informasi
            jumlah assignment aktif
            ditampilkan untuk membantu
            Admin menentukan pembagian
            tugas.
          </p>

          <ActionError
            state={state}
          />

          <div className="mt-4">
            <AddSubmitButton
              groupType={
                data.group_type
              }
            />
          </div>
        </form>
      )}
    </section>
  );
}

function ActiveAssignmentManagerCard({
  assignment,
  groupType,
  groupId,
}: {
  assignment:
    AdminGroupActiveAssignment;

  groupType:
    "care" | "tahfiz";

  groupId: string;
}) {
  const [
    endState,
    endFormAction,
  ] = useActionState(
    endAdminGroupAssignment,
    initialAdminGroupAssignmentActionState,
  );

  const [
    primaryState,
    primaryFormAction,
  ] = useActionState(
    setAdminTahfizPrimaryAssignment,
    initialAdminGroupAssignmentActionState,
  );

  const isCare =
    groupType === "care";

  const roleLabel =
    isCare
      ? "Pengasuh"
      : assignment.is_primary
        ? "Pembina Tahfiz Utama"
        : "Pembina Tahfiz";

  return (
    <article className="rounded-2xl border border-line bg-slate-50/70 p-4 sm:p-5">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
        <div className="min-w-0">
          <p className="font-bold text-ink">
            {assignment.full_name}
          </p>

          <p className="mt-1 text-xs font-medium text-slate-500">
            {roleLabel}
          </p>

          <p className="mt-1 text-xs text-slate-400">
            ID Staf{" "}
            {assignment.legacy_staff_id ??
              "-"}
          </p>

          {assignment.login_id && (
            <p className="mt-1 text-xs text-slate-400">
              ID Pengguna{" "}
              {
                assignment.login_id
              }
            </p>
          )}
        </div>

        <div className="flex flex-wrap gap-2">
          {assignment.is_primary && (
            <span className="rounded-full bg-brand-100 px-2.5 py-1 text-[10px] font-bold uppercase tracking-wide text-brand-700">
              Utama
            </span>
          )}

          <span
            className={
              assignment.account_active
                ? "rounded-full bg-brand-100 px-2.5 py-1 text-[10px] font-bold text-brand-700"
                : "rounded-full bg-amber-100 px-2.5 py-1 text-[10px] font-bold text-amber-700"
            }
          >
            {assignment.account_active
              ? "Akun aktif"
              : "Akun nonaktif"}
          </span>
        </div>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <div className="rounded-xl bg-white p-3">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
            Mulai assignment
          </p>

          <p className="mt-1 text-sm font-semibold text-slate-700">
            {formatDate(
              assignment.assigned_at,
            )}
          </p>
        </div>

        <div className="rounded-xl bg-white p-3">
          <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
            Status staf
          </p>

          <p
            className={
              assignment.staff_is_active
                ? "mt-1 text-sm font-bold text-brand-700"
                : "mt-1 text-sm font-bold text-amber-700"
            }
          >
            {assignment.staff_is_active
              ? "Aktif"
              : "Nonaktif"}
          </p>
        </div>
      </div>

      <div className="mt-4 flex flex-col gap-3 border-t border-line pt-4 sm:flex-row sm:flex-wrap sm:items-start">
        <Link
          href={`/admin/staf/${assignment.staff_id}`}
          className="inline-flex min-h-9 items-center justify-center rounded-xl border border-line bg-white px-3 text-xs font-semibold text-slate-600 transition hover:bg-slate-50"
        >
          Lihat Detail Staf
        </Link>

        {!isCare &&
          !assignment.is_primary && (
            <form
              action={
                primaryFormAction
              }
            >
              <input
                type="hidden"
                name="group_id"
                value={groupId}
              />

              <input
                type="hidden"
                name="assignment_id"
                value={
                  assignment.assignment_id
                }
              />

              <PrimarySubmitButton
                staffName={
                  assignment.full_name
                }
              />
            </form>
          )}

        {(
          isCare ||
          !assignment.is_primary
        ) && (
          <form
            action={
              endFormAction
            }
          >
            <input
              type="hidden"
              name="group_type"
              value={groupType}
            />

            <input
              type="hidden"
              name="group_id"
              value={groupId}
            />

            <input
              type="hidden"
              name="assignment_id"
              value={
                assignment.assignment_id
              }
            />

            <EndSubmitButton
              staffName={
                assignment.full_name
              }
              groupType={
                groupType
              }
            />
          </form>
        )}
      </div>

      {!isCare &&
        assignment.is_primary && (
          <div className="mt-4 rounded-xl border border-brand-100 bg-brand-50 px-3 py-2.5 text-xs leading-5 text-brand-700">
            Pembina utama tidak dapat
            langsung diakhiri. Jadikan
            Pembina lain sebagai utama
            terlebih dahulu.
          </div>
        )}

      <ActionError
        state={
          primaryState
        }
      />

      <ActionError
        state={
          endState
        }
      />
    </article>
  );
}

export function AdminGroupAssignmentManager({
  candidateData,
  activeAssignments,
}: AdminGroupAssignmentManagerProps) {
  const isCare =
    candidateData.group_type ===
    "care";

  return (
    <div className="mt-5 space-y-5">
      <AddAssignmentForm
        data={
          candidateData
        }
      />

      <section>
        <div className="flex flex-col gap-2 sm:flex-row sm:items-end sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-400">
              Assignment saat ini
            </p>

            <h3 className="mt-1 text-lg font-bold text-ink">
              {isCare
                ? "Pengasuh Aktif"
                : "Pembina Tahfiz Aktif"}
            </h3>
          </div>

          <p className="text-xs text-slate-500">
            {
              candidateData.summary
                .current_assignment_count
            }{" "}
            assignment aktif
          </p>
        </div>

        {activeAssignments.length ===
        0 ? (
          <div className="mt-4 rounded-2xl border border-dashed border-amber-300 bg-amber-50 p-5 text-sm text-amber-700">
            Belum ada assignment aktif
            untuk kelompok ini.
          </div>
        ) : (
          <div className="mt-4 grid gap-4 lg:grid-cols-2">
            {activeAssignments.map(
              (assignment) => (
                <ActiveAssignmentManagerCard
                  key={
                    assignment.assignment_id
                  }
                  assignment={
                    assignment
                  }
                  groupType={
                    candidateData.group_type
                  }
                  groupId={
                    candidateData.group.id
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