import Link from "next/link";

import {
  notFound,
} from "next/navigation";

import {
  getRoleCodeBySlug,
} from "@/config/roles";

import {
  BendaharaCreateBillForm,
} from "@/features/bendahara/bills/components/bendahara-create-bill-form";

import {
  getBendaharaBillStudentOptions,
} from "@/features/bendahara/bills/data/get-bendahara-bill-student-options";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  params:
    Promise<{
      role: string;
    }>;

  searchParams:
    Promise<{
      q?:
        | string
        | string[];

      student?:
        | string
        | string[];
    }>;
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

export default async function BendaharaCreateBillPage({
  params,
  searchParams,
}: PageProps) {
  const {
    role,
  } = await params;

  const roleCode =
    getRoleCodeBySlug(
      role,
    );

  if (
    roleCode !==
    "bendahara"
  ) {
    notFound();
  }

  await requireRole(
    "bendahara",
  );

  const resolvedSearchParams =
    await searchParams;

  const search =
    firstValue(
      resolvedSearchParams.q,
    )
      ?.trim() ?? "";

  const selectedStudentId =
    firstValue(
      resolvedSearchParams.student,
    )
      ?.trim() ?? "";

  const data =
    await getBendaharaBillStudentOptions({
      search:
        search.length > 0
          ? search
          : null,
    });

  const selectedStudent =
    data.items.find(
      (
        student,
      ) =>
        student.id ===
        selectedStudentId,
    );

  return (
    <div className="mx-auto w-full max-w-5xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* ===================================================
          HEADER
      =================================================== */}

      <section>
        <Link
          href="/bendahara/tagihan"
          className="text-sm font-semibold text-brand-700 hover:text-brand-800"
        >
          ← Kembali ke Tagihan
        </Link>

        <p className="mt-6 text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Bendahara
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Buat Tagihan
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Buat tagihan individual
          untuk santri pada tahun
          ajaran{" "}
          <span className="font-semibold text-ink">
            {
              data.academic_year
                .name
            }
          </span>
          .
        </p>
      </section>

      {/* ===================================================
          STUDENT SEARCH
      =================================================== */}

      {!selectedStudent && (
        <section className="mt-7">
          <div className="rounded-2xl border border-line bg-white p-5 shadow-soft sm:p-6">
            <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
              Langkah 1
            </p>

            <h2 className="mt-2 text-xl font-bold text-ink">
              Pilih Santri
            </h2>

            <p className="mt-2 text-sm leading-6 text-muted">
              Cari berdasarkan
              nama, NIS, atau ID
              santri.
            </p>

            <form
              method="GET"
              action="/bendahara/tagihan/baru"
              className="mt-5 flex flex-col gap-3 sm:flex-row"
            >
              <input
                type="search"
                name="q"
                defaultValue={
                  search
                }
                placeholder="Cari nama atau NIS santri..."
                className="min-h-11 flex-1 rounded-xl border border-line bg-white px-4 text-sm text-ink outline-none transition placeholder:text-muted focus:border-brand-400 focus:ring-2 focus:ring-brand-100"
              />

              <button
                type="submit"
                className="min-h-11 rounded-xl bg-brand-600 px-6 text-sm font-semibold text-white transition hover:bg-brand-700"
              >
                Cari Santri
              </button>

              {search && (
                <Link
                  href="/bendahara/tagihan/baru"
                  className="inline-flex min-h-11 items-center justify-center rounded-xl border border-line px-5 text-sm font-semibold text-muted hover:bg-slate-50"
                >
                  Reset
                </Link>
              )}
            </form>
          </div>

          {/* ===============================================
              STUDENT RESULTS
          =============================================== */}

          <div className="mt-5 space-y-3">
            {data.items.length ===
            0 ? (
              <div className="rounded-2xl border border-dashed border-line bg-white p-8 text-center">
                <h3 className="font-bold text-ink">
                  Santri tidak ditemukan
                </h3>

                <p className="mt-2 text-sm text-muted">
                  Coba gunakan nama
                  atau NIS yang
                  berbeda.
                </p>
              </div>
            ) : (
              data.items.map(
                (
                  student,
                ) => {
                  const params =
                    new URLSearchParams();

                  if (search) {
                    params.set(
                      "q",
                      search,
                    );
                  }

                  params.set(
                    "student",
                    student.id,
                  );

                  return (
                    <article
                      key={
                        student.id
                      }
                      className="rounded-2xl border border-line bg-white p-5 shadow-soft"
                    >
                      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                        <div>
                          <h3 className="font-bold text-ink">
                            {
                              student.full_name
                            }
                          </h3>

                          <div className="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-xs text-muted">
                            {student.nis && (
                              <span>
                                NIS{" "}
                                {
                                  student.nis
                                }
                              </span>
                            )}

                            {student.class && (
                              <span>
                                Kelas{" "}
                                {
                                  student.class
                                    .name
                                }
                              </span>
                            )}

                            <span>
                              Tagihan terbuka{" "}
                              {
                                student.finance_summary
                                  .open_bill_count
                              }
                            </span>

                            <span>
                              Sisa{" "}
                              {formatCurrency(
                                student.finance_summary
                                  .outstanding_amount,
                              )}
                            </span>
                          </div>
                        </div>

                        <Link
                          href={`/bendahara/tagihan/baru?${params.toString()}`}
                          className="inline-flex min-h-10 items-center justify-center rounded-xl bg-brand-600 px-5 text-sm font-semibold text-white transition hover:bg-brand-700"
                        >
                          Pilih
                        </Link>
                      </div>
                    </article>
                  );
                },
              )
            )}
          </div>
        </section>
      )}

      {/* ===================================================
          BILL FORM
      =================================================== */}

      {selectedStudent && (
        <section className="mt-7">
          <BendaharaCreateBillForm
            student={
              selectedStudent
            }
          />
        </section>
      )}
    </div>
  );
}