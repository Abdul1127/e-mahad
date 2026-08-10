begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 113-create-pembina-tahfiz-weekly-report-functions.sql
--
-- PURPOSE:
-- 1. Overview laporan Tahfiz per pekan
-- 2. Detail laporan satu santri
-- 3. Simpan / update draft
-- 4. Publish laporan
--
-- SECURITY:
-- - auth.uid()
-- - role pembina_tahfiz
-- - profile + staff aktif
-- - hanya kelompok assignment aktif
-- - hanya santri membership aktif kelompok tersebut
-- =========================================================


-- =========================================================
-- 1. WEEKLY REPORT OVERVIEW
-- =========================================================

create or replace function
public.get_pembina_tahfiz_weekly_report_overview(
    p_week_start date default null,
    p_search text default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_login_id text;

    v_staff_id uuid;
    v_legacy_staff_id text;
    v_full_name text;
    v_position text;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_week_start date;
    v_week_end date;

    v_search text;

    v_group_count integer := 0;
    v_student_count integer := 0;
    v_filtered_count integer := 0;

    v_not_created_count integer := 0;
    v_draft_count integer := 0;
    v_published_count integer := 0;

    v_items jsonb := '[]'::jsonb;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();

    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pembina_tahfiz'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Laporan Tahfiz ditolak.';
    end if;


    -- =====================================================
    -- B. PROFILE
    -- =====================================================

    select
        profile.login_id

    into
        v_login_id

    from public.profiles
        as profile

    where profile.id =
          v_profile_id

      and profile.is_active =
          true;


    if not found then
        raise exception using
            errcode = '42501',
            message = 'Profile Pembina Tahfiz tidak aktif.';
    end if;


    -- =====================================================
    -- C. STAFF
    -- =====================================================

    select
        staff.id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.position

    into
        v_staff_id,
        v_legacy_staff_id,
        v_full_name,
        v_position

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif Pembina Tahfiz tidak ditemukan.';
    end if;


    -- =====================================================
    -- D. CURRENT ACADEMIC YEAR
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
    -- E. WEEK
    -- =====================================================

    v_week_start :=
        coalesce(
            p_week_start,
            date_trunc(
                'week',
                current_date
            )::date
        );


    if extract(
        isodow
        from v_week_start
    ) <> 1
    then
        raise exception
            'Tanggal awal pekan harus hari Senin.';
    end if;


    v_week_end :=
        v_week_start + 6;


    if v_week_start <
       v_academic_year_start
       or v_week_end >
          v_academic_year_end
    then
        raise exception
            'Pekan berada di luar tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- F. SEARCH
    -- =====================================================

    v_search :=
        nullif(
            btrim(
                coalesce(
                    p_search,
                    ''
                )
            ),
            ''
        );


    -- =====================================================
    -- G. GROUP COUNT
    -- =====================================================

    select
        count(
            distinct assignment.tahfiz_group_id
        )::integer

    into
        v_group_count

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           assignment.tahfiz_group_id

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active =
          true

      and assignment.ended_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_academic_year_id;


    -- =====================================================
    -- H. STUDENT COUNT
    -- =====================================================

    select
        count(
            distinct student.id
        )::integer

    into
        v_student_count

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           assignment.tahfiz_group_id

    inner join public.tahfiz_group_members
        as membership
        on membership.tahfiz_group_id =
           tahfiz_group.id

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active =
          true

      and assignment.ended_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_academic_year_id

      and membership.is_active =
          true

      and membership.left_at
          is null

      and student.status =
          'active'

      and student.deleted_at
          is null;


    -- =====================================================
    -- I. REPORT STATUS SUMMARY
    -- =====================================================

    with own_students as (
        select distinct
            student.id
                as student_id

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               assignment.tahfiz_group_id

        inner join public.tahfiz_group_members
            as membership
            on membership.tahfiz_group_id =
               tahfiz_group.id

        inner join public.students
            as student
            on student.id =
               membership.student_id

        where assignment.staff_id =
              v_staff_id

          and assignment.is_active =
              true

          and assignment.ended_at
              is null

          and tahfiz_group.is_active =
              true

          and tahfiz_group.academic_year_id =
              v_academic_year_id

          and membership.is_active =
              true

          and membership.left_at
              is null

          and student.status =
              'active'

          and student.deleted_at
              is null
    )

    select
        count(*) filter (
            where report.id
                  is null
        )::integer,

        count(*) filter (
            where report.status =
                  'draft'
        )::integer,

        count(*) filter (
            where report.status =
                  'published'
        )::integer

    into
        v_not_created_count,
        v_draft_count,
        v_published_count

    from own_students

    left join public.tahfiz_weekly_reports
        as report
        on report.student_id =
           own_students.student_id

       and report.academic_year_id =
           v_academic_year_id

       and report.week_start =
           v_week_start;


    -- =====================================================
    -- J. ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                item_data.payload

                order by
                    item_data.group_name,
                    item_data.full_name,
                    item_data.student_id
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select distinct on (
            student.id
        )
            student.id
                as student_id,

            student.full_name,

            tahfiz_group.name
                as group_name,

            jsonb_build_object(
                'student',
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
                    student.gender::text
                ),

                'tahfiz_group',
                jsonb_build_object(
                    'id',
                    tahfiz_group.id,

                    'code',
                    tahfiz_group.code,

                    'name',
                    tahfiz_group.name,

                    'gender',
                    tahfiz_group.gender::text,

                    'grade_level',
                    tahfiz_group.grade_level
                ),

                'class',
                case
                    when current_class.class_id
                         is null
                    then null

                    else jsonb_build_object(
                        'id',
                        current_class.class_id,

                        'name',
                        current_class.class_name,

                        'grade_level',
                        current_class.grade_level
                    )
                end,

                'report',
                case
                    when report.id
                         is null
                    then null

                    else jsonb_build_object(
                        'id',
                        report.id,

                        'status',
                        report.status,

                        'week_start',
                        report.week_start,

                        'week_end',
                        report.week_end,

                        'published_at',
                        report.published_at,

                        'updated_at',
                        report.updated_at
                    )
                end
            ) as payload

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               assignment.tahfiz_group_id

        inner join public.tahfiz_group_members
            as membership
            on membership.tahfiz_group_id =
               tahfiz_group.id

        inner join public.students
            as student
            on student.id =
               membership.student_id

        left join public.tahfiz_weekly_reports
            as report
            on report.student_id =
               student.id

           and report.academic_year_id =
               v_academic_year_id

           and report.week_start =
               v_week_start

        left join lateral (
            select
                class.id
                    as class_id,

                class.name
                    as class_name,

                class.grade_level

            from public.class_enrollments
                as enrollment

            inner join public.classes
                as class
                on class.id =
                   enrollment.class_id

            where enrollment.student_id =
                  student.id

              and enrollment.is_active =
                  true

              and class.is_active =
                  true

              and class.academic_year_id =
                  v_academic_year_id

            order by
                enrollment.enrolled_at desc,
                enrollment.created_at desc

            limit 1
        ) as current_class
            on true

        where assignment.staff_id =
              v_staff_id

          and assignment.is_active =
              true

          and assignment.ended_at
              is null

          and tahfiz_group.is_active =
              true

          and tahfiz_group.academic_year_id =
              v_academic_year_id

          and membership.is_active =
              true

          and membership.left_at
              is null

          and student.status =
              'active'

          and student.deleted_at
              is null

          and (
              v_search is null

              or student.full_name
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.nis,
                  ''
              ) ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.legacy_student_id,
                  ''
              ) ilike
                 '%' || v_search || '%'

              or tahfiz_group.name
                 ilike
                 '%' || v_search || '%'
          )

        order by
            student.id,
            tahfiz_group.name
    ) as item_data;


    v_filtered_count :=
        jsonb_array_length(
            v_items
        );


    -- =====================================================
    -- K. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'profile',
        jsonb_build_object(
            'id',
            v_profile_id,

            'login_id',
            v_login_id
        ),

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'legacy_staff_id',
            v_legacy_staff_id,

            'full_name',
            v_full_name,

            'position',
            v_position
        ),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name,

            'start_date',
            v_academic_year_start,

            'end_date',
            v_academic_year_end
        ),

        'week',
        jsonb_build_object(
            'start',
            v_week_start,

            'end',
            v_week_end
        ),

        'filters',
        jsonb_build_object(
            'search',
            v_search
        ),

        'summary',
        jsonb_build_object(
            'group_count',
            coalesce(
                v_group_count,
                0
            ),

            'student_count',
            coalesce(
                v_student_count,
                0
            ),

            'filtered_count',
            coalesce(
                v_filtered_count,
                0
            ),

            'not_created_count',
            coalesce(
                v_not_created_count,
                0
            ),

            'draft_count',
            coalesce(
                v_draft_count,
                0
            ),

            'published_count',
            coalesce(
                v_published_count,
                0
            )
        ),

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- 2. REPORT DETAIL
-- =========================================================

