import { z } from "zod";

const staffLoginIdentityRoleSchema =
  z.object({
    code: z.string().min(1),
    name: z.string().min(1),
  });

export const staffLoginIdentitySchema =
  z.object({
    success: z.boolean(),

    status: z.enum([
      "candidate",
      "existing",
    ]),

    staff_id:
      z.string().uuid(),

    profile_id: z
      .string()
      .uuid()
      .nullable(),

    legacy_staff_id:
      z.string().min(1),

    full_name:
      z.string().min(1),

    position:
      z.string().nullable(),

    phone:
      z.string().nullable(),

    staff_is_active:
      z.boolean(),

    login_id:
      z.string().min(1),

    internal_auth_email:
      z.string().email(),

    roles: z.array(
      staffLoginIdentityRoleSchema,
    ),
  });

export type StaffLoginIdentityData =
  z.infer<
    typeof staffLoginIdentitySchema
  >;