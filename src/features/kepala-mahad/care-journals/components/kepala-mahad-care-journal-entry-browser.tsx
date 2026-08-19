"use client";

import {
  useMemo,
  useState,
} from "react";

import type {
  KepalaMahadCareJournalEntry,
} from "../schemas/kepala-mahad-care-journal-detail-schema";


const PAGE_SIZE =
  10;


type ConditionFilter =
  | "all"
  | "exception"
  | "attention"
  | "unwell"
  | "needs_reminder"
  | "psychological"
  | "case_notes"
  | "parent_visit"
  | "normal";


type Props = {
  entries:
    KepalaMahadCareJournalEntry[];
};


function readable(
  value:
    string | boolean | null,
): string {
  switch (value) {
    case "healthy":
      return "Sehat";

    case "unwell":
      return "Kurang Fit";

    case "on_time":
      return "Tepat Waktu";

    case "needs_reminder":
      return "Perlu Teguran";

    case "cheerful":
      return "Ceria";

    case "gloomy":
      return "Murung";

    case "quiet":
      return "Pendiam";

    case "homesick":
      return "Homesick";

    case "emotional":
      return "Emosional";

    case true:
      return "Ada";

    case false:
      return "Tidak Ada";

    default:
      return "-";
  }
}


function hasText(
  value:
    string | null,
): boolean {
  return Boolean(
    value?.trim(),
  );
}


function isNormal(
  entry:
    KepalaMahadCareJournalEntry,
): boolean {
  return (
    entry.health_condition ===
      "healthy" &&
    entry.sleep_compliance ===
      "on_time" &&
    entry.psychological_condition ===
      "cheerful" &&
    entry.parent_visit ===
      false &&
    !hasText(
      entry.case_notes,
    ) &&
    !hasText(
      entry.handling_notes,
    )
  );
}


function needsAttention(
  entry:
    KepalaMahadCareJournalEntry,
): boolean {
  return (
    entry.health_condition ===
      "unwell" ||
    entry.sleep_compliance ===
      "needs_reminder" ||
    (
      entry.psychological_condition !==
        null &&
      entry.psychological_condition !==
        "cheerful"
    ) ||
    hasText(
      entry.case_notes,
    ) ||
    hasText(
      entry.handling_notes,
    )
  );
}


function matchesFilter(
  entry:
    KepalaMahadCareJournalEntry,

  filter:
    ConditionFilter,
): boolean {
  switch (filter) {
    case "all":
      return true;

    case "exception":
      return !isNormal(
        entry,
      );

    case "attention":
      return needsAttention(
        entry,
      );

    case "unwell":
      return (
        entry.health_condition ===
        "unwell"
      );

    case "needs_reminder":
      return (
        entry.sleep_compliance ===
        "needs_reminder"
      );

    case "psychological":
      return (
        entry.psychological_condition !==
          null &&
        entry.psychological_condition !==
          "cheerful"
      );

    case "case_notes":
      return (
        hasText(
          entry.case_notes,
        ) ||
        hasText(
          entry.handling_notes,
        )
      );

    case "parent_visit":
      return (
        entry.parent_visit ===
        true
      );

    case "normal":
      return isNormal(
        entry,
      );
  }
}


function normalized(
  value:
    string,
): string {
  return value
    .trim()
    .toLocaleLowerCase(
      "id-ID",
    );
}


