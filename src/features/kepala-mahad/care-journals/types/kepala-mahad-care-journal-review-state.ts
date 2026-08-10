export type KepalaMahadCareJournalReviewState = {
  status:
    | "idle"
    | "error";

  message:
    | string
    | null;
};

export const initialKepalaMahadCareJournalReviewState: KepalaMahadCareJournalReviewState =
  {
    status: "idle",
    message: null,
  }; 