create or replace function
public.get_pembina_tahfiz_weekly_report_detail(
    p_student_id uuid,
    p_week_start date
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
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_week_end date;

    v_group_id uuid;

    v_student jsonb;
    v_group jsonb;
    v_class jsonb;
    v_report jsonb;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pembina_tahfiz'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses detail Laporan Tahfiz ditolak.';
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
            message = 'Profile Pembina Tahfiz tidak aktif.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif Pembina Tahfiz tidak ditemukan.';
    end if;


    if p_student_id is null then
        raise exception
            'Student ID wajib diisi.';
    end if;


    if p_week_start is null then
        raise exception
            'Tanggal awal pekan wajib diisi.';
    end if;


    if extract(
        isodow
        from p_week_start
    ) <> 1
    then
        raise exception
            'Tanggal awal pekan harus hari Senin.';
    end if;


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


    v_week_end :=
        p_week_start + 6;


    if p_week_start <
       v_academic_year_start
       or v_week_end >
          v_academic_year_end
    then
        raise exception
            'Pekan berada di luar tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- CURRENT GROUP + AUTHORIZATION
    -- =====================================================

    select
        tahfiz_group.id

    into
        v_group_id

    from public.tahfiz_group_members
        as membership

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           membership.tahfiz_group_id

    where membership.student_id =
          p_student_id

      and membership.is_active =
          true

      and membership.left_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_academic_year_id

      and exists (
          select 1

          from public.tahfiz_supervisor_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.tahfiz_group_id =
                tahfiz_group.id

            and assignment.is_active =
                true

            and assignment.ended_at
                is null
      )

    order by
        membership.joined_at desc,
        membership.created_at desc

    limit 1;


    if v_group_id is null then
        raise exception using
            errcode = '42501',
            message = 'Santri berada di luar assignment Pembina Tahfiz.';
    end if;


    -- =====================================================
    -- STUDENT
    -- =====================================================

    select
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
            student.gender::text
        )

    into
        v_student

    from public.students
        as student

    where student.id =
          p_student_id

      and student.status =
          'active'

      and student.deleted_at
          is null;


    if v_student is null then
        raise exception
            'Santri aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- GROUP
    -- =====================================================

    select
        jsonb_build_object(
            'id',
            tahfiz_group.id,

            'code',
            tahfiz_group.code,

            'name',
            tahfiz_group.name,

            'gender',
            tahfiz_group.gender::text,

            'grade_level',
            tahfiz_group.grade_level
        )

    into
        v_group

    from public.tahfiz_groups
        as tahfiz_group

    where tahfiz_group.id =
          v_group_id;


    -- =====================================================
    -- CLASS
    -- =====================================================

    select
        jsonb_build_object(
            'id',
            current_class.id,

            'name',
            current_class.name,

            'grade_level',
            current_class.grade_level
        )

    into
        v_class

    from public.class_enrollments
        as enrollment

    inner join public.classes
        as current_class
        on current_class.id =
           enrollment.class_id

    where enrollment.student_id =
          p_student_id

      and enrollment.is_active =
          true

      and current_class.is_active =
          true

      and current_class.academic_year_id =
          v_academic_year_id

    order by
        enrollment.enrolled_at desc,
        enrollment.created_at desc

    limit 1;


    -- =====================================================
    -- REPORT
    -- =====================================================

    select
        jsonb_build_object(
            'id',
            report.id,

            'week_start',
            report.week_start,

            'week_end',
            report.week_end,

            'memorization_achievement',
            report.memorization_achievement,

            'murajaah_achievement',
            report.murajaah_achievement,

            'fluency_rating',
            report.fluency_rating,

            'tajwid_rating',
            report.tajwid_rating,

            'consistency_rating',
            report.consistency_rating,

            'supervisor_notes',
            report.supervisor_notes,

            'next_week_target',
            report.next_week_target,

            'status',
            report.status,

            'published_at',
            report.published_at,

            'created_at',
            report.created_at,

            'updated_at',
            report.updated_at
        )

    into
        v_report

    from public.tahfiz_weekly_reports
        as report

    where report.student_id =
          p_student_id

      and report.academic_year_id =
          v_academic_year_id

      and report.week_start =
          p_week_start;


    return jsonb_build_object(
        'generated_at',
        now(),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name,

            'start_date',
            v_academic_year_start,

            'end_date',
            v_academic_year_end
        ),

        'week',
        jsonb_build_object(
            'start',
            p_week_start,

            'end',
            v_week_end
        ),

        'student',
        v_student,

        'tahfiz_group',
        v_group,

        'class',
        v_class,

        'report',
        v_report
    );

