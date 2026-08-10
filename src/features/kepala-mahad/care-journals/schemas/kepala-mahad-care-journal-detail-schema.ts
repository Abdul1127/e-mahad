import { z } from "zod";

import {
  kepalaMahadCareJournalReviewActionSchema,
  kepalaMahadCareJournalSessionSchema,
  kepalaMahadCareJournalStatusSchema,
} from "./kepala-mahad-care-journal-overview-schema";

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

const entrySchema =
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
      z.enum([
        "healthy",
        "unwell",
      ])
        .nullable(),

    sleep_compliance:
      z.enum([
        "on_time",
        "needs_reminder",
      ])
        .nullable(),

    psychological_condition:
      z.enum([
        "cheerful",
        "gloomy",
        "quiet",
        "homesick",
        "emotional",
      ])
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

const reviewSchema =
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

    reviewer:
      staffSchema,
  });

export const kepalaMahadCareJournalDetailSchema =
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
        entrySchema,
      ),

    reviews:
      z.array(
        reviewSchema,
      ),
  });

export type KepalaMahadCareJournalDetailData =
  z.infer<
    typeof kepalaMahadCareJournalDetailSchema
  >;

export type KepalaMahadCareJournalEntry =
  KepalaMahadCareJournalDetailData["entries"][number];