export type CreatePengasuhActivityScheduleState = {
  status:
    | "idle"
    | "error";

  message:
    string | null;

  values?: {
    careGroupId?:
      string;

    activityDate?:
      string;

    startTime?:
      string;

    endTime?:
      string;

    activityName?:
      string;

    location?:
      string;

    notes?:
      string;
  };
};

export const initialCreatePengasuhActivityScheduleState: CreatePengasuhActivityScheduleState =
  {
    status:
      "idle",

    message:
      null,
  };