export type SavePengasuhActivityAttendanceState = {
  status:
    | "idle"
    | "error";

  message:
    string | null;
};

export const initialSavePengasuhActivityAttendanceState: SavePengasuhActivityAttendanceState =
  {
    status:
      "idle",

    message:
      null,
  };