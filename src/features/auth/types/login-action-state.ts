export type LoginActionState = {
  status: "idle" | "error";
  message: string;
  fieldErrors: {
    email?: string[];
    password?: string[];
  };
};

export const initialLoginActionState: LoginActionState = {
  status: "idle",
  message: "",
  fieldErrors: {},
};