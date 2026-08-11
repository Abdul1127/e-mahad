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
  createBendaharaBillSchema,
} from "../schemas/create-bendahara-bill-schema";

import type {
  CreateBendaharaBillActionState,
} from "../types/create-bendahara-bill-action-state";

export async function createBendaharaStudentBillAction(
  _previousState:
    CreateBendaharaBillActionState,

  formData:
    FormData,
): Promise<CreateBendaharaBillActionState> {
  const rawValues = {
    studentId:
      String(
        formData.get(
          "studentId",
        ) ?? "",
      ),

    title:
      String(
        formData.get(
          "title",
        ) ?? "",
      ),

    category:
      String(
        formData.get(
          "category",
        ) ?? "",
      ),

    amount:
      String(
        formData.get(
          "amount",
        ) ?? "",
      ),

    description:
      String(
        formData.get(
          "description",
        ) ?? "",
      ),

    periodLabel:
      String(
        formData.get(
          "periodLabel",
        ) ?? "",
      ),

    periodStart:
      String(
        formData.get(
          "periodStart",
        ) ?? "",
      ),

    periodEnd:
      String(
        formData.get(
          "periodEnd",
        ) ?? "",
      ),

    dueDate:
      String(
        formData.get(
          "dueDate",
        ) ?? "",
      ),
  };

  const validation =
    createBendaharaBillSchema.safeParse(
      rawValues,
    );

  if (
    !validation.success
  ) {
    return {
      status:
        "error",

      message:
        "Periksa kembali data tagihan yang diisi.",

      fieldErrors:
        validation.error.flatten()
          .fieldErrors,

      values: {
        title:
          rawValues.title,

        category:
          rawValues.category,

        amount:
          rawValues.amount,

        description:
          rawValues.description,

        periodLabel:
          rawValues.periodLabel,

        periodStart:
          rawValues.periodStart,

        periodEnd:
          rawValues.periodEnd,

        dueDate:
          rawValues.dueDate,
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
    "create_bendahara_student_bill",
    {
      p_student_id:
        input.studentId,

      p_title:
        input.title,

      p_category:
        input.category,

      p_amount:
        input.amount,

      p_description:
        input.description,

      p_period_label:
        input.periodLabel,

      p_period_start:
        input.periodStart,

      p_period_end:
        input.periodEnd,

      p_due_date:
        input.dueDate,
    },
  );

  if (error) {
    return {
      status:
        "error",

      message:
        error.message,

      values: {
        title:
          rawValues.title,

        category:
          rawValues.category,

        amount:
          rawValues.amount,

        description:
          rawValues.description,

        periodLabel:
          rawValues.periodLabel,

        periodStart:
          rawValues.periodStart,

        periodEnd:
          rawValues.periodEnd,

        dueDate:
          rawValues.dueDate,
      },
    };
  }

  revalidatePath(
    "/bendahara/dashboard",
  );

  revalidatePath(
    "/bendahara/tagihan",
  );

  redirect(
    "/bendahara/tagihan",
  );
}