import type { Metadata } from "next";

import { LoginForm } from "@/features/auth/components/login-form";

export const metadata: Metadata = {
  title: "Login",
  description:
    "Masuk ke sistem informasi E-Ma'had.",
};

export default function LoginPage() {
  return (
    <main className="grid min-h-screen lg:grid-cols-2">
      <section className="hidden bg-emerald-900 px-12 py-16 text-white lg:flex lg:flex-col lg:justify-between">
        <div>
          <p className="text-sm font-bold uppercase tracking-[0.24em] text-emerald-200">
            Sistem Informasi Pesantren
          </p>

          <h1 className="mt-6 text-6xl font-bold tracking-tight">
            E-Ma&apos;had
          </h1>

          <p className="mt-6 max-w-xl text-lg leading-8 text-emerald-100">
            Sistem terpusat untuk pengelolaan dan
            pemantauan kegiatan asrama, pengasuhan,
            tahfiz, dan keuangan santri.
          </p>
        </div>

        <div className="rounded-2xl border border-emerald-700 bg-emerald-800/50 p-6">
          <p className="text-sm leading-7 text-emerald-100">
            Setiap pengguna memperoleh dashboard dan
            cakupan data berdasarkan role serta
            assignment yang telah ditentukan.
          </p>
        </div>
      </section>

      <section className="flex items-center justify-center bg-slate-50 px-5 py-12 sm:px-8">
        <div className="w-full max-w-md">
          <div className="rounded-3xl border border-slate-200 bg-white p-7 shadow-sm sm:p-9">
            <div className="mb-8">
              <p className="text-sm font-bold uppercase tracking-[0.18em] text-emerald-700">
                Selamat datang
              </p>

              <h2 className="mt-3 text-3xl font-bold tracking-tight text-slate-900">
                Masuk ke akun
              </h2>

              <p className="mt-3 leading-7 text-slate-600">
                Gunakan email dan password yang telah
                diberikan oleh administrator.
              </p>
            </div>

            <LoginForm />
          </div>

          <p className="mt-6 text-center text-sm text-slate-500">
            Hubungi administrator apabila akun tidak
            dapat digunakan.
          </p>
        </div>
      </section>
    </main>
  );
}