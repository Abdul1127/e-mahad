import { z } from "zod";

export const guardianAccountCreateSchema =
  z
    .object({
      password: z
        .string()
        .min(
          8,
          "Password minimal 8 karakter.",
        )
        .max(
          72,
          "Password maksimal 72 karakter.",
        )
        .refine(
          (value) => /[A-Za-z]/.test(value),
          {
            message:
              "Password harus memiliki minimal satu huruf.",
          },
        )
        .refine(
          (value) => /[0-9]/.test(value),
          {
            message:
              "Password harus memiliki minimal satu angka.",
          },
        ),

      password_confirmation: z.string(),
    })
    .superRefine((data, context) => {
      if (
        data.password !==
        data.password_confirmation
      ) {
        context.addIssue({
          code: "custom",
          path: ["password_confirmation"],
          message:
            "Konfirmasi password tidak sama.",
        });
      }
    });

export type GuardianAccountCreateData =
  z.infer<
    typeof guardianAccountCreateSchema
  >;