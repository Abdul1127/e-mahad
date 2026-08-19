export type ChangeOwnPasswordField =
  | "current_password"
  | "password"
  | "password_confirmation";

export type ChangeOwnPasswordActionState = {
  status:
    | "idle"
    | "error";

  message:
    string | null;

  fieldErrors:
    Partial<
      Record<
        ChangeOwnPasswordField,
        string[]
      >
    >;
};

export const initialChangeOwnPasswordActionState:
  ChangeOwnPasswordActionState = {
    status:
      "idle",

    message:
      null,

    fieldErrors:
      {},
  };