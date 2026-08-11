"use client";

import Link from "next/link";

import {
  useActionState,
} from "react";

import {
  createBendaharaStudentBillAction,
} from "../actions/create-bendahara-student-bill";

import type {
  BendaharaBillStudentOption,
} from "../schemas/bendahara-bill-student-options-schema";

import {
  initialCreateBendaharaBillActionState,
} from "../types/create-bendahara-bill-action-state";

type Props = {
  student:
    BendaharaBillStudentOption;
};

/*
 * =========================================================
 * HELPERS
 * =========================================================
 */

function formatCurrency(
  value: number,
): string {
  return new Intl.NumberFormat(
    "id-ID",
    {
      style:
        "currency",

      currency:
        "IDR",

      maximumFractionDigits:
        0,
    },
  ).format(
    value,
  );
}

function genderLabel(
  value:
    "male" | "female",
): string {
  return value ===
    "male"
    ? "Putra"
    : "Putri";
}

function FieldError({
  messages,
}: {
  messages?:
    string[];
}) {
  if (
    !messages ||
    messages.length ===
      0
  ) {
    return null;
  }

  return (
    <p className="mt-1 text-xs font-medium text-red-600">
      {messages[0]}
    </p>
  );
}

/*
 * =========================================================
 * COMPONENT
 * =========================================================
 */

