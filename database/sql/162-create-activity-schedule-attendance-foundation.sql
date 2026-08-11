begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 162-create-activity-schedule-attendance-foundation.sql
--
-- MVP JADWAL + ABSENSI ASRAMA
--
-- TABLE:
--
-- activity_schedules
-- activity_attendances
--
-- ALUR:
--
-- Pengasuh
--   ↓
-- Kelompok Asrama
--   ↓
-- Jadwal Kegiatan
--   ↓
-- Daftar Santri Kelompok
--   ↓
-- Hadir / Izin / Sakit / Alpa
--
-- STATUS JADWAL:
--
-- scheduled
-- completed
-- cancelled
--
-- STATUS ABSENSI:
--
-- present
-- permission
-- sick
-- absent
--
-- EXISTING FOUNDATION:
--
-- care_groups
-- care_group_members
-- caregiver_assignments
--
-- =========================================================


-- =========================================================
-- 1. ACTIVITY SCHEDULES
-- =========================================================

create table if not exists
public.activity_schedules (
    id uuid
        primary key
        default gen_random_uuid(),

    academic_year_id uuid
        not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    care_group_id uuid
        not null
        references public.care_groups(id)
        on update cascade
        on delete restrict,

    activity_date date
        not null,

    start_time time without time zone
        not null,

    end_time time without time zone,

    activity_name text
        not null,

    location text,

    notes text,

    status text
        not null
        default 'scheduled',

    created_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    updated_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    cancelled_by_staff_id uuid
        references public.staff(id)
        on update cascade
        on delete restrict,

    cancelled_at timestamptz,

    cancellation_reason text,

    created_at timestamptz
        not null
        default now(),

    updated_at timestamptz
        not null
        default now(),

    constraint activity_schedules_name_check
        check (
            length(
                btrim(activity_name)
            )
            between 2 and 150
        ),

    constraint activity_schedules_location_check
        check (
            location is null

            or length(location)
               <= 150
        ),

    constraint activity_schedules_notes_check
        check (
            notes is null

            or length(notes)
               <= 1000
        ),

    constraint activity_schedules_status_check
        check (
            status in (
                'scheduled',
                'completed',
                'cancelled'
            )
        ),

    constraint activity_schedules_time_check
        check (
            end_time is null

            or end_time >
               start_time
        ),

    constraint activity_schedules_cancellation_check
        check (
            (
                status <>
                'cancelled'

                and cancelled_by_staff_id
                    is null

                and cancelled_at
                    is null

                and cancellation_reason
                    is null
            )

            or

            (
                status =
                'cancelled'

                and cancelled_by_staff_id
                    is not null

                and cancelled_at
                    is not null

                and cancellation_reason
                    is not null

                and length(
                    btrim(
                        cancellation_reason
                    )
                ) > 0
            )
        )
);


-- =========================================================
-- 2. ATTENDANCE
-- =========================================================

create table if not exists
public.activity_attendances (
    id uuid
        primary key
        default gen_random_uuid(),

    schedule_id uuid
        not null
        references public.activity_schedules(id)
        on update cascade
        on delete cascade,

    student_id uuid
        not null
        references public.students(id)
        on update cascade
        on delete restrict,

    attendance_status text
        not null,

    notes text,

    recorded_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    updated_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    created_at timestamptz
        not null
        default now(),

    updated_at timestamptz
        not null
        default now(),

    constraint activity_attendances_unique_student
        unique (
            schedule_id,
            student_id
        ),

    constraint activity_attendances_status_check
        check (
            attendance_status in (
                'present',
                'permission',
                'sick',
                'absent'
            )
        ),

    constraint activity_attendances_notes_check
        check (
            notes is null

            or length(notes)
               <= 500
        )
);


-- =========================================================
-- 3. INDEXES
-- =========================================================

create index if not exists
activity_schedules_academic_year_idx

on public.activity_schedules (
    academic_year_id
);


