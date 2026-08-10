import { z } from "zod";

export const kepalaMahadCareJournalSessionSchema =
  z.enum([
    "morning",
    "evening",
  ]);

export const kepalaMahadCareJournalStatusSchema =
  z.enum([
    "draft",
    "submitted",
    "revision_requested",
    "reviewed",
  ]);

export const kepalaMahadCareJournalReviewActionSchema =
  z.enum([
    "reviewed",
    "revision_requested",
  ]);

const staffSchema =
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
  });

const latestReviewSchema =
  z.object({
    id:
      z.string().uuid(),

    submission_version:
      z.number()
        .int()
        .positive(),

    action:
      kepalaMahadCareJournalReviewActionSchema,

    note:
      z.string()
        .nullable(),

    created_at:
      z.string(),

    reviewer_name:
      z.string(),
  });

const journalItemSchema =
  z.object({
    id:
      z.string().uuid(),

    journal_date:
      z.string(),

    session:
      kepalaMahadCareJournalSessionSchema,

    status:
      kepalaMahadCareJournalStatusSchema,

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

    created_by:
      staffSchema,

    submitted_by:
      staffSchema
        .nullable(),

    entry_count:
      z.number()
        .int()
        .nonnegative(),

    complete_entry_count:
      z.number()
        .int()
        .nonnegative(),

    latest_review:
      latestReviewSchema
        .nullable(),
  });

export const kepalaMahadCareJournalOverviewSchema =
  z.object({
    generated_at:
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

    filters:
      z.object({
        status:
          kepalaMahadCareJournalStatusSchema
            .nullable(),

        date:
          z.string()
            .nullable(),
      }),

    summary:
      z.object({
        total_count:
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

    items:
      z.array(
        journalItemSchema,
      ),
  });

export type KepalaMahadCareJournalStatus =
  z.infer<
    typeof kepalaMahadCareJournalStatusSchema
  >;

export type KepalaMahadCareJournalOverviewData =
  z.infer<
    typeof kepalaMahadCareJournalOverviewSchema
  >;

export type KepalaMahadCareJournalOverviewItem =
  KepalaMahadCareJournalOverviewData["items"][number];