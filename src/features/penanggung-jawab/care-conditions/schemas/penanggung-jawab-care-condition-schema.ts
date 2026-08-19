import {
  z,
} from "zod";


export const penanggungJawabCareConditionFilterSchema =
  z.enum([
    "all",
    "exception",
    "attention",
    "unwell",
    "needs_reminder",
    "psychological",
    "case_notes",
    "parent_visit",
    "normal",
  ]);


const itemSchema =
  z.object({
    id:
      z.string().uuid(),

    student_id:
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
      z.boolean().nullable(),

    case_notes:
      z.string().nullable(),

    handling_notes:
      z.string().nullable(),

    updated_at:
      z.string(),

    is_normal:
      z.boolean(),

    needs_attention:
      z.boolean(),

    has_notes:
      z.boolean(),

    journal:
      z.object({
        id:
          z.string().uuid(),

        journal_date:
          z.string(),

        session:
          z.enum([
            "morning",
            "evening",
          ]),

        status:
          z.enum([
            "submitted",
            "revision_requested",
            "reviewed",
          ]),

        submission_version:
          z.number()
            .int()
            .nonnegative(),
      }),

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

    class:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),

        grade_level:
          z.number().int(),
      })
        .nullable(),
  });


export const penanggungJawabCareConditionSchema =
  z.object({
    generated_at:
      z.string(),

    access_mode:
      z.literal(
        "penanggung_jawab_read_only_care_conditions",
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

    filters:
      z.object({
        condition:
          penanggungJawabCareConditionFilterSchema,

        search:
          z.string().nullable(),

        requested_date:
          z.string().nullable(),

        effective_date:
          z.string(),

        page:
          z.number()
            .int()
            .positive(),

        page_size:
          z.number()
            .int()
            .positive(),
      }),

    summary:
      z.object({
        total_count:
          z.number()
            .int()
            .nonnegative(),

        exception_count:
          z.number()
            .int()
            .nonnegative(),

        attention_count:
          z.number()
            .int()
            .nonnegative(),

        unwell_count:
          z.number()
            .int()
            .nonnegative(),

        sleep_attention_count:
          z.number()
            .int()
            .nonnegative(),

        psychological_count:
          z.number()
            .int()
            .nonnegative(),

        note_count:
          z.number()
            .int()
            .nonnegative(),

        parent_visit_count:
          z.number()
            .int()
            .nonnegative(),

        normal_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    pagination:
      z.object({
        filtered_count:
          z.number()
            .int()
            .nonnegative(),

        page:
          z.number()
            .int()
            .positive(),

        page_size:
          z.number()
            .int()
            .positive(),

        total_pages:
          z.number()
            .int()
            .positive(),
      }),

    items:
      z.array(
        itemSchema,
      ),
  });


export type PenanggungJawabCareConditionFilter =
  z.infer<
    typeof penanggungJawabCareConditionFilterSchema
  >;


export type PenanggungJawabCareConditionData =
  z.infer<
    typeof penanggungJawabCareConditionSchema
  >;


export type PenanggungJawabCareConditionItem =
  z.infer<
    typeof itemSchema
  >;