create index if not exists
activity_schedules_care_group_idx

on public.activity_schedules (
    care_group_id
);


create index if not exists
activity_schedules_date_idx

on public.activity_schedules (
    activity_date desc,
    start_time
);


create index if not exists
activity_schedules_group_date_idx

on public.activity_schedules (
    care_group_id,
    activity_date desc
);


create index if not exists
activity_attendances_schedule_idx

on public.activity_attendances (
    schedule_id
);


create index if not exists
activity_attendances_student_idx

on public.activity_attendances (
    student_id
);


-- =========================================================
-- 4. UPDATED_AT TRIGGERS
-- =========================================================

drop trigger if exists
set_activity_schedules_updated_at
on public.activity_schedules;


create trigger
set_activity_schedules_updated_at

before update
on public.activity_schedules

for each row

execute function
public.set_updated_at();


drop trigger if exists
set_activity_attendances_updated_at
on public.activity_attendances;


create trigger
set_activity_attendances_updated_at

before update
on public.activity_attendances

for each row

execute function
public.set_updated_at();


-- =========================================================
-- 5. ATTENDANCE DATA INTEGRITY
--
-- Santri yang diabsen harus benar-benar menjadi anggota
-- kelompok pada tanggal kegiatan.
-- =========================================================

create or replace function
public.validate_activity_attendance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_care_group_id uuid;
    v_activity_date date;
    v_schedule_status text;
begin

    select
        schedule.care_group_id,
        schedule.activity_date,
        schedule.status

    into
        v_care_group_id,
        v_activity_date,
        v_schedule_status

    from public.activity_schedules
        as schedule

    where schedule.id =
          new.schedule_id;


    if v_care_group_id is null then
        raise exception
            'Jadwal kegiatan tidak ditemukan.';
    end if;


    if v_schedule_status =
       'cancelled'
    then
        raise exception
            'Absensi tidak dapat dicatat pada jadwal yang dibatalkan.';
    end if;


    if not exists (
        select 1

        from public.care_group_members
            as membership

        inner join public.students
            as student

            on student.id =
               membership.student_id

        where membership.care_group_id =
              v_care_group_id

          and membership.student_id =
              new.student_id

          and membership.joined_at <=
              v_activity_date

          and (
              membership.left_at
                  is null

              or membership.left_at >=
                 v_activity_date
          )

          and student.status =
              'active'

          and student.deleted_at
              is null
    ) then
        raise exception
            'Santri bukan anggota kelompok pada tanggal kegiatan.';
    end if;


    return new;

end;
$function$;


drop trigger if exists
validate_activity_attendance_trigger
on public.activity_attendances;


create trigger
validate_activity_attendance_trigger

before insert or update
on public.activity_attendances

for each row

execute function
public.validate_activity_attendance();


-- =========================================================
-- 6. RLS
-- =========================================================

alter table
public.activity_schedules
enable row level security;


alter table
public.activity_attendances
enable row level security;


drop policy if exists
"activity_schedules_service_role_all"
on public.activity_schedules;


create policy
"activity_schedules_service_role_all"

on public.activity_schedules

for all

to service_role

using (
    true
)

with check (
    true
);


drop policy if exists
"activity_attendances_service_role_all"
on public.activity_attendances;


create policy
"activity_attendances_service_role_all"

on public.activity_attendances

for all

to service_role

using (
    true
)

with check (
    true
);


revoke all
on table
public.activity_schedules
from anon;


revoke all
on table
public.activity_schedules
from authenticated;


revoke all
on table
public.activity_attendances
from anon;


revoke all
on table
public.activity_attendances
from authenticated;


grant select,
      insert,
      update,
      delete
on table
public.activity_schedules
to service_role;


grant select,
      insert,
      update,
      delete
on table
public.activity_attendances
to service_role;


-- =========================================================
-- 7. CREATE SCHEDULE
-- =========================================================

