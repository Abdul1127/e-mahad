import Link from "next/link";

export default function StudentNotFound() {
  return (
    <div className="mx-auto flex min-h-[65vh] w-full max-w-2xl items-center px-4 py-10 sm:px-6">
      <section className="w-full rounded-3xl border border-line bg-white p-8 text-center shadow-soft sm:p-10">
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-red-600">
          Data tidak ditemukan
        </p>

        <h1 className="mt-4 text-3xl font-bold tracking-tight text-ink">
          Santri tidak tersedia
        </h1>

        <p className="mx-auto mt-4 max-w-md leading-7 text-muted">
          Data mungkin sudah dihapus atau alamat
          detail yang dibuka tidak sesuai.
        </p>

        <Link
          href="/admin/santri"
          className="mt-7 inline-flex min-h-11 items-center justify-center rounded-xl bg-brand-700 px-5 text-sm font-semibold text-white transition hover:bg-brand-800"
        >
          Kembali ke Data Santri
        </Link>
      </section>
    </div>
  );
}