import { z } from "zod";

export const studentFormGenderSchema = z.enum([
  "male",
  "female",
]);

export const studentFormStatusSchema = z.enum([
  "active",
  "inactive",
  "graduated",
  "withdrawn",
]);

const optionalUuidSchema = z
  .union([
    z.literal(""),
    z.string().uuid(
      "Pilihan tidak valid.",
    ),
  ])
  .transform((value) =>
    value === "" ? null : value,
  );

export const adminStudentFormSchema = z
  .object({
    legacyStudentId: z
      .string()
      .trim()
      .min(1, "ID santri wajib diisi.")
      .max(
        100,
        "ID santri maksimal 100 karakter.",
      ),

    nis: z
      .string()
      .trim()
      .max(
        100,
        "NIS maksimal 100 karakter.",
      ),

    fullName: z
      .string()
      .trim()
      .min(1, "Nama lengkap wajib diisi.")
      .max(
        200,
        "Nama lengkap maksimal 200 karakter.",
      ),

    gender: studentFormGenderSchema,

    status: studentFormStatusSchema,

    classId: optionalUuidSchema,
    careGroupId: optionalUuidSchema,
    tahfizGroupId: optionalUuidSchema,
  })
  .superRefine((data, context) => {
    if (data.status !== "active") {
      return;
    }

    if (!data.classId) {
      context.addIssue({
        code: "custom",
        path: ["classId"],
        message:
          "Kelas wajib dipilih untuk santri aktif.",
      });
    }

    if (!data.careGroupId) {
      context.addIssue({
        code: "custom",
        path: ["careGroupId"],
        message:
          "Kelompok pengasuhan wajib dipilih.",
      });
    }

    if (!data.tahfizGroupId) {
      context.addIssue({
        code: "custom",
        path: ["tahfizGroupId"],
        message:
          "Kelompok tahfiz wajib dipilih.",
      });
    }
  });

export const studentFormOptionsSchema = z.object({
  academic_year: z
    .object({
      id: z.string().uuid(),
      name: z.string(),
      start_date: z.string(),
      end_date: z.string(),
    })
    .nullable(),

  classes: z.array(
    z.object({
      id: z.string().uuid(),
      name: z.string(),
      grade_level: z.number().int(),
      gender:
        studentFormGenderSchema.nullable(),
    }),
  ),

  care_groups: z.array(
    z.object({
      id: z.string().uuid(),
      name: z.string(),
      gender: studentFormGenderSchema,
    }),
  ),

  tahfiz_groups: z.array(
    z.object({
      id: z.string().uuid(),
      name: z.string(),
      grade_level:
        z.number().int().nullable(),
      gender: studentFormGenderSchema,
    }),
  ),
});

export const studentMutationResultSchema =
  z.object({
    success: z.literal(true),

    operation: z.enum([
      "created",
      "updated",
    ]),

    student_id: z.string().uuid(),

    legacy_student_id: z.string(),

    full_name: z.string(),
  });

export type AdminStudentFormInput = z.infer<
  typeof adminStudentFormSchema
>;

export type StudentFormOptions = z.infer<
  typeof studentFormOptionsSchema
>;

export type StudentFormGender = z.infer<
  typeof studentFormGenderSchema
>;

export type StudentFormStatus = z.infer<
  typeof studentFormStatusSchema
>;