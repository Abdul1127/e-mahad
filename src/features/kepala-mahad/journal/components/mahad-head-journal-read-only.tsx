import type {
  MahadHeadJournalChecklistItem,
} from "../schemas/mahad-head-journal-schema";

type Props = {
  checklist:
    MahadHeadJournalChecklistItem[];

  performanceNotes:
    string | null;

  obstaclesFollowUp:
    string | null;
};

export function MahadHeadJournalReadOnly({
  checklist,
  performanceNotes,
  obstaclesFollowUp,
}: Props) {
  const pillars =
    Array.from(
      new Map(
        checklist.map(
          (item) => [
            item.pillar_code,
            item.pillar_name,
          ],
        ),
      ),
    );

  return (
    <div className="space-y-6">
      {pillars.map(
        ([
          pillarCode,
          pillarName,
        ]) => {
          const items =
            checklist.filter(
              (item) =>
                item.pillar_code ===
                  pillarCode &&
                item.is_checked,
            );

          return (
            <section
              key={
                pillarCode
              }
              className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6"
            >
              <h2 className="text-lg font-bold text-ink">
                {pillarName}
              </h2>

              <p className="mt-1 text-xs text-muted">
                Ekuivalensi 3 JTM
              </p>

              {items.length ===
              0 ? (
                <p className="mt-4 text-sm text-muted">
                  Tidak ada kegiatan
                  yang dipilih pada
                  pilar ini.
                </p>
              ) : (
                <div className="mt-4 space-y-2">
                  {items.map(
                    (item) => (
                      <div
                        key={
                          item.id
                        }
                        className="flex gap-3 rounded-2xl border border-emerald-100 bg-emerald-50 p-4"
                      >
                        <span className="font-bold text-emerald-700">
                          ✓
                        </span>

                        <p className="text-sm leading-6 text-emerald-900">
                          {
                            item.label
                          }
                        </p>
                      </div>
                    ),
                  )}
                </div>
              )}
            </section>
          );
        },
      )}

      <section className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Catatan Kinerja
        </p>

        <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-slate-700">
          {performanceNotes ||
            "Tidak ada catatan."}
        </p>
      </section>

      <section className="rounded-3xl border border-line bg-white p-5 shadow-soft sm:p-6">
        <p className="text-xs font-semibold uppercase tracking-[0.14em] text-brand-600">
          Kendala dan Tindak Lanjut
        </p>

        <p className="mt-3 whitespace-pre-wrap text-sm leading-7 text-slate-700">
          {obstaclesFollowUp ||
            "Tidak ada kendala atau tindak lanjut yang dicatat."}
        </p>
      </section>
    </div>
  );
}