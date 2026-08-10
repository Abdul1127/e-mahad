export type GuardianTahfizReportHistorySearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type GuardianTahfizReportHistoryQuery = {
  page: number;
  limit: number;
  offset: number;
};

const PAGE_SIZE =
  10;

function firstValue(
  value:
    | string
    | string[]
    | undefined,
): string | undefined {
  return Array.isArray(value)
    ? value[0]
    : value;
}

export function parseGuardianTahfizReportHistoryQuery(
  searchParams:
    GuardianTahfizReportHistorySearchParams,
): GuardianTahfizReportHistoryQuery {
  const rawPage =
    Number(
      firstValue(
        searchParams.page,
      ) ?? "1",
    );

  const page =
    Number.isInteger(
      rawPage,
    ) &&
    rawPage > 0
      ? rawPage
      : 1;

  return {
    page,

    limit:
      PAGE_SIZE,

    offset:
      (
        page - 1
      ) *
      PAGE_SIZE,
  };
}