end;
$function$;


-- =========================================================
-- 3. SAVE / UPDATE WEEKLY REPORT
-- =========================================================

create or replace function
public.save_pembina_tahfiz_weekly_report(
    p_student_id uuid,
    p_week_start date,
    p_memorization_achievement text,
    p_murajaah_achievement text,
    p_fluency_rating text,
    p_tajwid_rating text,
    p_consistency_rating text,
    p_supervisor_notes text,
    p_next_week_target text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_academic_year_id uuid;
    v_academic_year_start date;
    v_academic_year_end date;

    v_group_id uuid;
    v_week_end date;

    v_report_id uuid;
    v_status text;

    v_memorization text;
    v_murajaah text;
    v_supervisor_notes text;
    v_next_week_target text;

    v_fluency text;
    v_tajwid text;
    v_consistency text;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pembina_tahfiz'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses pengisian Laporan Tahfiz ditolak.';
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
            message = 'Profile Pembina Tahfiz tidak aktif.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif Pembina Tahfiz tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. INPUT
    -- =====================================================

    if p_student_id is null then
        raise exception
            'Student ID wajib diisi.';
    end if;


    if p_week_start is null then
        raise exception
            'Tanggal awal pekan wajib diisi.';
    end if;


    if extract(
        isodow
        from p_week_start
    ) <> 1
    then
        raise exception
            'Tanggal awal pekan harus hari Senin.';
    end if;


    v_fluency :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_fluency_rating,
                        ''
                    )
                )
            ),
            ''
        );


    v_tajwid :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_tajwid_rating,
                        ''
                    )
                )
            ),
            ''
        );


    v_consistency :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_consistency_rating,
                        ''
                    )
                )
            ),
            ''
        );


    if v_fluency is not null
       and v_fluency not in (
           'excellent',
           'good',
           'fair',
           'needs_guidance'
       )
    then
        raise exception
            'Nilai kelancaran tidak valid.';
    end if;


    if v_tajwid is not null
       and v_tajwid not in (
           'excellent',
           'good',
           'fair',
           'needs_guidance'
       )
    then
        raise exception
            'Nilai tajwid tidak valid.';
    end if;


    if v_consistency is not null
       and v_consistency not in (
           'excellent',
           'good',
           'fair',
           'needs_guidance'
       )
    then
        raise exception
            'Nilai konsistensi tidak valid.';
    end if;


    v_memorization :=
        nullif(
            btrim(
                coalesce(
                    p_memorization_achievement,
                    ''
                )
            ),
            ''
        );


    v_murajaah :=
        nullif(
            btrim(
                coalesce(
                    p_murajaah_achievement,
                    ''
                )
            ),
            ''
        );


    v_supervisor_notes :=
        nullif(
            btrim(
                coalesce(
                    p_supervisor_notes,
                    ''
                )
            ),
            ''
        );


    v_next_week_target :=
        nullif(
            btrim(
                coalesce(
                    p_next_week_target,
                    ''
                )
            ),
            ''
        );


    -- =====================================================
    -- C. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
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


    v_week_end :=
        p_week_start + 6;


    if p_week_start <
       v_academic_year_start
       or v_week_end >
          v_academic_year_end
    then
        raise exception
            'Pekan berada di luar tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- D. CURRENT GROUP + AUTHORIZATION
    -- =====================================================

    select
        tahfiz_group.id

    into
        v_group_id

    from public.tahfiz_group_members
        as membership

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           membership.tahfiz_group_id

    where membership.student_id =
          p_student_id

      and membership.is_active =
          true

      and membership.left_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_academic_year_id

      and exists (
          select 1

          from public.tahfiz_supervisor_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.tahfiz_group_id =
                tahfiz_group.id

            and assignment.is_active =
                true

            and assignment.ended_at
                is null
      )

    order by
        membership.joined_at desc,
        membership.created_at desc

    limit 1;


    if v_group_id is null then
        raise exception using
            errcode = '42501',
            message = 'Santri berada di luar assignment Pembina Tahfiz.';
    end if;


    -- =====================================================
    -- E. UPSERT
    --
    -- Jika report sudah Published:
    -- - status tetap Published
    -- - published_at tetap
    -- - published_by tetap
    -- =====================================================

    insert into public.tahfiz_weekly_reports (
        academic_year_id,
        tahfiz_group_id,
        student_id,
        week_start,
        week_end,

        memorization_achievement,
        murajaah_achievement,

        fluency_rating,
        tajwid_rating,
        consistency_rating,

        supervisor_notes,
        next_week_target,

        status,

        created_by_staff_id,
        updated_by_staff_id
    )

    values (
        v_academic_year_id,
        v_group_id,
        p_student_id,
        p_week_start,
        v_week_end,

        v_memorization,
        v_murajaah,

        v_fluency,
        v_tajwid,
        v_consistency,

        v_supervisor_notes,
        v_next_week_target,

        'draft',

        v_staff_id,
        v_staff_id
    )

    on conflict (
        student_id,
        academic_year_id,
        week_start
    )

    do update

    set
        memorization_achievement =
            excluded.memorization_achievement,

        murajaah_achievement =
            excluded.murajaah_achievement,

        fluency_rating =
            excluded.fluency_rating,

        tajwid_rating =
            excluded.tajwid_rating,

        consistency_rating =
            excluded.consistency_rating,

        supervisor_notes =
            excluded.supervisor_notes,

        next_week_target =
            excluded.next_week_target,

        updated_by_staff_id =
            v_staff_id

    returning
        id,
        status

    into
        v_report_id,
        v_status;


    -- =====================================================
    -- F. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'report_id',
        v_report_id,

        'student_id',
        p_student_id,

        'tahfiz_group_id',
        v_group_id,

        'week_start',
        p_week_start,

        'week_end',
        v_week_end,

        'status',
        v_status,

        'saved_at',
        now()
    );

