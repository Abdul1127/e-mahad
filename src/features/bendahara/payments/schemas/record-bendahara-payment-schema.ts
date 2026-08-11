import { z } from "zod";

const optionalText = (
  maxLength: number,
) =>
  z.preprocess(
    (value) => {
      if (
        typeof value !==
        "string"
      ) {
        return null;
      }

      const normalized =
        value.trim();

      return normalized.length >
        0
        ? normalized
        : null;
    },
    z.string()
      .max(maxLength)
      .nullable(),
  );

export const recordBendaharaPaymentSchema =
  z.object({
    billId:
      z.string()
        .uuid(
          "Tagihan tidak valid.",
        ),

    paymentDate:
      z.string()
        .regex(
          /^\d{4}-\d{2}-\d{2}$/,
          "Tanggal pembayaran wajib diisi.",
        ),

    amount:
      z.coerce
        .number()
        .positive(
          "Nominal pembayaran harus lebih besar dari 0.",
        )
        .max(
          999999999999.99,
          "Nominal pembayaran terlalu besar.",
        ),

    paymentMethod:
      z.enum([
        "cash",
        "transfer",
        "bank_transfer",
        "other",
      ], {
        message:
          "Metode pembayaran tidak valid.",
      }),

    referenceNumber:
      optionalText(
        150,
      ),

    notes:
      optionalText(
        1000,
      ),
  });

export type RecordBendaharaPaymentInput =
  z.infer<
    typeof recordBendaharaPaymentSchema
  >;