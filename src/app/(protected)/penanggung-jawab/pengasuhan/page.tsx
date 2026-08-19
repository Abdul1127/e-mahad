import type {
  Metadata,
} from "next";

import {
  PenanggungJawabCareConditionMonitoring,
} from "@/features/penanggung-jawab/care-conditions/components/penanggung-jawab-care-condition-monitoring";

import {
  getPenanggungJawabCareCondition,
} from "@/features/penanggung-jawab/care-conditions/data/get-penanggung-jawab-care-condition";

import {
  parsePenanggungJawabCareConditionQuery,
  type PenanggungJawabCareConditionSearchParams,
} from "@/features/penanggung-jawab/care-conditions/lib/parse-penanggung-jawab-care-condition-query";

import {
  requireRole,
} from "@/lib/auth/guards";


export const metadata:
  Metadata = {
    title:
      "Kondisi Pengasuhan",

    description:
      "Monitoring kondisi Jurnal Pengasuhan untuk Penanggung Jawab E-Ma'had.",
  };


type Props = {
  searchParams:
    Promise<PenanggungJawabCareConditionSearchParams>;
};


export default async function PenanggungJawabCareConditionPage({
  searchParams,
}: Props) {
  await requireRole(
    "penanggung_jawab",
  );


  const query =
    parsePenanggungJawabCareConditionQuery(
      await searchParams,
    );


  const data =
    await getPenanggungJawabCareCondition(
      query,
    );


  return (
    <PenanggungJawabCareConditionMonitoring
      data={
        data
      }
    />
  );
}