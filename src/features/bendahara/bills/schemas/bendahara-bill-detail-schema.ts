import { z } from "zod";

const studentSchema =
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

const paymentSchema =
  z.object({
    allocation_id:
      z.string().uuid(),

    allocation_amount:
      z.number()
        .positive(),

    payment:
      z.object({
        id:
          z.string().uuid(),

        payment_code:
          z.string(),

        payment_date:
          z.string(),

        amount:
          z.number()
            .positive(),

        payment_method:
          z.string(),

        reference_number:
          z.string().nullable(),

        notes:
          z.string().nullable(),

        proof_path:
          z.string().nullable(),

        status:
          z.enum([
            "recorded",
            "cancelled",
          ]),

        cancelled_at:
          z.string().nullable(),

        cancellation_reason:
          z.string().nullable(),

        created_at:
          z.string(),

        updated_at:
          z.string(),
      }),
  });

export const bendaharaBillDetailSchema =
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

    summary:
      z.object({
        payment_count:
          z.number()
            .int()
            .nonnegative(),

        recorded_payment_count:
          z.number()
            .int()
            .nonnegative(),

        cancelled_payment_count:
          z.number()
            .int()
            .nonnegative(),

        bill_amount:
          z.number()
            .nonnegative(),

        paid_amount:
          z.number()
            .nonnegative(),

        outstanding_amount:
          z.number()
            .nonnegative(),
      }),

    bill:
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
          z.number()
            .positive(),

        paid_amount:
          z.number()
            .nonnegative(),

        outstanding_amount:
          z.number()
            .nonnegative(),

        due_date:
          z.string().nullable(),

        is_overdue:
          z.boolean(),

        status:
          z.enum([
            "unpaid",
            "partial",
            "paid",
            "cancelled",
          ]),

        cancelled_at:
          z.string().nullable(),

        cancellation_reason:
          z.string().nullable(),

        created_at:
          z.string(),

        updated_at:
          z.string(),

        can_record_payment:
          z.boolean(),

        can_cancel:
          z.boolean(),

        student:
          studentSchema,

        class:
          classSchema.nullable(),
      }),

    payments:
      z.array(
        paymentSchema,
      ),
  });

export type BendaharaBillDetailData =
  z.infer<
    typeof bendaharaBillDetailSchema
  >;