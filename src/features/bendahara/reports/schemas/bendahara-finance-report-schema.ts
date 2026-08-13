import {
  z,
} from "zod";

const studentSchema =
  z.object({
    id:
      z.string()
        .uuid(),

    nis:
      z.string()
        .nullable(),

    legacy_student_id:
      z.string()
        .nullable(),

    full_name:
      z.string(),

    gender:
      z.enum([
        "male",
        "female",
      ]),
  });

const billStatusSchema =
  z.enum([
    "unpaid",
    "partial",
    "paid",
    "cancelled",
  ]);

const paymentStatusSchema =
  z.enum([
    "recorded",
    "cancelled",
  ]);

export const bendaharaFinanceReportSchema =
  z.object({
    generated_at:
      z.string(),

    access_mode:
      z.literal(
        "bendahara_read_only_report",
      ),

    staff:
      z.object({
        id:
          z.string()
            .uuid(),

        full_name:
          z.string(),
      }),

    academic_year:
      z.object({
        id:
          z.string()
            .uuid(),

        name:
          z.string(),

        start_date:
          z.string(),

        end_date:
          z.string(),
      }),

    period:
      z.object({
        start_date:
          z.string(),

        end_date:
          z.string(),
      }),

    bill_summary:
      z.object({
        total_count:
          z.number()
            .int()
            .nonnegative(),

        active_count:
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

    payment_summary:
      z.object({
        total_count:
          z.number()
            .int()
            .nonnegative(),

        recorded_count:
          z.number()
            .int()
            .nonnegative(),

        cancelled_count:
          z.number()
            .int()
            .nonnegative(),

        recorded_amount:
          z.number()
            .nonnegative(),

        allocated_amount:
          z.number()
            .nonnegative(),

        unallocated_amount:
          z.number()
            .nonnegative(),
      }),

    category_summary:
      z.array(
        z.object({
          category:
            z.string(),

          bill_count:
            z.number()
              .int()
              .nonnegative(),

          billed_amount:
            z.number()
              .nonnegative(),
        }),
      ),

    payment_method_summary:
      z.array(
        z.object({
          payment_method:
            z.string(),

          payment_count:
            z.number()
              .int()
              .nonnegative(),

          amount:
            z.number()
              .nonnegative(),
        }),
      ),

    bills:
      z.array(
        z.object({
          id:
            z.string()
              .uuid(),

          bill_code:
            z.string(),

          title:
            z.string(),

          category:
            z.string(),

          period_label:
            z.string()
              .nullable(),

          report_date:
            z.string(),

          due_date:
            z.string()
              .nullable(),

          amount:
            z.number()
              .nonnegative(),

          paid_amount:
            z.number()
              .nonnegative(),

          outstanding_amount:
            z.number()
              .nonnegative(),

          status:
            billStatusSchema,

          student:
            studentSchema,
        }),
      ),

    payments:
      z.array(
        z.object({
          id:
            z.string()
              .uuid(),

          payment_code:
            z.string(),

          payment_date:
            z.string(),

          amount:
            z.number()
              .nonnegative(),

          payment_method:
            z.string(),

          reference_number:
            z.string()
              .nullable(),

          status:
            paymentStatusSchema,

          historical_allocated_amount:
            z.number()
              .nonnegative(),

          student:
            studentSchema,
        }),
      ),
  });

export type BendaharaFinanceReportData =
  z.infer<
    typeof bendaharaFinanceReportSchema
  >;