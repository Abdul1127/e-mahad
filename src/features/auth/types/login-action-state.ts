export type LoginActionState = {
  status: "idle" | "error";
  message: string;

  fieldErrors: {
    login_id?: string[];
    password?: string[];
  };
};

export const initialLoginActionState: LoginActionState =
  {
    status: "idle",
    message: "",
    fieldErrors: {},
  };