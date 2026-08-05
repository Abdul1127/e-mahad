import { z } from "zod";

const genderSchema = z.enum([
  "male",
  "female",
]);

const statusSchema = z.enum([
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

const assignedStaffSchema = z.object({
  id: z.string().uuid(),
  legacy_staff_id: z.string().nullable(),
  full_name: z.string(),
  is_primary: z.boolean(),
});

const currentClassSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  grade_level: z.number().int(),
  gender: genderSchema.nullable(),
  academic_year_id: z.string().uuid(),
  academic_year_name: z.string(),
  enrolled_at: z.string(),
  left_at: z.string().nullable(),
});

const currentCareGroupSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  gender: genderSchema,
  academic_year_id: z.string().uuid(),
  academic_year_name: z.string(),
  joined_at: z.string(),
  left_at: z.string().nullable(),
  caregivers: z.array(assignedStaffSchema),
});

const currentTahfizGroupSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  grade_level: z.number().int().nullable(),
  gender: genderSchema,
  academic_year_id: z.string().uuid(),
  academic_year_name: z.string(),
  joined_at: z.string(),
  left_at: z.string().nullable(),
  supervisors: z.array(assignedStaffSchema),
});

const guardianSchema = z.object({
  id: z.string().uuid(),
  legacy_guardian_id: z.string().nullable(),
  full_name: z.string(),
  phone: z.string().nullable(),
  email: z.string().nullable(),
  is_active: z.boolean(),
  profile_id: z.string().uuid().nullable(),
  account_email: z.string().nullable(),
  account_active: z.boolean(),
});

const classHistorySchema = z.object({
  id: z.string().uuid(),
  class_id: z.string().uuid(),
  class_name: z.string(),
  grade_level: z.number().int(),
  academic_year_id: z.string().uuid(),
  academic_year_name: z.string(),
  enrolled_at: z.string(),
  left_at: z.string().nullable(),
  is_active: z.boolean(),
});

const careHistorySchema = z.object({
  id: z.string().uuid(),
  care_group_id: z.string().uuid(),
  care_group_name: z.string(),
  gender: genderSchema,
  academic_year_id: z.string().uuid(),
  academic_year_name: z.string(),
  joined_at: z.string(),
  left_at: z.string().nullable(),
  is_active: z.boolean(),
});

const tahfizHistorySchema = z.object({
  id: z.string().uuid(),
  tahfiz_group_id: z.string().uuid(),
  tahfiz_group_name: z.string(),
  grade_level: z.number().int().nullable(),
  gender: genderSchema,
  academic_year_id: z.string().uuid(),
  academic_year_name: z.string(),
  joined_at: z.string(),
  left_at: z.string().nullable(),
  is_active: z.boolean(),
});

export const adminStudentDetailSchema = z.object({
  generated_at: z.string(),

  student: z.object({
    id: z.string().uuid(),
    legacy_student_id: z.string().nullable(),
    nis: z.string().nullable(),
    full_name: z.string(),
    gender: genderSchema,
    photo_url: z.string().nullable(),
    status: statusSchema,
    created_at: z.string(),
    updated_at: z.string(),
  }),

  academic_year: academicYearSchema.nullable(),

  current_placement: z.object({
    class: currentClassSchema.nullable(),
    care_group: currentCareGroupSchema.nullable(),
    tahfiz_group: currentTahfizGroupSchema.nullable(),
  }),

  guardians: z.array(guardianSchema),

  history: z.object({
    classes: z.array(classHistorySchema),
    care_groups: z.array(careHistorySchema),
    tahfiz_groups: z.array(
      tahfizHistorySchema,
    ),
  }),
});

export type AdminStudentDetailData = z.infer<
  typeof adminStudentDetailSchema
>;

export type StudentPlacementStaff = z.infer<
  typeof assignedStaffSchema
>;