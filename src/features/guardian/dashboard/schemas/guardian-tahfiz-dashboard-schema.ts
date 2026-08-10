import { z } from "zod";

const ratingSchema =
  z.enum([
    "excellent",
    "good",
    "fair",
    "needs_guidance",
  ]);

const latestReportSchema =
  z.object({
    id:
      z.string().uuid(),

    week_start:
      z.string(),

    week_end:
      z.string(),

    memorization_achievement:
      z.string().nullable(),

    murajaah_achievement:
      z.string().nullable(),

    fluency_rating:
      ratingSchema.nullable(),

    tajwid_rating:
      ratingSchema.nullable(),

    consistency_rating:
      ratingSchema.nullable(),

    supervisor_notes:
      z.string().nullable(),

    next_week_target:
      z.string().nullable(),

    status:
      z.literal(
        "published",
      ),

    published_at:
      z.string(),

    updated_at:
      z.string(),
  });

const childSchema =
  z.object({
    relationship:
      z.object({
        id:
          z.string().uuid(),

        type:
          z.string(),

        is_primary_contact:
          z.boolean(),
      }),

    student:
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
      }),

    class:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),

        grade_level:
          z.number()
            .int(),
      })
        .nullable(),

    tahfiz_group:
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
      })
        .nullable(),

    summary:
      z.object({
        published_report_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    latest_report:
      latestReportSchema
        .nullable(),
  });

export const guardianTahfizDashboardSchema =
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

    guardian:
      z.object({
        id:
          z.string().uuid(),

        legacy_guardian_id:
          z.string().nullable(),

        full_name:
          z.string(),

        phone:
          z.string().nullable(),

        email:
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
        child_count:
          z.number()
            .int()
            .nonnegative(),

        published_report_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    children:
      z.array(
        childSchema,
      ),
  });

export type GuardianTahfizDashboardData =
  z.infer<
    typeof guardianTahfizDashboardSchema
  >;

export type GuardianTahfizDashboardChild =
  GuardianTahfizDashboardData["children"][number];