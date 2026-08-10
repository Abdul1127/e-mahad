import { z } from "zod";

const genderSchema =
  z.enum([
    "male",
    "female",
  ]);

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
      genderSchema,
  });

const overdueBillSchema =
  z.object({
    id:
      z.string().uuid(),

    bill_code:
      z.string(),

    title:
      z.string(),

    category:
      z.string(),

    period_label:
      z.string().nullable(),

    amount:
      z.number(),

    paid_amount:
      z.number(),

    outstanding_amount:
      z.number(),

    due_date:
      z.string(),

    status:
      z.enum([
        "unpaid",
        "partial",
      ]),

    student:
      studentSchema,
  });

const recentPaymentSchema =
  z.object({
    id:
      z.string().uuid(),

    payment_code:
      z.string(),

    payment_date:
      z.string(),

    amount:
      z.number(),

    allocated_amount:
      z.number(),

    unallocated_amount:
      z.number(),

    payment_method:
      z.string(),

    reference_number:
      z.string().nullable(),

    proof_path:
      z.string().nullable(),

    status:
      z.enum([
        "recorded",
        "cancelled",
      ]),

    created_at:
      z.string(),

    student:
      studentSchema,
  });

export const bendaharaDashboardSchema =
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
        active_bill_count:
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

        payment_count_this_month:
          z.number()
            .int()
            .nonnegative(),

        payment_amount_this_month:
          z.number()
            .nonnegative(),
      }),

    overdue_bills:
      z.array(
        overdueBillSchema,
      ),

    recent_payments:
      z.array(
        recentPaymentSchema,
      ),
  });

export type BendaharaDashboardData =
  z.infer<
    typeof bendaharaDashboardSchema
  >;