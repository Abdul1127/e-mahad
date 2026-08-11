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
  cancelBendaharaPaymentSchema,
} from "../schemas/cancel-bendahara-payment-schema";

import type {
  CancelBendaharaPaymentActionState,
} from "../types/cancel-bendahara-payment-action-state";

export async function cancelBendaharaPaymentAction(
  _previousState:
    CancelBendaharaPaymentActionState,

  formData:
    FormData,
): Promise<CancelBendaharaPaymentActionState> {
  const rawValues = {
    billId:
      String(
        formData.get(
          "billId",
        ) ?? "",
      ),

    paymentId:
      String(
        formData.get(
          "paymentId",
        ) ?? "",
      ),

    cancellationReason:
      String(
        formData.get(
          "cancellationReason",
        ) ?? "",
      ),
  };

  const validation =
    cancelBendaharaPaymentSchema.safeParse(
      rawValues,
    );

  if (
    !validation.success
  ) {
    return {
      status:
        "error",

      message:
        "Periksa kembali data pembatalan pembayaran.",

      fieldErrors: {
        cancellationReason:
          validation.error
            .flatten()
            .fieldErrors
            .cancellationReason,
      },

      values: {
        cancellationReason:
          rawValues.cancellationReason,
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
    "cancel_bendahara_payment",
    {
      p_payment_id:
        input.paymentId,

      p_cancellation_reason:
        input.cancellationReason,
    },
  );

  if (error) {
    return {
      status:
        "error",

      message:
        error.message,

      values: {
        cancellationReason:
          rawValues.cancellationReason,
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

  revalidatePath(
    "/bendahara/pembayaran",
  );

  redirect(
    `/bendahara/tagihan/${input.billId}`,
  );
}