import { z } from "zod";

export const bendaharaPaymentStatusSchema =
  z.enum([
    "recorded",
    "cancelled",
  ]);

export const bendaharaPaymentMethodSchema =
  z.enum([
    "cash",
    "transfer",
    "bank_transfer",
    "other",
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
      z.enum([
        "male",
        "female",
      ]),
  });

const allocationSchema =
  z.object({
    allocation_id:
      z.string().uuid(),

    amount:
      z.number()
        .positive(),

    bill:
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
          z.number()
            .positive(),

        status:
          z.enum([
            "unpaid",
            "partial",
            "paid",
            "cancelled",
          ]),
      }),
  });

const paymentItemSchema =
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
      bendaharaPaymentMethodSchema,

    reference_number:
      z.string().nullable(),

    notes:
      z.string().nullable(),

    proof_path:
      z.string().nullable(),

    has_proof:
      z.boolean(),

    status:
      bendaharaPaymentStatusSchema,

    historical_allocated_amount:
      z.number()
        .nonnegative(),

    allocated_amount:
      z.number()
        .nonnegative(),

    unallocated_amount:
      z.number()
        .nonnegative(),

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

    allocations:
      z.array(
        allocationSchema,
      ),
  });

export const bendaharaPaymentHistorySchema =
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
          bendaharaPaymentStatusSchema
            .nullable(),

        method:
          bendaharaPaymentMethodSchema
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

        active_allocated_amount:
          z.number()
            .nonnegative(),

        unallocated_amount:
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
        paymentItemSchema,
      ),
  });

export type BendaharaPaymentHistoryData =
  z.infer<
    typeof bendaharaPaymentHistorySchema
  >;

export type BendaharaPaymentStatus =
  z.infer<
    typeof bendaharaPaymentStatusSchema
  >;

export type BendaharaPaymentMethod =
  z.infer<
    typeof bendaharaPaymentMethodSchema
  >;