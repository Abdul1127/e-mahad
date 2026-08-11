import {
  notFound,
} from "next/navigation";

import {
  z,
} from "zod";

import {
  PengasuhActivityScheduleDetail,
} from "@/features/pengasuh/activities/components/pengasuh-activity-schedule-detail";

import {
  getPengasuhActivityScheduleDetailData,
} from "@/features/pengasuh/activities/data/get-pengasuh-activity-schedule-detail-data";

import {
  requireRole,
} from "@/lib/auth/guards";

type PageProps = {
  params:
    Promise<{
      scheduleId:
        string;
    }>;

  searchParams:
    Promise<{
      saved?:
        string | string[];
    }>;
};

export default async function PengasuhJadwalDetailPage({
  params,
  searchParams,
}: PageProps) {
  await requireRole(
    "pengasuh",
  );

  const {
    scheduleId,
  } = await params;

  const validation =
    z.string()
      .uuid()
      .safeParse(
        scheduleId,
      );

  if (
    !validation.success
  ) {
    notFound();
  }

  const query =
    await searchParams;

  const rawSaved =
    Array.isArray(
      query.saved,
    )
      ? query.saved[0]
      : query.saved;

  const data =
    await getPengasuhActivityScheduleDetailData(
      validation.data,
    );

  return (
    <PengasuhActivityScheduleDetail
      data={
        data
      }
      saved={
        rawSaved ===
        "1"
      }
    />
  );
}