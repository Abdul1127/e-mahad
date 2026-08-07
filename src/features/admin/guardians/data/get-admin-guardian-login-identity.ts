import { createClient } from "@/lib/supabase/server";

import {
  guardianLoginIdentitySchema,
  type GuardianLoginIdentityData,
} from "../schemas/guardian-login-identity-schema";

export async function getAdminGuardianLoginIdentity(
  guardianId: string,
): Promise<GuardianLoginIdentityData> {
  const supabase = await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_admin_guardian_login_identity",
    {
      p_guardian_id: guardianId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal membaca identitas login wali: ${error.message}`,
    );
  }

  const validationResult =
    guardianLoginIdentitySchema.safeParse(
      data,
    );

  if (!validationResult.success) {
    console.error(
      "Response identitas login wali tidak valid:",
      validationResult.error.flatten(),
    );

    throw new Error(
      "Format identitas login wali tidak valid.",
    );
  }

  return validationResult.data;
}