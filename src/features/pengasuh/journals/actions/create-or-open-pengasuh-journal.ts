"use server";

import { redirect } from "next/navigation";
import { z } from "zod";

import { requireRole } from "@/lib/auth/guards";
import { createClient } from "@/lib/supabase/server";

import type { PengasuhJournalActionState } from "../types/pengasuh-journal-action-state";

const createJournalSchema =
  z.object({
    careGroupId:
      z.string()
        .uuid(),

    journalDate:
      z.string()
        .regex(
          /^\d{4}-\d{2}-\d{2}$/,
          "Tanggal jurnal tidak valid.",
        ),

    session:
      z.enum([
        "morning",
        "evening",
      ]),
  });

const responseSchema =
  z.object({
    success:
      z.boolean(),

    created:
      z.boolean(),

    journal_id:
      z.string()
        .uuid(),

    care_group_id:
      z.string()
        .uuid(),

    journal_date:
      z.string(),

    session:
      z.enum([
        "morning",
        "evening",
      ]),

    status:
      z.enum([
        "draft",
        "submitted",
        "revision_requested",
        "reviewed",
      ]),

    entry_count:
      z.number()
        .int()
        .nonnegative(),
  });

export async function createOrOpenPengasuhJournal(
  _previousState:
    PengasuhJournalActionState,
  formData:
    FormData,
): Promise<PengasuhJournalActionState> {
  await requireRole(
    "pengasuh",
  );

  const validation =
    createJournalSchema.safeParse({
      careGroupId:
        formData.get(
          "careGroupId",
        ),

      journalDate:
        formData.get(
          "journalDate",
        ),

      session:
        formData.get(
          "session",
        ),
    });

  if (!validation.success) {
    return {
      status: "error",
      message:
        validation.error
          .issues[0]
          ?.message ??
        "Data jurnal tidak valid.",
    };
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "create_or_open_pengasuh_journal",
    {
      p_care_group_id:
        validation.data
          .careGroupId,

      p_journal_date:
        validation.data
          .journalDate,

      p_session:
        validation.data
          .session,
    },
  );

  if (error) {
    console.error(
      "Gagal membuat/membuka Jurnal Pengasuhan:",
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

  if (
    !responseValidation.success
  ) {
    console.error(
      "Response create/open jurnal tidak valid:",
      responseValidation.error.flatten(),
    );

    return {
      status: "error",
      message:
        "Format response jurnal dari database tidak valid.",
    };
  }

  redirect(
    `/pengasuh/jurnal/${responseValidation.data.journal_id}`,
  );
}