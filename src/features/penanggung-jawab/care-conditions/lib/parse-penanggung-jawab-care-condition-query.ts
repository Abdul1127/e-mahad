import {
  penanggungJawabCareConditionFilterSchema,
  type PenanggungJawabCareConditionFilter,
} from "../schemas/penanggung-jawab-care-condition-schema";


export type PenanggungJawabCareConditionSearchParams =
  Record<
    string,
    string | string[] | undefined
  >;


export type PenanggungJawabCareConditionQuery = {
  condition:
    PenanggungJawabCareConditionFilter;

  search:
    string | null;

  date:
    string | null;

  page:
    number;
};


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


function validDate(
  value:
    string,
): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(
    value,
  );
}


function positiveInteger(
  value:
    string | undefined,
): number {
  const parsed =
    Number.parseInt(
      value ?? "",
      10,
    );

  return Number.isInteger(
    parsed,
  ) &&
    parsed > 0
    ? parsed
    : 1;
}


export function parsePenanggungJawabCareConditionQuery(
  searchParams:
    PenanggungJawabCareConditionSearchParams,
): PenanggungJawabCareConditionQuery {
  const conditionValidation =
    penanggungJawabCareConditionFilterSchema.safeParse(
      firstValue(
        searchParams.condition,
      )
        ?.trim()
        .toLowerCase(),
    );


  const rawSearch =
    firstValue(
      searchParams.search,
    )?.trim();


  const rawDate =
    firstValue(
      searchParams.date,
    )?.trim();


  return {
    condition:
      conditionValidation.success
        ? conditionValidation.data
        : "exception",

    search:
      rawSearch
        ? rawSearch.slice(
            0,
            100,
          )
        : null,

    date:
      rawDate &&
      validDate(
        rawDate,
      )
        ? rawDate
        : null,

    page:
      positiveInteger(
        firstValue(
          searchParams.page,
        ),
      ),
  };
}