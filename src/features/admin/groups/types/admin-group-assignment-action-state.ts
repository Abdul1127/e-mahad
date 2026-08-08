export type AdminGroupAssignmentActionState = {
  status:
    | "idle"
    | "error";

  message:
    string | null;
};

export const initialAdminGroupAssignmentActionState: AdminGroupAssignmentActionState =
  {
    status: "idle",
    message: null,
  };