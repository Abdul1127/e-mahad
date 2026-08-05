export type GuardianStudentRelationFormValues = {
  student_id: string;
  relationship_type: string;
  is_primary_contact: boolean;
};

export type GuardianStudentRelationFormField =
  keyof GuardianStudentRelationFormValues;

export type GuardianStudentRelationActionState = {
  status: "idle" | "error";
  message: string | null;

  fieldErrors: Partial<
    Record<
      GuardianStudentRelationFormField,
      string[]
    >
  >;

  values:
    GuardianStudentRelationFormValues;
};

export const initialGuardianStudentRelationActionState: GuardianStudentRelationActionState =
  {
    status: "idle",
    message: null,

    fieldErrors: {},

    values: {
      student_id: "",
      relationship_type: "guardian",
      is_primary_contact: false,
    },
  };