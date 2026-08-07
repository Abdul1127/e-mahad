import { z } from "zod";

const genderSchema = z.enum([
  "male",
  "female",
]);

const assignmentStaffSchema = z.object({
  assignment_id: z.string().uuid(),

  staff_id: z.string().uuid(),

  legacy_staff_id: z
    .string()
    .nullable(),

  full_name: z.string(),

  position: z
    .string()
    .nullable(),

  is_primary: z.boolean(),

  assigned_at: z.string(),
});

const careGroupSchema = z.object({
  id: z.string().uuid(),

  code: z.string(),
  name: z.string(),

  gender: genderSchema,

  description: z
    .string()
    .nullable(),

  is_active: z.boolean(),

  member_count: z
    .number()
    .int()
    .nonnegative(),

  caregiver_count: z
    .number()
    .int()
    .nonnegative(),

  primary_caregiver_count: z
    .number()
    .int()
    .nonnegative(),

  caregivers: z.array(
    assignmentStaffSchema,
  ),
});

const tahfizGroupSchema = z.object({
  id: z.string().uuid(),

  code: z.string(),
  name: z.string(),

  grade_level: z
    .number()
    .int()
    .nullable(),

  gender: genderSchema,

  description: z
    .string()
    .nullable(),

  is_active: z.boolean(),

  member_count: z
    .number()
    .int()
    .nonnegative(),

  supervisor_count: z
    .number()
    .int()
    .nonnegative(),

  primary_supervisor_count: z
    .number()
    .int()
    .nonnegative(),

  supervisors: z.array(
    assignmentStaffSchema,
  ),
});

export const adminGroupAssignmentOverviewSchema =
  z.object({
    generated_at: z.string(),

    academic_year: z.object({
      id: z.string().uuid(),

      name: z.string(),

      start_date: z.string(),
      end_date: z.string(),
    }),

    summary: z.object({
      active_students: z
        .number()
        .int()
        .nonnegative(),

      active_care_groups: z
        .number()
        .int()
        .nonnegative(),

      active_tahfiz_groups: z
        .number()
        .int()
        .nonnegative(),

      active_care_memberships: z
        .number()
        .int()
        .nonnegative(),

      active_tahfiz_memberships: z
        .number()
        .int()
        .nonnegative(),

      active_caregiver_assignments: z
        .number()
        .int()
        .nonnegative(),

      active_tahfiz_assignments: z
        .number()
        .int()
        .nonnegative(),

      students_without_care_group: z
        .number()
        .int()
        .nonnegative(),

      students_without_tahfiz_group: z
        .number()
        .int()
        .nonnegative(),

      care_groups_without_caregiver: z
        .number()
        .int()
        .nonnegative(),

      tahfiz_groups_without_primary_supervisor:
        z.number()
          .int()
          .nonnegative(),
    }),

    care_groups: z.array(
      careGroupSchema,
    ),

    tahfiz_groups: z.array(
      tahfizGroupSchema,
    ),
  });

export type AdminGroupAssignmentOverviewData =
  z.infer<
    typeof adminGroupAssignmentOverviewSchema
  >;

export type AdminCareGroup =
  AdminGroupAssignmentOverviewData["care_groups"][number];

export type AdminTahfizGroup =
  AdminGroupAssignmentOverviewData["tahfiz_groups"][number];