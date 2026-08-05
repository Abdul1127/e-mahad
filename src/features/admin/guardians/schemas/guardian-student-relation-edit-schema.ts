import { z } from "zod";

import { guardianRelationshipTypeSchema } from "./guardian-student-relation-form-schema";

export const guardianStudentRelationEditSchema =
  z.object({
    relationship_type:
      guardianRelationshipTypeSchema,

    is_primary_contact: z.boolean(),
  });

export type GuardianStudentRelationEditData =
  z.infer<
    typeof guardianStudentRelationEditSchema
  >;