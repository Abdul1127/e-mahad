import {
  z,
} from "zod";

export const changeOwnPasswordSchema =
  z
    .object({
      current_password:
        z
          .string()
          .min(
            1,
            "Password saat ini wajib diisi.",
          )
          .max(
            256,
            "Password saat ini terlalu panjang.",
          ),

      password:
        z
          .string()
          .min(
            8,
            "Password baru minimal 8 karakter.",
          )
          .max(
            72,
            "Password baru maksimal 72 karakter.",
          ),

      password_confirmation:
        z
          .string()
          .min(
            1,
            "Konfirmasi password wajib diisi.",
          )
          .max(
            72,
            "Konfirmasi password terlalu panjang.",
          ),
    })
    .superRefine(
      (
        value,
        context,
      ) => {
        if (
          value.password !==
          value.password_confirmation
        ) {
          context.addIssue({
            code:
              "custom",

            path: [
              "password_confirmation",
            ],

            message:
              "Konfirmasi password baru tidak sama.",
          });
        }

        if (
          value.current_password ===
          value.password
        ) {
          context.addIssue({
            code:
              "custom",

            path: [
              "password",
            ],

            message:
              "Password baru harus berbeda dari password saat ini.",
          });
        }
      },
    );

export type ChangeOwnPasswordInput =
  z.infer<
    typeof changeOwnPasswordSchema
  >;