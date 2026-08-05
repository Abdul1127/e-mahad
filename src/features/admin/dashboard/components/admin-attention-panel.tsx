import { AppIcon } from "@/components/app-shell/app-icon";

import type { AdminDashboardData } from "../schemas/admin-dashboard-schema";

type AdminAttentionPanelProps = {
  data: AdminDashboardData;
};

type AttentionItem = {
  label: string;
  description: string;
  count: number;
};

export function AdminAttentionPanel({
  data,
}: AdminAttentionPanelProps) {
  const attentionItems: AttentionItem[] = [
    {
      label: "Akun pengurus belum terhubung",
      description:
        "Pengurus belum dapat login menggunakan akun masing-masing.",
      count:
        data.attention.staff_without_accounts,
    },
    {
      label: "Santri belum terhubung wali",
      description:
        "Relasi orang tua atau wali belum tersedia untuk santri tersebut.",
      count:
        data.attention.students_without_guardians,
    },
    {
      label: "Santri tanpa kelas aktif",
      description:
        "Santri belum mempunyai enrollment kelas pada tahun aktif.",
      count:
        data.attention.students_without_active_class,
    },
    {
      label: "Santri tanpa kelompok pengasuhan",
      description:
        "Santri belum masuk ke cakupan Pengasuhan Putra atau Putri.",
      count:
        data.attention
          .students_without_active_care_group,
    },
    {
      label: "Santri tanpa kelompok tahfiz",
      description:
        "Santri belum mempunyai kelompok tahfiz aktif.",
      count:
        data.attention
          .students_without_active_tahfiz_group,
    },
    {
      label: "Kelompok tanpa Pengasuh",
      description:
        "Kelompok pengasuhan belum mempunyai assignment Pengasuh.",
      count:
        data.attention
          .care_groups_without_caregiver,
    },
    {
      label: "Kelompok tahfiz tanpa Pembina utama",
      description:
        "Kelompok belum mempunyai Pembina Tahfiz utama.",
      count:
        data.attention
          .tahfiz_groups_without_primary_supervisor,
    },
  ];

  const activeAttentionItems =
    attentionItems.filter(
      (item) => item.count > 0,
    );

  return (
    <section className="rounded-3xl border border-line bg-white p-6 shadow-soft sm:p-7">
      <div className="flex items-start gap-4">
        <div className="grid size-11 shrink-0 place-items-center rounded-2xl bg-amber-50 text-amber-700">
          <AppIcon
            name="shield"
            className="size-5"
          />
        </div>

        <div>
          <p className="text-xs font-semibold uppercase tracking-[0.16em] text-amber-700">
            Perlu perhatian
          </p>

          <h2 className="mt-2 text-xl font-bold text-ink">
            Data yang perlu dilengkapi
          </h2>
        </div>
      </div>

      {activeAttentionItems.length === 0 ? (
        <div className="mt-6 rounded-2xl border border-brand-100 bg-brand-50 p-5">
          <p className="font-semibold text-brand-800">
            Seluruh pemeriksaan selesai
          </p>

          <p className="mt-1 text-sm leading-6 text-brand-700">
            Tidak ada struktur data yang membutuhkan
            tindakan pada saat ini.
          </p>
        </div>
      ) : (
        <div className="mt-6 space-y-3">
          {activeAttentionItems.map((item) => (
            <article
              key={item.label}
              className="flex items-start gap-4 rounded-2xl border border-amber-100 bg-amber-50/60 p-4"
            >
              <div className="grid min-w-10 shrink-0 place-items-center rounded-xl bg-white px-2.5 py-2 text-sm font-bold text-amber-700 shadow-sm">
                {item.count}
              </div>

              <div className="min-w-0">
                <h3 className="font-semibold text-slate-800">
                  {item.label}
                </h3>

                <p className="mt-1 text-sm leading-6 text-slate-600">
                  {item.description}
                </p>
              </div>
            </article>
          ))}
        </div>
      )}

      {data.unlinked_staff.length > 0 && (
        <div className="mt-6 border-t border-line pt-5">
          <p className="text-sm font-semibold text-slate-800">
            Pengurus belum mempunyai akun
          </p>

          <div className="mt-3 space-y-2">
            {data.unlinked_staff
              .slice(0, 5)
              .map((staff) => (
                <div
                  key={
                    staff.legacy_staff_id ??
                    staff.full_name
                  }
                  className="flex items-center justify-between gap-4 rounded-xl bg-slate-50 px-4 py-3"
                >
                  <div className="min-w-0">
                    <p className="truncate text-sm font-semibold text-slate-700">
                      {staff.full_name}
                    </p>

                    <p className="mt-0.5 truncate text-xs text-slate-500">
                      {staff.position ??
                        "Posisi belum tersedia"}
                    </p>
                  </div>

                  <span className="shrink-0 text-xs font-medium text-slate-400">
                    {staff.legacy_staff_id}
                  </span>
                </div>
              ))}
          </div>

          {data.unlinked_staff.length > 5 && (
            <p className="mt-3 text-xs text-slate-500">
              +{data.unlinked_staff.length - 5} pengurus
              lainnya.
            </p>
          )}
        </div>
      )}
    </section>
  );
}