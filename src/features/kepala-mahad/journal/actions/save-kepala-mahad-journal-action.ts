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
  MahadHeadJournalActionState,
} from "../types/mahad-head-journal-action-state";

const journalIdSchema =
  z.string().uuid();

const inputSchema =
  z.object({
    intent:
      z.enum([
        "save",
        "submit",
      ]),

    checkedItemKeys:
      z.array(
        z.string().min(1),
      ),

    performanceNotes:
      z.string()
        .max(
          5000,
          "Catatan kinerja maksimal 5000 karakter.",
        ),

    obstaclesFollowUp:
      z.string()
        .max(
          5000,
          "Kendala dan tindak lanjut maksimal 5000 karakter.",
        ),
  });

export async function saveKepalaMahadJournalAction(
  journalId:
    string,

  previousState:
    MahadHeadJournalActionState,

  formData:
    FormData,
): Promise<MahadHeadJournalActionState> {
  void previousState;

  await requireRole(
    "kepala_mahad",
  );

  const journalValidation =
    journalIdSchema.safeParse(
      journalId,
    );

  if (
    !journalValidation.success
  ) {
    return {
      status:
        "error",

      message:
        "ID jurnal tidak valid.",
    };
  }

  const validation =
    inputSchema.safeParse({
      intent:
        String(
          formData.get(
            "intent",
          ) ?? "save",
        ),

      checkedItemKeys:
        formData
          .getAll(
            "checked_item_keys",
          )
          .map(
            (value) =>
              String(
                value,
              ),
          ),

      performanceNotes:
        String(
          formData.get(
            "performance_notes",
          ) ?? "",
        ),

      obstaclesFollowUp:
        String(
          formData.get(
            "obstacles_follow_up",
          ) ?? "",
        ),
    });

  if (
    !validation.success
  ) {
    return {
      status:
        "error",

      message:
        validation.error.issues[0]?.message ??
        "Data jurnal tidak valid.",
    };
  }

  if (
    validation.data.intent ===
      "submit" &&
    validation.data.checkedItemKeys
      .length ===
      0
  ) {
    return {
      status:
        "error",

      message:
        "Pilih minimal satu kegiatan sebelum jurnal dikirim.",
    };
  }

  if (
    validation.data.intent ===
      "submit" &&
    validation.data.performanceNotes
      .trim()
      .length ===
      0
  ) {
    return {
      status:
        "error",

      message:
        "Catatan kinerja wajib diisi sebelum jurnal dikirim.",
    };
  }

  const supabase =
    await createClient();

  const {
    error: saveError,
  } =
    await supabase.rpc(
      "save_kepala_mahad_journal",
      {
        p_journal_id:
          journalValidation.data,

        p_checked_item_keys:
          validation.data
            .checkedItemKeys,

        p_performance_notes:
          validation.data
            .performanceNotes,

        p_obstacles_follow_up:
          validation.data
            .obstaclesFollowUp,
      },
    );

  if (saveError) {
    return {
      status:
        "error",

      message:
        saveError.message,
    };
  }

  revalidatePath(
    "/kepala-mahad/jurnal",
  );

  revalidatePath(
    `/kepala-mahad/jurnal/${journalValidation.data}`,
  );

  if (
    validation.data.intent ===
    "submit"
  ) {
    const {
      error: submitError,
    } =
      await supabase.rpc(
        "submit_kepala_mahad_journal",
        {
          p_journal_id:
            journalValidation.data,
        },
      );

    if (submitError) {
      return {
        status:
          "error",

        message:
          submitError.message,
      };
    }

    revalidatePath(
      "/kepala-mahad/jurnal",
    );

    revalidatePath(
      `/kepala-mahad/jurnal/${journalValidation.data}`,
    );

    revalidatePath(
      "/penanggung-jawab/jurnal",
    );

    redirect(
      `/kepala-mahad/jurnal/${journalValidation.data}?submitted=1`,
    );
  }

  return {
    status:
      "success",

    message:
      "Draft jurnal berhasil disimpan.",
  };
}