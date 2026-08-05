 "use client";

import Link from "next/link";
import {
  useActionState,
  useState,
} from "react";

import { createAdminStudentAction } from "../actions/create-admin-student";
import { updateAdminStudentAction } from "../actions/update-admin-student";
import type {
  StudentFormGender,
  StudentFormOptions,
  StudentFormStatus,
} from "../schemas/admin-student-form-schema";
import {
  initialStudentFormActionState,
} from "../types/student-form-action-state";

import { StudentFormFieldError } from "./student-form-field-error";

type StudentFormInitialValues = {
  legacyStudentId: string;
  nis: string;
  fullName: string;
  gender: StudentFormGender;
  status: StudentFormStatus;
  classId: string;
  careGroupId: string;
  tahfizGroupId: string;
};

type StudentFormProps = {
  mode: "create" | "edit";
  options: StudentFormOptions;
  studentId?: string;
  initialValues?: StudentFormInitialValues;
};

const defaultValues: StudentFormInitialValues = {
  legacyStudentId: "",
  nis: "",
  fullName: "",
  gender: "male",
  status: "active",
  classId: "",
  careGroupId: "",
  tahfizGroupId: "",
};

export function StudentForm({
  mode,
  options,
  studentId,
  initialValues = defaultValues,
}: StudentFormProps) {
  const action =
    mode === "create"
      ? createAdminStudentAction
      : updateAdminStudentAction;

  const [state, formAction, isPending] =
    useActionState(
      action,
      initialStudentFormActionState,
    );

  const [gender, setGender] =
    useState<StudentFormGender>(
      initialValues.gender,
    );

  const [status, setStatus] =
    useState<StudentFormStatus>(
      initialValues.status,
    );

  const [classId, setClassId] =
    useState(initialValues.classId);

  const [careGroupId, setCareGroupId] =
    useState(
      initialValues.careGroupId,
    );

  const [tahfizGroupId, setTahfizGroupId] =
    useState(
      initialValues.tahfizGroupId,
    );

  const selectedClass =
    options.classes.find(
      (item) => item.id === classId,
    );

  const selectedGradeLevel =
    selectedClass?.grade_level ?? null;

  const availableClasses =
    options.classes.filter(
      (item) =>
        item.gender === null ||
        item.gender === gender,
    );

  const availableCareGroups =
    options.care_groups.filter(
      (item) => item.gender === gender,
    );

  const availableTahfizGroups =
    options.tahfiz_groups.filter(
      (item) => {
        const genderMatches =
          item.gender === gender;

        const gradeMatches =
          selectedGradeLevel === null ||
          item.grade_level === null ||
          item.grade_level ===
            selectedGradeLevel;

        return (
          genderMatches && gradeMatches
        );
      },
    );

  const placementRequired =
    status === "active";

  function handleGenderChange(
    newGender: StudentFormGender,
  ) {
    setGender(newGender);

    const currentClass =
      options.classes.find(
        (item) => item.id === classId,
      );

    if (
      currentClass?.gender &&
      currentClass.gender !== newGender
    ) {
      setClassId("");
    }

    const currentCareGroup =
      options.care_groups.find(
        (item) =>
          item.id === careGroupId,
      );

    if (
      currentCareGroup &&
      currentCareGroup.gender !==
        newGender
    ) {
      setCareGroupId("");
    }

    const currentTahfizGroup =
      options.tahfiz_groups.find(
        (item) =>
          item.id === tahfizGroupId,
      );

    if (
      currentTahfizGroup &&
      currentTahfizGroup.gender !==
        newGender
    ) {
      setTahfizGroupId("");
    }
  }

  function handleClassChange(
    newClassId: string,
  ) {
    setClassId(newClassId);

    const newClass =
      options.classes.find(
        (item) => item.id === newClassId,
      );

    const currentTahfizGroup =
      options.tahfiz_groups.find(
        (item) =>
          item.id === tahfizGroupId,
      );

    if (
      newClass &&
      currentTahfizGroup
    ) {
      const gradeDoesNotMatch =
        currentTahfizGroup.grade_level !==
          null &&
        currentTahfizGroup.grade_level !==
          newClass.grade_level;

      if (gradeDoesNotMatch) {
        setTahfizGroupId("");
      }
    }
  }

  const cancelHref =
    mode === "edit" && studentId
      ? `/admin/santri/${studentId}`
      : "/admin/santri";

  return (
    <form
      action={formAction}
      className="space-y-6"
    >
      {studentId && (
        <input
          type="hidden"
          name="studentId"
          value={studentId}
        />
      )}

      <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Identitas
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Data dasar santri
          </h2>
        </div>

        <div className="mt-6 grid gap-5 md:grid-cols-2">
          <div>
            <label
              htmlFor="legacyStudentId"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              ID Santri
            </label>

            <input
              id="legacyStudentId"
              name="legacyStudentId"
              type="text"
              required
              maxLength={100}
              defaultValue={
                initialValues.legacyStudentId
              }
              disabled={isPending}
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            />

            <StudentFormFieldError
              errors={
                state.fieldErrors
                  .legacyStudentId
              }
            />
          </div>

          <div>
            <label
              htmlFor="nis"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              NIS
              <span className="ml-2 text-xs font-normal text-slate-400">
                Opsional
              </span>
            </label>

            <input
              id="nis"
              name="nis"
              type="text"
              maxLength={100}
              defaultValue={
                initialValues.nis
              }
              disabled={isPending}
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            />

            <StudentFormFieldError
              errors={state.fieldErrors.nis}
            />
          </div>

          <div className="md:col-span-2">
            <label
              htmlFor="fullName"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              Nama lengkap
            </label>

            <input
              id="fullName"
              name="fullName"
              type="text"
              required
              maxLength={200}
              defaultValue={
                initialValues.fullName
              }
              disabled={isPending}
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            />

            <StudentFormFieldError
              errors={
                state.fieldErrors.fullName
              }
            />
          </div>

          <div>
            <label
              htmlFor="gender"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              Gender
            </label>

            <select
              id="gender"
              name="gender"
              value={gender}
              disabled={isPending}
              onChange={(event) =>
                handleGenderChange(
                  event.target
                    .value as StudentFormGender,
                )
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            >
              <option value="male">
                Putra
              </option>

              <option value="female">
                Putri
              </option>
            </select>

            <StudentFormFieldError
              errors={
                state.fieldErrors.gender
              }
            />
          </div>

          <div>
            <label
              htmlFor="status"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              Status
            </label>

            <select
              id="status"
              name="status"
              value={status}
              disabled={isPending}
              onChange={(event) =>
                setStatus(
                  event.target
                    .value as StudentFormStatus,
                )
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            >
              <option value="active">
                Aktif
              </option>

              <option value="inactive">
                Tidak aktif
              </option>

              <option value="graduated">
                Lulus
              </option>

              <option value="withdrawn">
                Keluar
              </option>
            </select>

            <StudentFormFieldError
              errors={
                state.fieldErrors.status
              }
            />
          </div>
        </div>
      </section>

      <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Penempatan
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Tahun ajaran{" "}
            {options.academic_year?.name ??
              "aktif"}
          </h2>

          <p className="mt-2 text-sm leading-6 text-muted">
            Perubahan penempatan akan tetap
            menyimpan data sebelumnya sebagai
            riwayat.
          </p>
        </div>

        {!placementRequired && (
          <div className="mt-5 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm leading-6 text-amber-800">
            Status nonaktif akan menutup kelas,
            pengasuhan, dan kelompok tahfiz yang
            sedang aktif.
          </div>
        )}

        <div className="mt-6 grid gap-5 xl:grid-cols-3">
          <div>
            <label
              htmlFor="classId"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              Kelas
            </label>

            <select
              id="classId"
              name="classId"
              value={classId}
              required={placementRequired}
              disabled={
                isPending ||
                !placementRequired
              }
              onChange={(event) =>
                handleClassChange(
                  event.target.value,
                )
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            >
              <option value="">
                Pilih kelas
              </option>

              {availableClasses.map(
                (item) => (
                  <option
                    key={item.id}
                    value={item.id}
                  >
                    {item.name}
                  </option>
                ),
              )}
            </select>

            <StudentFormFieldError
              errors={
                state.fieldErrors.classId
              }
            />
          </div>

          <div>
            <label
              htmlFor="careGroupId"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              Kelompok pengasuhan
            </label>

            <select
              id="careGroupId"
              name="careGroupId"
              value={careGroupId}
              required={placementRequired}
              disabled={
                isPending ||
                !placementRequired
              }
              onChange={(event) =>
                setCareGroupId(
                  event.target.value,
                )
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            >
              <option value="">
                Pilih pengasuhan
              </option>

              {availableCareGroups.map(
                (item) => (
                  <option
                    key={item.id}
                    value={item.id}
                  >
                    {item.name}
                  </option>
                ),
              )}
            </select>

            <StudentFormFieldError
              errors={
                state.fieldErrors.careGroupId
              }
            />
          </div>

          <div>
            <label
              htmlFor="tahfizGroupId"
              className="mb-2 block text-sm font-semibold text-slate-700"
            >
              Kelompok tahfiz
            </label>

            <select
              id="tahfizGroupId"
              name="tahfizGroupId"
              value={tahfizGroupId}
              required={placementRequired}
              disabled={
                isPending ||
                !placementRequired ||
                !classId
              }
              onChange={(event) =>
                setTahfizGroupId(
                  event.target.value,
                )
              }
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3.5 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-4 focus:ring-brand-100 disabled:bg-slate-100"
            >
              <option value="">
                {classId
                  ? "Pilih kelompok tahfiz"
                  : "Pilih kelas terlebih dahulu"}
              </option>

              {availableTahfizGroups.map(
                (item) => (
                  <option
                    key={item.id}
                    value={item.id}
                  >
                    {item.name}
                  </option>
                ),
              )}
            </select>

            <StudentFormFieldError
              errors={
                state.fieldErrors
                  .tahfizGroupId
              }
            />
          </div>
        </div>
      </section>

      {state.status === "error" && (
        <div
          role="alert"
          className="rounded-2xl border border-red-200 bg-red-50 p-4 text-sm leading-6 text-red-700"
        >
          {state.message}
        </div>
      )}

      <div className="sticky bottom-20 z-20 rounded-2xl border border-line bg-white/95 p-4 shadow-panel backdrop-blur lg:bottom-4">
        <div className="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
          <Link
            href={cancelHref}
            className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-slate-600 transition hover:bg-slate-50"
          >
            Batal
          </Link>

          <button
            type="submit"
            disabled={isPending}
            className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-6 text-sm font-semibold text-white transition hover:bg-brand-800 disabled:cursor-not-allowed disabled:bg-brand-300"
          >
            {isPending
              ? "Menyimpan..."
              : mode === "create"
                ? "Simpan santri"
                : "Simpan perubahan"}
          </button>
        </div>
      </div>
    </form>
  );
}