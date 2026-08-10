import { z } from "zod";

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
      z.number()
        .int(),
  });

const studentItemSchema =
  z.object({
    id:
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

    tahfiz_group:
      tahfizGroupSchema,

    class:
      classSchema
        .nullable(),
  });

export const pembinaTahfizStudentListSchema =
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
        search:
          z.string()
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
      }),

    items:
      z.array(
        studentItemSchema,
      ),
  });

export type PembinaTahfizStudentListData =
  z.infer<
    typeof pembinaTahfizStudentListSchema
  >;

export type PembinaTahfizStudentListItem =
  PembinaTahfizStudentListData["items"][number];