import {
  notFound,
} from "next/navigation";

import {
  z,
} from "zod";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  BendaharaBillDetail,
} from "@/features/bendahara/bills/components/bendahara-bill-detail";

import {
  getBendaharaBillDetailData,
} from "@/features/bendahara/bills/data/get-bendahara-bill-detail-data";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  params:
    Promise<{
      role: string;
      billId: string;
    }>;
};

export default async function BendaharaBillDetailPage({
  params,
}: PageProps) {
  const {
    role,
    billId,
  } = await params;

  const roleCode =
    getRoleCodeBySlug(
      role,
    );

  if (
    roleCode !==
    "bendahara"
  ) {
    notFound();
  }

  const billIdValidation =
    z.string()
      .uuid()
      .safeParse(
        billId,
      );

  if (
    !billIdValidation.success
  ) {
    notFound();
  }

  await requireRole(
    "bendahara",
  );

  const data =
    await getBendaharaBillDetailData(
      billIdValidation.data,
    );

  return (
    <BendaharaBillDetail
      data={data}
    />
  );
}