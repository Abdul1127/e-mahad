export type StaffAccountActionState = {
  status: "idle" | "error";
  message: string;

  fieldErrors: {
    password?: string[];

    password_confirmation?:
      string[];

    role_codes?: string[];
  };
};

export const initialStaffAccountActionState: StaffAccountActionState =
  {
    status: "idle",
    message: "",
    fieldErrors: {},
  };


export type StaffAccountStatusActionState = {
  status: "idle" | "error";
  message: string | null;
};

export const initialStaffAccountStatusActionState: StaffAccountStatusActionState =
  {
    status: "idle",
    message: null,
  };


export type StaffAccountResetPasswordActionState =
  {
    status: "idle" | "error";

    message: string | null;

    fieldErrors: {
      password?: string[];

      password_confirmation?:
        string[];
    };
  };

export const initialStaffAccountResetPasswordActionState: StaffAccountResetPasswordActionState =
  {
    status: "idle",
    message: null,
    fieldErrors: {},
  };


export type StaffRoleActionState = {
  status: "idle" | "error";

  message: string | null;

  fieldErrors: {
    role_codes?: string[];
  };
};

export const initialStaffRoleActionState: StaffRoleActionState =
  {
    status: "idle",
    message: null,
    fieldErrors: {},
  };