import { z } from "zod";

const genderSchema = z.enum([
  "male",
  "female",
]);

const academicYearSchema = z.object({
  id: z.string().uuid(),
  name: z.string(),
  start_date: z.string(),
  end_date: z.string(),
});

const classDistributionSchema = z.object({
  grade_level: z.number().int(),
  class_name: z.string(),
  student_count: z.number().int().nonnegative(),
});

const careDistributionSchema = z.object({
  care_group_name: z.string(),
  gender: genderSchema,
  student_count: z.number().int().nonnegative(),
  caregiver_count: z.number().int().nonnegative(),
});

const tahfizDistributionSchema = z.object({
  tahfiz_group_name: z.string(),
  grade_level: z.number().int().nullable(),
  gender: genderSchema,
  student_count: z.number().int().nonnegative(),
  supervisor_count: z.number().int().nonnegative(),
  primary_supervisor_count: z
    .number()
    .int()
    .nonnegative(),
});

const unlinkedStaffSchema = z.object({
  legacy_staff_id: z.string().nullable(),
  full_name: z.string(),
  position: z.string().nullable(),
});

export const adminDashboardSchema = z.object({
  generated_at: z.string(),

  academic_year: academicYearSchema.nullable(),

  summary: z.object({
    active_students: z.number().int().nonnegative(),
    active_staff: z.number().int().nonnegative(),
    linked_staff_accounts: z
      .number()
      .int()
      .nonnegative(),
    unlinked_staff_accounts: z
      .number()
      .int()
      .nonnegative(),
    active_guardians: z.number().int().nonnegative(),
    active_classes: z.number().int().nonnegative(),
    active_care_groups: z.number().int().nonnegative(),
    active_tahfiz_groups: z
      .number()
      .int()
      .nonnegative(),
  }),

  class_distribution: z.array(
    classDistributionSchema,
  ),

  care_distribution: z.array(
    careDistributionSchema,
  ),

  tahfiz_distribution: z.array(
    tahfizDistributionSchema,
  ),

  attention: z.object({
    staff_without_accounts: z
      .number()
      .int()
      .nonnegative(),

    students_without_guardians: z
      .number()
      .int()
      .nonnegative(),

    students_without_active_class: z
      .number()
      .int()
      .nonnegative(),

    students_without_active_care_group: z
      .number()
      .int()
      .nonnegative(),

    students_without_active_tahfiz_group: z
      .number()
      .int()
      .nonnegative(),

    care_groups_without_caregiver: z
      .number()
      .int()
      .nonnegative(),

    tahfiz_groups_without_primary_supervisor: z
      .number()
      .int()
      .nonnegative(),
  }),

  readiness: z.object({
    class_memberships_complete: z.boolean(),
    care_memberships_complete: z.boolean(),
    tahfiz_memberships_complete: z.boolean(),
    care_assignments_complete: z.boolean(),
    tahfiz_assignments_complete: z.boolean(),
  }),

  unlinked_staff: z.array(unlinkedStaffSchema),
});

export type AdminDashboardData = z.infer<
  typeof adminDashboardSchema
>;