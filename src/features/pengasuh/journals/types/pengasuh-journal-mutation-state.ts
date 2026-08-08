export type PengasuhJournalMutationState = {
  status:
    | "idle"
    | "success"
    | "error";

  message:
    | string
    | null;
};

export const initialPengasuhJournalMutationState: PengasuhJournalMutationState =
  {
    status: "idle",
    message: null,
  };