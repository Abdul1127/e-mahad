import { z } from "zod";

import {
  tahfizWeeklyReportStatusSchema,
} from "./pembina-tahfiz-weekly-report-overview-schema";

const historyItemSchema =
  z.object({
    report:
      z.object({
        id:
          z.string().uuid(),

        week_start:
          z.string(),

        week_end:
          z.string(),

        status:
          tahfizWeeklyReportStatusSchema,

        published_at:
          z.string().nullable(),

        created_at:
          z.string(),

        updated_at:
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
          z.number()
            .int(),
      })
        .nullable(),
  });

export const pembinaTahfizWeeklyReportHistorySchema =
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

    filters:
      z.object({
        status:
          tahfizWeeklyReportStatusSchema
            .nullable(),

        search:
          z.string()
            .nullable(),

        limit:
          z.number()
            .int()
            .positive(),

        offset:
          z.number()
            .int()
            .nonnegative(),
      }),

    summary:
      z.object({
        total_count:
          z.number()
            .int()
            .nonnegative(),

        filtered_count:
          z.number()
            .int()
            .nonnegative(),

        draft_count:
          z.number()
            .int()
            .nonnegative(),

        published_count:
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
        historyItemSchema,
      ),
  });

export type PembinaTahfizWeeklyReportHistoryData =
  z.infer<
    typeof pembinaTahfizWeeklyReportHistorySchema
  >;

export type PembinaTahfizWeeklyReportHistoryItem =
  PembinaTahfizWeeklyReportHistoryData["items"][number];