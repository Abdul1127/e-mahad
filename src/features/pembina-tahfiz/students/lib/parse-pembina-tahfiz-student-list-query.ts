export type PembinaTahfizStudentListSearchParams =
  Record<
    string,
    string | string[] | undefined
  >;

export type PembinaTahfizStudentListQuery = {
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

export function parsePembinaTahfizStudentListQuery(
  searchParams:
    PembinaTahfizStudentListSearchParams,
): PembinaTahfizStudentListQuery {
  const rawSearch =
    firstValue(
      searchParams.search,
    )?.trim();

  return {
    search:
      rawSearch &&
      rawSearch.length > 0
        ? rawSearch
        : null,
  };
}