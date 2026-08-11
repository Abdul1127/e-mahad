"use server";

import {
  revalidatePath,
} from "next/cache";

import {
  redirect,
} from "next/navigation";

import {
  createClient,
} from "@/lib/supabase/server";

import {
  recordBendaharaPaymentSchema,
} from "../schemas/record-bendahara-payment-schema";

import type {
  RecordBendaharaPaymentActionState,
} from "../types/record-bendahara-payment-action-state";

export async function recordBendaharaBillPaymentAction(
  _previousState:
    RecordBendaharaPaymentActionState,

  formData:
    FormData,
): Promise<RecordBendaharaPaymentActionState> {
  const rawValues = {
    billId:
      String(
        formData.get(
          "billId",
        ) ?? "",
      ),

    paymentDate:
      String(
        formData.get(
          "paymentDate",
        ) ?? "",
      ),

    amount:
      String(
        formData.get(
          "amount",
        ) ?? "",
      ),

    paymentMethod:
      String(
        formData.get(
          "paymentMethod",
        ) ?? "",
      ),

    referenceNumber:
      String(
        formData.get(
          "referenceNumber",
        ) ?? "",
      ),

    notes:
      String(
        formData.get(
          "notes",
        ) ?? "",
      ),
  };

  const validation =
    recordBendaharaPaymentSchema.safeParse(
      rawValues,
    );

  if (
    !validation.success
  ) {
    return {
      status:
        "error",

      message:
        "Periksa kembali data pembayaran yang diisi.",

      fieldErrors:
        validation.error
          .flatten()
          .fieldErrors,

      values: {
        paymentDate:
          rawValues.paymentDate,

        amount:
          rawValues.amount,

        paymentMethod:
          rawValues.paymentMethod,

        referenceNumber:
          rawValues.referenceNumber,

        notes:
          rawValues.notes,
      },
    };
  }

  const input =
    validation.data;

  const supabase =
    await createClient();

  const {
    error,
  } = await supabase.rpc(
    "record_bendahara_bill_payment",
    {
      p_bill_id:
        input.billId,

      p_payment_date:
        input.paymentDate,

      p_amount:
        input.amount,

      p_payment_method:
        input.paymentMethod,

      p_reference_number:
        input.referenceNumber,

      p_notes:
        input.notes,
    },
  );

  if (error) {
    return {
      status:
        "error",

      message:
        error.message,

      values: {
        paymentDate:
          rawValues.paymentDate,

        amount:
          rawValues.amount,

        paymentMethod:
          rawValues.paymentMethod,

        referenceNumber:
          rawValues.referenceNumber,

        notes:
          rawValues.notes,
      },
    };
  }

  revalidatePath(
    "/bendahara/dashboard",
  );

  revalidatePath(
    "/bendahara/tagihan",
  );

  revalidatePath(
    `/bendahara/tagihan/${input.billId}`,
  );

  redirect(
    `/bendahara/tagihan/${input.billId}`,
  );
}