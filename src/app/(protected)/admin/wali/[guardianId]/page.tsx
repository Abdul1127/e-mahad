import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { AdminGuardianDetail } from "@/features/admin/guardians/components/admin-guardian-detail";
import { getAdminGuardianDetail } from "@/features/admin/guardians/data/get-admin-guardian-detail";
import { requireRole } from "@/lib/auth/guards";

export const metadata: Metadata = {
  title: "Detail Wali",
  description:
    "Detail orang tua atau wali E-Ma'had.",
};

type DetailGuardianSearchParams = {
  account?: string | string[];
};

type AdminGuardianDetailPageProps = {
  params: Promise<{
    guardianId: string;
  }>;

  searchParams: Promise<DetailGuardianSearchParams>;
};

function getFirstSearchParam(
  value: string | string[] | undefined,
): string | null {
  if (Array.isArray(value)) {
    return value[0] ?? null;
  }

  return value ?? null;
}

export default async function AdminGuardianDetailPage({
  params,
  searchParams,
}: AdminGuardianDetailPageProps) {
  await requireRole("admin");

  const { guardianId } = await params;
  const resolvedSearchParams =
    await searchParams;

  const accountMessage =
    getFirstSearchParam(
      resolvedSearchParams.account,
    );

  const data =
    await getAdminGuardianDetail(
      guardianId,
    );

  if (!data) {
    notFound();
  }

  return (
    <>
      {accountMessage ===
        "password-reset-success" && (
        <div className="mx-auto w-full max-w-[1480px] px-4 pt-6 sm:px-6 sm:pt-8 lg:px-8">
          <div
            role="status"
            className="rounded-2xl border border-brand-200 bg-brand-50 px-5 py-4 text-sm leading-6 text-brand-800 shadow-sm"
          >
            <p className="font-bold">
              Password akun berhasil
              diperbarui
            </p>

            <p className="mt-1">
              Wali harus menggunakan password
              yang baru ditetapkan pada proses
              login berikutnya.
            </p>
          </div>
        </div>
      )}

      <AdminGuardianDetail data={data} />
    </>
  );
}