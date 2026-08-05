import { AppIcon } from "@/components/app-shell/app-icon";

import type { AdminDashboardData } from "../schemas/admin-dashboard-schema";

type AdminReadinessPanelProps = {
  data: AdminDashboardData;
};

type ReadinessItem = {
  label: string;
  description: string;
  complete: boolean;
};

export function AdminReadinessPanel({
  data,
}: AdminReadinessPanelProps) {
  const items: ReadinessItem[] = [
    {
      label: "Kelas santri",
      description:
        "Seluruh santri mempunyai enrollment kelas aktif.",
      complete:
        data.readiness
          .class_memberships_complete,
    },
    {
      label: "Kelompok pengasuhan",
      description:
        "Seluruh santri masuk kelompok pengasuhan aktif.",
      complete:
        data.readiness
          .care_memberships_complete,
    },
    {
      label: "Kelompok tahfiz",
      description:
        "Seluruh santri masuk kelompok tahfiz aktif.",
      complete:
        data.readiness
          .tahfiz_memberships_complete,
    },
    {
      label: "Assignment Pengasuh",
      description:
        "Seluruh kelompok pengasuhan mempunyai Pengasuh.",
      complete:
        data.readiness
          .care_assignments_complete,
    },
    {
      label: "Assignment Pembina Tahfiz",
      description:
        "Seluruh kelompok tahfiz mempunyai Pembina utama.",
      complete:
        data.readiness
          .tahfiz_assignments_complete,
    },
  ];

  const completedCount = items.filter(
    (item) => item.complete,
  ).length;

  return (
    <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
      <div className="flex items-start justify-between gap-4">
        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-brand-600">
            Kesiapan struktur
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Fondasi operasional
          </h2>
        </div>

        <div className="rounded-full bg-brand-50 px-3 py-1.5 text-sm font-bold text-brand-700">
          {completedCount}/{items.length}
        </div>
      </div>

      <div className="mt-6 space-y-3">
        {items.map((item) => (
          <article
            key={item.label}
            className="flex items-start gap-3 rounded-2xl border border-line bg-slate-50/70 p-4"
          >
            <div
              className={
                item.complete
                  ? "grid size-9 shrink-0 place-items-center rounded-xl bg-brand-100 text-brand-700"
                  : "grid size-9 shrink-0 place-items-center rounded-xl bg-amber-100 text-amber-700"
              }
            >
              <AppIcon
                name={
                  item.complete
                    ? "shield"
                    : "journal"
                }
                className="size-4.5"
              />
            </div>

            <div>
              <div className="flex flex-wrap items-center gap-2">
                <h3 className="text-sm font-semibold text-slate-800">
                  {item.label}
                </h3>

                <span
                  className={
                    item.complete
                      ? "rounded-full bg-brand-100 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-brand-700"
                      : "rounded-full bg-amber-100 px-2 py-0.5 text-[10px] font-semibold uppercase tracking-wide text-amber-700"
                  }
                >
                  {item.complete
                    ? "Siap"
                    : "Perlu dicek"}
                </span>
              </div>

              <p className="mt-1 text-sm leading-6 text-slate-500">
                {item.description}
              </p>
            </div>
          </article>
        ))}
      </div>
    </section>
  );
}