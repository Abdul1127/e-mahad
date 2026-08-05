import {
  AppIcon,
  type AppIconName,
} from "@/components/app-shell/app-icon";

type AdminMetricCardProps = {
  label: string;
  value: string;
  description: string;
  icon: AppIconName;
};

export function AdminMetricCard({
  label,
  value,
  description,
  icon,
}: AdminMetricCardProps) {
  return (
    <article className="rounded-2xl border border-line bg-white p-5 shadow-soft">
      <div className="flex items-start justify-between gap-4">
        <div className="min-w-0">
          <p className="text-sm font-medium text-muted">
            {label}
          </p>

          <p className="mt-3 truncate text-3xl font-bold tracking-tight text-ink">
            {value}
          </p>
        </div>

        <div className="grid size-11 shrink-0 place-items-center rounded-2xl bg-brand-50 text-brand-700">
          <AppIcon
            name={icon}
            className="size-5"
          />
        </div>
      </div>

      <p className="mt-4 text-xs leading-5 text-slate-500">
        {description}
      </p>
    </article>
  );
}