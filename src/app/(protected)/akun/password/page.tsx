import type {
  Metadata,
} from "next";

import {
  ChangeOwnPasswordForm,
} from "@/features/account/components/change-own-password-form";

import {
  requireAccessContext,
} from "@/lib/auth/guards";


export const metadata:
  Metadata = {
    title:
      "Ubah Password",

    description:
      "Mengubah password akun E-Ma'had yang sedang digunakan.",
  };


type PageProps = {
  searchParams:
    Promise<{
      changed?:
        string |
        string[];
    }>;
};


export default async function ChangePasswordPage({
  searchParams,
}: PageProps) {
  const context =
    await requireAccessContext();

  const parameters =
    await searchParams;

  const changed =
    parameters.changed ===
    "1";


  return (
    <div className="mx-auto w-full max-w-4xl px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Akun Saya
        </p>

        <h1 className="mt-2 text-3xl font-bold tracking-tight text-ink">
          Ubah Password
        </h1>

        <p className="mt-3 max-w-2xl leading-7 text-muted">
          Kelola password akun{" "}
          <strong className="text-slate-700">
            {
              context.fullName
            }
          </strong>
          {" "}secara mandiri.
        </p>
      </section>


      {changed && (
        <section
          role="status"
          className="mt-6 rounded-2xl border border-emerald-200 bg-emerald-50 px-5 py-4"
        >
          <p className="font-semibold text-emerald-800">
            Password berhasil diubah
          </p>

          <p className="mt-1 text-sm leading-6 text-emerald-700">
            Gunakan password baru
            pada proses login berikutnya.
          </p>
        </section>
      )}


      <div className="mt-6">
        <ChangeOwnPasswordForm />
      </div>


      <section className="mt-6 rounded-2xl border border-slate-200 bg-slate-50 p-5">
        <h2 className="font-semibold text-slate-800">
          Lupa password?
        </h2>

        <p className="mt-2 text-sm leading-6 text-slate-600">
          Apabila tidak dapat masuk ke
          akun, hubungi Admin E-Ma&apos;had
          untuk mendapatkan reset password.
          Setelah berhasil login kembali,
          password dapat diubah lagi dari
          halaman ini.
        </p>
      </section>
    </div>
  );
}