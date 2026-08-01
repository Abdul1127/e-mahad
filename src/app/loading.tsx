export default function RootLoading() {
  return (
    <main className="flex min-h-screen items-center justify-center px-6">
      <div className="text-center">
        <div
          aria-hidden="true"
          className="mx-auto size-10 animate-spin rounded-full border-4 border-slate-200 border-t-emerald-700"
        />

        <p className="mt-4 text-sm font-medium text-slate-600">
          Memuat E-Ma&apos;had...
        </p>
      </div>
    </main>
  );
}