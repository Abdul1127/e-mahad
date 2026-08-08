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
  PengasuhJournalMutationState,
} from "../types/pengasuh-journal-mutation-state";

const submitJournalSchema =
  z.object({
    journalId:
      z.string()
        .uuid(),
  });

const submitResponseSchema =
  z.object({
    success:
      z.boolean(),

    journal_id:
      z.string()
        .uuid(),

    status:
      z.literal(
        "submitted",
      ),

    submission_version:
      z.number()
        .int()
        .positive(),

    student_count:
      z.number()
        .int()
        .positive(),

    submitted_at:
      z.string(),
  });

export async function submitPengasuhJournal(
  _previousState:
    PengasuhJournalMutationState,
  formData:
    FormData,
): Promise<PengasuhJournalMutationState> {
  await requireRole(
    "pengasuh",
  );

  const validation =
    submitJournalSchema.safeParse({
      journalId:
        formData.get(
          "journalId",
        ),
    });

  if (
    !validation.success
  ) {
    return {
      status: "error",
      message:
        "Journal ID tidak valid.",
    };
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "submit_pengasuh_journal",
    {
      p_journal_id:
        validation.data
          .journalId,
    },
  );

  if (error) {
    console.error(
      "Gagal submit Jurnal Pengasuhan:",
      error,
    );

    return {
      status: "error",
      message:
        error.message,
    };
  }

  const responseValidation =
    submitResponseSchema.safeParse(
      data,
    );

  if (
    !responseValidation.success
  ) {
    console.error(
      "Response submit jurnal tidak valid:",
      responseValidation.error.flatten(),
    );

    return {
      status: "error",
      message:
        "Format response submit jurnal tidak valid.",
    };
  }

  revalidatePath(
    "/pengasuh/jurnal",
  );

  revalidatePath(
    `/pengasuh/jurnal/${validation.data.journalId}`,
  );

  redirect(
    `/pengasuh/jurnal/${validation.data.journalId}`,
  );
}