import { z } from "zod";

export const studentGenderSchema = z.enum([
  "male",
  "female",
]);

const studentStatusSchema = z.enum([
  "active",
  "inactive",
  "graduated",
  "withdrawn",
]);

const academicYearSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  start_date: z.string(),
  end_date: z.string(),
});

const studentListItemSchema = z.object({
  id: z.string().uuid(),

  legacy_student_id: z.string().nullable(),
  nis: z.string().nullable(),

  full_name: z.string(),
  gender: studentGenderSchema,

  photo_url: z.string().nullable(),
  status: studentStatusSchema,

  class_id: z.string().uuid().nullable(),
  class_name: z.string().nullable(),
  grade_level: z.number().int().nullable(),

  care_group_id: z.string().uuid().nullable(),
  care_group_name: z.string().nullable(),

  tahfiz_group_id: z.string().uuid().nullable(),
  tahfiz_group_name: z.string().nullable(),

  guardian_count: z
    .number()
    .int()
    .nonnegative(),
});

const classOptionSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  grade_level: z.number().int(),
  gender: studentGenderSchema.nullable(),
});

const careGroupOptionSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  gender: studentGenderSchema,
});

const tahfizGroupOptionSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  grade_level: z.number().int().nullable(),
  gender: studentGenderSchema,
});

export const adminStudentListSchema = z.object({
  generated_at: z.string(),

  academic_year: academicYearSchema.nullable(),

  filters: z.object({
    search: z.string().nullable(),
    grade_level: z.number().int().nullable(),
    gender: studentGenderSchema.nullable(),
    care_group_id: z.string().uuid().nullable(),
    tahfiz_group_id: z.string().uuid().nullable(),
  }),

  pagination: z.object({
    current_page: z.number().int().positive(),
    page_size: z.number().int().positive(),

    total_items: z
      .number()
      .int()
      .nonnegative(),

    total_pages: z
      .number()
      .int()
      .nonnegative(),

    from_item: z
      .number()
      .int()
      .nonnegative(),

    to_item: z
      .number()
      .int()
      .nonnegative(),
  }),

  items: z.array(studentListItemSchema),

  filter_options: z.object({
    classes: z.array(classOptionSchema),
    care_groups: z.array(
      careGroupOptionSchema,
    ),
    tahfiz_groups: z.array(
      tahfizGroupOptionSchema,
    ),
  }),
});

export type StudentGender = z.infer<
  typeof studentGenderSchema
>;

export type AdminStudentListData = z.infer<
  typeof adminStudentListSchema
>;

export type AdminStudentListItem =
  AdminStudentListData["items"][number];

export type StudentFilterOptions =
  AdminStudentListData["filter_options"];