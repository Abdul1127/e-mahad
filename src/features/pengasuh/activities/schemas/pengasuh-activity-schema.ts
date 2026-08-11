import { z } from "zod";

export const activityAttendanceStatusSchema =
  z.enum([
    "present",
    "permission",
    "sick",
    "absent",
  ]);

export const activityScheduleStatusSchema =
  z.enum([
    "scheduled",
    "completed",
    "cancelled",
  ]);

export const activityCareGroupSchema =
  z.object({
    id:
      z.string().uuid(),

    code:
      z.string(),

    name:
      z.string(),

    gender:
      z.enum([
        "male",
        "female",
      ]),
  });

export const pengasuhActivityScheduleListSchema =
  z.object({
    generated_at:
      z.string(),

    academic_year:
      z.object({
        id:
          z.string().uuid(),

        name:
          z.string(),
      }),

    staff:
      z.object({
        id:
          z.string().uuid(),

        full_name:
          z.string(),
      }),

    filters:
      z.object({
        date_from:
          z.string(),

        date_to:
          z.string(),
      }),

    groups:
      z.array(
        activityCareGroupSchema,
      ),

    summary:
      z.object({
        total_count:
          z.number()
            .int()
            .nonnegative(),

        today_count:
          z.number()
            .int()
            .nonnegative(),

        completed_count:
          z.number()
            .int()
            .nonnegative(),

        cancelled_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    items:
      z.array(
        z.object({
          id:
            z.string().uuid(),

          activity_date:
            z.string(),

          start_time:
            z.string(),

          end_time:
            z.string().nullable(),

          activity_name:
            z.string(),

          location:
            z.string().nullable(),

          notes:
            z.string().nullable(),

          status:
            activityScheduleStatusSchema,

          care_group:
            activityCareGroupSchema,

          attendance:
            z.object({
              eligible_count:
                z.number()
                  .int()
                  .nonnegative(),

              recorded_count:
                z.number()
                  .int()
                  .nonnegative(),
            }),
        }),
      ),
  });

export const pengasuhActivityScheduleDetailSchema =
  z.object({
    schedule:
      z.object({
        id:
          z.string().uuid(),

        activity_date:
          z.string(),

        start_time:
          z.string(),

        end_time:
          z.string().nullable(),

        activity_name:
          z.string(),

        location:
          z.string().nullable(),

        notes:
          z.string().nullable(),

        status:
          activityScheduleStatusSchema,

        can_record_attendance:
          z.boolean(),

        care_group:
          activityCareGroupSchema,
      }),

    summary:
      z.object({
        eligible_count:
          z.number()
            .int()
            .nonnegative(),

        recorded_count:
          z.number()
            .int()
            .nonnegative(),

        present_count:
          z.number()
            .int()
            .nonnegative(),

        permission_count:
          z.number()
            .int()
            .nonnegative(),

        sick_count:
          z.number()
            .int()
            .nonnegative(),

        absent_count:
          z.number()
            .int()
            .nonnegative(),
      }),

    students:
      z.array(
        z.object({
          id:
            z.string().uuid(),

          legacy_student_id:
            z.string().nullable(),

          nis:
            z.string().nullable(),

          full_name:
            z.string(),

          gender:
            z.enum([
              "male",
              "female",
            ]),

          attendance:
            z.object({
              id:
                z.string().uuid(),

              status:
                activityAttendanceStatusSchema,

              notes:
                z.string().nullable(),
            })
            .nullable(),
        }),
      ),
  });

export type PengasuhActivityScheduleListData =
  z.infer<
    typeof pengasuhActivityScheduleListSchema
  >;

export type PengasuhActivityScheduleDetailData =
  z.infer<
    typeof pengasuhActivityScheduleDetailSchema
  >;

export type ActivityAttendanceStatus =
  z.infer<
    typeof activityAttendanceStatusSchema
  >;