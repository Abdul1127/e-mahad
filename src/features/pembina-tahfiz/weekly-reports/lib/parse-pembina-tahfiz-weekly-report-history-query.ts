export type PembinaTahfizWeeklyReportHistorySearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type PembinaTahfizWeeklyReportHistoryQuery = {
  status:
    | "draft"
    | "published"
    | null;

  search:
    string | null;

  page:
    number;

  limit:
    number;

  offset:
    number;
};

const PAGE_SIZE =
  20;

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

export function parsePembinaTahfizWeeklyReportHistoryQuery(
  searchParams:
    PembinaTahfizWeeklyReportHistorySearchParams,
): PembinaTahfizWeeklyReportHistoryQuery {
  const rawStatus =
    firstValue(
      searchParams.status,
    )?.trim()
      .toLowerCase();

  const status =
    rawStatus === "draft" ||
    rawStatus === "published"
      ? rawStatus
      : null;

  const rawSearch =
    firstValue(
      searchParams.search,
    )?.trim();

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
    status,

    search:
      rawSearch &&
      rawSearch.length > 0
        ? rawSearch
        : null,

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