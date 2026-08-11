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
      .max(
        maxLength,
      )
      .nullable(),
  );

const optionalDate =
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
      .regex(
        /^\d{4}-\d{2}-\d{2}$/,
        "Format tanggal tidak valid.",
      )
      .nullable(),
  );

export const createBendaharaBillSchema =
  z.object({
    studentId:
      z.string()
        .uuid(
          "Santri tidak valid.",
        ),

    title:
      z.string()
        .trim()
        .min(
          1,
          "Nama tagihan wajib diisi.",
        )
        .max(
          150,
          "Nama tagihan maksimal 150 karakter.",
        ),

    category:
      z.string()
        .trim()
        .min(
          1,
          "Kategori tagihan wajib dipilih.",
        )
        .max(
          80,
        ),

    amount:
      z.coerce
        .number({
          message:
            "Nominal tagihan wajib diisi.",
        })
        .positive(
          "Nominal harus lebih besar dari 0.",
        )
        .max(
          999999999999.99,
          "Nominal terlalu besar.",
        ),

    description:
      optionalText(
        1000,
      ),

    periodLabel:
      optionalText(
        100,
      ),

    periodStart:
      optionalDate,

    periodEnd:
      optionalDate,

    dueDate:
      optionalDate,
  })
  .superRefine(
    (
      data,
      context,
    ) => {
      if (
        data.periodStart &&
        data.periodEnd &&
        data.periodEnd <
          data.periodStart
      ) {
        context.addIssue({
          code:
            "custom",

          path: [
            "periodEnd",
          ],

          message:
            "Tanggal akhir periode tidak boleh sebelum tanggal mulai.",
        });
      }
    },
  );

export type CreateBendaharaBillInput =
  z.infer<
    typeof createBendaharaBillSchema
  >;