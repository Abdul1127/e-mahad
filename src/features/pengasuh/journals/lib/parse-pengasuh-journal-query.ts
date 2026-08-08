export type PengasuhJournalSearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type PengasuhJournalQuery = {
  date: string;
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

function getCurrentJakartaDate(): string {
  return new Intl.DateTimeFormat(
    "en-CA",
    {
      timeZone:
        "Asia/Jakarta",

      year:
        "numeric",

      month:
        "2-digit",

      day:
        "2-digit",
    },
  ).format(
    new Date(),
  );
}

function isValidDateString(
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

export function parsePengasuhJournalQuery(
  searchParams:
    PengasuhJournalSearchParams,
): PengasuhJournalQuery {
  const rawDate =
    firstValue(
      searchParams.date,
    )?.trim();

  const date =
    rawDate &&
    isValidDateString(
      rawDate,
    )
      ? rawDate
      : getCurrentJakartaDate();

  return {
    date,
  };
}