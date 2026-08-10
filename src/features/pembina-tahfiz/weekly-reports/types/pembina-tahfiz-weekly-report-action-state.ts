export type PembinaTahfizWeeklyReportActionState = {
  status:
    | "idle"
    | "error";

  message:
    | string
    | null;
};

export const initialPembinaTahfizWeeklyReportActionState: PembinaTahfizWeeklyReportActionState =
  {
    status: "idle",
    message: null,
  };