create or replace function
public.create_pengasuh_activity_schedule(
    p_care_group_id uuid,
    p_activity_date date,
    p_start_time time without time zone,
    p_end_time time without time zone default null,
    p_activity_name text default null,
    p_location text default null,
    p_notes text default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;
    v_staff_name text;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_group_name text;

    v_activity_name text;
    v_location text;
    v_notes text;

    v_schedule_id uuid;
begin

    -- =====================================================
    -- AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses jadwal Pengasuh ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    select
        staff.id,
        staff.full_name

    into
        v_staff_id,
        v_staff_name

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Pengasuh aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- CURRENT YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.name,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
        v_academic_year_name,
        v_academic_year_start,
        v_academic_year_end

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;


    -- =====================================================
    -- INPUT
    -- =====================================================

    if p_care_group_id is null then
        raise exception
            'Kelompok asrama wajib dipilih.';
    end if;


    if p_activity_date is null then
        raise exception
            'Tanggal kegiatan wajib diisi.';
    end if;


    if p_activity_date <
       v_academic_year_start

       or p_activity_date >
          v_academic_year_end
    then
        raise exception
            'Tanggal kegiatan berada di luar tahun ajaran aktif.';
    end if;


    if p_start_time is null then
        raise exception
            'Waktu mulai kegiatan wajib diisi.';
    end if;


    if p_end_time is not null
       and p_end_time <=
           p_start_time
    then
        raise exception
            'Waktu selesai harus setelah waktu mulai.';
    end if;


    v_activity_name :=
        nullif(
            btrim(
                coalesce(
                    p_activity_name,
                    ''
                )
            ),
            ''
        );


    if v_activity_name is null
       or length(
           v_activity_name
       ) < 2
    then
        raise exception
            'Nama kegiatan wajib diisi.';
    end if;


    if length(
        v_activity_name
    ) > 150 then
        raise exception
            'Nama kegiatan maksimal 150 karakter.';
    end if;


    v_location :=
        nullif(
            btrim(
                coalesce(
                    p_location,
                    ''
                )
            ),
            ''
        );


    if v_location is not null
       and length(
           v_location
       ) > 150
    then
        raise exception
            'Lokasi maksimal 150 karakter.';
    end if;


    v_notes :=
        nullif(
            btrim(
                coalesce(
                    p_notes,
                    ''
                )
            ),
            ''
        );


    if v_notes is not null
       and length(
           v_notes
       ) > 1000
    then
        raise exception
            'Catatan maksimal 1000 karakter.';
    end if;


    -- =====================================================
    -- GROUP + CAREGIVER ASSIGNMENT
    -- =====================================================

    select
        care_group.name

    into
        v_group_name

    from public.care_groups
        as care_group

    inner join public.caregiver_assignments
        as assignment

        on assignment.care_group_id =
           care_group.id

    where care_group.id =
          p_care_group_id

      and care_group.academic_year_id =
          v_academic_year_id

      and care_group.is_active =
          true

      and assignment.staff_id =
          v_staff_id

      and assignment.is_active =
          true

      and assignment.assigned_at <=
          p_activity_date

      and (
          assignment.ended_at
              is null

          or assignment.ended_at >=
             p_activity_date
      )

    limit 1;


    if v_group_name is null then
        raise exception using
            errcode = '42501',
            message = 'Pengasuh tidak memiliki akses ke kelompok asrama tersebut.';
    end if;


    -- =====================================================
    -- INSERT
    -- =====================================================

    insert into public.activity_schedules (
        academic_year_id,
        care_group_id,
        activity_date,
        start_time,
        end_time,
        activity_name,
        location,
        notes,
        status,
        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        p_care_group_id,
        p_activity_date,
        p_start_time,
        p_end_time,
        v_activity_name,
        v_location,
        v_notes,
        'scheduled',
        v_staff_id,
        v_staff_id
    )
    returning id
    into v_schedule_id;


    return jsonb_build_object(
        'success',
        true,

        'message',
        'Jadwal kegiatan berhasil dibuat.',

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name
        ),

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'full_name',
            v_staff_name
        ),

        'schedule',
        jsonb_build_object(
            'id',
            v_schedule_id,

            'care_group_id',
            p_care_group_id,

            'care_group_name',
            v_group_name,

            'activity_date',
            p_activity_date,

            'start_time',
            p_start_time,

            'end_time',
            p_end_time,

            'activity_name',
            v_activity_name,

            'location',
            v_location,

            'notes',
            v_notes,

            'status',
            'scheduled'
        )
    );

