import { z } from "zod";

export const adminStaffRoleSchema = z.object({
  code: z.string().min(1),
  name: z.string().min(1),
});

const adminStaffListItemSchema = z.object({
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

  account_linked: z.boolean(),
  account_active: z.boolean(),

  account_login_id: z
    .string()
    .nullable(),

  roles: z.array(
    adminStaffRoleSchema,
  ),

  role_count: z
    .number()
    .int()
    .nonnegative(),

  created_at: z.string(),
  updated_at: z.string(),
});

export const staffAccountStatusSchema =
  z.enum([
    "linked",
    "unlinked",
  ]);

export const adminStaffListSchema =
  z.object({
    generated_at: z.string(),

    filters: z.object({
      search: z
        .string()
        .nullable(),

      is_active: z
        .boolean()
        .nullable(),

      account_status:
        staffAccountStatusSchema.nullable(),

      role_code: z
        .string()
        .nullable(),
    }),

    summary: z.object({
      total_staff: z
        .number()
        .int()
        .nonnegative(),

      active_staff: z
        .number()
        .int()
        .nonnegative(),

      linked_accounts: z
        .number()
        .int()
        .nonnegative(),

      unlinked_accounts: z
        .number()
        .int()
        .nonnegative(),

      active_accounts: z
        .number()
        .int()
        .nonnegative(),

      inactive_accounts: z
        .number()
        .int()
        .nonnegative(),

      total_role_assignments: z
        .number()
        .int()
        .nonnegative(),
    }),

    pagination: z.object({
      current_page: z
        .number()
        .int()
        .positive(),

      page_size: z
        .number()
        .int()
        .positive(),

      total_items: z
        .number()
        .int()
        .nonnegative(),

      total_pages: z
        .number()
        .int()
        .nonnegative(),

      from_item: z
        .number()
        .int()
        .nonnegative(),

      to_item: z
        .number()
        .int()
        .nonnegative(),
    }),

    items: z.array(
      adminStaffListItemSchema,
    ),
  });

export type StaffAccountStatus =
  z.infer<
    typeof staffAccountStatusSchema
  >;

export type AdminStaffRole =
  z.infer<
    typeof adminStaffRoleSchema
  >;

export type AdminStaffListData =
  z.infer<
    typeof adminStaffListSchema
  >;

export type AdminStaffListItem =
  AdminStaffListData["items"][number];