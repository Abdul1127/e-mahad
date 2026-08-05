import type { AdminStudentDetailData } from "../schemas/admin-student-detail-schema";

type StudentGuardianPanelProps = {
  guardians:
    AdminStudentDetailData["guardians"];
};

export function StudentGuardianPanel({
  guardians,
}: StudentGuardianPanelProps) {
  return (
    <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Orang tua atau wali
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Akun keluarga
          </h2>
        </div>

        <span className="rounded-full bg-brand-50 px-3 py-1.5 text-sm font-bold text-brand-700">
          {guardians.length}
        </span>
      </div>

      {guardians.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-dashed border-amber-200 bg-amber-50/60 p-5">
          <p className="font-semibold text-amber-800">
            Belum ada wali terhubung
          </p>

          <p className="mt-2 text-sm leading-6 text-amber-700">
            Data orang tua belum diimpor atau belum
            dihubungkan dengan santri ini.
          </p>
        </div>
      ) : (
        <div className="mt-6 space-y-3">
          {guardians.map((guardian) => (
            <article
              key={guardian.id}
              className="rounded-2xl border border-line bg-slate-50/70 p-4"
            >
              <div className="flex flex-wrap items-start justify-between gap-3">
                <div>
                  <h3 className="font-semibold text-slate-800">
                    {guardian.full_name}
                  </h3>

                  <p className="mt-1 text-xs text-slate-500">
                    ID Wali{" "}
                    {guardian.legacy_guardian_id ??
                      "-"}
                  </p>
                </div>

                <span
                  className={
                    guardian.account_active
                      ? "rounded-full bg-brand-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-brand-700"
                      : "rounded-full bg-amber-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-amber-700"
                  }
                >
                  {guardian.account_active
                    ? "Akun aktif"
                    : "Belum login"}
                </span>
              </div>

              <dl className="mt-4 grid gap-3 sm:grid-cols-2">
                <div>
                  <dt className="text-xs text-slate-400">
                    Telepon
                  </dt>

                  <dd className="mt-1 text-sm font-medium text-slate-700">
                    {guardian.phone ??
                      "Belum tersedia"}
                  </dd>
                </div>

                <div>
                  <dt className="text-xs text-slate-400">
                    Email
                  </dt>

                  <dd className="mt-1 break-all text-sm font-medium text-slate-700">
                    {guardian.account_email ??
                      guardian.email ??
                      "Belum tersedia"}
                  </dd>
                </div>
              </dl>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}