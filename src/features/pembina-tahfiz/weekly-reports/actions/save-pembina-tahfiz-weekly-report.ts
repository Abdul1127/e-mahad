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
  PembinaTahfizWeeklyReportActionState,
} from "../types/pembina-tahfiz-weekly-report-action-state";

const ratingSchema =
  z.union([
    z.literal(""),
    z.enum([
      "excellent",
      "good",
      "fair",
      "needs_guidance",
    ]),
  ]);

const inputSchema =
  z.object({
    studentId:
      z.string()
        .uuid(),

    weekStart:
      z.string()
        .regex(
          /^\d{4}-\d{2}-\d{2}$/,
          "Tanggal pekan tidak valid.",
        ),

    memorizationAchievement:
      z.string()
        .trim()
        .max(
          5000,
          "Capaian hafalan maksimal 5.000 karakter.",
        ),

    murajaahAchievement:
      z.string()
        .trim()
        .max(
          5000,
          "Capaian murajaah maksimal 5.000 karakter.",
        ),

    fluencyRating:
      ratingSchema,

    tajwidRating:
      ratingSchema,

    consistencyRating:
      ratingSchema,

    supervisorNotes:
      z.string()
        .trim()
        .max(
          5000,
          "Catatan Pembina maksimal 5.000 karakter.",
        ),

    nextWeekTarget:
      z.string()
        .trim()
        .max(
          5000,
          "Target pekan berikutnya maksimal 5.000 karakter.",
        ),

    intent:
      z.enum([
        "save",
        "publish",
      ]),
  });

const saveResponseSchema =
  z.object({
    success:
      z.boolean(),

    report_id:
      z.string()
        .uuid(),

    student_id:
      z.string()
        .uuid(),

    tahfiz_group_id:
      z.string()
        .uuid(),

    week_start:
      z.string(),

    week_end:
      z.string(),

    status:
      z.enum([
        "draft",
        "published",
      ]),

    saved_at:
      z.string(),
  });

const publishResponseSchema =
  z.object({
    success:
      z.boolean(),

    report_id:
      z.string()
        .uuid(),

    student_id:
      z.string()
        .uuid(),

    week_start:
      z.string(),

    status:
      z.literal(
        "published",
      ),

    published_at:
      z.string(),

    published_by_staff_id:
      z.string()
        .uuid(),
  });

