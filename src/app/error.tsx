"use client";

import { useEffect } from "react";

type ErrorPageProps = {
  error: Error & {
    digest?: string;
  };
  reset: () => void;
};

export default function ErrorPage({
  error,
  reset,
}: ErrorPageProps) {
  useEffect(() => {
    console.error("E-Ma'had application error:", error);
  }, [error]);

  return (
    <main className="flex min-h-screen items-center justify-center px-6">
      <div className="max-w-lg text-center">
        <p className="text-sm font-bold uppercase tracking-[0.2em] text-red-700">
          Terjadi kesalahan
        </p>

        <h1 className="mt-4 text-4xl font-bold text-slate-900">
          Halaman tidak dapat ditampilkan
        </h1>

        <p className="mt-4 leading-7 text-slate-600">
          Sistem mengalami kendala ketika memproses permintaan.
          Silakan coba kembali.
        </p>

        <button
          type="button"
          onClick={reset}
          className="mt-7 rounded-xl bg-emerald-700 px-5 py-3 text-sm font-semibold text-white transition hover:bg-emerald-800"
        >
          Coba kembali
        </button>
      </div>
    </main>
  );
}