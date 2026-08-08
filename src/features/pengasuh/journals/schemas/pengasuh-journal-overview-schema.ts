import { z } from "zod";

export const careJournalSessionSchema =
  z.enum([
    "morning",
    "evening",
  ]);

export const careJournalStatusSchema =
  z.enum([
    "draft",
    "submitted",
    "revision_requested",
    "reviewed",
  ]);

const journalSummarySchema =
  z.object({
    id:
      z.string().uuid(),

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

    entry_count:
      z.number()
        .int()
        .nonnegative(),

    complete_entry_count:
      z.number()
        .int()
        .nonnegative(),
  });

const journalGroupSchema =
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

    active_student_count:
      z.number()
        .int()
        .nonnegative(),

    journals:
      z.array(
        journalSummarySchema,
      ),
  });

export const pengasuhJournalOverviewSchema =
  z.object({
    generated_at:
      z.string(),

    selected_date:
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
      }),

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
      }),

    groups:
      z.array(
        journalGroupSchema,
      ),
  });

export type CareJournalSession =
  z.infer<
    typeof careJournalSessionSchema
  >;

export type CareJournalStatus =
  z.infer<
    typeof careJournalStatusSchema
  >;

export type PengasuhJournalOverviewData =
  z.infer<
    typeof pengasuhJournalOverviewSchema
  >;

export type PengasuhJournalOverviewGroup =
  PengasuhJournalOverviewData["groups"][number];

export type PengasuhJournalOverviewItem =
  PengasuhJournalOverviewGroup["journals"][number];