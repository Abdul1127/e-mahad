import {
  notFound,
} from "next/navigation";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  BendaharaBillList,
} from "@/features/bendahara/bills/components/bendahara-bill-list";

import {
  getBendaharaBillListData,
} from "@/features/bendahara/bills/data/get-bendahara-bill-list-data";

import {
  parseBendaharaBillListQuery,
} from "@/features/bendahara/bills/lib/parse-bendahara-bill-list-query";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  params:
    Promise<{
      role: string;
    }>;

  searchParams:
    Promise<{
      q?:
        | string
        | string[];

      status?:
        | string
        | string[];

      page?:
        | string
        | string[];
    }>;
};

export default async function BendaharaBillListPage({
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
    parseBendaharaBillListQuery(
      await searchParams,
    );

  const data =
    await getBendaharaBillListData({
      search:
        query.search,

      status:
        query.status,

      page:
        query.page,

      pageSize:
        query.pageSize,
    });

  return (
    <BendaharaBillList
      data={data}
      search={
        query.search
      }
      status={
        query.status
      }
    />
  );
}