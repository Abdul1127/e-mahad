import { z } from "zod";

export const bendaharaBillStatusSchema =
  z.enum([
    "unpaid",
    "partial",
    "paid",
    "cancelled",
  ]);

export const bendaharaBillFilterStatusSchema =
  z.enum([
    "unpaid",
    "partial",
    "paid",
    "cancelled",
    "overdue",
  ]);

const studentSchema =
  z.object({
    id: z.string().uuid(),

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
  });

const classSchema =
  z.object({
    id:
      z.string().uuid(),

    name:
      z.string(),

    grade_level:
      z.number()
        .int()
        .nullable(),
  });

const billItemSchema =
  z.object({
    id:
      z.string().uuid(),

    bill_code:
      z.string(),

    title:
      z.string(),

    description:
      z.string().nullable(),

    category:
      z.string(),

    period_label:
      z.string().nullable(),

    period_start:
      z.string().nullable(),

    period_end:
      z.string().nullable(),

    amount:
      z.number().nonnegative(),

    paid_amount:
      z.number().nonnegative(),

    outstanding_amount:
      z.number().nonnegative(),

    due_date:
      z.string().nullable(),

    is_overdue:
      z.boolean(),

    status:
      bendaharaBillStatusSchema,

    cancelled_at:
      z.string().nullable(),

    cancellation_reason:
      z.string().nullable(),

    created_at:
      z.string(),

    updated_at:
      z.string(),

    student:
      studentSchema,

    class:
      classSchema.nullable(),
  });

export const bendaharaBillListSchema =
  z.object({
    generated_at:
      z.string(),

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
          z.string().nullable(),

        status:
          bendaharaBillFilterStatusSchema
            .nullable(),
      }),

    summary:
      z.object({
        total_count:
          z.number()
            .int()
            .nonnegative(),

        filtered_count:
          z.number()
            .int()
            .nonnegative(),

        unpaid_count:
          z.number()
            .int()
            .nonnegative(),

        partial_count:
          z.number()
            .int()
            .nonnegative(),

        paid_count:
          z.number()
            .int()
            .nonnegative(),

        cancelled_count:
          z.number()
            .int()
            .nonnegative(),

        overdue_count:
          z.number()
            .int()
            .nonnegative(),

        billed_amount:
          z.number()
            .nonnegative(),

        paid_amount:
          z.number()
            .nonnegative(),

        outstanding_amount:
          z.number()
            .nonnegative(),
      }),

    pagination:
      z.object({
        page:
          z.number()
            .int()
            .positive(),

        page_size:
          z.number()
            .int()
            .positive(),

        offset:
          z.number()
            .int()
            .nonnegative(),

        has_previous:
          z.boolean(),

        has_next:
          z.boolean(),
      }),

    items:
      z.array(
        billItemSchema,
      ),
  });

export type BendaharaBillListData =
  z.infer<
    typeof bendaharaBillListSchema
  >;

export type BendaharaBillFilterStatus =
  z.infer<
    typeof bendaharaBillFilterStatusSchema
  >;