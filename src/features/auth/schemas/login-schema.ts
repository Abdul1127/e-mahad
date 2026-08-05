import { z } from "zod";

export const loginSchema = z.object({
  email: z
    .string()
    .trim()
    .min(1, "Email wajib diisi.")
    .email("Format email tidak valid.")
    .max(254, "Email terlalu panjang."),

  password: z
    .string()
    .min(1, "Password wajib diisi.")
    .max(256, "Password terlalu panjang."),
});

export type LoginInput = z.infer<
  typeof loginSchema
>;