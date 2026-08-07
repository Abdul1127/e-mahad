import { z } from "zod";

export const guardianLoginIdentitySchema =
  z.object({
    success: z.boolean(),

    status: z.enum([
      "candidate",
      "existing",
    ]),

    guardian_id: z.string().uuid(),

    profile_id: z
      .string()
      .uuid()
      .nullable(),

    full_name: z.string().min(1),

    student_seed: z
      .string()
      .nullable()
      .optional(),

    login_id: z.string().min(1),

    internal_auth_email: z
      .string()
      .email(),
  });

export type GuardianLoginIdentityData =
  z.infer<
    typeof guardianLoginIdentitySchema
  >;