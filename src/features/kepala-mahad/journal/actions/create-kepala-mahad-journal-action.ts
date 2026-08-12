"use server";

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

import {
  createKepalaMahadJournalResponseSchema,
} from "../schemas/mahad-head-journal-schema";

import type {
  MahadHeadJournalActionState,
} from "../types/mahad-head-journal-action-state";

const inputSchema =
  z.object({
    journal_date:
      z.string()
        .regex(
          /^\d{4}-\d{2}-\d{2}$/,
          "Tanggal pelaksanaan tidak valid.",
        ),
  });

export async function createKepalaMahadJournalAction(
  previousState:
    MahadHeadJournalActionState,

  formData:
    FormData,
): Promise<MahadHeadJournalActionState> {
  void previousState;

  await requireRole(
    "kepala_mahad",
  );

  const validation =
    inputSchema.safeParse({
      journal_date:
        String(
          formData.get(
            "journal_date",
          ) ?? "",
        ),
    });

  if (!validation.success) {
    return {
      status:
        "error",

      message:
        validation.error.issues[0]?.message ??
        "Tanggal jurnal tidak valid.",
    };
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "create_or_open_kepala_mahad_journal",
      {
        p_journal_date:
          validation.data
            .journal_date,
      },
    );

  if (error) {
    return {
      status:
        "error",

      message:
        error.message,
    };
  }

  const result =
    createKepalaMahadJournalResponseSchema.safeParse(
      data,
    );

  if (!result.success) {
    return {
      status:
        "error",

      message:
        "Respons pembuatan jurnal tidak valid.",
    };
  }

  redirect(
    `/kepala-mahad/jurnal/${result.data.journal_id}`,
  );
}