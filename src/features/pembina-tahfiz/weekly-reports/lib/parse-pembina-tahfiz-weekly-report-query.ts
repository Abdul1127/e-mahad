export type PembinaTahfizWeeklyReportSearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type PembinaTahfizWeeklyReportQuery = {
  weekStart:
    string | null;

  search:
    string | null;
};

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

function isValidDate(
  value: string,
): boolean {
  if (
    !/^\d{4}-\d{2}-\d{2}$/.test(
      value,
    )
  ) {
    return false;
  }

  const [
    year,
    month,
    day,
  ] = value
    .split("-")
    .map(Number);

  const date =
    new Date(
      Date.UTC(
        year,
        month - 1,
        day,
      ),
    );

  return (
    date.getUTCFullYear() ===
      year &&
    date.getUTCMonth() ===
      month - 1 &&
    date.getUTCDate() ===
      day
  );
}

function isMonday(
  value: string,
): boolean {
  if (
    !isValidDate(
      value,
    )
  ) {
    return false;
  }

  const date =
    new Date(
      `${value}T00:00:00Z`,
    );

  return (
    date.getUTCDay() === 1
  );
}

export function parsePembinaTahfizWeekStart(
  value:
    | string
    | string[]
    | undefined,
): string | null {
  const rawValue =
    firstValue(
      value,
    )?.trim();

  if (
    !rawValue ||
    !isMonday(
      rawValue,
    )
  ) {
    return null;
  }

  return rawValue;
}

export function parsePembinaTahfizWeeklyReportQuery(
  searchParams:
    PembinaTahfizWeeklyReportSearchParams,
): PembinaTahfizWeeklyReportQuery {
  const rawSearch =
    firstValue(
      searchParams.search,
    )?.trim();

  return {
    weekStart:
      parsePembinaTahfizWeekStart(
        searchParams.week,
      ),

    search:
      rawSearch &&
      rawSearch.length > 0
        ? rawSearch
        : null,
  };
}