export type GuardianStudentRelationEditValues = {
  relationship_type: string;
  is_primary_contact: boolean;
};

export type GuardianStudentRelationEditField =
  keyof GuardianStudentRelationEditValues;

export type GuardianStudentRelationEditActionState = {
  status: "idle" | "error";
  message: string | null;

  fieldErrors: Partial<
    Record<
      GuardianStudentRelationEditField,
      string[]
    >
  >;

  values:
    GuardianStudentRelationEditValues;
};

export type GuardianStudentRelationDeleteActionState =
  {
    status: "idle" | "error";
    message: string | null;
  };

export const initialGuardianStudentRelationDeleteActionState: GuardianStudentRelationDeleteActionState =
  {
    status: "idle",
    message: null,
  };