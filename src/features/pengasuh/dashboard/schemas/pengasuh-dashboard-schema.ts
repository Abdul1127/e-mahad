import { z } from "zod";

const genderSchema = z.enum([
  "male",
  "female",
]);

const memberPreviewSchema = z.object({
  membership_id: z.string().uuid(),

  joined_at: z.string(),

  student_id: z.string().uuid(),

  legacy_student_id: z
    .string()
    .nullable(),

  nis: z
    .string()
    .nullable(),

  full_name: z.string(),

  gender: genderSchema,

  class_id: z
    .string()
    .uuid()
    .nullable(),

  class_name: z
    .string()
    .nullable(),

  grade_level: z
    .number()
    .int()
    .nullable(),
});

const pengasuhGroupSchema = z.object({
  assignment_id:
    z.string().uuid(),

  assigned_at:
    z.string(),

  id:
    z.string().uuid(),

  code:
    z.string(),

  name:
    z.string(),

  gender:
    genderSchema,

  description:
    z.string()
      .nullable(),

  active_member_count:
    z.number()
      .int()
      .nonnegative(),

  member_preview:
    z.array(
      memberPreviewSchema,
    ),
});

export const pengasuhDashboardSchema =
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

        phone:
          z.string()
            .nullable(),

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

        start_date:
          z.string(),

        end_date:
          z.string(),

        is_current:
          z.boolean(),
      }),

    summary:
      z.object({
        assigned_group_count:
          z.number()
            .int()
            .nonnegative(),

        active_student_count:
          z.number()
            .int()
            .nonnegative(),

        male_student_count:
          z.number()
            .int()
            .nonnegative(),

        female_student_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    groups:
      z.array(
        pengasuhGroupSchema,
      ),
  });

export type PengasuhDashboardData =
  z.infer<
    typeof pengasuhDashboardSchema
  >;

export type PengasuhDashboardGroup =
  PengasuhDashboardData["groups"][number];

export type PengasuhDashboardMemberPreview =
  PengasuhDashboardGroup["member_preview"][number];