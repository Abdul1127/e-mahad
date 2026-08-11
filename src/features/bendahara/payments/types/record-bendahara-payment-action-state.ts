export type RecordBendaharaPaymentField =
  | "billId"
  | "paymentDate"
  | "amount"
  | "paymentMethod"
  | "referenceNumber"
  | "notes";

export type RecordBendaharaPaymentActionState = {
  status:
    | "idle"
    | "error";

  message:
    string | null;

  fieldErrors?: Partial<
    Record<
      RecordBendaharaPaymentField,
      string[]
    >
  >;

  values?: {
    paymentDate?: string;
    amount?: string;
    paymentMethod?: string;
    referenceNumber?: string;
    notes?: string;
  };
};

export const initialRecordBendaharaPaymentActionState: RecordBendaharaPaymentActionState =
  {
    status:
      "idle",

    message:
      null,
  };