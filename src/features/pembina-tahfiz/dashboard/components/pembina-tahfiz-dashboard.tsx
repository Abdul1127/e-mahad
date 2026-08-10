import type {
  PembinaTahfizDashboardData,
  PembinaTahfizDashboardGroup,
} from "../schemas/pembina-tahfiz-dashboard-schema";

type Props = {
  data:
    PembinaTahfizDashboardData;
};

function getGenderLabel(
  gender:
    | "male"
    | "female"
    | null,
): string {
  switch (gender) {
    case "male":
      return "Putra";

    case "female":
      return "Putri";

    default:
      return "Campuran";
  }
}

function GroupCard({
  group,
}: {
  group:
    PembinaTahfizDashboardGroup;
}) {
  return (
    <article className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
        <div>
          <div className="flex flex-wrap gap-2">
            <span className="rounded-full bg-brand-50 px-2.5 py-1 text-xs font-semibold text-brand-700">
              {getGenderLabel(
                group.gender,
              )}
            </span>

            {group.grade_level !==
              null && (
              <span className="rounded-full bg-slate-100 px-2.5 py-1 text-xs font-semibold text-slate-600">
                Tingkat{" "}
                {
                  group.grade_level
                }
              </span>
            )}

            {group.assignment
              .is_primary && (
              <span className="rounded-full bg-emerald-50 px-2.5 py-1 text-xs font-semibold text-emerald-700">
                Pembina Utama
              </span>
            )}
          </div>

          <h2 className="mt-3 text-xl font-bold text-ink">
            {group.name}
          </h2>

          <p className="mt-1 text-sm text-muted">
            Kode kelompok:{" "}
            <span className="font-semibold text-slate-600">
              {group.code}
            </span>
          </p>
        </div>

        <div className="rounded-2xl bg-brand-50 px-5 py-4 text-center">
          <p className="text-3xl font-bold text-brand-900">
            {
              group.summary
                .member_count
            }
          </p>

          <p className="mt-1 text-xs font-medium text-brand-700">
            Santri
          </p>
        </div>
      </div>

      <div className="mt-5 grid gap-3 sm:grid-cols-2">
        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs text-muted">
            Santri Putra
          </p>

          <p className="mt-1 text-xl font-bold text-ink">
            {
              group.summary
                .male_count
            }
          </p>
        </div>

        <div className="rounded-2xl bg-slate-50 p-4">
          <p className="text-xs text-muted">
            Santri Putri
          </p>

          <p className="mt-1 text-xl font-bold text-ink">
            {
              group.summary
                .female_count
            }
          </p>
        </div>
      </div>

      <div className="mt-6 border-t border-line pt-5">
        <div className="flex items-center justify-between gap-4">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.12em] text-brand-600">
              Preview Santri
            </p>

            <p className="mt-1 text-sm text-muted">
              Maksimal 8 santri
              ditampilkan di
              dashboard.
            </p>
          </div>
        </div>

        {group.member_preview
          .length === 0 ? (
          <div className="mt-4 rounded-2xl border border-dashed border-line p-5 text-center">
            <p className="text-sm font-medium text-muted">
              Belum ada santri
              aktif pada kelompok
              ini.
            </p>
          </div>
        ) : (
          <div className="mt-4 divide-y divide-line overflow-hidden rounded-2xl border border-line">
            {group.member_preview.map(
              (student) => (
                <div
                  key={
                    student.id
                  }
                  className="flex flex-col gap-2 bg-white px-4 py-3 sm:flex-row sm:items-center sm:justify-between"
                >
                  <div>
                    <p className="text-sm font-semibold text-ink">
                      {
                        student.full_name
                      }
                    </p>

                    <div className="mt-1 flex flex-wrap gap-x-3 gap-y-1 text-xs text-slate-400">
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
                    </div>
                  </div>

                  <span className="w-fit rounded-full bg-slate-50 px-2.5 py-1 text-xs font-semibold text-slate-500">
                    {student.gender ===
                    "male"
                      ? "Putra"
                      : "Putri"}
                  </span>
                </div>
              ),
            )}
          </div>
        )}
      </div>
    </article>
  );
}

export function PembinaTahfizDashboard({
  data,
}: Props) {
  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      {/* =====================================================
          HEADER
      ===================================================== */}

      <section>
        <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
          Pembina Tahfiz
        </p>

        <h1 className="mt-2 text-3xl font-bold text-ink">
          Selamat datang,{" "}
          {
            data.staff
              .full_name
          }
        </h1>

        <p className="mt-3 max-w-3xl text-sm leading-7 text-muted">
          Pantau kelompok Tahfiz
          dan santri yang menjadi
          tanggung jawab Anda.
        </p>

        <div className="mt-3 flex flex-wrap gap-2">
          <span className="rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700">
            Tahun Ajaran{" "}
            {
              data.academic_year
                .name
            }
          </span>

          {data.profile
            .login_id && (
            <span className="rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold text-slate-600">
              {
                data.profile
                  .login_id
              }
            </span>
          )}
        </div>
      </section>

      {/* =====================================================
          SUMMARY
      ===================================================== */}

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <div className="rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <p className="text-xs font-medium text-brand-700">
            Kelompok Ampuan
          </p>

          <p className="mt-2 text-3xl font-bold text-brand-900">
            {
              data.summary
                .group_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-line bg-white p-5 shadow-soft">
          <p className="text-xs text-muted">
            Santri Ampuan
          </p>

          <p className="mt-2 text-3xl font-bold text-ink">
            {
              data.summary
                .student_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-blue-100 bg-blue-50 p-5">
          <p className="text-xs font-medium text-blue-700">
            Santri Putra
          </p>

          <p className="mt-2 text-3xl font-bold text-blue-900">
            {
              data.summary
                .male_count
            }
          </p>
        </div>

        <div className="rounded-2xl border border-pink-100 bg-pink-50 p-5">
          <p className="text-xs font-medium text-pink-700">
            Santri Putri
          </p>

          <p className="mt-2 text-3xl font-bold text-pink-900">
            {
              data.summary
                .female_count
            }
          </p>
        </div>
      </section>

      {/* =====================================================
          GROUPS
      ===================================================== */}

      <section className="mt-8">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
            Assignment Aktif
          </p>

          <h2 className="mt-2 text-2xl font-bold text-ink">
            Kelompok Tahfiz Ampuan
          </h2>

          <p className="mt-2 max-w-3xl text-sm leading-6 text-muted">
            Dashboard hanya
            menampilkan kelompok
            yang tercatat sebagai
            assignment aktif Anda
            pada tahun ajaran
            berjalan.
          </p>
        </div>

        {data.groups.length ===
        0 ? (
          <div className="mt-5 rounded-3xl border border-dashed border-line bg-white p-10 text-center">
            <h3 className="font-bold text-ink">
              Belum ada kelompok
              Tahfiz
            </h3>

            <p className="mt-2 text-sm text-muted">
              Akun Pembina belum
              mempunyai assignment
              kelompok aktif.
            </p>
          </div>
        ) : (
          <div className="mt-5 grid gap-5 xl:grid-cols-2">
            {data.groups.map(
              (group) => (
                <GroupCard
                  key={
                    group.id
                  }
                  group={
                    group
                  }
                />
              ),
            )}
          </div>
        )}
      </section>
    </div>
  );
}