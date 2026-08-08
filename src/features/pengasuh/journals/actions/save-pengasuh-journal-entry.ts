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

import {
  healthConditionSchema,
  psychologicalConditionSchema,
  sleepComplianceSchema,
} from "../schemas/pengasuh-journal-detail-schema";

import type {
  PengasuhJournalMutationState,
} from "../types/pengasuh-journal-mutation-state";

const saveJournalEntrySchema =
  z.object({
    journalId:
      z.string()
        .uuid(),

    studentId:
      z.string()
        .uuid(),

    healthCondition:
      healthConditionSchema,

    sleepCompliance:
      sleepComplianceSchema,

    psychologicalCondition:
      psychologicalConditionSchema,

    parentVisit:
      z.enum([
        "true",
        "false",
      ]),

    caseNotes:
      z.string()
        .trim()
        .max(
          2000,
          "Catatan kasus maksimal 2.000 karakter.",
        ),

    handlingNotes:
      z.string()
        .trim()
        .max(
          2000,
          "Catatan penanganan maksimal 2.000 karakter.",
        ),
  });

const saveResponseSchema =
  z.object({
    success:
      z.boolean(),

    journal_id:
      z.string()
        .uuid(),

    student_id:
      z.string()
        .uuid(),

    entry_id:
      z.string()
        .uuid(),

    status:
      z.enum([
        "draft",
        "submitted",
        "revision_requested",
        "reviewed",
      ]),
  });

export async function savePengasuhJournalEntry(
  _previousState:
    PengasuhJournalMutationState,
  formData:
    FormData,
): Promise<PengasuhJournalMutationState> {
  await requireRole(
    "pengasuh",
  );

  const validation =
    saveJournalEntrySchema.safeParse({
      journalId:
        formData.get(
          "journalId",
        ),

      studentId:
        formData.get(
          "studentId",
        ),

      healthCondition:
        formData.get(
          "healthCondition",
        ),

      sleepCompliance:
        formData.get(
          "sleepCompliance",
        ),

      psychologicalCondition:
        formData.get(
          "psychologicalCondition",
        ),

      parentVisit:
        formData.get(
          "parentVisit",
        ),

      caseNotes:
        formData.get(
          "caseNotes",
        ) ?? "",

      handlingNotes:
        formData.get(
          "handlingNotes",
        ) ?? "",
    });

  if (
    !validation.success
  ) {
    return {
      status: "error",
      message:
        validation.error
          .issues[0]
          ?.message ??
        "Data jurnal santri belum lengkap.",
    };
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "save_pengasuh_journal_entry",
    {
      p_journal_id:
        validation.data
          .journalId,

      p_student_id:
        validation.data
          .studentId,

      p_health_condition:
        validation.data
          .healthCondition,

      p_sleep_compliance:
        validation.data
          .sleepCompliance,

      p_psychological_condition:
        validation.data
          .psychologicalCondition,

      p_parent_visit:
        validation.data
          .parentVisit ===
        "true",

      p_case_notes:
        validation.data
          .caseNotes.length >
        0
          ? validation.data
              .caseNotes
          : null,

      p_handling_notes:
        validation.data
          .handlingNotes.length >
        0
          ? validation.data
              .handlingNotes
          : null,
    },
  );

  if (error) {
    console.error(
      "Gagal menyimpan entry Jurnal Pengasuhan:",
      error,
    );

    return {
      status: "error",
      message:
        error.message,
    };
  }

  const responseValidation =
    saveResponseSchema.safeParse(
      data,
    );

  if (
    !responseValidation.success
  ) {
    console.error(
      "Response save entry jurnal tidak valid:",
      responseValidation.error.flatten(),
    );

    return {
      status: "error",
      message:
        "Format response penyimpanan jurnal tidak valid.",
    };
  }

  revalidatePath(
    `/pengasuh/jurnal/${validation.data.journalId}`,
  );

  revalidatePath(
    "/pengasuh/jurnal",
  );

  return {
    status: "success",
    message:
      "Data santri berhasil disimpan.",
  };
}