end;
$function$;


-- =========================================================
-- 8. LIST SCHEDULES
-- =========================================================

create or replace function
public.get_pengasuh_activity_schedule_list(
    p_date_from date default null,
    p_date_to date default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;
    v_staff_name text;

    v_academic_year_id uuid;
    v_academic_year_name text;

    v_date_from date;
    v_date_to date;

    v_groups jsonb :=
        '[]'::jsonb;

    v_items jsonb :=
        '[]'::jsonb;

    v_total_count integer :=
        0;

    v_today_count integer :=
        0;

    v_completed_count integer :=
        0;

    v_cancelled_count integer :=
        0;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses jadwal Pengasuh ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    select
        staff.id,
        staff.full_name

    into
        v_staff_id,
        v_staff_name

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Pengasuh aktif tidak ditemukan.';
    end if;


    select
        academic_year.id,
        academic_year.name

    into
        v_academic_year_id,
        v_academic_year_name

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;


    v_date_from :=
        coalesce(
            p_date_from,
            current_date - 7
        );


    v_date_to :=
        coalesce(
            p_date_to,
            current_date + 30
        );


    if v_date_to <
       v_date_from
    then
        raise exception
            'Rentang tanggal jadwal tidak valid.';
    end if;


    -- =====================================================
    -- GROUP OPTIONS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                group_data.payload

                order by
                    group_data.group_name
            ),
            '[]'::jsonb
        )

    into
        v_groups

    from (
        select distinct
            care_group.id,

            care_group.name
                as group_name,

            jsonb_build_object(
                'id',
                care_group.id,

                'code',
                care_group.code,

                'name',
                care_group.name,

                'gender',
                care_group.gender::text
            )
                as payload

        from public.caregiver_assignments
            as assignment

        inner join public.care_groups
            as care_group

            on care_group.id =
               assignment.care_group_id

        where assignment.staff_id =
              v_staff_id

          and assignment.is_active =
              true

          and (
              assignment.ended_at
                  is null

              or assignment.ended_at >=
                 current_date
          )

          and care_group.academic_year_id =
              v_academic_year_id

          and care_group.is_active =
              true
    )
        as group_data;


    -- =====================================================
    -- ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                schedule_data.payload

                order by
                    schedule_data.activity_date,
                    schedule_data.start_time,
                    schedule_data.schedule_id
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            schedule.id
                as schedule_id,

            schedule.activity_date,

            schedule.start_time,

            jsonb_build_object(
                'id',
                schedule.id,

                'activity_date',
                schedule.activity_date,

                'start_time',
                schedule.start_time,

                'end_time',
                schedule.end_time,

                'activity_name',
                schedule.activity_name,

                'location',
                schedule.location,

                'notes',
                schedule.notes,

                'status',
                schedule.status,

                'care_group',
                jsonb_build_object(
                    'id',
                    care_group.id,

                    'code',
                    care_group.code,

                    'name',
                    care_group.name,

                    'gender',
                    care_group.gender::text
                ),

                'attendance',
                jsonb_build_object(
                    'eligible_count',
                    (
                        select
                            count(*)::integer

                        from public.care_group_members
                            as membership

                        inner join public.students
                            as student

                            on student.id =
                               membership.student_id

                        where membership.care_group_id =
                              schedule.care_group_id

                          and membership.joined_at <=
                              schedule.activity_date

                          and (
                              membership.left_at
                                  is null

                              or membership.left_at >=
                                 schedule.activity_date
                          )

                          and student.status =
                              'active'

                          and student.deleted_at
                              is null
                    ),

                    'recorded_count',
                    (
                        select
                            count(*)::integer

                        from public.activity_attendances
                            as attendance

                        where attendance.schedule_id =
                              schedule.id
                    )
                )
            )
                as payload

        from public.activity_schedules
            as schedule

        inner join public.care_groups
            as care_group

            on care_group.id =
               schedule.care_group_id

        where schedule.academic_year_id =
              v_academic_year_id

          and schedule.activity_date
              between
              v_date_from
              and
              v_date_to

          and exists (
              select 1

              from public.caregiver_assignments
                  as assignment

              where assignment.care_group_id =
                    schedule.care_group_id

                and assignment.staff_id =
                    v_staff_id

                and assignment.assigned_at <=
                    schedule.activity_date

                and (
                    assignment.ended_at
                        is null

                    or assignment.ended_at >=
                       schedule.activity_date
                )
          )
    )
        as schedule_data;


    -- =====================================================
    -- SUMMARY
    -- =====================================================

    select
        count(*)::integer,

        count(*) filter (
            where schedule.activity_date =
                  current_date
        )::integer,

        count(*) filter (
            where schedule.status =
                  'completed'
        )::integer,

        count(*) filter (
            where schedule.status =
                  'cancelled'
        )::integer

    into
        v_total_count,
        v_today_count,
        v_completed_count,
        v_cancelled_count

    from public.activity_schedules
        as schedule

    where schedule.academic_year_id =
          v_academic_year_id

      and schedule.activity_date
          between
          v_date_from
          and
          v_date_to

      and exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.care_group_id =
                schedule.care_group_id

            and assignment.staff_id =
                v_staff_id

            and assignment.assigned_at <=
                schedule.activity_date

            and (
                assignment.ended_at
                    is null

                or assignment.ended_at >=
                   schedule.activity_date
            )
      );


    return jsonb_build_object(
        'generated_at',
        now(),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name
        ),

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'full_name',
            v_staff_name
        ),

        'filters',
        jsonb_build_object(
            'date_from',
            v_date_from,

            'date_to',
            v_date_to
        ),

        'groups',
        v_groups,

        'summary',
        jsonb_build_object(
            'total_count',
            v_total_count,

            'today_count',
            v_today_count,

            'completed_count',
            v_completed_count,

            'cancelled_count',
            v_cancelled_count
        ),

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- 9. SCHEDULE DETAIL + STUDENTS
-- =========================================================

