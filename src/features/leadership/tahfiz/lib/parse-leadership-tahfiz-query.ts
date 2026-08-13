import {
  z,
} from "zod";

export type LeadershipTahfizSearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type LeadershipTahfizQuery = {
  weekStart:
    string | null;

  search:
    string | null;

  groupId:
    string | null;

  page:
    number;

  pageSize:
    number;
};

const uuidSchema =
  z.string().uuid();

function firstValue(
  value:
    | string
    | string[]
    | undefined,
): string | undefined {
  return Array.isArray(
    value,
  )
    ? value[0]
    : value;
}

function parsePositiveInteger(
  value:
    string | undefined,
): number | null {
  if (!value) {
    return null;
  }

  const parsed =
    Number.parseInt(
      value,
      10,
    );

  if (
    !Number.isInteger(
      parsed,
    ) ||
    parsed <= 0
  ) {
    return null;
  }

  return parsed;
}

function isValidDate(
  value:
    string,
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
  ] =
    value
      .split("-")
      .map(
        Number,
      );

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
  value:
    string,
): boolean {
  if (
    !isValidDate(
      value,
    )
  ) {
    return false;
  }

  return (
    new Date(
      `${value}T00:00:00Z`,
    ).getUTCDay() ===
    1
  );
}

export function parseLeadershipTahfizQuery(
  searchParams:
    LeadershipTahfizSearchParams,
): LeadershipTahfizQuery {
  const rawWeek =
    firstValue(
      searchParams.week,
    )?.trim();

  const rawSearch =
    firstValue(
      searchParams.search,
    )?.trim();

  const rawGroup =
    firstValue(
      searchParams.group,
    )?.trim();

  const rawPage =
    firstValue(
      searchParams.page,
    )?.trim();

  const groupValidation =
    rawGroup
      ? uuidSchema.safeParse(
          rawGroup,
        )
      : null;

  return {
    weekStart:
      rawWeek &&
      isMonday(
        rawWeek,
      )
        ? rawWeek
        : null,

    search:
      rawSearch &&
      rawSearch.length >
        0
        ? rawSearch
        : null,

    groupId:
      groupValidation
        ?.success
        ? groupValidation.data
        : null,

    page:
      parsePositiveInteger(
        rawPage,
      ) ?? 1,

    pageSize:
      20,
  };
}