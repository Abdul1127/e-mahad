import { z } from "zod";

const guardianChildSchema = z.object({
  relation_id: z.string().uuid(),

  relationship_type: z.enum([
    "father",
    "mother",
    "guardian",
    "other",
  ]),

  is_primary_contact: z.boolean(),
  linked_at: z.string(),

  student_id: z.string().uuid(),
  legacy_student_id: z.string().nullable(),
  nis: z.string().nullable(),
  full_name: z.string(),

  gender: z.string(),
  status: z.string(),

  class_id: z.string().uuid().nullable(),
  class_name: z.string().nullable(),

  grade_level: z
    .number()
    .int()
    .nullable(),

  academic_year_name: z
    .string()
    .nullable(),
});

export const adminGuardianDetailSchema =
  z.object({
    generated_at: z.string(),

    guardian: z.object({
      id: z.string().uuid(),

      profile_id: z
        .string()
        .uuid()
        .nullable(),

      legacy_guardian_id: z
        .string()
        .nullable(),

      full_name: z.string(),
      phone: z.string().nullable(),
      email: z.string().nullable(),

      is_active: z.boolean(),

      created_at: z.string(),
      updated_at: z.string(),
    }),

    account: z.object({
      linked: z.boolean(),
      active: z.boolean(),

      profile_id: z
        .string()
        .uuid()
        .nullable(),

      login_id: z
        .string()
        .nullable(),

      /*
       * Dipertahankan sementara sampai seluruh
       * komponen UI selesai menggunakan login_id.
       */
      login_email: z
        .string()
        .nullable(),
    }),

    summary: z.object({
      children_count: z
        .number()
        .int()
        .nonnegative(),

      active_children_count: z
        .number()
        .int()
        .nonnegative(),

      primary_contact_count: z
        .number()
        .int()
        .nonnegative(),
    }),

    children: z.array(
      guardianChildSchema,
    ),
  });

export type AdminGuardianDetailData =
  z.infer<
    typeof adminGuardianDetailSchema
  >;