import {
  createClient,
} from "@/lib/supabase/server";

import {
  guardianPaymentHistorySchema,
  type GuardianPaymentHistoryData,
} from "../schemas/guardian-finance-schema";

type Input = {
  studentId:
    string | null;

  page:
    number;

  pageSize:
    number;
};

export async function getGuardianPaymentHistoryData({
  studentId,
  page,
  pageSize,
}: Input): Promise<GuardianPaymentHistoryData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_guardian_payment_history",
    {
      p_student_id:
        studentId,

      p_page:
        page,

      p_page_size:
        pageSize,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil riwayat pembayaran Wali: ${error.message}`,
    );
  }

  const validation =
    guardianPaymentHistorySchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format pembayaran Wali tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format data riwayat pembayaran Wali tidak valid.",
    );
  }

  return validation.data;
}