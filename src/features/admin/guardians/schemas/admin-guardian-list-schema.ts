import { z } from "zod";

const guardianListItemSchema = z.object({
  id: z.string().uuid(),

  profile_id: z
    .string()
    .uuid()
    .nullable(),

  legacy_guardian_id: z
    .string()
    .nullable(),

  full_name: z.string(),

  phone: z.string().nullable(),
  email: z.string().nullable(),

  is_active: z.boolean(),

  account_linked: z.boolean(),
  account_active: z.boolean(),

  account_login_id: z
    .string()
    .nullable(),

  children_count: z
    .number()
    .int()
    .nonnegative(),

  active_children_count: z
    .number()
    .int()
    .nonnegative(),

  primary_contact_count: z
    .number()
    .int()
    .nonnegative(),

  created_at: z.string(),
  updated_at: z.string(),
});

export const guardianAccountStatusSchema =
  z.enum([
    "linked",
    "unlinked",
  ]);

export const adminGuardianListSchema =
  z.object({
    generated_at: z.string(),

    filters: z.object({
      search: z.string().nullable(),
      is_active: z.boolean().nullable(),

      account_status:
        guardianAccountStatusSchema.nullable(),
    }),

    summary: z.object({
      total_guardians: z
        .number()
        .int()
        .nonnegative(),

      active_guardians: z
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

      total_child_links: z
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
      guardianListItemSchema,
    ),
  });

export type GuardianAccountStatus =
  z.infer<
    typeof guardianAccountStatusSchema
  >;

export type AdminGuardianListData =
  z.infer<
    typeof adminGuardianListSchema
  >;

export type AdminGuardianListItem =
  AdminGuardianListData["items"][number];