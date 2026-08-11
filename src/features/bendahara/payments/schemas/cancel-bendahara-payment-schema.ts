import { z } from "zod";

export const cancelBendaharaPaymentSchema =
  z.object({
    billId:
      z.string()
        .uuid(
          "Tagihan tidak valid.",
        ),

    paymentId:
      z.string()
        .uuid(
          "Pembayaran tidak valid.",
        ),

    cancellationReason:
      z.string()
        .trim()
        .min(
          1,
          "Alasan pembatalan wajib diisi.",
        )
        .max(
          1000,
          "Alasan pembatalan maksimal 1000 karakter.",
        ),
  });

export type CancelBendaharaPaymentInput =
  z.infer<
    typeof cancelBendaharaPaymentSchema
  >;