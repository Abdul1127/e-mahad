"use server";

import {
  revalidatePath,
} from "next/cache";

import {
  redirect,
} from "next/navigation";

import {
  getServerActionReturnTo,
} from "@/lib/navigation/get-server-action-return-to";

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
  /*
   * =====================================================
   * RAW VALUES
   * =====================================================
   */

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

  /*
   * =====================================================
   * VALIDATION
   * =====================================================
   */

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

  /*
   * =====================================================
   * DATABASE
   * =====================================================
   */

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

  /*
   * =====================================================
   * REVALIDATION
   * =====================================================
   */

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

  /*
   * =====================================================
   * REDIRECT
   * =====================================================
   */

  const detailHref =
    `/bendahara/tagihan/${input.billId}`;

  const redirectTarget =
    await getServerActionReturnTo({
      fallbackHref:
        detailHref,

      expectedPath:
        detailHref,
    });

  redirect(
    redirectTarget,
  );
}