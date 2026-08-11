import {
  PengasuhActivityScheduleList,
} from "@/features/pengasuh/activities/components/pengasuh-activity-schedule-list";

import {
  getPengasuhActivityScheduleListData,
} from "@/features/pengasuh/activities/data/get-pengasuh-activity-schedule-list-data";

import {
  requireRole,
} from "@/lib/auth/guards";

export default async function PengasuhJadwalPage() {
  await requireRole(
    "pengasuh",
  );

  const data =
    await getPengasuhActivityScheduleListData();

  return (
    <PengasuhActivityScheduleList
      data={
        data
      }
    />
  );
}