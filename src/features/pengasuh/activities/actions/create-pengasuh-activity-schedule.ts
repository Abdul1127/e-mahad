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
  createClient,
} from "@/lib/supabase/server";

import type {
  CreatePengasuhActivityScheduleState,
} from "../types/create-pengasuh-activity-schedule-state";

const createScheduleSchema =
  z.object({
    careGroupId:
      z.string()
        .uuid(
          "Kelompok asrama tidak valid.",
        ),

    activityDate:
      z.string()
        .regex(
          /^\d{4}-\d{2}-\d{2}$/,
          "Tanggal kegiatan tidak valid.",
        ),

    startTime:
      z.string()
        .regex(
          /^\d{2}:\d{2}$/,
          "Waktu mulai tidak valid.",
        ),

    endTime:
      z.string(),

    activityName:
      z.string()
        .trim()
        .min(
          2,
          "Nama kegiatan wajib diisi.",
        )
        .max(
          150,
          "Nama kegiatan maksimal 150 karakter.",
        ),

    location:
      z.string()
        .trim()
        .max(
          150,
          "Lokasi maksimal 150 karakter.",
        ),

    notes:
      z.string()
        .trim()
        .max(
          1000,
          "Catatan maksimal 1000 karakter.",
        ),
  });

type RpcResponse = {
  success?: boolean;

  schedule?: {
    id?: string;
  };
};

export async function createPengasuhActivityScheduleAction(
  _previousState:
    CreatePengasuhActivityScheduleState,

  formData:
    FormData,
): Promise<CreatePengasuhActivityScheduleState> {
  const rawValues = {
    careGroupId:
      String(
        formData.get(
          "careGroupId",
        ) ?? "",
      ),

    activityDate:
      String(
        formData.get(
          "activityDate",
        ) ?? "",
      ),

    startTime:
      String(
        formData.get(
          "startTime",
        ) ?? "",
      ),

    endTime:
      String(
        formData.get(
          "endTime",
        ) ?? "",
      ),

    activityName:
      String(
        formData.get(
          "activityName",
        ) ?? "",
      ),

    location:
      String(
        formData.get(
          "location",
        ) ?? "",
      ),

    notes:
      String(
        formData.get(
          "notes",
        ) ?? "",
      ),
  };

  const validation =
    createScheduleSchema.safeParse(
      rawValues,
    );

  if (
    !validation.success
  ) {
    const flattened =
      validation.error.flatten();

    const firstError =
      Object.values(
        flattened.fieldErrors,
      )
        .flat()
        .find(
          Boolean,
        );

    return {
      status:
        "error",

      message:
        firstError ??
        "Periksa kembali data jadwal kegiatan.",

      values:
        rawValues,
    };
  }

  const input =
    validation.data;

  if (
    input.endTime &&
    input.endTime <=
      input.startTime
  ) {
    return {
      status:
        "error",

      message:
        "Waktu selesai harus setelah waktu mulai.",

      values:
        rawValues,
    };
  }

  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "create_pengasuh_activity_schedule",
    {
      p_care_group_id:
        input.careGroupId,

      p_activity_date:
        input.activityDate,

      p_start_time:
        input.startTime,

      p_end_time:
        input.endTime ||
        null,

      p_activity_name:
        input.activityName,

      p_location:
        input.location ||
        null,

      p_notes:
        input.notes ||
        null,
    },
  );

  if (error) {
    return {
      status:
        "error",

      message:
        error.message,

      values:
        rawValues,
    };
  }

  const result =
    data as RpcResponse | null;

  const scheduleId =
    result?.schedule?.id;

  if (!scheduleId) {
    return {
      status:
        "error",

      message:
        "Jadwal berhasil diproses tetapi ID jadwal tidak ditemukan.",

      values:
        rawValues,
    };
  }

  revalidatePath(
    "/pengasuh/jadwal",
  );

  redirect(
    `/pengasuh/jadwal/${scheduleId}`,
  );
}