end;
$function$;


-- =========================================================
-- 4. PUBLISH REPORT
-- =========================================================

create or replace function
public.publish_pembina_tahfiz_weekly_report(
    p_student_id uuid,
    p_week_start date
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_academic_year_id uuid;

    v_group_id uuid;

    v_report_id uuid;
    v_status text;

    v_published_at timestamptz;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pembina_tahfiz'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses publikasi Laporan Tahfiz ditolak.';
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
            message = 'Profile Pembina Tahfiz tidak aktif.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif Pembina Tahfiz tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. CURRENT YEAR
    -- =====================================================

    select
        academic_year.id

    into
        v_academic_year_id

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
    -- C. AUTHORIZATION
    -- =====================================================

    select
        tahfiz_group.id

    into
        v_group_id

    from public.tahfiz_group_members
        as membership

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           membership.tahfiz_group_id

    where membership.student_id =
          p_student_id

      and membership.is_active =
          true

      and membership.left_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_academic_year_id

      and exists (
          select 1

          from public.tahfiz_supervisor_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.tahfiz_group_id =
                tahfiz_group.id

            and assignment.is_active =
                true

            and assignment.ended_at
                is null
      )

    limit 1;


    if v_group_id is null then
        raise exception using
            errcode = '42501',
            message = 'Santri berada di luar assignment Pembina Tahfiz.';
    end if;


    -- =====================================================
    -- D. LOCK REPORT
    -- =====================================================

    select
        report.id,
        report.status

    into
        v_report_id,
        v_status

    from public.tahfiz_weekly_reports
        as report

    where report.student_id =
          p_student_id

      and report.academic_year_id =
          v_academic_year_id

      and report.week_start =
          p_week_start

      and report.tahfiz_group_id =
          v_group_id

    for update;


    if not found then
        raise exception
            'Laporan Tahfiz belum dibuat.';
    end if;


    -- =====================================================
    -- E. REQUIRED CONTENT
    -- =====================================================

    if exists (
        select 1

        from public.tahfiz_weekly_reports
            as report

        where report.id =
              v_report_id

          and (
              nullif(
                  btrim(
                      coalesce(
                          report.memorization_achievement,
                          ''
                      )
                  ),
                  ''
              ) is null

              or nullif(
                  btrim(
                      coalesce(
                          report.murajaah_achievement,
                          ''
                      )
                  ),
                  ''
              ) is null

              or report.fluency_rating
                 is null

              or report.tajwid_rating
                 is null

              or report.consistency_rating
                 is null

              or nullif(
                  btrim(
                      coalesce(
                          report.next_week_target,
                          ''
                      )
                  ),
                  ''
              ) is null
          )
    ) then
        raise exception
            'Laporan belum lengkap dan belum dapat dipublikasikan.';
    end if;


    -- =====================================================
    -- F. PUBLISH
    -- =====================================================

    if v_status =
       'published'
    then

        select
            report.published_at

        into
            v_published_at

        from public.tahfiz_weekly_reports
            as report

        where report.id =
              v_report_id;

    else

        update public.tahfiz_weekly_reports

        set
            status =
                'published',

            published_at =
                now(),

            published_by_staff_id =
                v_staff_id,

            updated_by_staff_id =
                v_staff_id

        where id =
              v_report_id

        returning
            published_at

        into
            v_published_at;

    end if;


    -- =====================================================
    -- G. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'report_id',
        v_report_id,

        'student_id',
        p_student_id,

        'week_start',
        p_week_start,

        'status',
        'published',

        'published_at',
        v_published_at,

        'published_by_staff_id',
        v_staff_id
    );

