export type PengasuhJournalActionState = {
  status:
    | "idle"
    | "error";

  message:
    | string
    | null;
};

export const initialPengasuhJournalActionState: PengasuhJournalActionState =
  {
    status: "idle",
    message: null,
  };