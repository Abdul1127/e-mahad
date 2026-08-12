import Link from "next/link";

import type {
  KepalaMahadJournalOverview,
  PenanggungJawabMahadHeadJournalOverview,
} from "../schemas/mahad-head-journal-schema";

type Props =
  | {
      mode:
        "kepala_mahad";

      data:
        KepalaMahadJournalOverview;
    }
  | {
      mode:
        "penanggung_jawab";

      data:
        PenanggungJawabMahadHeadJournalOverview;
    };

function formatDate(
  value: string,
): string {
  return new Intl.DateTimeFormat(
    "id-ID",
    {
      day:
        "2-digit",

      month:
        "long",

      year:
        "numeric",

      timeZone:
        "Asia/Makassar",
    },
  ).format(
    new Date(
      `${value}T00:00:00+08:00`,
    ),
  );
}

export function MahadHeadJournalOverview({
  mode,
  data,
}: Props) {
  const isKepala =
    mode ===
    "kepala_mahad";

  const basePath =
    isKepala
      ? "/kepala-mahad/jurnal"
      : "/penanggung-jawab/jurnal";

  const total =
    isKepala
      ? data.summary.total_count
      : data.summary.submitted_count;

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="flex flex-col gap-5 lg:flex-row lg:items-end lg:justify-between">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            {isKepala
              ? "Operasional Ma'had"
              : "Monitoring Pimpinan"}
          </p>

          <h1 className="mt-2 text-3xl font-bold text-ink">
            Jurnal Kepala Ma&apos;had
          </h1>

          <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
            {isKepala
              ? "Catat pelaksanaan kegiatan, kinerja, bukti, serta kendala operasional Ma'had."
              : "Pantau jurnal kegiatan Kepala Ma'had yang telah dikirim."}
          </p>

          <span className="mt-3 inline-flex rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
            Tahun Ajaran{" "}
            {
              data.academic_year.name
            }
          </span>
        </div>

        {isKepala && (
          <Link
            href="/kepala-mahad/jurnal/baru"
            className="inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
          >
            + Buat / Buka Jurnal
          </Link>
        )}
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-3">
        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Total Jurnal
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {total}
          </p>
        </div>

        {isKepala && (
          <>
            <div className="rounded-2xl border border-amber-100 bg-amber-50 p-5">
              <p className="text-xs text-amber-700">
                Draft
              </p>

              <p className="mt-2 text-3xl font-bold text-amber-900">
                {
                  data.summary.draft_count
                }
              </p>
            </div>

            <div className="rounded-2xl border border-emerald-100 bg-emerald-50 p-5">
              <p className="text-xs text-emerald-700">
                Sudah Dikirim
              </p>

              <p className="mt-2 text-3xl font-bold text-emerald-900">
                {
                  data.summary.submitted_count
                }
              </p>
            </div>
          </>
        )}
      </section>

      <form
        method="get"
        className="mt-6 grid gap-3 rounded-2xl border border-line bg-white p-4 shadow-soft sm:grid-cols-[1fr_1fr_auto]"
      >
        <div>
          <label className="text-xs font-semibold text-muted">
            Dari
          </label>

          <input
            type="date"
            name="from"
            defaultValue={
              data.filters.date_from
            }
            className="mt-1 min-h-10 w-full rounded-xl border border-line px-3 text-sm"
          />
        </div>

        <div>
          <label className="text-xs font-semibold text-muted">
            Sampai
          </label>

          <input
            type="date"
            name="to"
            defaultValue={
              data.filters.date_to
            }
            className="mt-1 min-h-10 w-full rounded-xl border border-line px-3 text-sm"
          />
        </div>

        <button
          type="submit"
          className="min-h-10 self-end rounded-xl border border-brand-200 bg-brand-50 px-5 text-sm font-semibold text-brand-700"
        >
          Terapkan
        </button>
      </form>

      {data.items.length ===
      0 ? (
        <section className="mt-6 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
          <h2 className="font-bold text-ink">
            Belum ada jurnal
          </h2>

          <p className="mt-2 text-sm text-muted">
            Tidak terdapat jurnal pada
            rentang tanggal tersebut.
          </p>
        </section>
      ) : (
        <div className="mt-6 space-y-3">
          {data.items.map(
            (item) => (
              <Link
                key={
                  item.id
                }
                href={`${basePath}/${item.id}`}
                className="block rounded-2xl border border-line bg-white p-5 shadow-soft transition hover:border-brand-200 hover:bg-brand-50/30"
              >
                <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                  <div>
                    <p className="font-bold text-ink">
                      {formatDate(
                        item.journal_date,
                      )}
                    </p>

                    {"staff" in item && (
                      <p className="mt-1 text-xs text-muted">
                        {
                          item.staff.full_name
                        }
                        {item.staff.position
                          ? ` • ${item.staff.position}`
                          : ""}
                      </p>
                    )}

                    <p className="mt-2 text-xs text-muted">
                      {
                        item.checked_count
                      }{" "}
                      kegiatan dicatat
                    </p>
                  </div>

                  <div className="flex flex-wrap gap-2">
                    <span
                      className={
                        item.status ===
                        "submitted"
                          ? "rounded-full bg-emerald-50 px-3 py-1 text-xs font-semibold text-emerald-700"
                          : "rounded-full bg-amber-50 px-3 py-1 text-xs font-semibold text-amber-700"
                      }
                    >
                      {item.status ===
                      "submitted"
                        ? "Sudah Dikirim"
                        : "Draft"}
                    </span>

                    {item.has_evidence && (
                      <span className="rounded-full bg-blue-50 px-3 py-1 text-xs font-semibold text-blue-700">
                        Ada Bukti
                      </span>
                    )}
                  </div>
                </div>
              </Link>
            ),
          )}
        </div>
      )}
    </div>
  );
}