import { z } from "zod";

export const loginSchema = z.object({
  login_id: z
    .string()
    .trim()
    .min(
      1,
      "ID Pengguna wajib diisi.",
    )
    .max(
      64,
      "ID Pengguna maksimal 64 karakter.",
    )
    .transform((value) =>
      value.toUpperCase(),
    )
    .refine(
      (value) =>
        /^[A-Z0-9]+(?:-[A-Z0-9]+)*$/.test(
          value,
        ),
      {
        message:
          "Format ID Pengguna tidak valid.",
      },
    ),

  password: z
    .string()
    .min(
      1,
      "Password wajib diisi.",
    )
    .max(
      256,
      "Password terlalu panjang.",
    ),
});

export type LoginInput = z.infer<
  typeof loginSchema
>;