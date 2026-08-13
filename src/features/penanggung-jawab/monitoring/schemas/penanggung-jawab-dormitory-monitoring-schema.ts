import {
  z,
} from "zod";

const genderSchema =
  z.enum([
    "male",
    "female",
  ]);

const careJournalStatusSchema =
  z.enum([
    "draft",
    "submitted",
    "revision_requested",
    "reviewed",
  ]);

const careRecentItemSchema =
  z.object({
    id:
      z.string().uuid(),

    journal_date:
      z.string(),

    session:
      z.string(),

    status:
      careJournalStatusSchema,

    submission_version:
      z.number()
        .int()
        .nonnegative(),

    submitted_at:
      z.string().nullable(),

    last_reviewed_at:
      z.string().nullable(),

    care_group:
      z.object({
        id:
          z.string().uuid(),

        code:
          z.string(),

        name:
          z.string(),

        gender:
          genderSchema,
      }),

    entry_count:
      z.number()
        .int()
        .nonnegative(),

    attention_student_count:
      z.number()
        .int()
        .nonnegative(),
  });

const tahfizGroupSummarySchema =
  z.object({
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

    student_count:
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
  });

const latestMahadHeadJournalSchema =
  z.object({
    id:
      z.string().uuid(),

    journal_date:
      z.string(),

    status:
      z.literal(
        "submitted",
      ),

    submitted_at:
      z.string().nullable(),

    has_evidence:
      z.boolean(),

    checked_count:
      z.number()
        .int()
        .nonnegative(),

    total_checklist_count:
      z.number()
        .int()
        .nonnegative(),

    staff:
      z.object({
        id:
          z.string().uuid(),

        full_name:
          z.string(),

        position:
          z.string().nullable(),
      }),
  });

export const penanggungJawabDormitoryMonitoringSchema =
  z.object({
    generated_at:
      z.string(),

    access_mode:
      z.literal(
        "penanggung_jawab_read_only_monitoring",
      ),

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

    care:
      z.object({
        summary:
          z.object({
            group_count:
              z.number()
                .int()
                .nonnegative(),

            journal_count:
              z.number()
                .int()
                .nonnegative(),

            draft_count:
              z.number()
                .int()
                .nonnegative(),

            submitted_count:
              z.number()
                .int()
                .nonnegative(),

            revision_requested_count:
              z.number()
                .int()
                .nonnegative(),

            reviewed_count:
              z.number()
                .int()
                .nonnegative(),

            pending_review_count:
              z.number()
                .int()
                .nonnegative(),

            follow_up_count:
              z.number()
                .int()
                .nonnegative(),

            attention_student_count:
              z.number()
                .int()
                .nonnegative(),

            latest_journal_date:
              z.string().nullable(),
          }),

        recent_items:
          z.array(
            careRecentItemSchema,
          ),
      }),

    mahad_head_journal:
      z.object({
        summary:
          z.object({
            submitted_count:
              z.number()
                .int()
                .nonnegative(),

            latest_journal_date:
              z.string().nullable(),

            latest_submitted_at:
              z.string().nullable(),

            latest_checked_count:
              z.number()
                .int()
                .nonnegative(),

            total_checklist_count:
              z.number()
                .int()
                .nonnegative(),

            latest_completion_percentage:
              z.number()
                .int()
                .min(0)
                .max(100),
          }),

        latest_item:
          latestMahadHeadJournalSchema.nullable(),
      }),

    tahfiz:
      z.object({
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

            completion_percentage:
              z.number()
                .int()
                .min(0)
                .max(100),
          }),

        groups:
          z.array(
            tahfizGroupSummarySchema,
          ),
      }),
  });

export type PenanggungJawabDormitoryMonitoringData =
  z.infer<
    typeof penanggungJawabDormitoryMonitoringSchema
  >;

export type PenanggungJawabCareRecentItem =
  z.infer<
    typeof careRecentItemSchema
  >;

export type PenanggungJawabTahfizGroupSummary =
  z.infer<
    typeof tahfizGroupSummarySchema
  >;