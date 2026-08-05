import { z } from "zod";

const guardianStudentOptionSchema = z.object({
  student_id: z.string().uuid(),

  legacy_student_id: z
    .string()
    .nullable(),

  nis: z.string().nullable(),
  full_name: z.string(),

  gender: z.string(),
  status: z.string(),

  class_id: z
    .string()
    .uuid()
    .nullable(),

  class_name: z.string().nullable(),

  grade_level: z
    .number()
    .int()
    .nullable(),

  academic_year_name: z
    .string()
    .nullable(),

  guardian_count: z
    .number()
    .int()
    .nonnegative(),

  primary_guardian_name: z
    .string()
    .nullable(),
});

export const guardianStudentOptionsSchema =
  z.object({
    guardian_id: z.string().uuid(),

    search: z
      .string()
      .nullable(),

    limit: z
      .number()
      .int()
      .positive(),

    items: z.array(
      guardianStudentOptionSchema,
    ),
  });

export type GuardianStudentOptionsData =
  z.infer<
    typeof guardianStudentOptionsSchema
  >;

export type GuardianStudentOption =
  GuardianStudentOptionsData["items"][number];