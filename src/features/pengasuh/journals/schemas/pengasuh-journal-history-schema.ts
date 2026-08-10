import { z } from "zod";

import {
  careJournalSessionSchema,
  careJournalStatusSchema,
} from "./pengasuh-journal-overview-schema";

const staffSchema =
  z.object({
    staff_id:
      z.string().uuid(),

    legacy_staff_id:
      z.string().nullable(),

    full_name:
      z.string(),

    position:
      z.string().nullable(),
  });

const reviewSchema =
  z.object({
    id:
      z.string().uuid(),

    submission_version:
      z.number()
        .int()
        .positive(),

    action:
      z.enum([
        "reviewed",
        "revision_requested",
      ]),

    note:
      z.string().nullable(),

    created_at:
      z.string(),

    reviewer:
      staffSchema,
  });

const historyItemSchema =
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
      z.string().nullable(),

    last_reviewed_at:
      z.string().nullable(),

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
      staffSchema.nullable(),

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

    latest_review:
      reviewSchema.nullable(),
  });

export const pengasuhJournalHistorySchema =
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

    filters:
      z.object({
        status:
          careJournalStatusSchema.nullable(),

        session:
          careJournalSessionSchema.nullable(),

        date:
          z.string().nullable(),
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

        filtered_count:
          z.number()
            .int()
            .nonnegative(),

        returned_count:
          z.number()
            .int()
            .nonnegative(),

        has_more:
          z.boolean(),
      }),

    items:
      z.array(
        historyItemSchema,
      ),
  });

export type PengasuhJournalHistoryData =
  z.infer<
    typeof pengasuhJournalHistorySchema
  >;

export type PengasuhJournalHistoryItem =
  PengasuhJournalHistoryData["items"][number];