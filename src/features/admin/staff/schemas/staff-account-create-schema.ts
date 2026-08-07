import { z } from "zod";

const passwordSchema = z
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
  );

export const staffAccountCreateSchema =
  z
    .object({
      password:
        passwordSchema,

      password_confirmation:
        z.string().min(
          1,
          "Konfirmasi password wajib diisi.",
        ),

      role_codes: z
        .array(
          z.string().trim().min(1),
        )
        .min(
          1,
          "Pilih minimal satu role staf.",
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

export type StaffAccountCreateInput =
  z.infer<
    typeof staffAccountCreateSchema
  >;