import { AppIcon } from "@/components/app-shell/app-icon";
import { roleDefinitions } from "@/config/roles";
import type { UserRole } from "@/lib/auth/types";

import { selectActiveRoleAction } from "../actions/select-active-role";

type RoleSelectionFormProps = {
  roles: UserRole[];
};

export function RoleSelectionForm({
  roles,
}: RoleSelectionFormProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      {roles.map((role) => {
        const definition =
          roleDefinitions[role.code];

        return (
          <form
            key={role.code}
            action={selectActiveRoleAction}
          >
            <input
              type="hidden"
              name="role"
              value={role.code}
            />

            <button
              type="submit"
              className="group h-full w-full rounded-3xl border border-line bg-white p-6 text-left shadow-soft transition hover:-translate-y-0.5 hover:border-brand-200 hover:shadow-panel"
            >
              <div className="flex items-start justify-between gap-4">
                <div className="grid size-12 shrink-0 place-items-center rounded-2xl bg-brand-50 text-brand-700 transition group-hover:bg-brand-700 group-hover:text-white">
                  <AppIcon
                    name="switch"
                    className="size-5"
                  />
                </div>

                <AppIcon
                  name="chevron-right"
                  className="mt-1 size-5 text-slate-300 transition group-hover:translate-x-1 group-hover:text-brand-600"
                />
              </div>

              <span className="mt-6 block text-xl font-bold text-ink">
                {definition.label}
              </span>

              <span className="mt-2 block text-sm leading-6 text-muted">
                {definition.description}
              </span>

              <span className="mt-6 block text-sm font-semibold text-brand-700">
                Gunakan role ini
              </span>
            </button>
          </form>
        );
      })}
    </div>
  );
}