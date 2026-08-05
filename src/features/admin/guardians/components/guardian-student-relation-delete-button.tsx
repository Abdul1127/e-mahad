"use client";

import { useActionState } from "react";
import { useFormStatus } from "react-dom";

import {
  initialGuardianStudentRelationDeleteActionState,
  type GuardianStudentRelationDeleteActionState,
} from "../types/guardian-student-relation-mutation-state";

type DeleteRelationAction = (
  state:
    GuardianStudentRelationDeleteActionState,
  formData: FormData,
) => Promise<GuardianStudentRelationDeleteActionState>;

type GuardianStudentRelationDeleteButtonProps = {
  action: DeleteRelationAction;
  studentName: string;
};

function DeleteSubmitButton({
  studentName,
}: {
  studentName: string;
}) {
  const { pending } = useFormStatus();

  function handleClick(
    event: React.MouseEvent<HTMLButtonElement>,
  ) {
    const confirmed = window.confirm(
      `Lepaskan hubungan wali dengan ${studentName}? Tindakan ini tidak menghapus data wali maupun data santri.`,
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
      className="inline-flex min-h-10 items-center justify-center rounded-xl border border-red-200 bg-white px-4 text-sm font-semibold text-red-600 transition hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-60"
    >
      {pending
        ? "Melepaskan..."
        : "Lepaskan"}
    </button>
  );
}

export function GuardianStudentRelationDeleteButton({
  action,
  studentName,
}: GuardianStudentRelationDeleteButtonProps) {
  const [state, formAction] =
    useActionState(
      action,
      initialGuardianStudentRelationDeleteActionState,
    );

  return (
    <form action={formAction}>
      <DeleteSubmitButton
        studentName={studentName}
      />

      {state.message && (
        <p className="mt-2 max-w-48 text-xs font-medium leading-5 text-red-600">
          {state.message}
        </p>
      )}
    </form>
  );
}