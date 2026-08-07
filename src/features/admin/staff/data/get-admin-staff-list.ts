import { createClient } from "@/lib/supabase/server";

import type { AdminStaffListQuery } from "../lib/parse-staff-list-query";
import {
  adminStaffListSchema,
  type AdminStaffListData,
} from "../schemas/admin-staff-list-schema";

export async function getAdminStaffList(
  query: AdminStaffListQuery,
): Promise<AdminStaffListData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_staff_list",
    {
      p_search:
        query.search.length > 0
          ? query.search
          : null,

      p_is_active:
        query.isActive,

      p_account_status:
        query.accountStatus,

      p_role_code:
        query.roleCode,

      p_page:
        query.page,

      p_page_size:
        query.pageSize,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca daftar staf: ${error.message}`,
    );
  }

  const validationResult =
    adminStaffListSchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response daftar staf tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format daftar staf tidak sesuai.",
    );
  }

  return validationResult.data;
}