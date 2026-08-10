"use server";

import {
  revalidatePath,
} from "next/cache";

import {
  redirect,
} from "next/navigation";

import {
  z,
} from "zod";

import {
  requireRole,
} from "@/lib/auth/guards";

import {
  createClient,
} from "@/lib/supabase/server";

import type {
  KepalaMahadCareJournalReviewState,
} from "../types/kepala-mahad-care-journal-review-state";

const reviewSchema =
  z.object({
    journalId:
      z.string()
        .uuid(),

    reviewAction:
      z.enum([
        "reviewed",
        "revision_requested",
      ]),

    note:
      z.string()
        .trim()
        .max(
          2000,
          "Catatan maksimal 2.000 karakter.",
        ),
  })
    .superRefine(
      (
        data,
        context,
      ) => {
        if (
          data.reviewAction ===
            "revision_requested" &&
          data.note.length === 0
        ) {
          context.addIssue({
            code:
              z.ZodIssueCode.custom,

            path: [
              "note",
            ],

            message:
              "Catatan revisi wajib diisi.",
          });
        }
      },
    );

const responseSchema =
  z.object({
    success:
      z.boolean(),

    journal_id:
      z.string()
        .uuid(),

    review_id:
      z.string()
        .uuid(),

    submission_version:
      z.number()
        .int()
        .positive(),

    action:
      z.enum([
        "reviewed",
        "revision_requested",
      ]),

    status:
      z.enum([
        "reviewed",
        "revision_requested",
      ]),

    note:
      z.string()
        .nullable(),

    reviewed_by_staff_id:
      z.string()
        .uuid(),

    reviewed_at:
      z.string(),
  });

export async function reviewKepalaMahadCareJournal(
  _previousState:
    KepalaMahadCareJournalReviewState,
  formData:
    FormData,
): Promise<KepalaMahadCareJournalReviewState> {
  await requireRole(
    "kepala_mahad",
  );

  const validation =
    reviewSchema.safeParse({
      journalId:
        formData.get(
          "journalId",
        ),

      reviewAction:
        formData.get(
          "reviewAction",
        ),

      note:
        formData.get(
          "note",
        ) ?? "",
    });

  if (!validation.success) {
    return {
      status: "error",

      message:
        validation.error
          .issues[0]
          ?.message ??
        "Data review belum valid.",
    };
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "review_kepala_mahad_care_journal",
    {
      p_journal_id:
        validation.data
          .journalId,

      p_action:
        validation.data
          .reviewAction,

      p_note:
        validation.data
          .note.length >
        0
          ? validation.data
              .note
          : null,
    },
  );

  if (error) {
    console.error(
      "Gagal review Jurnal Pengasuhan:",
      error,
    );

    return {
      status: "error",
      message:
        error.message,
    };
  }

  const responseValidation =
    responseSchema.safeParse(
      data,
    );

  if (!responseValidation.success) {
    console.error(
      "Response review jurnal Kepala Ma'had tidak valid:",
      responseValidation.error.flatten(),
    );

    return {
      status: "error",
      message:
        "Format response review jurnal tidak valid.",
    };
  }

  const journalId =
    validation.data
      .journalId;

  revalidatePath(
    "/kepala-mahad/pengasuhan",
  );

  revalidatePath(
    `/kepala-mahad/pengasuhan/${journalId}`,
  );

  /*
   * Review Kepala Ma'had juga mengubah
   * data yang dibaca pada sisi Pengasuh.
   */
  revalidatePath(
    "/pengasuh/jurnal",
  );

  revalidatePath(
    `/pengasuh/jurnal/${journalId}`,
  );

  redirect(
    `/kepala-mahad/pengasuhan/${journalId}`,
  );
}