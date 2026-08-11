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
  SavePengasuhActivityAttendanceState,
} from "../types/save-pengasuh-activity-attendance-state";

const studentIdsSchema =
  z.array(
    z.string().uuid(),
  )
    .min(
      1,
    );

const statusSchema =
  z.enum([
    "present",
    "permission",
    "sick",
    "absent",
  ]);

export async function savePengasuhActivityAttendanceAction(
  _previousState:
    SavePengasuhActivityAttendanceState,

  formData:
    FormData,
): Promise<SavePengasuhActivityAttendanceState> {
  const scheduleId =
    String(
      formData.get(
        "scheduleId",
      ) ?? "",
    );

  const scheduleValidation =
    z.string()
      .uuid()
      .safeParse(
        scheduleId,
      );

  if (
    !scheduleValidation.success
  ) {
    return {
      status:
        "error",

      message:
        "ID jadwal tidak valid.",
    };
  }

  let parsedStudentIds:
    unknown;

  try {
    parsedStudentIds =
      JSON.parse(
        String(
          formData.get(
            "studentIds",
          ) ?? "[]",
        ),
      );
  } catch {
    return {
      status:
        "error",

      message:
        "Daftar santri tidak valid.",
    };
  }

  const studentIdsValidation =
    studentIdsSchema.safeParse(
      parsedStudentIds,
    );

  if (
    !studentIdsValidation.success
  ) {
    return {
      status:
        "error",

      message:
        "Daftar santri absensi tidak valid.",
    };
  }

  const entries:
    Array<{
      student_id: string;

      status:
        | "present"
        | "permission"
        | "sick"
        | "absent";

      notes:
        string | null;
    }> = [];

  for (
    const studentId
    of studentIdsValidation.data
  ) {
    const rawStatus =
      String(
        formData.get(
          `status_${studentId}`,
        ) ?? "",
      );

    const statusValidation =
      statusSchema.safeParse(
        rawStatus,
      );

    if (
      !statusValidation.success
    ) {
      return {
        status:
          "error",

        message:
          "Terdapat status absensi yang belum valid.",
      };
    }

    const notes =
      String(
        formData.get(
          `notes_${studentId}`,
        ) ?? "",
      )
        .trim();

    if (
      notes.length >
      500
    ) {
      return {
        status:
          "error",

        message:
          "Catatan absensi maksimal 500 karakter.",
      };
    }

    entries.push({
      student_id:
        studentId,

      status:
        statusValidation.data,

      notes:
        notes ||
        null,
    });
  }

  const supabase =
    await createClient();

  const {
    error,
  } = await supabase.rpc(
    "save_pengasuh_activity_attendance",
    {
      p_schedule_id:
        scheduleValidation.data,

      p_entries:
        entries,
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

  revalidatePath(
    "/pengasuh/jadwal",
  );

  revalidatePath(
    `/pengasuh/jadwal/${scheduleValidation.data}`,
  );

  redirect(
    `/pengasuh/jadwal/${scheduleValidation.data}?saved=1`,
  );
}