export async function savePembinaTahfizWeeklyReport(
  _previousState:
    PembinaTahfizWeeklyReportActionState,

  formData:
    FormData,
): Promise<PembinaTahfizWeeklyReportActionState> {
  await requireRole(
    "pembina_tahfiz",
  );

  const validation =
    inputSchema.safeParse({
      studentId:
        formData.get(
          "studentId",
        ),

      weekStart:
        formData.get(
          "weekStart",
        ),

      memorizationAchievement:
        formData.get(
          "memorizationAchievement",
        ) ?? "",

      murajaahAchievement:
        formData.get(
          "murajaahAchievement",
        ) ?? "",

      fluencyRating:
        formData.get(
          "fluencyRating",
        ) ?? "",

      tajwidRating:
        formData.get(
          "tajwidRating",
        ) ?? "",

      consistencyRating:
        formData.get(
          "consistencyRating",
        ) ?? "",

      supervisorNotes:
        formData.get(
          "supervisorNotes",
        ) ?? "",

      nextWeekTarget:
        formData.get(
          "nextWeekTarget",
        ) ?? "",

      intent:
        formData.get(
          "intent",
        ),
    });

  if (!validation.success) {
    return {
      status: "error",

      message:
        validation.error
          .issues[0]
          ?.message ??
        "Data laporan belum valid.",
    };
  }

  /*
   * Untuk Publish, lakukan validasi awal
   * agar Pembina mendapat pesan yang jelas
   * sebelum RPC publish dipanggil.
   */
  if (
    validation.data.intent ===
    "publish"
  ) {
    if (
      validation.data
        .memorizationAchievement
        .length === 0
    ) {
      return {
        status: "error",
        message:
          "Capaian hafalan baru wajib diisi sebelum laporan dipublikasikan.",
      };
    }

    if (
      validation.data
        .murajaahAchievement
        .length === 0
    ) {
      return {
        status: "error",
        message:
          "Capaian murajaah wajib diisi sebelum laporan dipublikasikan.",
      };
    }

    if (
      validation.data
        .fluencyRating ===
      ""
    ) {
      return {
        status: "error",
        message:
          "Penilaian kelancaran wajib dipilih sebelum laporan dipublikasikan.",
      };
    }

    if (
      validation.data
        .tajwidRating ===
      ""
    ) {
      return {
        status: "error",
        message:
          "Penilaian tajwid wajib dipilih sebelum laporan dipublikasikan.",
      };
    }

    if (
      validation.data
        .consistencyRating ===
      ""
    ) {
      return {
        status: "error",
        message:
          "Penilaian konsistensi wajib dipilih sebelum laporan dipublikasikan.",
      };
    }

    if (
      validation.data
        .nextWeekTarget
        .length === 0
    ) {
      return {
        status: "error",
        message:
          "Target pekan berikutnya wajib diisi sebelum laporan dipublikasikan.",
      };
    }
  }

  const supabase =
    await createClient();

  /*
   * =====================================================
   * 1. SAVE
   * =====================================================
   */

  const {
    data:
      saveData,
    error:
      saveError,
  } = await supabase.rpc(
    "save_pembina_tahfiz_weekly_report",
    {
      p_student_id:
        validation.data
          .studentId,

      p_week_start:
        validation.data
          .weekStart,

      p_memorization_achievement:
        validation.data
          .memorizationAchievement
          .length > 0
          ? validation.data
              .memorizationAchievement
          : null,

      p_murajaah_achievement:
        validation.data
          .murajaahAchievement
          .length > 0
          ? validation.data
              .murajaahAchievement
          : null,

      p_fluency_rating:
        validation.data
          .fluencyRating ||
        null,

      p_tajwid_rating:
        validation.data
          .tajwidRating ||
        null,

      p_consistency_rating:
        validation.data
          .consistencyRating ||
        null,

      p_supervisor_notes:
        validation.data
          .supervisorNotes
          .length > 0
          ? validation.data
              .supervisorNotes
          : null,

      p_next_week_target:
        validation.data
          .nextWeekTarget
          .length > 0
          ? validation.data
              .nextWeekTarget
          : null,
    },
  );

  if (saveError) {
    console.error(
      "Gagal menyimpan Laporan Tahfiz:",
      saveError,
    );

    return {
      status: "error",
      message:
        saveError.message,
    };
  }

  const saveValidation =
    saveResponseSchema.safeParse(
      saveData,
    );

  if (!saveValidation.success) {
    console.error(
      "Response save Laporan Tahfiz tidak valid:",
      saveValidation.error.flatten(),
    );

    return {
      status: "error",
      message:
        "Format response penyimpanan laporan tidak valid.",
    };
  }

  /*
   * =====================================================
   * 2. PUBLISH
   * =====================================================
   */

  if (
    validation.data.intent ===
    "publish"
  ) {
    const {
      data:
        publishData,
      error:
        publishError,
    } = await supabase.rpc(
      "publish_pembina_tahfiz_weekly_report",
      {
        p_student_id:
          validation.data
            .studentId,

        p_week_start:
          validation.data
            .weekStart,
      },
    );

    if (publishError) {
      console.error(
        "Gagal mempublikasikan Laporan Tahfiz:",
        publishError,
      );

      /*
       * Save yang dilakukan sebelumnya tetap
       * tersimpan sebagai draft. Ini disengaja
       * agar input Pembina tidak hilang.
       */
      return {
        status: "error",

        message:
          `Draft berhasil disimpan, tetapi publikasi gagal: ${publishError.message}`,
      };
    }

    const publishValidation =
      publishResponseSchema.safeParse(
        publishData,
      );

    if (
      !publishValidation.success
    ) {
      console.error(
        "Response publish Laporan Tahfiz tidak valid:",
        publishValidation.error.flatten(),
      );

      return {
        status: "error",

        message:
          "Laporan berhasil disimpan tetapi format response publikasi tidak valid.",
      };
    }
  }

  /*
   * =====================================================
   * 3. REFRESH DATA
   * =====================================================
   */

  const studentId =
    validation.data
      .studentId;

  const weekStart =
    validation.data
      .weekStart;

  revalidatePath(
    "/pembina-tahfiz/laporan",
  );

  revalidatePath(
    `/pembina-tahfiz/laporan/${studentId}`,
  );

  /*
   * Setelah Orang Tua dibuat nanti,
   * published report juga akan kita
   * revalidate pada route Guardian.
   */

  redirect(
    `/pembina-tahfiz/laporan?week=${weekStart}`,
  );
}