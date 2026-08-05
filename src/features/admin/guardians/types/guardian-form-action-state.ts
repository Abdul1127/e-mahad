export type GuardianFormValues = {
  legacy_guardian_id: string;
  full_name: string;
  phone: string;
  email: string;
  is_active: boolean;
};

export type GuardianFormField =
  keyof GuardianFormValues;

export type GuardianFormActionState = {
  status: "idle" | "error";
  message: string | null;

  fieldErrors: Partial<
    Record<GuardianFormField, string[]>
  >;

  values: GuardianFormValues;
};

export const emptyGuardianFormValues: GuardianFormValues =
  {
    legacy_guardian_id: "",
    full_name: "",
    phone: "",
    email: "",
    is_active: true,
  };

export const initialGuardianFormActionState: GuardianFormActionState =
  {
    status: "idle",
    message: null,
    fieldErrors: {},
    values: emptyGuardianFormValues,
  };