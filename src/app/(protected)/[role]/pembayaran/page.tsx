import {
  notFound,
} from "next/navigation";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  BendaharaPaymentHistory,
} from "@/features/bendahara/payments/components/bendahara-payment-history";

import {
  getBendaharaPaymentHistoryData,
} from "@/features/bendahara/payments/data/get-bendahara-payment-history-data";

import {
  parseBendaharaPaymentHistoryQuery,
} from "@/features/bendahara/payments/lib/parse-bendahara-payment-history-query";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  params:
    Promise<{
      role:
        string;
    }>;

  searchParams:
    Promise<{
      q?:
        | string
        | string[];

      status?:
        | string
        | string[];

      method?:
        | string
        | string[];

      page?:
        | string
        | string[];
    }>;
};

export default async function BendaharaPaymentHistoryPage({
  params,
  searchParams,
}: PageProps) {
  const {
    role,
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

  await requireRole(
    "bendahara",
  );

  const query =
    parseBendaharaPaymentHistoryQuery(
      await searchParams,
    );

  const data =
    await getBendaharaPaymentHistoryData({
      search:
        query.search,

      status:
        query.status,

      method:
        query.method,

      page:
        query.page,

      pageSize:
        query.pageSize,
    });

  return (
    <BendaharaPaymentHistory
      data={
        data
      }
      search={
        query.search
      }
      status={
        query.status
      }
      method={
        query.method
      }
    />
  );
}