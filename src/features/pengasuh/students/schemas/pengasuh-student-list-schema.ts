import { z } from "zod";

const genderSchema = z.enum([
  "male",
  "female",
]);

const careGroupSchema = z.object({
  id: z.string().uuid(),
  code: z.string(),
  name: z.string(),
  gender: genderSchema,
});

const classSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  grade_level: z.number().int(),
});

const studentItemSchema = z.object({
  student_id: z.string().uuid(),

  legacy_student_id: z
    .string()
    .nullable(),

  nis: z
    .string()
    .nullable(),

  full_name: z.string(),

  gender: genderSchema,

  membership_id:
    z.string().uuid(),

  joined_at:
    z.string(),

  care_group:
    careGroupSchema,

  class:
    classSchema.nullable(),
});

export const pengasuhStudentListSchema =
  z.object({
    generated_at:
      z.string(),

    profile:
      z.object({
        id:
          z.string().uuid(),

        login_id:
          z.string()
            .nullable(),
      }),

    staff:
      z.object({
        id:
          z.string().uuid(),

        legacy_staff_id:
          z.string()
            .nullable(),

        full_name:
          z.string(),

        position:
          z.string()
            .nullable(),
      }),

    academic_year:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),
      }),

    query:
      z.object({
        search:
          z.string()
            .nullable(),
      }),

    summary:
      z.object({
        group_count:
          z.number()
            .int()
            .nonnegative(),

        student_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    items:
      z.array(
        studentItemSchema,
      ),
  });

export type PengasuhStudentListData =
  z.infer<
    typeof pengasuhStudentListSchema
  >;

export type PengasuhStudentListItem =
  PengasuhStudentListData["items"][number];