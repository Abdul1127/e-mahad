export type PengasuhStudentListSearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type PengasuhStudentListQuery = {
  search: string;
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

export function parsePengasuhStudentListQuery(
  searchParams:
    PengasuhStudentListSearchParams,
): PengasuhStudentListQuery {
  const search =
    firstValue(
      searchParams.q,
    )
      ?.trim()
      .slice(
        0,
        100,
      ) ?? "";

  return {
    search,
  };
}