export function KepalaMahadCareJournalEntryBrowser({
  entries,
}: Props) {
  const [
    search,
    setSearch,
  ] =
    useState(
      "",
    );

  const [
    filter,
    setFilter,
  ] =
    useState<ConditionFilter>(
      "exception",
    );

  const [
    page,
    setPage,
  ] =
    useState(
      1,
    );


  const filteredEntries =
    useMemo(
      () => {
        const searchValue =
          normalized(
            search,
          );

        return entries.filter(
          (
            entry,
          ) => {
            if (
              !matchesFilter(
                entry,
                filter,
              )
            ) {
              return false;
            }

            if (
              !searchValue
            ) {
              return true;
            }

            return [
              entry.full_name,
              entry.nis ?? "",
              entry.legacy_student_id ??
                "",
            ].some(
              (
                value,
              ) =>
                normalized(
                  value,
                ).includes(
                  searchValue,
                ),
            );
          },
        );
      },
      [
        entries,
        filter,
        search,
      ],
    );


  const summary =
    useMemo(
      () => ({
        total:
          entries.length,

        exception:
          entries.filter(
            (
              entry,
            ) =>
              !isNormal(
                entry,
              ),
          ).length,

        attention:
          entries.filter(
            needsAttention,
          ).length,

        unwell:
          entries.filter(
            (
              entry,
            ) =>
              entry.health_condition ===
              "unwell",
          ).length,

        normal:
          entries.filter(
            isNormal,
          ).length,
      }),
      [
        entries,
      ],
    );


  const totalPages =
    Math.max(
      1,
      Math.ceil(
        filteredEntries.length /
          PAGE_SIZE,
      ),
    );


  const safePage =
    Math.min(
      page,
      totalPages,
    );


  const start =
    (
      safePage -
      1
    ) *
    PAGE_SIZE;


  const visibleEntries =
    filteredEntries.slice(
      start,
      start +
        PAGE_SIZE,
    );


  function resetPage() {
    setPage(
      1,
    );
  }


  return (
    <div className="mt-5">
      <section className="grid gap-3 sm:grid-cols-2 xl:grid-cols-5">
        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs text-muted">
            Total
          </p>

          <p className="mt-1 text-2xl font-bold text-ink">
            {
              summary.total
            }
          </p>
        </div>

        <div className="rounded-2xl bg-amber-50 p-4">
          <p className="text-xs text-amber-700">
            Berbeda dari Normal
          </p>

          <p className="mt-1 text-2xl font-bold text-amber-900">
            {
              summary.exception
            }
          </p>
        </div>

        <div className="rounded-2xl bg-red-50 p-4">
          <p className="text-xs text-red-700">
            Perlu Perhatian
          </p>

          <p className="mt-1 text-2xl font-bold text-red-900">
            {
              summary.attention
            }
          </p>
        </div>

        <div className="rounded-2xl bg-orange-50 p-4">
          <p className="text-xs text-orange-700">
            Kurang Fit
          </p>

          <p className="mt-1 text-2xl font-bold text-orange-900">
            {
              summary.unwell
            }
          </p>
        </div>

        <div className="rounded-2xl bg-emerald-50 p-4">
          <p className="text-xs text-emerald-700">
            Normal
          </p>

          <p className="mt-1 text-2xl font-bold text-emerald-900">
            {
              summary.normal
            }
          </p>
        </div>
      </section>


      <section className="mt-5 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <div className="grid gap-4 lg:grid-cols-[minmax(0,1fr)_300px]">
          <div>
            <label
              htmlFor="care-student-search"
              className="mb-2 block text-xs font-semibold text-slate-500"
            >
              Cari Santri
            </label>

            <input
              id="care-student-search"
              type="search"
              value={
                search
              }
              onChange={(
                event,
              ) => {
                setSearch(
                  event.target.value,
                );

                resetPage();
              }}
              placeholder="Cari nama, NIS, atau ID santri..."
              className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
            />
          </div>


          <div>
            <label
              htmlFor="care-condition-filter"
              className="mb-2 block text-xs font-semibold text-slate-500"
            >
              Filter Kondisi
            </label>

            <select
              id="care-condition-filter"
              value={
                filter
              }
              onChange={(
                event,
              ) => {
                setFilter(
                  event.target
                    .value as ConditionFilter,
                );

                resetPage();
              }}
              className="min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink"
            >
              <option value="all">
                Semua Kondisi
              </option>

              <option value="exception">
                Berbeda dari Normal
              </option>

              <option value="attention">
                Perlu Perhatian
              </option>

              <option value="unwell">
                Kurang Fit
              </option>

              <option value="needs_reminder">
                Perlu Teguran
              </option>

              <option value="psychological">
                Kondisi Psikologis
              </option>

              <option value="case_notes">
                Ada Catatan / Kejadian
              </option>

              <option value="parent_visit">
                Ada Kunjungan Orang Tua
              </option>

              <option value="normal">
                Normal
              </option>
            </select>
          </div>
        </div>


        <div className="mt-4 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
          <p className="text-sm font-semibold text-ink">
            {
              filteredEntries.length
            }{" "}
            santri ditemukan
          </p>

          {(search ||
            filter !==
              "exception") && (
            <button
              type="button"
              onClick={() => {
                setSearch(
                  "",
                );

                setFilter(
                  "exception",
                );

                setPage(
                  1,
                );
              }}
              className="w-fit text-sm font-semibold text-brand-700 hover:text-brand-800"
            >
              Reset Filter
            </button>
          )}
        </div>
      </section>


      {visibleEntries.length ===
      0 ? (
        <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-8 text-center">
          <p className="font-semibold text-ink">
            Tidak ada santri yang
            sesuai filter.
          </p>
        </div>
      ) : (
        <div className="mt-5 space-y-3">
          {visibleEntries.map(
            (
              entry,
            ) => {
              const normal =
                isNormal(
                  entry,
                );

              const attention =
                needsAttention(
                  entry,
                );

              return (
                <article
                  key={
                    entry.id
                  }
                  className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5"
                >
                  <div className="flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between">
                    <div>
                      <p className="font-bold text-ink">
                        {
                          entry.full_name
                        }
                      </p>

                      <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-400">
                        {entry.nis && (
                          <span>
                            NIS{" "}
                            {
                              entry.nis
                            }
                          </span>
                        )}

                        {entry.legacy_student_id && (
                          <span>
                            ID{" "}
                            {
                              entry.legacy_student_id
                            }
                          </span>
                        )}

                        {entry.class && (
                          <span>
                            Kelas{" "}
                            {
                              entry.class
                                .name
                            }
                          </span>
                        )}
                      </div>
                    </div>


                    <div className="flex flex-wrap gap-2">
                      {normal && (
                        <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                          Normal
                        </span>
                      )}

                      {attention && (
                        <span className="rounded-full bg-red-50 px-2.5 py-1 text-xs font-semibold text-red-700">
                          Perlu Perhatian
                        </span>
                      )}

                      {entry.parent_visit ===
                        true && (
                        <span className="rounded-full bg-blue-50 px-2.5 py-1 text-xs font-semibold text-blue-700">
                          Ada Kunjungan
                        </span>
                      )}
                    </div>
                  </div>


                  <div className="mt-4 grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
                    <div className={
                      entry.health_condition ===
                      "unwell"
                        ? "rounded-xl bg-red-50 p-3"
                        : "rounded-xl bg-slate-50 p-3"
                    }>
                      <p className="text-xs text-muted">
                        Kesehatan
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.health_condition,
                        )}
                      </p>
                    </div>

                    <div className={
                      entry.sleep_compliance ===
                      "needs_reminder"
                        ? "rounded-xl bg-amber-50 p-3"
                        : "rounded-xl bg-slate-50 p-3"
                    }>
                      <p className="text-xs text-muted">
                        Jam Tidur
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.sleep_compliance,
                        )}
                      </p>
                    </div>

                    <div className={
                      entry.psychological_condition !==
                        null &&
                      entry.psychological_condition !==
                        "cheerful"
                        ? "rounded-xl bg-amber-50 p-3"
                        : "rounded-xl bg-slate-50 p-3"
                    }>
                      <p className="text-xs text-muted">
                        Psikologis
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.psychological_condition,
                        )}
                      </p>
                    </div>

                    <div className="rounded-xl bg-slate-50 p-3">
                      <p className="text-xs text-muted">
                        Kunjungan Orang Tua
                      </p>

                      <p className="mt-1 text-sm font-semibold text-ink">
                        {readable(
                          entry.parent_visit,
                        )}
                      </p>
                    </div>
                  </div>


                  {(hasText(
                    entry.case_notes,
                  ) ||
                    hasText(
                      entry.handling_notes,
                    )) && (
                    <div className="mt-4 grid gap-3 lg:grid-cols-2">
                      <div className="rounded-xl border border-amber-100 bg-amber-50 p-4">
                        <p className="text-xs font-semibold text-amber-700">
                          Kasus / Kejadian
                        </p>

                        <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-amber-900">
                          {entry.case_notes ??
                            "-"}
                        </p>
                      </div>

                      <div className="rounded-xl border border-brand-100 bg-brand-50 p-4">
                        <p className="text-xs font-semibold text-brand-700">
                          Penanganan
                        </p>

                        <p className="mt-2 whitespace-pre-wrap text-sm leading-6 text-brand-900">
                          {entry.handling_notes ??
                            "-"}
                        </p>
                      </div>
                    </div>
                  )}
                </article>
              );
            },
          )}
        </div>
      )}


      {filteredEntries.length >
        PAGE_SIZE && (
        <section className="mt-6 flex flex-col gap-3 rounded-2xl border border-line bg-white p-4 shadow-soft sm:flex-row sm:items-center sm:justify-between">
          <button
            type="button"
            disabled={
              safePage <=
              1
            }
            onClick={() =>
              setPage(
                Math.max(
                  1,
                  safePage -
                    1,
                ),
              )
            }
            className="min-h-10 rounded-xl border border-line px-4 text-sm font-semibold text-slate-700 disabled:opacity-40"
          >
            ← Sebelumnya
          </button>

          <p className="text-center text-sm font-semibold text-slate-600">
            Halaman{" "}
            {
              safePage
            }{" "}
            dari{" "}
            {
              totalPages
            }
          </p>

          <button
            type="button"
            disabled={
              safePage >=
              totalPages
            }
            onClick={() =>
              setPage(
                Math.min(
                  totalPages,
                  safePage +
                    1,
                ),
              )
            }
            className="min-h-10 rounded-xl border border-line px-4 text-sm font-semibold text-slate-700 disabled:opacity-40"
          >
            Berikutnya →
          </button>
        </section>
      )}
    </div>
  );
}