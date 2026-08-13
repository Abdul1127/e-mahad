import {
  z,
} from "zod";

const genderSchema =
  z.enum([
    "male",
    "female",
  ]);

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

const studentSchema =
  z.object({
    id:
      z.string()
        .uuid(),

    legacy_student_id:
      z.string()
        .nullable(),

    nis:
      z.string()
        .nullable(),

    full_name:
      z.string(),

    gender:
      genderSchema,
  });

const overdueBillSchema =
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

    amount:
      z.number()
        .nonnegative(),

    paid_amount:
      z.number()
        .nonnegative(),

    outstanding_amount:
      z.number()
        .nonnegative(),

    due_date:
      z.string(),

    status:
      billStatusSchema,

    student:
      studentSchema,
  });

const recentPaymentSchema =
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

    allocated_amount:
      z.number()
        .nonnegative(),

    payment_method:
      z.string(),

    reference_number:
      z.string()
        .nullable(),

    status:
      paymentStatusSchema,

    cancelled_at:
      z.string()
        .nullable(),

    cancellation_reason:
      z.string()
        .nullable(),

    student:
      studentSchema,
  });

export const kepalaMahadFinanceSummarySchema =
  z.object({
    generated_at:
      z.string(),

    access_mode:
      z.literal(
        "read_only",
      ),

    viewer:
      z.object({
        profile_id:
          z.string()
            .uuid(),

        login_id:
          z.string()
            .nullable(),

        staff_id:
          z.string()
            .uuid(),

        legacy_staff_id:
          z.string()
            .nullable(),

        full_name:
          z.string(),

        role:
          z.literal(
            "kepala_mahad",
          ),
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

export type KepalaMahadFinanceSummaryData =
  z.infer<
    typeof kepalaMahadFinanceSummarySchema
  >;

export type KepalaMahadFinanceOverdueBill =
  KepalaMahadFinanceSummaryData[
    "overdue_bills"
  ][number];

export type KepalaMahadFinanceRecentPayment =
  KepalaMahadFinanceSummaryData[
    "recent_payments"
  ][number];