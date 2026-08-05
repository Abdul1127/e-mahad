import Link from "next/link";

import { LogoutButton } from "@/features/auth/components/logout-button";

export default function AccessDeniedPage() {
  return (
    <main className="flex min-h-screen items-center justify-center bg-slate-50 px-5">
      <div className="w-full max-w-lg rounded-3xl border border-slate-200 bg-white p-8 text-center shadow-sm">
        <p className="text-sm font-bold uppercase tracking-[0.18em] text-red-700">
          Akses ditolak
        </p>

        <h1 className="mt-4 text-3xl font-bold text-slate-900">
          Akun tidak dapat membuka halaman ini
        </h1>

        <p className="mt-4 leading-7 text-slate-600">
          Akun mungkin belum mempunyai role, sedang
          tidak aktif, atau mencoba membuka dashboard
          role lain.
        </p>

        <div className="mt-7 flex flex-wrap justify-center gap-3">
          <Link
            href="/dashboard"
            className="rounded-lg bg-emerald-700 px-4 py-2 text-sm font-semibold text-white transition hover:bg-emerald-800"
          >
            Kembali ke dashboard
          </Link>

          <LogoutButton />
        </div>
      </div>
    </main>
  );
}