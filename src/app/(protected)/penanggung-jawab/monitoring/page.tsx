import type {
  Metadata,
} from "next";

import {
  PenanggungJawabDormitoryMonitoring,
} from "@/features/penanggung-jawab/monitoring/components/penanggung-jawab-dormitory-monitoring";

import {
  getPenanggungJawabDormitoryMonitoring,
} from "@/features/penanggung-jawab/monitoring/data/get-penanggung-jawab-dormitory-monitoring";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Monitoring Asrama",

  description:
    "Monitoring operasional asrama untuk Penanggung Jawab E-Ma'had.",
};

export default async function PenanggungJawabMonitoringPage() {
  await requireRole(
    "penanggung_jawab",
  );

  const data =
    await getPenanggungJawabDormitoryMonitoring();

  return (
    <PenanggungJawabDormitoryMonitoring
      data={
        data
      }
    />
  );
}