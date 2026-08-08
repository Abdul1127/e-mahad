import { z } from "zod";

import { adminGroupTypeSchema } from "./admin-group-assignment-detail-schema";

const genderSchema = z.enum([
  "male",
  "female",
]);

const requiredRoleSchema = z.enum([
  "pengasuh",
  "pembina_tahfiz",
]);

const assignmentSummarySchema = z.object({
  candidate_count: z
    .number()
    .int()
    .nonnegative(),

  current_assignment_count: z
    .number()
    .int()
    .nonnegative(),

  current_primary_count: z
    .number()
    .int()
    .nonnegative(),
});

const currentAssignmentSchema = z.object({
  assignment_id: z.string().uuid(),

  staff_id: z.string().uuid(),

  legacy_staff_id: z
    .string()
    .nullable(),

  full_name: z.string(),

  position: z
    .string()
    .nullable(),

  profile_id: z
    .string()
    .uuid()
    .nullable(),

  login_id: z
    .string()
    .nullable(),

  staff_is_active: z.boolean(),

  account_active: z.boolean(),

  is_primary: z.boolean(),

  assigned_at: z.string(),
});

const candidateActiveAssignmentSchema =
  z.object({
    assignment_id: z.string().uuid(),

    group_id: z.string().uuid(),

    group_name: z.string(),

    group_gender: genderSchema,

    grade_level: z
      .number()
      .int()
      .nullable()
      .optional(),

    is_primary: z.boolean(),

    assigned_at: z.string(),
  });

const candidateSchema = z.object({
  staff_id: z.string().uuid(),

  legacy_staff_id: z
    .string()
    .nullable(),

  full_name: z.string(),

  position: z
    .string()
    .nullable(),

  profile_id: z
    .string()
    .uuid()
    .nullable(),

  login_id: z
    .string()
    .nullable(),

  staff_is_active: z.boolean(),

  account_active: z.boolean(),

  roles: z.array(
    z.string(),
  ),

  assigned_to_target: z.boolean(),

  active_assignment_count: z
    .number()
    .int()
    .nonnegative(),

  active_assignments: z.array(
    candidateActiveAssignmentSchema,
  ),
});

export const adminGroupAssignmentCandidatesSchema =
  z.object({
    generated_at: z.string(),

    group_type:
      adminGroupTypeSchema,

    required_role:
      requiredRoleSchema,

    group: z.object({
      id: z.string().uuid(),

      code: z.string(),

      name: z.string(),

      gender: genderSchema,

      grade_level: z
        .number()
        .int()
        .nullable(),

      academic_year_id:
        z.string().uuid(),

      academic_year_name:
        z.string(),
    }),

    summary:
      assignmentSummarySchema,

    current_assignments:
      z.array(
        currentAssignmentSchema,
      ),

    candidates:
      z.array(
        candidateSchema,
      ),
  });

export type AdminGroupAssignmentCandidatesData =
  z.infer<
    typeof adminGroupAssignmentCandidatesSchema
  >;

export type AdminGroupAssignmentCandidate =
  AdminGroupAssignmentCandidatesData["candidates"][number];