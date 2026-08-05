import type { GuardianAccountStatus } from "../schemas/admin-guardian-list-schema";

export type GuardianListSearchParams = Record<
  string,
  string | string[] | undefined
>;

export type AdminGuardianListQuery = {
  search: string;
  isActive: boolean | null;
  accountStatus:
    GuardianAccountStatus | null;
  page: number;
  pageSize: number;
};

function firstValue(
  value: string | string[] | undefined,
): string | undefined {
  return Array.isArray(value)
    ? value[0]
    : value;
}

function parsePositiveInteger(
  value: string | undefined,
): number | null {
  if (!value) {
    return null;
  }

  const parsedValue =
    Number.parseInt(value, 10);

  if (
    !Number.isInteger(parsedValue) ||
    parsedValue <= 0
  ) {
    return null;
  }

  return parsedValue;
}

function parseActiveStatus(
  value: string | undefined,
): boolean | null {
  if (value === "active") {
    return true;
  }

  if (value === "inactive") {
    return false;
  }

  return null;
}

function parseAccountStatus(
  value: string | undefined,
): GuardianAccountStatus | null {
  if (
    value === "linked" ||
    value === "unlinked"
  ) {
    return value;
  }

  return null;
}

export function parseGuardianListQuery(
  searchParams: GuardianListSearchParams,
): AdminGuardianListQuery {
  const search =
    firstValue(searchParams.q)
      ?.trim()
      .slice(0, 100) ?? "";

  const page =
    parsePositiveInteger(
      firstValue(searchParams.page),
    ) ?? 1;

  return {
    search,

    isActive: parseActiveStatus(
      firstValue(searchParams.status),
    ),

    accountStatus: parseAccountStatus(
      firstValue(searchParams.account),
    ),

    page,
    pageSize: 20,
  };
}