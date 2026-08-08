import { z } from "zod";

export const adminGroupTypeSchema =
  z.enum([
    "care",
    "tahfiz",
  ]);

const genderSchema =
  z.enum([
    "male",
    "female",
  ]);

const studentStatusSchema =
  z.enum([
    "active",
    "inactive",
    "graduated",
    "withdrawn",
  ]);

const groupMemberSchema =
  z.object({
    membership_id:
      z.string().uuid(),

    joined_at:
      z.string(),

    student_id:
      z.string().uuid(),

    legacy_student_id:
      z.string().nullable(),

    nis:
      z.string().nullable(),

    full_name:
      z.string(),

    gender:
      genderSchema,

    status:
      studentStatusSchema,

    class_id:
      z.string()
        .uuid()
        .nullable(),

    class_name:
      z.string()
        .nullable(),

    grade_level:
      z.number()
        .int()
        .nullable(),
  });

const activeAssignmentSchema =
  z.object({
    assignment_id:
      z.string().uuid(),

    staff_id:
      z.string().uuid(),

    profile_id:
      z.string()
        .uuid()
        .nullable(),

    legacy_staff_id:
      z.string()
        .nullable(),

    full_name:
      z.string(),

    phone:
      z.string()
        .nullable(),

    position:
      z.string()
        .nullable(),

    staff_is_active:
      z.boolean(),

    login_id:
      z.string()
        .nullable(),

    account_active:
      z.boolean(),

    is_primary:
      z.boolean(),

    assigned_at:
      z.string(),
  });

const assignmentHistorySchema =
  z.object({
    assignment_id:
      z.string().uuid(),

    staff_id:
      z.string().uuid(),

    legacy_staff_id:
      z.string()
        .nullable(),

    full_name:
      z.string(),

    position:
      z.string()
        .nullable(),

    is_primary:
      z.boolean(),

    assigned_at:
      z.string(),

    ended_at:
      z.string()
        .nullable(),

    is_active:
      z.boolean(),
  });

export const adminGroupAssignmentDetailSchema =
  z.object({
    generated_at:
      z.string(),

    group_type:
      adminGroupTypeSchema,

    group: z.object({
      id:
        z.string().uuid(),

      code:
        z.string(),

      name:
        z.string(),

      gender:
        genderSchema,

      grade_level:
        z.number()
          .int()
          .nullable(),

      description:
        z.string()
          .nullable(),

      is_active:
        z.boolean(),

      created_at:
        z.string(),

      updated_at:
        z.string(),
    }),

    academic_year:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),

        start_date:
          z.string(),

        end_date:
          z.string(),

        is_current:
          z.boolean(),
      }),

    summary: z.object({
      active_member_count:
        z.number()
          .int()
          .nonnegative(),

      active_assignment_count:
        z.number()
          .int()
          .nonnegative(),

      primary_assignment_count:
        z.number()
          .int()
          .nonnegative(),

      assignment_history_count:
        z.number()
          .int()
          .nonnegative(),
    }),

    members:
      z.array(
        groupMemberSchema,
      ),

    active_assignments:
      z.array(
        activeAssignmentSchema,
      ),

    assignment_history:
      z.array(
        assignmentHistorySchema,
      ),
  });

export type AdminGroupType =
  z.infer<
    typeof adminGroupTypeSchema
  >;

export type AdminGroupAssignmentDetailData =
  z.infer<
    typeof adminGroupAssignmentDetailSchema
  >;

export type AdminGroupMember =
  AdminGroupAssignmentDetailData["members"][number];

export type AdminGroupActiveAssignment =
  AdminGroupAssignmentDetailData["active_assignments"][number];

export type AdminGroupAssignmentHistory =
  AdminGroupAssignmentDetailData["assignment_history"][number];