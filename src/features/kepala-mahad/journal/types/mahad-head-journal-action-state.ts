export type MahadHeadJournalActionState = {
  status:
    | "idle"
    | "success"
    | "error";

  message:
    string | null;
};

export const initialMahadHeadJournalActionState: MahadHeadJournalActionState =
  {
    status:
      "idle",

    message:
      null,
  };