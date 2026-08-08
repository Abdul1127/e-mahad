"use server";

import {
  revalidatePath,
} from "next/cache";

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

const inputSchema =
  z.object({
    journalId:
      z.string()
        .uuid(),
  });

const responseSchema =
  z.object({
    success:
      z.boolean(),

    journal_id:
      z.string()
        .uuid(),

    status:
      z.enum([
        "draft",
        "submitted",
        "revision_requested",
        "reviewed",
      ]),

    inserted_entry_count:
      z.number()
        .int()
        .nonnegative(),

    filled_entry_count:
      z.number()
        .int()
        .nonnegative(),

    total_entry_count:
      z.number()
        .int()
        .nonnegative(),

    complete_entry_count:
      z.number()
        .int()
        .nonnegative(),
  });

export async function fillNormalPengasuhJournal(
  _previousState:
    PengasuhJournalMutationState,
  formData:
    FormData,
): Promise<PengasuhJournalMutationState> {
  await requireRole(
    "pengasuh",
  );

  const validation =
    inputSchema.safeParse({
      journalId:
        formData.get(
          "journalId",
        ),
    });

  if (!validation.success) {
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
    "fill_normal_pengasuh_journal_entries",
    {
      p_journal_id:
        validation.data
          .journalId,
    },
  );

  if (error) {
    console.error(
      "Gagal mengisi kondisi normal jurnal:",
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
      "Response bulk normal jurnal tidak valid:",
      responseValidation.error.flatten(),
    );

    return {
      status: "error",
      message:
        "Format response pengisian kondisi normal tidak valid.",
    };
  }

  revalidatePath(
    `/pengasuh/jurnal/${validation.data.journalId}`,
  );

  revalidatePath(
    "/pengasuh/jurnal",
  );

  const {
    filled_entry_count:
      filledCount,
    complete_entry_count:
      completeCount,
    total_entry_count:
      totalCount,
  } = responseValidation.data;

  return {
    status: "success",
    message:
      filledCount > 0
        ? `${filledCount} santri yang belum lengkap berhasil diisi dengan kondisi normal. Progress ${completeCount}/${totalCount}.`
        : "Tidak ada data kosong yang perlu diisi.",
  };
}