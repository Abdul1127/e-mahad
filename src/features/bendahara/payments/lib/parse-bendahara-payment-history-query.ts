import {
  bendaharaPaymentMethodSchema,
  bendaharaPaymentStatusSchema,
  type BendaharaPaymentMethod,
  type BendaharaPaymentStatus,
} from "../schemas/bendahara-payment-history-schema";

const PAGE_SIZE =
  20;

type SearchParams = {
  q?:
    | string
    | string[]
    | undefined;

  status?:
    | string
    | string[]
    | undefined;

  method?:
    | string
    | string[]
    | undefined;

  page?:
    | string
    | string[]
    | undefined;
};

export type BendaharaPaymentHistoryQuery = {
  search:
    string | null;

  status:
    BendaharaPaymentStatus | null;

  method:
    BendaharaPaymentMethod | null;

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

export function parseBendaharaPaymentHistoryQuery(
  searchParams:
    SearchParams,
): BendaharaPaymentHistoryQuery {
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

  const rawMethod =
    firstValue(
      searchParams.method,
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
    bendaharaPaymentStatusSchema.safeParse(
      rawStatus,
    );

  const methodValidation =
    bendaharaPaymentMethodSchema.safeParse(
      rawMethod,
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

    method:
      methodValidation.success
        ? methodValidation.data
        : null,

    page,

    pageSize:
      PAGE_SIZE,
  };
}