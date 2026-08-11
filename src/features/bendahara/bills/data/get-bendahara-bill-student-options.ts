import {
  createClient,
} from "@/lib/supabase/server";

import {
  bendaharaBillStudentOptionsSchema,
  type BendaharaBillStudentOptionsData,
} from "../schemas/bendahara-bill-student-options-schema";

type Input = {
  search:
    string | null;
};

export async function getBendaharaBillStudentOptions({
  search,
}: Input): Promise<BendaharaBillStudentOptionsData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } = await supabase.rpc(
    "get_bendahara_bill_student_options",
    {
      p_search:
        search,

      p_limit:
        search
          ? 50
          : 30,
    },
  );

  if (error) {
    throw new Error(
      `Gagal mengambil kandidat santri: ${error.message}`,
    );
  }

  const validation =
    bendaharaBillStudentOptionsSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Format kandidat santri Bendahara tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format kandidat santri dari database tidak valid.",
    );
  }

  return validation.data;
}