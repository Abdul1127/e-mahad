import type { StaffAccountStatus } from "../schemas/admin-staff-list-schema";

export type StaffListSearchParams = Record<
  string,
  string | string[] | undefined
>;

export type AdminStaffListQuery = {
  search: string;
  isActive: boolean | null;

  accountStatus:
    StaffAccountStatus | null;

  roleCode: string | null;

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
    Number.parseInt(
      value,
      10,
    );

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
): StaffAccountStatus | null {
  if (
    value === "linked" ||
    value === "unlinked"
  ) {
    return value;
  }

  return null;
}

function parseRoleCode(
  value: string | undefined,
): string | null {
  const normalizedValue =
    value
      ?.trim()
      .toLowerCase()
      .slice(0, 100);

  return normalizedValue || null;
}

export function parseStaffListQuery(
  searchParams: StaffListSearchParams,
): AdminStaffListQuery {
  const search =
    firstValue(
      searchParams.q,
    )
      ?.trim()
      .slice(0, 100) ?? "";

  const page =
    parsePositiveInteger(
      firstValue(
        searchParams.page,
      ),
    ) ?? 1;

  return {
    search,

    isActive:
      parseActiveStatus(
        firstValue(
          searchParams.status,
        ),
      ),

    accountStatus:
      parseAccountStatus(
        firstValue(
          searchParams.account,
        ),
      ),

    roleCode:
      parseRoleCode(
        firstValue(
          searchParams.role,
        ),
      ),

    page,
    pageSize: 20,
  };
}