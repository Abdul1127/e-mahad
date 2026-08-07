export type GuardianAccountCreateField =
  | "password"
  | "password_confirmation";

export type GuardianAccountActionState = {
  status: "idle" | "error";
  message: string | null;

  fieldErrors: Partial<
    Record<
      GuardianAccountCreateField,
      string[]
    >
  >;
};

export const initialGuardianAccountActionState: GuardianAccountActionState =
  {
    status: "idle",
    message: null,
    fieldErrors: {},
  };

export type GuardianAccountStatusActionState = {
  status: "idle" | "error";
  message: string | null;
};

export const initialGuardianAccountStatusActionState: GuardianAccountStatusActionState =
  {
    status: "idle",
    message: null,
  };

export type GuardianAccountResetPasswordField =
  | "password"
  | "password_confirmation";

export type GuardianAccountResetPasswordActionState =
  {
    status: "idle" | "error";
    message: string | null;

    fieldErrors: Partial<
      Record<
        GuardianAccountResetPasswordField,
        string[]
      >
    >;
  };

export const initialGuardianAccountResetPasswordActionState: GuardianAccountResetPasswordActionState =
  {
    status: "idle",
    message: null,
    fieldErrors: {},
  };