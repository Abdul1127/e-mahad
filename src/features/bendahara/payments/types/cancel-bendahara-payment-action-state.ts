export type CancelBendaharaPaymentActionState = {
  status:
    | "idle"
    | "error";

  message:
    string | null;

  fieldErrors?: {
    cancellationReason?:
      string[];
  };

  values?: {
    cancellationReason?:
      string;
  };
};

export const initialCancelBendaharaPaymentActionState: CancelBendaharaPaymentActionState =
  {
    status:
      "idle",

    message:
      null,
  };