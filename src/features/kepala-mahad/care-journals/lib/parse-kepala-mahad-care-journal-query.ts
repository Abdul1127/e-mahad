import type {
  KepalaMahadCareJournalStatus,
} from "../schemas/kepala-mahad-care-journal-overview-schema";

export type KepalaMahadCareJournalSearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type KepalaMahadCareJournalQuery = {
  status:
    KepalaMahadCareJournalStatus | null;

  date:
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

export function parseKepalaMahadCareJournalQuery(
  searchParams:
    KepalaMahadCareJournalSearchParams,
): KepalaMahadCareJournalQuery {
  const rawStatus =
    firstValue(
      searchParams.status,
    )
      ?.trim()
      .toLowerCase();

  const allowedStatuses =
    new Set([
      "draft",
      "submitted",
      "revision_requested",
      "reviewed",
    ]);

  const status =
    rawStatus === "all"
      ? null
      : rawStatus &&
          allowedStatuses.has(
            rawStatus,
          )
        ? rawStatus as KepalaMahadCareJournalStatus
        : "submitted";

  const rawDate =
    firstValue(
      searchParams.date,
    )?.trim();

  const date =
    rawDate &&
    isValidDate(
      rawDate,
    )
      ? rawDate
      : null;

  return {
    status,
    date,
  };
}