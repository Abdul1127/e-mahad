import { z } from "zod";

const studentOptionSchema =
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

    class:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),

        grade_level:
          z.number()
            .int()
            .nullable(),
      })
        .nullable(),

    finance_summary:
      z.object({
        active_bill_count:
          z.number()
            .int()
            .nonnegative(),

        open_bill_count:
          z.number()
            .int()
            .nonnegative(),

        outstanding_amount:
          z.number()
            .nonnegative(),
      }),
  });

export const bendaharaBillStudentOptionsSchema =
  z.object({
    generated_at:
      z.string(),

    academic_year:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),
      }),

    filters:
      z.object({
        search:
          z.string().nullable(),

        limit:
          z.number()
            .int()
            .positive(),
      }),

    items:
      z.array(
        studentOptionSchema,
      ),
  });

export type BendaharaBillStudentOptionsData =
  z.infer<
    typeof bendaharaBillStudentOptionsSchema
  >;

export type BendaharaBillStudentOption =
  BendaharaBillStudentOptionsData["items"][number];