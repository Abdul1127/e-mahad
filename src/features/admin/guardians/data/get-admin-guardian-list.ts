import { createClient } from "@/lib/supabase/server";

import type { AdminGuardianListQuery } from "../lib/parse-guardian-list-query";
import {
  adminGuardianListSchema,
  type AdminGuardianListData,
} from "../schemas/admin-guardian-list-schema";

export async function getAdminGuardianList(
  query: AdminGuardianListQuery,
): Promise<AdminGuardianListData> {
  const supabase = await createClient();

  const { data, error } = await supabase.rpc(
    "get_admin_guardian_list",
    {
      p_search:
        query.search.length > 0
          ? query.search
          : null,

      p_is_active: query.isActive,

      p_account_status:
        query.accountStatus,

      p_page: query.page,

      p_page_size: query.pageSize,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca daftar wali: ${error.message}`,
    );
  }

  const validationResult =
    adminGuardianListSchema.safeParse(data);

  if (!validationResult.success) {
    console.error(
      "Response daftar wali tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format daftar wali tidak sesuai.",
    );
  }

  return validationResult.data;
}