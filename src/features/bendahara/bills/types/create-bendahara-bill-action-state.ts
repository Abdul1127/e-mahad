export type CreateBendaharaBillField =
  | "studentId"
  | "title"
  | "category"
  | "amount"
  | "description"
  | "periodLabel"
  | "periodStart"
  | "periodEnd"
  | "dueDate";

export type CreateBendaharaBillActionState = {
  status:
    | "idle"
    | "error";

  message:
    string | null;

  fieldErrors?: Partial<
    Record<
      CreateBendaharaBillField,
      string[]
    >
  >;

  values?: {
    title?: string;
    category?: string;
    amount?: string;
    description?: string;
    periodLabel?: string;
    periodStart?: string;
    periodEnd?: string;
    dueDate?: string;
  };
};

export const initialCreateBendaharaBillActionState: CreateBendaharaBillActionState =
  {
    status:
      "idle",

    message:
      null,
  };