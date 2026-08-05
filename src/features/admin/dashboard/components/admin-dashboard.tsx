import { AdminAttentionPanel } from "./admin-attention-panel";
import { AdminMetricCard } from "./admin-metric-card";
import { AdminReadinessPanel } from "./admin-readiness-panel";

import type { AccessContext } from "@/lib/auth/types";

import type { AdminDashboardData } from "../schemas/admin-dashboard-schema";

type AdminDashboardProps = {
  context: AccessContext;
  data: AdminDashboardData;
};

const numberFormatter = new Intl.NumberFormat(
  "id-ID",
);

function formatNumber(value: number): string {
  return numberFormatter.format(value);
}

function formatDate(
  value: string,
): string {
  return new Intl.DateTimeFormat("id-ID", {
    day: "numeric",
    month: "long",
    year: "numeric",
  }).format(new Date(`${value}T00:00:00`));
}

function genderLabel(
  gender: "male" | "female",
): string {
  return gender === "male"
    ? "Putra"
    : "Putri";
}

export function AdminDashboard({
  context,
  data,
}: AdminDashboardProps) {
  const maximumClassCount = Math.max(
    ...data.class_distribution.map(
      (item) => item.student_count,
    ),
    1,
  );

  return (
    <div className="mx-auto w-full max-w-[1480px] px-4 py-6 sm:px-6 sm:py-8 lg:px-8">
      <section className="overflow-hidden rounded-3xl border border-brand-100 bg-white shadow-soft">
        <div className="grid gap-8 p-6 sm:p-8 xl:grid-cols-[minmax(0,1fr)_360px] xl:p-10">
          <div>
            <div className="inline-flex items-center gap-2 rounded-full bg-brand-50 px-3 py-1.5 text-xs font-semibold text-brand-700">
              <span className="size-2 rounded-full bg-brand-500" />
              Dashboard Admin
            </div>

            <h2 className="mt-5 text-3xl font-bold tracking-tight text-ink sm:text-4xl">
              Assalamu&apos;alaikum,{" "}
              {context.fullName}
            </h2>

            <p className="mt-4 max-w-3xl leading-7 text-muted">
              Pantau kelengkapan data utama, akun
              pengguna, kelompok, dan assignment
              E-Ma&apos;had dari satu ruang kerja.
            </p>
          </div>

          <div className="rounded-2xl border border-brand-100 bg-brand-50/70 p-5">
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Tahun ajaran aktif
            </p>

            <p className="mt-3 text-2xl font-bold text-brand-950">
              {data.academic_year?.name ??
                "Belum ditentukan"}
            </p>

            {data.academic_year && (
              <p className="mt-2 text-sm leading-6 text-brand-700">
                {formatDate(
                  data.academic_year.start_date,
                )}{" "}
                –{" "}
                {formatDate(
                  data.academic_year.end_date,
                )}
              </p>
            )}
          </div>
        </div>
      </section>

      <section className="mt-6 grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
        <AdminMetricCard
          label="Santri aktif"
          value={formatNumber(
            data.summary.active_students,
          )}
          description="Santri aktif dan tidak berstatus terhapus."
          icon="students"
        />

        <AdminMetricCard
          label="Pengurus aktif"
          value={formatNumber(
            data.summary.active_staff,
          )}
          description="Seluruh pengurus aktif dalam data E-Ma'had."
          icon="staff"
        />

        <AdminMetricCard
          label="Akun pengurus"
          value={`${formatNumber(
            data.summary.linked_staff_accounts,
          )}/${formatNumber(
            data.summary.active_staff,
          )}`}
          description="Pengurus yang sudah terhubung dengan akun login."
          icon="shield"
        />

        <AdminMetricCard
          label="Kelompok aktif"
          value={formatNumber(
            data.summary.active_care_groups +
              data.summary.active_tahfiz_groups,
          )}
          description={`${data.summary.active_care_groups} pengasuhan dan ${data.summary.active_tahfiz_groups} tahfiz.`}
          icon="groups"
        />
      </section>

      <div className="mt-6 grid gap-6 xl:grid-cols-[minmax(0,1.15fr)_minmax(340px,0.85fr)]">
        <AdminAttentionPanel data={data} />

        <AdminReadinessPanel data={data} />
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-2">
        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Distribusi kelas
            </p>

            <h2 className="mt-2 text-xl font-bold text-ink">
              Santri per tingkat
            </h2>
          </div>

          <div className="mt-7 space-y-5">
            {data.class_distribution.map(
              (item) => {
                const widthPercentage =
                  Math.max(
                    (
                      item.student_count /
                      maximumClassCount
                    ) * 100,
                    4,
                  );

                return (
                  <div key={item.class_name}>
                    <div className="flex items-center justify-between gap-4">
                      <div>
                        <p className="text-sm font-semibold text-slate-800">
                          {item.class_name}
                        </p>

                        <p className="mt-0.5 text-xs text-slate-500">
                          Tingkat {item.grade_level}
                        </p>
                      </div>

                      <p className="text-sm font-bold text-brand-700">
                        {formatNumber(
                          item.student_count,
                        )}{" "}
                        santri
                      </p>
                    </div>

                    <div className="mt-3 h-2.5 overflow-hidden rounded-full bg-slate-100">
                      <div
                        className="h-full rounded-full bg-brand-600"
                        style={{
                          width: `${widthPercentage}%`,
                        }}
                      />
                    </div>
                  </div>
                );
              },
            )}
          </div>
        </section>

        <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
          <div>
            <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
              Cakupan pengasuhan
            </p>

            <h2 className="mt-2 text-xl font-bold text-ink">
              Santri dan Pengasuh
            </h2>
          </div>

          <div className="mt-6 space-y-3">
            {data.care_distribution.map(
              (item) => (
                <article
                  key={item.care_group_name}
                  className="rounded-2xl border border-line bg-slate-50/70 p-4"
                >
                  <div className="flex items-center justify-between gap-4">
                    <div>
                      <h3 className="font-semibold text-slate-800">
                        {item.care_group_name}
                      </h3>

                      <p className="mt-1 text-xs text-slate-500">
                        {genderLabel(item.gender)}
                      </p>
                    </div>

                    <span className="rounded-full bg-brand-100 px-3 py-1 text-xs font-semibold text-brand-700">
                      {item.caregiver_count} Pengasuh
                    </span>
                  </div>

                  <p className="mt-4 text-sm text-slate-600">
                    <strong className="text-slate-800">
                      {formatNumber(
                        item.student_count,
                      )}
                    </strong>{" "}
                    santri berada dalam kelompok ini.
                  </p>
                </article>
              ),
            )}
          </div>
        </section>
      </div>

      <section className="mt-6 rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Kelompok tahfiz
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Cakupan Pembina Tahfiz
          </h2>
        </div>

        <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
          {data.tahfiz_distribution.map(
            (item) => (
              <article
                key={item.tahfiz_group_name}
                className="rounded-2xl border border-line bg-slate-50/70 p-4"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <h3 className="font-semibold text-slate-800">
                      {item.tahfiz_group_name}
                    </h3>

                    <p className="mt-1 text-xs text-slate-500">
                      {genderLabel(item.gender)}
                    </p>
                  </div>

                  <span
                    className={
                      item.primary_supervisor_count > 0
                        ? "rounded-full bg-brand-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-brand-700"
                        : "rounded-full bg-amber-100 px-2.5 py-1 text-[10px] font-semibold uppercase tracking-wide text-amber-700"
                    }
                  >
                    {item.primary_supervisor_count > 0
                      ? "Pembina siap"
                      : "Belum ada"}
                  </span>
                </div>

                <div className="mt-5 grid grid-cols-2 gap-3">
                  <div className="rounded-xl bg-white p-3">
                    <p className="text-xs text-slate-500">
                      Santri
                    </p>

                    <p className="mt-1 text-lg font-bold text-slate-800">
                      {formatNumber(
                        item.student_count,
                      )}
                    </p>
                  </div>

                  <div className="rounded-xl bg-white p-3">
                    <p className="text-xs text-slate-500">
                      Pembina
                    </p>

                    <p className="mt-1 text-lg font-bold text-slate-800">
                      {formatNumber(
                        item.supervisor_count,
                      )}
                    </p>
                  </div>
                </div>
              </article>
            ),
          )}
        </div>
      </section>
    </div>
  );
}