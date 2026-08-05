import { z } from "zod";

const phonePattern = /^[0-9+() ./-]+$/;

export const guardianFormSchema = z.object({
  legacy_guardian_id: z
    .string()
    .trim()
    .max(
      100,
      "ID wali maksimal 100 karakter.",
    )
    .transform((value) =>
      value.length > 0 ? value : null,
    ),

  full_name: z
    .string()
    .trim()
    .min(
      2,
      "Nama lengkap minimal 2 karakter.",
    )
    .max(
      200,
      "Nama lengkap maksimal 200 karakter.",
    )
    .transform((value) =>
      value.replace(/\s+/g, " "),
    ),

  phone: z
    .string()
    .trim()
    .max(
      30,
      "Nomor telepon maksimal 30 karakter.",
    )
    .superRefine((value, context) => {
      if (value.length === 0) {
        return;
      }

      if (!phonePattern.test(value)) {
        context.addIssue({
          code: "custom",
          message:
            "Format nomor telepon tidak valid.",
        });

        return;
      }

      const digits = value.replace(
        /[^0-9]/g,
        "",
      );

      if (digits.length < 8) {
        context.addIssue({
          code: "custom",
          message:
            "Nomor telepon minimal 8 digit.",
        });
      }
    })
    .transform((value) =>
      value.length > 0 ? value : null,
    ),

  email: z
    .string()
    .trim()
    .toLowerCase()
    .max(
      254,
      "Email maksimal 254 karakter.",
    )
    .refine(
      (value) =>
        value.length === 0 ||
        z.string().email().safeParse(value)
          .success,
      {
        message: "Format email tidak valid.",
      },
    )
    .transform((value) =>
      value.length > 0 ? value : null,
    ),

  is_active: z.boolean(),
});

export type GuardianFormData = z.infer<
  typeof guardianFormSchema
>;