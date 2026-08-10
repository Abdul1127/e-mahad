import { z } from "zod";

const ratingSchema =
  z.enum([
    "excellent",
    "good",
    "fair",
    "needs_guidance",
  ]);

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
  });

const reportSchema =
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

    tahfiz_group:
      tahfizGroupSchema,
  });

export const guardianTahfizReportHistorySchema =
  z.object({
    generated_at:
      z.string(),

    guardian:
      z.object({
        id:
          z.string().uuid(),

        full_name:
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
      }),

    relationship:
      z.object({
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

    summary:
      z.object({
        published_report_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    pagination:
      z.object({
        limit:
          z.number()
            .int()
            .positive(),

        offset:
          z.number()
            .int()
            .nonnegative(),

        has_previous:
          z.boolean(),

        has_next:
          z.boolean(),
      }),

    items:
      z.array(
        reportSchema,
      ),
  });

export type GuardianTahfizReportHistoryData =
  z.infer<
    typeof guardianTahfizReportHistorySchema
  >;