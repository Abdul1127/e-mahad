import {
  bendaharaBillFilterStatusSchema,
  type BendaharaBillFilterStatus,
} from "../schemas/bendahara-bill-list-schema";

const PAGE_SIZE = 20;

type SearchParams = {
  q?:
    | string
    | string[]
    | undefined;

  status?:
    | string
    | string[]
    | undefined;

  page?:
    | string
    | string[]
    | undefined;
};

export type BendaharaBillListQuery = {
  search:
    string | null;

  status:
    BendaharaBillFilterStatus | null;

  page:
    number;

  pageSize:
    number;
};

function firstValue(
  value:
    | string
    | string[]
    | undefined,
): string | undefined {
  if (
    Array.isArray(
      value,
    )
  ) {
    return value[0];
  }

  return value;
}

export function parseBendaharaBillListQuery(
  searchParams:
    SearchParams,
): BendaharaBillListQuery {
  const rawSearch =
    firstValue(
      searchParams.q,
    )
      ?.trim() ?? "";

  const rawStatus =
    firstValue(
      searchParams.status,
    )
      ?.trim()
      .toLowerCase() ?? "";

  const rawPage =
    firstValue(
      searchParams.page,
    );

  const parsedPage =
    Number.parseInt(
      rawPage ?? "1",
      10,
    );

  const page =
    Number.isFinite(
      parsedPage,
    ) &&
    parsedPage > 0
      ? parsedPage
      : 1;

  const statusValidation =
    bendaharaBillFilterStatusSchema
      .safeParse(
        rawStatus,
      );

  return {
    search:
      rawSearch.length > 0
        ? rawSearch
        : null,

    status:
      statusValidation.success
        ? statusValidation.data
        : null,

    page,

    pageSize:
      PAGE_SIZE,
  };
}