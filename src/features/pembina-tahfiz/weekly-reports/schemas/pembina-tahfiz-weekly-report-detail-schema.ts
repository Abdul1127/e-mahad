import { z } from "zod";

import {
  tahfizWeeklyReportStatusSchema,
} from "./pembina-tahfiz-weekly-report-overview-schema";

const ratingSchema =
  z.enum([
    "excellent",
    "good",
    "fair",
    "needs_guidance",
  ]);

export const pembinaTahfizWeeklyReportDetailSchema =
  z.object({
    generated_at:
      z.string(),

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

    week:
      z.object({
        start:
          z.string(),

        end:
          z.string(),
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
      }),

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

    report:
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
          tahfizWeeklyReportStatusSchema,

        published_at:
          z.string().nullable(),

        created_at:
          z.string(),

        updated_at:
          z.string(),
      })
        .nullable(),
  });

export type PembinaTahfizWeeklyReportDetailData =
  z.infer<
    typeof pembinaTahfizWeeklyReportDetailSchema
  >;