create or replace function
public.get_pengasuh_activity_schedule_detail(
    p_schedule_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_academic_year_id uuid;

    v_care_group_id uuid;
    v_activity_date date;

    v_schedule jsonb;

    v_students jsonb :=
        '[]'::jsonb;

    v_eligible_count integer :=
        0;

    v_recorded_count integer :=
        0;

    v_present_count integer :=
        0;

    v_permission_count integer :=
        0;

    v_sick_count integer :=
        0;

    v_absent_count integer :=
        0;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses absensi Pengasuh ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Pengasuh aktif tidak ditemukan.';
    end if;


    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    limit 1;


    select
        schedule.care_group_id,
        schedule.activity_date,

        jsonb_build_object(
            'id',
            schedule.id,

            'activity_date',
            schedule.activity_date,

            'start_time',
            schedule.start_time,

            'end_time',
            schedule.end_time,

            'activity_name',
            schedule.activity_name,

            'location',
            schedule.location,

            'notes',
            schedule.notes,

            'status',
            schedule.status,

            'can_record_attendance',
            (
                schedule.status <>
                    'cancelled'

                and schedule.activity_date <=
                    current_date
            ),

            'care_group',
            jsonb_build_object(
                'id',
                care_group.id,

                'code',
                care_group.code,

                'name',
                care_group.name,

                'gender',
                care_group.gender::text
            )
        )

    into
        v_care_group_id,
        v_activity_date,
        v_schedule

    from public.activity_schedules
        as schedule

    inner join public.care_groups
        as care_group

        on care_group.id =
           schedule.care_group_id

    where schedule.id =
          p_schedule_id

      and schedule.academic_year_id =
          v_academic_year_id

      and exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.care_group_id =
                schedule.care_group_id

            and assignment.staff_id =
                v_staff_id

            and assignment.assigned_at <=
                schedule.activity_date

            and (
                assignment.ended_at
                    is null

                or assignment.ended_at >=
                   schedule.activity_date
            )
      )

    limit 1;


    if v_schedule is null then
        raise exception using
            errcode = '42501',
            message = 'Jadwal tidak ditemukan atau tidak dapat diakses oleh Pengasuh.';
    end if;


    -- =====================================================
    -- STUDENTS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                student_data.payload

                order by
                    student_data.full_name,
                    student_data.student_id
            ),
            '[]'::jsonb
        )

    into
        v_students

    from (
        select
            student.id
                as student_id,

            student.full_name,

            jsonb_build_object(
                'id',
                student.id,

                'legacy_student_id',
                student.legacy_student_id,

                'nis',
                student.nis,

                'full_name',
                student.full_name,

                'gender',
                student.gender::text,

                'attendance',
                case
                    when attendance.id
                         is null
                    then
                        null

                    else
                        jsonb_build_object(
                            'id',
                            attendance.id,

                            'status',
                            attendance.attendance_status,

                            'notes',
                            attendance.notes
                        )
                end
            )
                as payload

        from public.care_group_members
            as membership

        inner join public.students
            as student

            on student.id =
               membership.student_id

        left join public.activity_attendances
            as attendance

            on attendance.schedule_id =
               p_schedule_id

           and attendance.student_id =
               student.id

        where membership.care_group_id =
              v_care_group_id

          and membership.joined_at <=
              v_activity_date

          and (
              membership.left_at
                  is null

              or membership.left_at >=
                 v_activity_date
          )

          and student.status =
              'active'

          and student.deleted_at
              is null
    )
        as student_data;


    -- =====================================================
    -- SUMMARY
    -- =====================================================

    select
        count(*)::integer

    into
        v_eligible_count

    from public.care_group_members
        as membership

    inner join public.students
        as student

        on student.id =
           membership.student_id

    where membership.care_group_id =
          v_care_group_id

      and membership.joined_at <=
          v_activity_date

      and (
          membership.left_at
              is null

          or membership.left_at >=
             v_activity_date
      )

      and student.status =
          'active'

      and student.deleted_at
          is null;


    select
        count(*)::integer,

        count(*) filter (
            where attendance.attendance_status =
                  'present'
        )::integer,

        count(*) filter (
            where attendance.attendance_status =
                  'permission'
        )::integer,

        count(*) filter (
            where attendance.attendance_status =
                  'sick'
        )::integer,

        count(*) filter (
            where attendance.attendance_status =
                  'absent'
        )::integer

    into
        v_recorded_count,
        v_present_count,
        v_permission_count,
        v_sick_count,
        v_absent_count

    from public.activity_attendances
        as attendance

    where attendance.schedule_id =
          p_schedule_id;


    return jsonb_build_object(
        'schedule',
        v_schedule,

        'summary',
        jsonb_build_object(
            'eligible_count',
            v_eligible_count,

            'recorded_count',
            v_recorded_count,

            'present_count',
            v_present_count,

            'permission_count',
            v_permission_count,

            'sick_count',
            v_sick_count,

            'absent_count',
            v_absent_count
        ),

        'students',
        v_students
    );

