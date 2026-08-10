import { z } from "zod";

export const tahfizWeeklyReportStatusSchema =
  z.enum([
    "draft",
    "published",
  ]);

const studentSchema =
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
  });

const classSchema =
  z.object({
    id:
      z.string().uuid(),

    name:
      z.string(),

    grade_level:
      z.number().int(),
  });

const reportSchema =
  z.object({
    id:
      z.string().uuid(),

    status:
      tahfizWeeklyReportStatusSchema,

    week_start:
      z.string(),

    week_end:
      z.string(),

    published_at:
      z.string().nullable(),

    updated_at:
      z.string(),
  });

const itemSchema =
  z.object({
    student:
      studentSchema,

    tahfiz_group:
      tahfizGroupSchema,

    class:
      classSchema.nullable(),

    report:
      reportSchema.nullable(),
  });

export const pembinaTahfizWeeklyReportOverviewSchema =
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

    week:
      z.object({
        start:
          z.string(),

        end:
          z.string(),
      }),

    filters:
      z.object({
        search:
          z.string().nullable(),
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

        filtered_count:
          z.number()
            .int()
            .nonnegative(),

        not_created_count:
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

    items:
      z.array(
        itemSchema,
      ),
  });

export type PembinaTahfizWeeklyReportOverviewData =
  z.infer<
    typeof pembinaTahfizWeeklyReportOverviewSchema
  >;

export type PembinaTahfizWeeklyReportOverviewItem =
  PembinaTahfizWeeklyReportOverviewData["items"][number];