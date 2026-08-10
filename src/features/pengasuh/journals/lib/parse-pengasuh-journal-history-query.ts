import type {
  CareJournalSession,
  CareJournalStatus,
} from "../schemas/pengasuh-journal-overview-schema";

export type PengasuhJournalHistorySearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type PengasuhJournalHistoryQuery = {
  status:
    CareJournalStatus | null;

  session:
    CareJournalSession | null;

  date:
    string | null;

  page:
    number;

  limit:
    number;

  offset:
    number;
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

export function parsePengasuhJournalHistoryQuery(
  searchParams:
    PengasuhJournalHistorySearchParams,
): PengasuhJournalHistoryQuery {
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
    rawStatus &&
    rawStatus !== "all" &&
    allowedStatuses.has(
      rawStatus,
    )
      ? rawStatus as CareJournalStatus
      : null;

  const rawSession =
    firstValue(
      searchParams.session,
    )
      ?.trim()
      .toLowerCase();

  const allowedSessions =
    new Set([
      "morning",
      "evening",
    ]);

  const session =
    rawSession &&
    rawSession !== "all" &&
    allowedSessions.has(
      rawSession,
    )
      ? rawSession as CareJournalSession
      : null;

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

  const limit =
    20;

  return {
    status,
    session,
    date,
    page,
    limit,
    offset:
      (page - 1) *
      limit,
  };
}