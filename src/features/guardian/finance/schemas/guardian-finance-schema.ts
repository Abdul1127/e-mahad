import { z } from "zod";

export const guardianFinanceChildSchema =
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

const academicYearSchema =
  z.object({
    id:
      z.string().uuid(),

    name:
      z.string(),

    start_date:
      z.string(),

    end_date:
      z.string(),
  });

const billStudentSchema =
  guardianFinanceChildSchema;

const guardianBillItemSchema =
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
        .nonnegative(),

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
      ]),

    student:
      billStudentSchema,
  });

export const guardianBillListSchema =
  z.object({
    generated_at:
      z.string(),

    academic_year:
      academicYearSchema,

    guardian:
      z.object({
        id:
          z.string().uuid(),
      }),

    children:
      z.array(
        guardianFinanceChildSchema,
      ),

    selected_student_id:
      z.string()
        .uuid()
        .nullable(),

    summary:
      z.object({
        total_count:
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

    items:
      z.array(
        guardianBillItemSchema,
      ),
  });

const allocationSchema =
  z.object({
    allocation_id:
      z.string().uuid(),

    amount:
      z.number()
        .nonnegative(),

    bill:
      z.object({
        id:
          z.string().uuid(),

        bill_code:
          z.string(),

        title:
          z.string(),

        period_label:
          z.string().nullable(),
      }),
  });

const guardianPaymentItemSchema =
  z.object({
    id:
      z.string().uuid(),

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
      z.string().nullable(),

    notes:
      z.string().nullable(),

    status:
      z.enum([
        "recorded",
        "cancelled",
      ]),

    proof_path:
      z.string().nullable(),

    has_proof:
      z.boolean(),

    student:
      guardianFinanceChildSchema,

    allocations:
      z.array(
        allocationSchema,
      ),
  });

export const guardianPaymentHistorySchema =
  z.object({
    generated_at:
      z.string(),

    academic_year:
      academicYearSchema,

    guardian:
      z.object({
        id:
          z.string().uuid(),
      }),

    children:
      z.array(
        guardianFinanceChildSchema,
      ),

    selected_student_id:
      z.string()
        .uuid()
        .nullable(),

    summary:
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
        guardianPaymentItemSchema,
      ),
  });

export type GuardianBillListData =
  z.infer<
    typeof guardianBillListSchema
  >;

export type GuardianPaymentHistoryData =
  z.infer<
    typeof guardianPaymentHistorySchema
  >;