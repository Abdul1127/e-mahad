import {
  z,
} from "zod";

import {
  GuardianPaymentHistory,
} from "@/features/guardian/finance/components/guardian-payment-history";

import {
  getGuardianPaymentHistoryData,
} from "@/features/guardian/finance/data/get-guardian-payment-history-data";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  searchParams:
    Promise<{
      student?:
        | string
        | string[];

      page?:
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

export default async function GuardianPaymentHistoryPage({
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

  const studentValidation =
    z.string()
      .uuid()
      .safeParse(
        rawStudent,
      );

  const studentId =
    studentValidation.success
      ? studentValidation.data
      : null;

  const rawPage =
    firstValue(
      params.page,
    );

  const parsedPage =
    Number.parseInt(
      rawPage ?? "1",
      10,
    );

  const page =
    Number.isFinite(
      parsedPage,
    ) &&
    parsedPage > 0
      ? parsedPage
      : 1;

  const data =
    await getGuardianPaymentHistoryData({
      studentId,

      page,

      pageSize:
        20,
    });

  return (
    <GuardianPaymentHistory
      data={
        data
      }
    />
  );
}