end;
$function$;


-- =========================================================
-- 10. SAVE ATTENDANCE BATCH
-- =========================================================

create or replace function
public.save_pengasuh_activity_attendance(
    p_schedule_id uuid,
    p_entries jsonb
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_staff_id uuid;

    v_academic_year_id uuid;

    v_care_group_id uuid;
    v_activity_date date;
    v_schedule_status text;

    v_entry jsonb;

    v_student_id_text text;
    v_student_id uuid;

    v_status text;
    v_notes text;

    v_entry_count integer;
    v_distinct_student_count integer;

    v_eligible_count integer;
    v_recorded_count integer;
begin

    -- =====================================================
    -- AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses absensi Pengasuh ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Pengasuh aktif tidak ditemukan.';
    end if;


    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    limit 1;


    -- =====================================================
    -- SCHEDULE LOCK
    -- =====================================================

    select
        schedule.care_group_id,
        schedule.activity_date,
        schedule.status

    into
        v_care_group_id,
        v_activity_date,
        v_schedule_status

    from public.activity_schedules
        as schedule

    where schedule.id =
          p_schedule_id

      and schedule.academic_year_id =
          v_academic_year_id

    for update;


    if not found then
        raise exception
            'Jadwal kegiatan tidak ditemukan.';
    end if;


    if not exists (
        select 1

        from public.caregiver_assignments
            as assignment

        where assignment.care_group_id =
              v_care_group_id

          and assignment.staff_id =
              v_staff_id

          and assignment.assigned_at <=
              v_activity_date

          and (
              assignment.ended_at
                  is null

              or assignment.ended_at >=
                 v_activity_date
          )
    ) then
        raise exception using
            errcode = '42501',
            message = 'Pengasuh tidak memiliki akses ke jadwal tersebut.';
    end if;


    if v_schedule_status =
       'cancelled'
    then
        raise exception
            'Jadwal yang dibatalkan tidak dapat diabsen.';
    end if;


    if v_activity_date >
       current_date
    then
        raise exception
            'Absensi belum dapat dicatat untuk kegiatan yang belum berlangsung.';
    end if;


    -- =====================================================
    -- JSON
    -- =====================================================

    if p_entries is null
       or jsonb_typeof(
           p_entries
       ) <>
       'array'
    then
        raise exception
            'Data absensi harus berupa array.';
    end if;


    v_entry_count :=
        jsonb_array_length(
            p_entries
        );


    if v_entry_count =
       0
    then
        raise exception
            'Data absensi tidak boleh kosong.';
    end if;


    select
        count(
            distinct
            entry.value ->> 'student_id'
        )::integer

    into
        v_distinct_student_count

    from jsonb_array_elements(
        p_entries
    )
        as entry(value);


    if v_distinct_student_count <>
       v_entry_count
    then
        raise exception
            'Terdapat santri ganda pada data absensi.';
    end if;


    -- =====================================================
    -- SAVE EACH STUDENT
    -- =====================================================

    for v_entry in

        select
            value

        from jsonb_array_elements(
            p_entries
        )

    loop

        v_student_id_text :=
            nullif(
                btrim(
                    coalesce(
                        v_entry
                        ->> 'student_id',
                        ''
                    )
                ),
                ''
            );


        if v_student_id_text is null
           or v_student_id_text !~
              '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
        then
            raise exception
                'ID santri pada data absensi tidak valid.';
        end if;


        v_student_id :=
            v_student_id_text::uuid;


        v_status :=
            lower(
                btrim(
                    coalesce(
                        v_entry
                        ->> 'status',
                        ''
                    )
                )
            );


        if v_status not in (
            'present',
            'permission',
            'sick',
            'absent'
        ) then
            raise exception
                'Status absensi tidak valid.';
        end if;


        v_notes :=
            nullif(
                btrim(
                    coalesce(
                        v_entry
                        ->> 'notes',
                        ''
                    )
                ),
                ''
            );


        if v_notes is not null
           and length(
               v_notes
           ) > 500
        then
            raise exception
                'Catatan absensi maksimal 500 karakter.';
        end if;


        if not exists (
            select 1

            from public.care_group_members
                as membership

            inner join public.students
                as student

                on student.id =
                   membership.student_id

            where membership.care_group_id =
                  v_care_group_id

              and membership.student_id =
                  v_student_id

              and membership.joined_at <=
                  v_activity_date

              and (
                  membership.left_at
                      is null

                  or membership.left_at >=
                     v_activity_date
              )

              and student.status =
                  'active'

              and student.deleted_at
                  is null
        ) then
            raise exception
                'Santri bukan anggota kelompok pada tanggal kegiatan.';
        end if;


        insert into public.activity_attendances (
            schedule_id,
            student_id,
            attendance_status,
            notes,
            recorded_by_staff_id,
            updated_by_staff_id
        )
        values (
            p_schedule_id,
            v_student_id,
            v_status,
            v_notes,
            v_staff_id,
            v_staff_id
        )

        on conflict (
            schedule_id,
            student_id
        )

        do update
        set
            attendance_status =
                excluded.attendance_status,

            notes =
                excluded.notes,

            updated_by_staff_id =
                v_staff_id;

    end loop;


    -- =====================================================
    -- AUTO COMPLETE
    -- =====================================================

    select
        count(*)::integer

    into
        v_eligible_count

    from public.care_group_members
        as membership

    inner join public.students
        as student

        on student.id =
           membership.student_id

    where membership.care_group_id =
          v_care_group_id

      and membership.joined_at <=
          v_activity_date

      and (
          membership.left_at
              is null

          or membership.left_at >=
             v_activity_date
      )

      and student.status =
          'active'

      and student.deleted_at
          is null;


    select
        count(*)::integer

    into
        v_recorded_count

    from public.activity_attendances
        as attendance

    where attendance.schedule_id =
          p_schedule_id;


    update public.activity_schedules
    set
        status =
            case
                when v_eligible_count > 0
                     and v_recorded_count >=
                         v_eligible_count
                then
                    'completed'

                else
                    'scheduled'
            end,

        updated_by_staff_id =
            v_staff_id

    where id =
          p_schedule_id;


    return public.get_pengasuh_activity_schedule_detail(
        p_schedule_id
    );

end;
$function$;


-- =========================================================
-- 11. FUNCTION PRIVILEGES
-- =========================================================

revoke all
on function
public.create_pengasuh_activity_schedule(
    uuid,
    date,
    time without time zone,
    time without time zone,
    text,
    text,
    text
)
from public;


revoke all
on function
public.create_pengasuh_activity_schedule(
    uuid,
    date,
    time without time zone,
    time without time zone,
    text,
    text,
    text
)
from anon;


grant execute
on function
public.create_pengasuh_activity_schedule(
    uuid,
    date,
    time without time zone,
    time without time zone,
    text,
    text,
    text
)
to authenticated;


revoke all
on function
public.get_pengasuh_activity_schedule_list(
    date,
    date
)
from public;


revoke all
on function
public.get_pengasuh_activity_schedule_list(
    date,
    date
)
from anon;


grant execute
on function
public.get_pengasuh_activity_schedule_list(
    date,
    date
)
to authenticated;


revoke all
on function
public.get_pengasuh_activity_schedule_detail(
    uuid
)
from public;


revoke all
on function
public.get_pengasuh_activity_schedule_detail(
    uuid
)
from anon;


grant execute
on function
public.get_pengasuh_activity_schedule_detail(
    uuid
)
to authenticated;


revoke all
on function
public.save_pengasuh_activity_attendance(
    uuid,
    jsonb
)
from public;


revoke all
on function
public.save_pengasuh_activity_attendance(
    uuid,
    jsonb
)
from anon;


grant execute
on function
public.save_pengasuh_activity_attendance(
    uuid,
    jsonb
)
to authenticated;


commit;