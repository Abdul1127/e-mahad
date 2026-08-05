import { z } from "zod";

import type { StudentGender } from "../schemas/admin-student-list-schema";

export type StudentListSearchParams = Record<
  string,
  string | string[] | undefined
>;

export type AdminStudentListQuery = {
  search: string;
  gradeLevel: number | null;
  gender: StudentGender | null;
  careGroupId: string | null;
  tahfizGroupId: string | null;
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

  const parsedValue = Number.parseInt(
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

function parseUuid(
  value: string | undefined,
): string | null {
  if (!value) {
    return null;
  }

  const validationResult = z
    .string()
    .uuid()
    .safeParse(value);

  return validationResult.success
    ? validationResult.data
    : null;
}

function parseGender(
  value: string | undefined,
): StudentGender | null {
  if (
    value === "male" ||
    value === "female"
  ) {
    return value;
  }

  return null;
}

export function parseStudentListQuery(
  searchParams: StudentListSearchParams,
): AdminStudentListQuery {
  const rawSearch =
    firstValue(searchParams.q)?.trim() ?? "";

  const search = rawSearch.slice(0, 100);

  const gradeLevel = parsePositiveInteger(
    firstValue(searchParams.grade),
  );

  const page =
    parsePositiveInteger(
      firstValue(searchParams.page),
    ) ?? 1;

  return {
    search,
    gradeLevel,

    gender: parseGender(
      firstValue(searchParams.gender),
    ),

    careGroupId: parseUuid(
      firstValue(searchParams.care_group),
    ),

    tahfizGroupId: parseUuid(
      firstValue(
        searchParams.tahfiz_group,
      ),
    ),

    page,
    pageSize: 20,
  };
}