import {
  z,
} from "zod";

import {
  GuardianBillList,
} from "@/features/guardian/finance/components/guardian-bill-list";

import {
  getGuardianBillListData,
} from "@/features/guardian/finance/data/get-guardian-bill-list-data";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  searchParams:
    Promise<{
      student?:
        | string
        | string[];
    }>;
};

function firstValue(
  value:
    | string
    | string[]
    | undefined,
): string | undefined {
  if (
    Array.isArray(
      value,
    )
  ) {
    return value[0];
  }

  return value;
}

export default async function GuardianBillPage({
  searchParams,
}: PageProps) {
  await requireRole(
    "guardian",
  );

  const params =
    await searchParams;

  const rawStudent =
    firstValue(
      params.student,
    );

  const validation =
    z.string()
      .uuid()
      .safeParse(
        rawStudent,
      );

  const studentId =
    validation.success
      ? validation.data
      : null;

  const data =
    await getGuardianBillListData(
      studentId,
    );

  return (
    <GuardianBillList
      data={
        data
      }
    />
  );
}