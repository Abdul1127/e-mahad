import { z } from "zod";

export const staffAccountResetPasswordSchema =
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
        .regex(
          /[A-Za-z]/,
          "Password harus memiliki minimal satu huruf.",
        )
        .regex(
          /[0-9]/,
          "Password harus memiliki minimal satu angka.",
        ),

      password_confirmation:
        z.string().min(
          1,
          "Konfirmasi password wajib diisi.",
        ),
    })
    .superRefine(
      (values, context) => {
        if (
          values.password !==
          values.password_confirmation
        ) {
          context.addIssue({
            code:
              z.ZodIssueCode.custom,

            path: [
              "password_confirmation",
            ],

            message:
              "Konfirmasi password tidak sama.",
          });
        }
      },
    );