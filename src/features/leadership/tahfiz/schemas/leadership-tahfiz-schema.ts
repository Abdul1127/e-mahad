import {
  z,
} from "zod";

export const leadershipTahfizRatingSchema =
  z.enum([
    "excellent",
    "good",
    "fair",
    "needs_guidance",
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

const supervisorSchema =
  z.object({
    staff_id:
      z.string().uuid(),

    full_name:
      z.string(),

    is_primary:
      z.boolean(),
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

const publishedReportSchema =
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
      leadershipTahfizRatingSchema
        .nullable(),

    tajwid_rating:
      leadershipTahfizRatingSchema
        .nullable(),

    consistency_rating:
      leadershipTahfizRatingSchema
        .nullable(),

    supervisor_notes:
      z.string().nullable(),

    next_week_target:
      z.string().nullable(),

    status:
      z.literal(
        "published",
      ),

    published_at:
      z.string().nullable(),

    updated_at:
      z.string(),
  });

const academicYearSchema =
  z.object({
    id:
      z.string().uuid(),

    name:
      z.string(),

    start_date:
      z.string(),

    end_date:
      z.string(),
  });

export const leadershipTahfizMonitoringOverviewSchema =
  z.object({
    generated_at:
      z.string(),

    academic_year:
      academicYearSchema,

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

        group_id:
          z.string()
            .uuid()
            .nullable(),
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

        published_count:
          z.number()
            .int()
            .nonnegative(),

        missing_count:
          z.number()
            .int()
            .nonnegative(),

        attention_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    groups:
      z.array(
        tahfizGroupSchema.extend({
          member_count:
            z.number()
              .int()
              .nonnegative(),

          published_count:
            z.number()
              .int()
              .nonnegative(),

          missing_count:
            z.number()
              .int()
              .nonnegative(),

          supervisors:
            z.array(
              supervisorSchema,
            ),
        }),
      ),

    items:
      z.array(
        z.object({
          student:
            studentSchema,

          tahfiz_group:
            tahfizGroupSchema,

          supervisors:
            z.array(
              supervisorSchema,
            ),

          report:
            publishedReportSchema
              .nullable(),
        }),
      ),
  });

export const leadershipTahfizStudentHistorySchema =
  z.object({
    generated_at:
      z.string(),

    academic_year:
      academicYearSchema,

    student:
      studentSchema,

    current_group:
      tahfizGroupSchema
        .extend({
          supervisors:
            z.array(
              supervisorSchema,
            ),
        })
        .nullable(),

    summary:
      z.object({
        published_report_count:
          z.number()
            .int()
            .nonnegative(),

        attention_report_count:
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
        publishedReportSchema.extend({
          tahfiz_group:
            tahfizGroupSchema,

          published_by:
            z.object({
              staff_id:
                z.string().uuid(),

              full_name:
                z.string(),
            })
              .nullable(),
        }),
      ),
  });

export type LeadershipTahfizMonitoringOverview =
  z.infer<
    typeof leadershipTahfizMonitoringOverviewSchema
  >;

export type LeadershipTahfizMonitoringItem =
  LeadershipTahfizMonitoringOverview["items"][number];

export type LeadershipTahfizStudentHistory =
  z.infer<
    typeof leadershipTahfizStudentHistorySchema
  >;

export type LeadershipTahfizRating =
  z.infer<
    typeof leadershipTahfizRatingSchema
  >;