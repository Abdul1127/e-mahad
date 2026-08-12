import {
  z,
} from "zod";

export const mahadHeadJournalStatusSchema =
  z.enum([
    "draft",
    "submitted",
  ]);

export const mahadHeadJournalChecklistItemSchema =
  z.object({
    id:
      z.string().uuid(),

    item_key:
      z.string(),

    pillar_code:
      z.string(),

    pillar_name:
      z.string(),

    equivalent_jtm:
      z.number().int().positive(),

    sort_order:
      z.number().int().positive(),

    label:
      z.string(),

    is_checked:
      z.boolean(),
  });

const journalBaseSchema =
  z.object({
    id:
      z.string().uuid(),

    journal_date:
      z.string(),

    status:
      mahadHeadJournalStatusSchema,

    performance_notes:
      z.string().nullable(),

    obstacles_follow_up:
      z.string().nullable(),

    evidence_path:
      z.string().nullable(),

    has_evidence:
      z.boolean(),

    submitted_at:
      z.string().nullable(),
  });

export const kepalaMahadJournalDetailSchema =
  z.object({
    journal:
      journalBaseSchema.extend({
        created_at:
          z.string(),

        updated_at:
          z.string(),
      }),

    checklist:
      z.array(
        mahadHeadJournalChecklistItemSchema,
      ),
  });

const kepalaMahadJournalListItemSchema =
  z.object({
    id:
      z.string().uuid(),

    journal_date:
      z.string(),

    status:
      mahadHeadJournalStatusSchema,

    performance_notes:
      z.string().nullable(),

    obstacles_follow_up:
      z.string().nullable(),

    has_evidence:
      z.boolean(),

    evidence_path:
      z.string().nullable(),

    submitted_at:
      z.string().nullable(),

    updated_at:
      z.string(),

    checked_count:
      z.number().int().nonnegative(),

    total_checklist_count:
      z.number().int().nonnegative(),
  });

export const kepalaMahadJournalOverviewSchema =
  z.object({
    academic_year:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),
      }),

    staff:
      z.object({
        id:
          z.string().uuid(),

        full_name:
          z.string(),
      }),

    filters:
      z.object({
        date_from:
          z.string(),

        date_to:
          z.string(),
      }),

    summary:
      z.object({
        total_count:
          z.number().int().nonnegative(),

        draft_count:
          z.number().int().nonnegative(),

        submitted_count:
          z.number().int().nonnegative(),
      }),

    items:
      z.array(
        kepalaMahadJournalListItemSchema,
      ),
  });

const monitoringStaffSchema =
  z.object({
    id:
      z.string().uuid(),

    full_name:
      z.string(),

    position:
      z.string().nullable(),
  });

export const penanggungJawabMahadHeadJournalOverviewSchema =
  z.object({
    academic_year:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),
      }),

    filters:
      z.object({
        date_from:
          z.string(),

        date_to:
          z.string(),
      }),

    summary:
      z.object({
        submitted_count:
          z.number().int().nonnegative(),
      }),

    items:
      z.array(
        z.object({
          id:
            z.string().uuid(),

          journal_date:
            z.string(),

          status:
            z.literal(
              "submitted",
            ),

          performance_notes:
            z.string().nullable(),

          obstacles_follow_up:
            z.string().nullable(),

          has_evidence:
            z.boolean(),

          evidence_path:
            z.string().nullable(),

          submitted_at:
            z.string().nullable(),

          staff:
            monitoringStaffSchema,

          checked_count:
            z.number().int().nonnegative(),
        }),
      ),
  });

export const penanggungJawabMahadHeadJournalDetailSchema =
  z.object({
    journal:
      journalBaseSchema.extend({
        staff:
          monitoringStaffSchema,
      }),

    checklist:
      z.array(
        mahadHeadJournalChecklistItemSchema,
      ),
  });

export const createKepalaMahadJournalResponseSchema =
  z.object({
    success:
      z.boolean(),

    created:
      z.boolean(),

    journal_id:
      z.string().uuid(),
  });

export type KepalaMahadJournalDetail =
  z.infer<
    typeof kepalaMahadJournalDetailSchema
  >;

export type KepalaMahadJournalOverview =
  z.infer<
    typeof kepalaMahadJournalOverviewSchema
  >;

export type PenanggungJawabMahadHeadJournalOverview =
  z.infer<
    typeof penanggungJawabMahadHeadJournalOverviewSchema
  >;

export type PenanggungJawabMahadHeadJournalDetail =
  z.infer<
    typeof penanggungJawabMahadHeadJournalDetailSchema
  >;

export type MahadHeadJournalChecklistItem =
  z.infer<
    typeof mahadHeadJournalChecklistItemSchema
  >;