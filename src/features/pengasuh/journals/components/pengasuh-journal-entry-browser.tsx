"use client";

import {
  useMemo,
  useState,
} from "react";

import type {
  PengasuhJournalEntry,
} from "../schemas/pengasuh-journal-detail-schema";

import {
  FillNormalPengasuhJournalButton,
} from "./fill-normal-pengasuh-journal-button";

import {
  PengasuhJournalEntryForm,
} from "./pengasuh-journal-entry-form";


const PAGE_SIZE =
  10;


type PengasuhJournalEntryBrowserProps = {
  journalId:
    string;

  entries:
    PengasuhJournalEntry[];

  incompleteCount:
    number;

  disabled:
    boolean;
};


function normalizeSearch(
  value:
    string,
): string {
  return value
    .trim()
    .toLocaleLowerCase(
      "id-ID",
    );
}


export function PengasuhJournalEntryBrowser({
  journalId,
  entries,
  incompleteCount,
  disabled,
}: PengasuhJournalEntryBrowserProps) {
  const [
    searchQuery,
    setSearchQuery,
  ] =
    useState(
      "",
    );

  const [
    currentPage,
    setCurrentPage,
  ] =
    useState(
      1,
    );


  const normalizedSearch =
    normalizeSearch(
      searchQuery,
    );


  const filteredEntries =
    useMemo(
      () => {
        if (
          !normalizedSearch
        ) {
          return entries;
        }

        return entries.filter(
          (
            entry,
          ) =>
            normalizeSearch(
              entry.full_name,
            ).includes(
              normalizedSearch,
            ),
        );
      },
      [
        entries,
        normalizedSearch,
      ],
    );


  const totalResults =
    filteredEntries.length;


  const totalPages =
    Math.max(
      1,
      Math.ceil(
        totalResults /
          PAGE_SIZE,
      ),
    );


  const safeCurrentPage =
    Math.min(
      currentPage,
      totalPages,
    );


  const startIndex =
    (
      safeCurrentPage -
      1
    ) *
    PAGE_SIZE;


  const endIndex =
    Math.min(
      startIndex +
        PAGE_SIZE,
      totalResults,
    );


  const visibleEntries =
    filteredEntries.slice(
      startIndex,
      endIndex,
    );


  const pageNumbers =
    Array.from(
      {
        length:
          totalPages,
      },
      (
        _value,
        index,
      ) =>
        index + 1,
    );


  function handleSearchChange(
    value:
      string,
  ) {
    setSearchQuery(
      value,
    );

    setCurrentPage(
      1,
    );
  }


  function resetSearch() {
    setSearchQuery(
      "",
    );

    setCurrentPage(
      1,
    );
  }


  function goToPage(
    page:
      number,
  ) {
    const nextPage =
      Math.min(
        Math.max(
          page,
          1,
        ),
        totalPages,
      );

    setCurrentPage(
      nextPage,
    );

    window.requestAnimationFrame(
      () => {
        document
          .getElementById(
            "pengasuh-journal-entry-list",
          )
          ?.scrollIntoView({
            behavior:
              "smooth",

            block:
              "start",
          });
      },
    );
  }


  return (
    <div className="mt-5">
      {/* =====================================================
          SEARCH + FILL NORMAL
      ===================================================== */}

      <section className="rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
        <div className="grid gap-5 lg:grid-cols-[minmax(0,1fr)_auto] lg:items-start">
          <div className="min-w-0">
            <label
              htmlFor="journal-student-search"
              className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600"
            >
              Cari Santri
            </label>

            <div className="mt-2 flex flex-col gap-2 sm:flex-row">
              <div className="relative min-w-0 flex-1">
                <input
                  id="journal-student-search"
                  type="search"
                  value={
                    searchQuery
                  }
                  onChange={(
                    event,
                  ) =>
                    handleSearchChange(
                      event
                        .target
                        .value,
                    )
                  }
                  placeholder="Cari berdasarkan nama santri..."
                  autoComplete="off"
                  className="min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-slate-400 focus:border-brand-400 focus:ring-4 focus:ring-brand-50"
                />
              </div>

              {searchQuery && (
                <button
                  type="button"
                  onClick={
                    resetSearch
                  }
                  className="inline-flex min-h-11 shrink-0 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-600 transition hover:border-slate-300 hover:bg-slate-50"
                >
                  Reset
                </button>
              )}
            </div>

            <p className="mt-2 text-xs leading-5 text-slate-400">
              Pencarian berlaku
              untuk seluruh{" "}
              {
                entries.length
              }{" "}
              santri, bukan hanya
              halaman yang sedang
              tampil.
            </p>
          </div>


          {!disabled &&
            incompleteCount >
              0 && (
              <div className="lg:max-w-sm">
                <FillNormalPengasuhJournalButton
                  journalId={
                    journalId
                  }
                  incompleteCount={
                    incompleteCount
                  }
                />

                <p className="mt-2 text-xs leading-5 text-slate-400">
                  Isi kondisi normal
                  terlebih dahulu,
                  kemudian cari nama
                  santri yang perlu
                  diubah karena
                  mempunyai kondisi
                  khusus.
                </p>
              </div>
            )}
        </div>
      </section>


      {/* =====================================================
          RESULT SUMMARY
      ===================================================== */}

      <div className="mt-5 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-sm font-semibold text-ink">
            {normalizedSearch
              ? totalResults ===
                0
                ? "Santri tidak ditemukan"
                : `${totalResults} santri ditemukan`
              : totalResults ===
                  0
                ? "Tidak ada santri"
                : `Menampilkan ${
                    startIndex +
                    1
                  }–${endIndex} dari ${totalResults} santri`}
          </p>

          {normalizedSearch && (
            <p className="mt-1 text-xs text-muted">
              Hasil pencarian untuk
              &quot;{
                searchQuery.trim()
              }&quot;
            </p>
          )}
        </div>


        {!normalizedSearch &&
          totalPages >
            1 && (
            <div className="rounded-full bg-slate-100 px-3 py-1.5 text-xs font-semibold text-slate-600">
              Halaman{" "}
              {
                safeCurrentPage
              }{" "}
              dari{" "}
              {
                totalPages
              }
            </div>
          )}
      </div>


      {/* =====================================================
          ENTRY LIST
      ===================================================== */}

      <div
        id="pengasuh-journal-entry-list"
        className="scroll-mt-24"
      >
        {visibleEntries.length ===
        0 ? (
          <div className="mt-4 rounded-3xl border border-dashed border-line bg-white p-8 text-center">
            <p className="font-semibold text-ink">
              Tidak ada santri yang
              sesuai pencarian.
            </p>

            <p className="mt-2 text-sm leading-6 text-muted">
              Coba gunakan nama yang
              lebih pendek atau reset
              pencarian.
            </p>

            {searchQuery && (
              <button
                type="button"
                onClick={
                  resetSearch
                }
                className="mt-5 inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-brand-50 px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-100"
              >
                Tampilkan Semua
                Santri
              </button>
            )}
          </div>
        ) : (
          <div className="mt-4 space-y-4">
            {visibleEntries.map(
              (
                entry,
              ) => (
                <PengasuhJournalEntryForm
                  key={`${entry.id}-${entry.updated_at}`}
                  journalId={
                    journalId
                  }
                  entry={
                    entry
                  }
                  disabled={
                    disabled
                  }
                />
              ),
            )}
          </div>
        )}
      </div>


      {/* =====================================================
          PAGINATION
      ===================================================== */}

      {!normalizedSearch &&
        totalPages >
          1 && (
          <section className="mt-6 rounded-2xl border border-line bg-white p-4 shadow-soft sm:p-5">
            <div className="flex flex-col gap-4">
              <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
                <button
                  type="button"
                  disabled={
                    safeCurrentPage <=
                    1
                  }
                  onClick={() =>
                    goToPage(
                      safeCurrentPage -
                        1,
                    )
                  }
                  className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-700 transition hover:border-brand-200 hover:bg-brand-50 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  ← Sebelumnya
                </button>


                <div className="flex flex-wrap items-center justify-center gap-2">
                  {pageNumbers.map(
                    (
                      page,
                    ) => {
                      const isActive =
                        page ===
                        safeCurrentPage;

                      return (
                        <button
                          key={
                            page
                          }
                          type="button"
                          aria-current={
                            isActive
                              ? "page"
                              : undefined
                          }
                          onClick={() =>
                            goToPage(
                              page,
                            )
                          }
                          className={
                            isActive
                              ? "grid size-10 place-items-center rounded-xl bg-brand-700 text-sm font-bold text-white shadow-sm"
                              : "grid size-10 place-items-center rounded-xl border border-line bg-white text-sm font-semibold text-slate-600 transition hover:border-brand-200 hover:bg-brand-50 hover:text-brand-700"
                          }
                        >
                          {
                            page
                          }
                        </button>
                      );
                    },
                  )}
                </div>


                <button
                  type="button"
                  disabled={
                    safeCurrentPage >=
                    totalPages
                  }
                  onClick={() =>
                    goToPage(
                      safeCurrentPage +
                        1,
                    )
                  }
                  className="inline-flex min-h-10 items-center justify-center rounded-xl border border-line bg-white px-4 text-sm font-semibold text-slate-700 transition hover:border-brand-200 hover:bg-brand-50 disabled:cursor-not-allowed disabled:opacity-40"
                >
                  Berikutnya →
                </button>
              </div>


              <p className="text-center text-xs leading-5 text-slate-400">
                Simpan perubahan pada
                santri sebelum
                berpindah halaman agar
                perubahan tidak
                terlewat.
              </p>
            </div>
          </section>
        )}
    </div>
  );
}