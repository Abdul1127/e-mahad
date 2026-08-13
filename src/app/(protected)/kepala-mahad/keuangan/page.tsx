import type {
  Metadata,
} from "next";

import {
  KepalaMahadFinanceSummary,
} from "@/features/kepala-mahad/finance/components/kepala-mahad-finance-summary";

import {
  getKepalaMahadFinanceSummary,
} from "@/features/kepala-mahad/finance/data/get-kepala-mahad-finance-summary";

import {
  requireRole,
} from "@/lib/auth/guards";

export const metadata: Metadata = {
  title:
    "Ringkasan Keuangan",

  description:
    "Monitoring keuangan read-only untuk Kepala Ma'had.",
};

export default async function KepalaMahadFinancePage() {
  await requireRole(
    "kepala_mahad",
  );

  const data =
    await getKepalaMahadFinanceSummary();

  return (
    <KepalaMahadFinanceSummary
      data={
        data
      }
    />
  );
}