import Link from "next/link";

export default function NotFoundPage() {
  return (
    <main className="flex min-h-screen items-center justify-center px-6">
      <div className="max-w-lg text-center">
        <p className="text-sm font-bold uppercase tracking-[0.2em] text-emerald-700">
          404
        </p>

        <h1 className="mt-4 text-4xl font-bold text-slate-900">
          Halaman tidak ditemukan
        </h1>

        <p className="mt-4 leading-7 text-slate-600">
          Halaman yang kamu buka belum tersedia atau alamatnya
          sudah berubah.
        </p>

        <Link
          href="/"
          className="mt-7 inline-flex rounded-xl bg-emerald-700 px-5 py-3 text-sm font-semibold text-white transition hover:bg-emerald-800"
        >
          Kembali ke halaman utama
        </Link>
      </div>
    </main>
  );
}