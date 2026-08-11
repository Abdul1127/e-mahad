import {
  createClient,
} from "@/lib/supabase/server";

import {
  guardianBillListSchema,
  type GuardianBillListData,
} from "../schemas/guardian-finance-schema";

export async function getGuardianBillListData(
  studentId:
    string | null,
): Promise<GuardianBillListData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_guardian_bill_list",
    {
      p_student_id:
        studentId,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil tagihan Wali: ${error.message}`,
    );
  }

  const validation =
    guardianBillListSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format tagihan Wali tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format data tagihan Wali tidak valid.",
    );
  }

  return validation.data;
}