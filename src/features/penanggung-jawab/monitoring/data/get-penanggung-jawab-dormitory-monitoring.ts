import "server-only";

import {
  createClient,
} from "@/lib/supabase/server";

import {
  penanggungJawabDormitoryMonitoringSchema,
  type PenanggungJawabDormitoryMonitoringData,
} from "../schemas/penanggung-jawab-dormitory-monitoring-schema";

export async function getPenanggungJawabDormitoryMonitoring(): Promise<PenanggungJawabDormitoryMonitoringData> {
  const supabase =
    await createClient();

  const {
    data,
    error,
  } =
    await supabase.rpc(
      "get_penanggung_jawab_dormitory_monitoring",
    );

  if (error) {
    throw new Error(
      `Gagal memuat Monitoring Asrama Penanggung Jawab: ${error.message}`,
    );
  }

  const validation =
    penanggungJawabDormitoryMonitoringSchema.safeParse(
      data,
    );

  if (
    !validation.success
  ) {
    console.error(
      "Payload Monitoring Asrama Penanggung Jawab tidak valid:",
      validation.error.flatten(),
    );

    throw new Error(
      "Format data Monitoring Asrama Penanggung Jawab tidak valid.",
    );
  }

  return validation.data;
}