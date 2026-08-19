import "server-only";

import {
  createClient,
} from "@/lib/supabase/server";

import type {
  PenanggungJawabCareConditionQuery,
} from "../lib/parse-penanggung-jawab-care-condition-query";

import {
  penanggungJawabCareConditionSchema,
  type PenanggungJawabCareConditionData,
} from "../schemas/penanggung-jawab-care-condition-schema";


export async function getPenanggungJawabCareCondition(
  query:
    PenanggungJawabCareConditionQuery,
): Promise<PenanggungJawabCareConditionData> {
  const supabase =
    await createClient();


  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_penanggung_jawab_care_condition_monitoring",
      {
        p_condition:
          query.condition,

        p_search:
          query.search,

        p_date:
          query.date,

        p_page:
          query.page,

        p_page_size:
          20,
      },
    );


  if (error) {
    throw new Error(
      `Gagal memuat kondisi Pengasuhan Penanggung Jawab: ${error.message}`,
    );
  }


  const validation =
    penanggungJawabCareConditionSchema.safeParse(
      data,
    );


  if (
    !validation.success
  ) {
    console.error(
      "Payload kondisi Pengasuhan PJ tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format data kondisi Pengasuhan Penanggung Jawab tidak valid.",
    );
  }


  return validation.data;
}