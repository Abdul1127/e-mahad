import { z } from "zod";

import {
  careJournalSessionSchema,
  careJournalStatusSchema,
} from "./pengasuh-journal-overview-schema";

export const healthConditionSchema =
  z.enum([
    "healthy",
    "unwell",
  ]);

export const sleepComplianceSchema =
  z.enum([
    "on_time",
    "needs_reminder",
  ]);

export const psychologicalConditionSchema =
  z.enum([
    "cheerful",
    "gloomy",
    "quiet",
    "homesick",
    "emotional",
  ]);

export const careJournalReviewActionSchema =
  z.enum([
    "reviewed",
    "revision_requested",
  ]);

const journalEntrySchema =
  z.object({
    id:
      z.string().uuid(),

    student_id:
      z.string().uuid(),

    legacy_student_id:
      z.string()
        .nullable(),

    nis:
      z.string()
        .nullable(),

    full_name:
      z.string(),

    gender:
      z.enum([
        "male",
        "female",
      ]),

    health_condition:
      healthConditionSchema
        .nullable(),

    sleep_compliance:
      sleepComplianceSchema
        .nullable(),

    psychological_condition:
      psychologicalConditionSchema
        .nullable(),

    parent_visit:
      z.boolean()
        .nullable(),

    case_notes:
      z.string()
        .nullable(),

    handling_notes:
      z.string()
        .nullable(),

    updated_at:
      z.string(),

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

const journalReviewSchema =
  z.object({
    id:
      z.string().uuid(),

    submission_version:
      z.number()
        .int()
        .positive(),

    action:
      careJournalReviewActionSchema,

    note:
      z.string()
        .nullable(),

    created_at:
      z.string(),

    reviewer:
      z.object({
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
      }),
  });

export const pengasuhJournalDetailSchema =
  z.object({
    generated_at:
      z.string(),

    journal:
      z.object({
        id:
          z.string().uuid(),

        journal_date:
          z.string(),

        session:
          careJournalSessionSchema,

        status:
          careJournalStatusSchema,

        submission_version:
          z.number()
            .int()
            .nonnegative(),

        submitted_at:
          z.string()
            .nullable(),

        last_reviewed_at:
          z.string()
            .nullable(),

        created_at:
          z.string(),

        updated_at:
          z.string(),

        care_group:
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
              ]),
          }),
      }),

    summary:
      z.object({
        entry_count:
          z.number()
            .int()
            .nonnegative(),

        complete_entry_count:
          z.number()
            .int()
            .nonnegative(),

        review_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    entries:
      z.array(
        journalEntrySchema,
      ),

    reviews:
      z.array(
        journalReviewSchema,
      ),
  });

export type HealthCondition =
  z.infer<
    typeof healthConditionSchema
  >;

export type SleepCompliance =
  z.infer<
    typeof sleepComplianceSchema
  >;

export type PsychologicalCondition =
  z.infer<
    typeof psychologicalConditionSchema
  >;

export type PengasuhJournalDetailData =
  z.infer<
    typeof pengasuhJournalDetailSchema
  >;

export type PengasuhJournalEntry =
  PengasuhJournalDetailData["entries"][number];

export type PengasuhJournalReview =
  PengasuhJournalDetailData["reviews"][number];