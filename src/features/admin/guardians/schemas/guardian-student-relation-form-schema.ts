import { z } from "zod";

export const guardianRelationshipTypeSchema =
  z.enum([
    "father",
    "mother",
    "guardian",
    "other",
  ]);

export const guardianStudentRelationFormSchema =
  z.object({
    student_id: z
      .string()
      .trim()
      .uuid(
        "Pilih santri yang akan dihubungkan.",
      ),

    relationship_type:
      guardianRelationshipTypeSchema,

    is_primary_contact: z.boolean(),
  });

export type GuardianRelationshipType =
  z.infer<
    typeof guardianRelationshipTypeSchema
  >;

export type GuardianStudentRelationFormData =
  z.infer<
    typeof guardianStudentRelationFormSchema
  >;