end;
$function$;


-- =========================================================
-- COMMENTS
-- =========================================================

comment on function
public.get_pembina_tahfiz_weekly_report_overview(date,text)
is
'Daftar status Laporan Tahfiz Mingguan seluruh santri assignment Pembina pada satu pekan.';


comment on function
public.get_pembina_tahfiz_weekly_report_detail(uuid,date)
is
'Detail Laporan Tahfiz Mingguan satu santri yang berada dalam assignment Pembina.';


comment on function
public.save_pembina_tahfiz_weekly_report(
    uuid,date,text,text,text,text,text,text,text
)
is
'Membuat atau memperbarui Laporan Tahfiz Mingguan. Laporan published tetap published apabila diedit.';


comment on function
public.publish_pembina_tahfiz_weekly_report(uuid,date)
is
'Mempublikasikan Laporan Tahfiz Mingguan yang sudah lengkap.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.get_pembina_tahfiz_weekly_report_overview(date,text)
from public;

revoke all on function
public.get_pembina_tahfiz_weekly_report_overview(date,text)
from anon;

grant execute on function
public.get_pembina_tahfiz_weekly_report_overview(date,text)
to authenticated;


revoke all on function
public.get_pembina_tahfiz_weekly_report_detail(uuid,date)
from public;

revoke all on function
public.get_pembina_tahfiz_weekly_report_detail(uuid,date)
from anon;

grant execute on function
public.get_pembina_tahfiz_weekly_report_detail(uuid,date)
to authenticated;


revoke all on function
public.save_pembina_tahfiz_weekly_report(
    uuid,date,text,text,text,text,text,text,text
)
from public;

revoke all on function
public.save_pembina_tahfiz_weekly_report(
    uuid,date,text,text,text,text,text,text,text
)
from anon;

grant execute on function
public.save_pembina_tahfiz_weekly_report(
    uuid,date,text,text,text,text,text,text,text
)
to authenticated;


revoke all on function
public.publish_pembina_tahfiz_weekly_report(uuid,date)
from public;

revoke all on function
public.publish_pembina_tahfiz_weekly_report(uuid,date)
from anon;

grant execute on function
public.publish_pembina_tahfiz_weekly_report(uuid,date)
to authenticated;


commit;