export function BendaharaCreateBillForm({
  student,
}: Props) {
  const [
    state,
    formAction,
    pending,
  ] = useActionState(
    createBendaharaStudentBillAction,
    initialCreateBendaharaBillActionState,
  );

  return (
    <form
      action={
        formAction
      }
      className="space-y-6"
    >
      <input
        type="hidden"
        name="studentId"
        value={
          student.id
        }
      />

      {/* ===================================================
          SELECTED STUDENT
      =================================================== */}

      <section className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
        <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Santri Terpilih
            </p>

            <h2 className="mt-2 text-xl font-bold text-ink">
              {
                student.full_name
              }
            </h2>

            <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
              {student.nis && (
                <span>
                  NIS{" "}
                  {
                    student.nis
                  }
                </span>
              )}

              <span>
                {genderLabel(
                  student.gender,
                )}
              </span>

              {student.class && (
                <span>
                  Kelas{" "}
                  {
                    student.class
                      .name
                  }
                </span>
              )}
            </div>
          </div>

          <Link
            href="/bendahara/tagihan/baru"
            className="inline-flex min-h-10 items-center justify-center rounded-xl border border-brand-200 bg-white px-4 text-sm font-semibold text-brand-700 transition hover:bg-brand-50"
          >
            Ganti Santri
          </Link>
        </div>

        <div className="mt-4 grid gap-3 sm:grid-cols-3">
          <div className="rounded-xl bg-white p-3">
            <p className="text-xs text-muted">
              Tagihan Aktif
            </p>

            <p className="mt-1 font-bold text-ink">
              {
                student.finance_summary
                  .active_bill_count
              }
            </p>
          </div>

          <div className="rounded-xl bg-white p-3">
            <p className="text-xs text-muted">
              Belum Lunas
            </p>

            <p className="mt-1 font-bold text-ink">
              {
                student.finance_summary
                  .open_bill_count
              }
            </p>
          </div>

          <div className="rounded-xl bg-white p-3">
            <p className="text-xs text-muted">
              Sisa Tagihan
            </p>

            <p className="mt-1 font-bold text-ink">
              {formatCurrency(
                student.finance_summary
                  .outstanding_amount,
              )}
            </p>
          </div>
        </div>
      </section>

      {/* ===================================================
          ERROR
      =================================================== */}

      {state.status ===
        "error" && (
        <div className="rounded-xl border border-red-200 bg-red-50 p-4">
          <p className="text-sm font-semibold text-red-800">
            Tagihan belum
            tersimpan
          </p>

          <p className="mt-1 text-sm text-red-700">
            {
              state.message
            }
          </p>
        </div>
      )}

      {/* ===================================================
          BASIC DATA
      =================================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Informasi Tagihan
        </p>

        <h2 className="mt-2 text-xl font-bold text-ink">
          Detail Tagihan
        </h2>

        <div className="mt-5 grid gap-5 sm:grid-cols-2">
          {/* CATEGORY */}

          <div>
            <label
              htmlFor="category"
              className="text-sm font-semibold text-ink"
            >
              Kategori Tagihan
            </label>

            <select
              id="category"
              name="category"
              defaultValue={
                state.values
                  ?.category ??
                "spp"
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-3 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            >
              <option value="spp">
                SPP
              </option>

              <option value="makan_asrama">
                Makan Asrama
              </option>

              <option value="kegiatan">
                Kegiatan
              </option>

              <option value="perlengkapan">
                Perlengkapan
              </option>

              <option value="lainnya">
                Lainnya
              </option>
            </select>

            <FieldError
              messages={
                state.fieldErrors
                  ?.category
              }
            />
          </div>

          {/* TITLE */}

          <div>
            <label
              htmlFor="title"
              className="text-sm font-semibold text-ink"
            >
              Nama Tagihan
            </label>

            <input
              id="title"
              name="title"
              type="text"
              maxLength={
                150
              }
              defaultValue={
                state.values
                  ?.title ??
                ""
              }
              placeholder="Contoh: SPP Agustus 2026"
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />

            <FieldError
              messages={
                state.fieldErrors
                  ?.title
              }
            />
          </div>

          {/* PERIOD LABEL */}

          <div>
            <label
              htmlFor="periodLabel"
              className="text-sm font-semibold text-ink"
            >
              Periode
            </label>

            <input
              id="periodLabel"
              name="periodLabel"
              type="text"
              maxLength={
                100
              }
              defaultValue={
                state.values
                  ?.periodLabel ??
                ""
              }
              placeholder="Contoh: Agustus 2026"
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />

            <FieldError
              messages={
                state.fieldErrors
                  ?.periodLabel
              }
            />
          </div>

          {/* AMOUNT */}

          <div>
            <label
              htmlFor="amount"
              className="text-sm font-semibold text-ink"
            >
              Nominal Tagihan
            </label>

            <div className="mt-2 flex min-h-11 overflow-hidden rounded-xl border border-line bg-white focus-within:border-brand-400 focus-within:ring-2 focus-within:ring-brand-100">
              <span className="flex items-center border-r border-line bg-slate-50 px-4 text-sm font-semibold text-muted">
                Rp
              </span>

              <input
                id="amount"
                name="amount"
                type="number"
                min="1"
                step="1"
                inputMode="numeric"
                defaultValue={
                  state.values
                    ?.amount ??
                  ""
                }
                placeholder="750000"
                className="min-w-0 flex-1 bg-white px-4 text-sm text-ink outline-none"
              />
            </div>

            <FieldError
              messages={
                state.fieldErrors
                  ?.amount
              }
            />
          </div>
        </div>
      </section>

      {/* ===================================================
          PERIOD
      =================================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Periode & Jatuh Tempo
        </p>

        <div className="mt-5 grid gap-5 sm:grid-cols-3">
          <div>
            <label
              htmlFor="periodStart"
              className="text-sm font-semibold text-ink"
            >
              Mulai Periode
            </label>

            <input
              id="periodStart"
              name="periodStart"
              type="date"
              defaultValue={
                state.values
                  ?.periodStart ??
                ""
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />

            <FieldError
              messages={
                state.fieldErrors
                  ?.periodStart
              }
            />
          </div>

          <div>
            <label
              htmlFor="periodEnd"
              className="text-sm font-semibold text-ink"
            >
              Akhir Periode
            </label>

            <input
              id="periodEnd"
              name="periodEnd"
              type="date"
              defaultValue={
                state.values
                  ?.periodEnd ??
                ""
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />

            <FieldError
              messages={
                state.fieldErrors
                  ?.periodEnd
              }
            />
          </div>

          <div>
            <label
              htmlFor="dueDate"
              className="text-sm font-semibold text-ink"
            >
              Jatuh Tempo
            </label>

            <input
              id="dueDate"
              name="dueDate"
              type="date"
              defaultValue={
                state.values
                  ?.dueDate ??
                ""
              }
              className="mt-2 min-h-11 w-full rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
            />

            <FieldError
              messages={
                state.fieldErrors
                  ?.dueDate
              }
            />
          </div>
        </div>
      </section>

      {/* ===================================================
          DESCRIPTION
      =================================================== */}

      <section className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <label
          htmlFor="description"
          className="text-sm font-semibold text-ink"
        >
          Keterangan
        </label>

        <textarea
          id="description"
          name="description"
          rows={
            4
          }
          maxLength={
            1000
          }
          defaultValue={
            state.values
              ?.description ??
            ""
          }
          placeholder="Keterangan tambahan apabila diperlukan..."
          className="mt-2 w-full resize-y rounded-xl border border-line bg-white px-4 py-3 text-sm leading-6 text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
        />

        <FieldError
          messages={
            state.fieldErrors
              ?.description
          }
        />
      </section>

      {/* ===================================================
          ACTION
      =================================================== */}

      <section className="flex flex-col-reverse gap-3 border-t border-line pt-5 sm:flex-row sm:justify-end">
        <Link
          href="/bendahara/tagihan"
          className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line bg-white px-5 text-sm font-semibold text-muted transition hover:bg-slate-50 hover:text-ink"
        >
          Batal
        </Link>

        <button
          type="submit"
          disabled={
            pending
          }
          className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-600 px-6 text-sm font-semibold text-white transition hover:bg-brand-700 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {pending
            ? "Menyimpan..."
            : "Simpan Tagihan"}
        </button>
      </section>
    </form>
  );
}