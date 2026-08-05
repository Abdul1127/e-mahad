import { AppShell } from "@/components/app-shell/app-shell";
import { getActiveRole } from "@/lib/auth/get-active-role";
import { requireAccessContext } from "@/lib/auth/guards";

type ProtectedLayoutProps = Readonly<{
  children: React.ReactNode;
}>;

export default async function ProtectedLayout({
  children,
}: ProtectedLayoutProps) {
  const context = await requireAccessContext();
  const activeRole = await getActiveRole();

  return (
    <AppShell
      context={context}
      activeRole={activeRole}
    >
      {children}
    </AppShell>
  );
}