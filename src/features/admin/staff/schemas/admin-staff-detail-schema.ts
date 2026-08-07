import { z } from "zod";

const adminStaffDetailRoleSchema = z.object({
  code: z.string().min(1),
  name: z.string().min(1),

  assigned_by: z
    .string()
    .uuid()
    .nullable(),
});

export const adminStaffDetailSchema =
  z.object({
    generated_at: z.string(),

    staff: z.object({
      id: z.string().uuid(),

      profile_id: z
        .string()
        .uuid()
        .nullable(),

      legacy_staff_id: z
        .string()
        .nullable(),

      full_name: z.string(),

      phone: z
        .string()
        .nullable(),

      position: z
        .string()
        .nullable(),

      is_active: z.boolean(),

      created_at: z.string(),
      updated_at: z.string(),
    }),

    account: z.object({
      linked: z.boolean(),
      active: z.boolean(),

      profile_id: z
        .string()
        .uuid()
        .nullable(),

      login_id: z
        .string()
        .nullable(),
    }),

    summary: z.object({
      role_count: z
        .number()
        .int()
        .nonnegative(),
    }),

    roles: z.array(
      adminStaffDetailRoleSchema,
    ),
  });

export type AdminStaffDetailData =
  z.infer<
    typeof adminStaffDetailSchema
  >;

export type AdminStaffDetailRole =
  AdminStaffDetailData["roles"][number];