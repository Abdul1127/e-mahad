import { z } from "zod";

const memberPreviewSchema =
  z.object({
    id:
      z.string().uuid(),

    legacy_student_id:
      z.string().nullable(),

    nis:
      z.string().nullable(),

    full_name:
      z.string(),

    gender:
      z.enum([
        "male",
        "female",
      ]),

    class:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),

        grade_level:
          z.number().int(),
      })
        .nullable(),
  });

const tahfizGroupSchema =
  z.object({
    id:
      z.string().uuid(),

    code:
      z.string(),

    name:
      z.string(),

    gender:
      z.enum([
        "male",
        "female",
      ])
        .nullable(),

    grade_level:
      z.number()
        .int()
        .nullable(),

    assignment:
      z.object({
        id:
          z.string().uuid(),

        is_primary:
          z.boolean(),

        assigned_at:
          z.string(),
      }),

    summary:
      z.object({
        member_count:
          z.number()
            .int()
            .nonnegative(),

        male_count:
          z.number()
            .int()
            .nonnegative(),

        female_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    member_preview:
      z.array(
        memberPreviewSchema,
      ),
  });

export const pembinaTahfizDashboardSchema =
  z.object({
    generated_at:
      z.string(),

    profile:
      z.object({
        id:
          z.string().uuid(),

        login_id:
          z.string().nullable(),
      }),

    staff:
      z.object({
        id:
          z.string().uuid(),

        legacy_staff_id:
          z.string().nullable(),

        full_name:
          z.string(),

        position:
          z.string().nullable(),
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

        male_count:
          z.number()
            .int()
            .nonnegative(),

        female_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    groups:
      z.array(
        tahfizGroupSchema,
      ),
  });

export type PembinaTahfizDashboardData =
  z.infer<
    typeof pembinaTahfizDashboardSchema
  >;

export type PembinaTahfizDashboardGroup =
  PembinaTahfizDashboardData["groups"][number];