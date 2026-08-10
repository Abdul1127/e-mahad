begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 117-create-pembina-tahfiz-weekly-report-history-function.sql
--
-- PURPOSE:
-- - Riwayat Laporan Tahfiz Pembina
-- - Hanya tahun ajaran aktif
-- - Hanya santri dalam assignment aktif Pembina
-- - Filter status
-- - Filter pencarian
-- - Pagination
--
-- SECURITY:
-- - auth.uid()
-- - role pembina_tahfiz
-- - profile/staff aktif
-- - scope assignment aktif
-- =========================================================


create or replace function
public.get_pembina_tahfiz_weekly_report_history(
    p_status text default null,
    p_search text default null,
    p_limit integer default 20,
    p_offset integer default 0
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

    v_status text;
    v_search text;

    v_limit integer;
    v_offset integer;

    v_total_count integer := 0;
    v_filtered_count integer := 0;
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
            message = 'Akses Riwayat Laporan Tahfiz ditolak.';
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
    -- B. CURRENT ACADEMIC YEAR
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
    -- C. FILTERS
    -- =====================================================

    v_status :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_status,
                        ''
                    )
                )
            ),
            ''
        );


    if v_status is not null
       and v_status not in (
           'draft',
           'published'
       )
    then
        raise exception
            'Filter status Riwayat Laporan Tahfiz tidak valid.';
    end if;


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


    v_limit :=
        least(
            greatest(
                coalesce(
                    p_limit,
                    20
                ),
                1
            ),
            100
        );


    v_offset :=
        greatest(
            coalesce(
                p_offset,
                0
            ),
            0
        );


    -- =====================================================
    -- D. BASE REPORT COUNTS
    -- =====================================================

    with own_reports as (
        select distinct
            report.id,
            report.status

        from public.tahfiz_weekly_reports
            as report

        inner join public.students
            as student
            on student.id =
               report.student_id

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               report.tahfiz_group_id

        where report.academic_year_id =
              v_academic_year_id

          and student.status =
              'active'

          and student.deleted_at
              is null

          and tahfiz_group.is_active =
              true

          and exists (
              select 1

              from public.tahfiz_supervisor_assignments
                  as assignment

              where assignment.staff_id =
                    v_staff_id

                and assignment.tahfiz_group_id =
                    report.tahfiz_group_id

                and assignment.is_active =
                    true

                and assignment.ended_at
                    is null
          )

          and exists (
              select 1

              from public.tahfiz_group_members
                  as membership

              where membership.student_id =
                    report.student_id

                and membership.tahfiz_group_id =
                    report.tahfiz_group_id

                and membership.is_active =
                    true

                and membership.left_at
                    is null
          )
    )

    select
        count(*)::integer,

        count(*) filter (
            where status =
                  'draft'
        )::integer,

        count(*) filter (
            where status =
                  'published'
        )::integer

    into
        v_total_count,
        v_draft_count,
        v_published_count

    from own_reports;


    -- =====================================================
    -- E. FILTERED COUNT
    -- =====================================================

    select
        count(
            distinct report.id
        )::integer

    into
        v_filtered_count

    from public.tahfiz_weekly_reports
        as report

    inner join public.students
        as student
        on student.id =
           report.student_id

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           report.tahfiz_group_id

    where report.academic_year_id =
          v_academic_year_id

      and student.status =
          'active'

      and student.deleted_at
          is null

      and tahfiz_group.is_active =
          true

      and exists (
          select 1

          from public.tahfiz_supervisor_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.tahfiz_group_id =
                report.tahfiz_group_id

            and assignment.is_active =
                true

            and assignment.ended_at
                is null
      )

      and exists (
          select 1

          from public.tahfiz_group_members
              as membership

          where membership.student_id =
                report.student_id

            and membership.tahfiz_group_id =
                report.tahfiz_group_id

            and membership.is_active =
                true

            and membership.left_at
                is null
      )

      and (
          v_status is null

          or report.status =
             v_status
      )

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
      );


    -- =====================================================
    -- F. ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                history_item.payload

                order by
                    history_item.week_start desc,
                    history_item.updated_at desc,
                    history_item.full_name
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            report.week_start,
            report.updated_at,
            student.full_name,

            jsonb_build_object(
                'report',
                jsonb_build_object(
                    'id',
                    report.id,

                    'week_start',
                    report.week_start,

                    'week_end',
                    report.week_end,

                    'status',
                    report.status,

                    'published_at',
                    report.published_at,

                    'created_at',
                    report.created_at,

                    'updated_at',
                    report.updated_at
                ),

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
                end
            ) as payload

        from public.tahfiz_weekly_reports
            as report

        inner join public.students
            as student
            on student.id =
               report.student_id

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               report.tahfiz_group_id

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

        where report.academic_year_id =
              v_academic_year_id

          and student.status =
              'active'

          and student.deleted_at
              is null

          and tahfiz_group.is_active =
              true

          and exists (
              select 1

              from public.tahfiz_supervisor_assignments
                  as assignment

              where assignment.staff_id =
                    v_staff_id

                and assignment.tahfiz_group_id =
                    report.tahfiz_group_id

                and assignment.is_active =
                    true

                and assignment.ended_at
                    is null
          )

          and exists (
              select 1

              from public.tahfiz_group_members
                  as membership

              where membership.student_id =
                    report.student_id

                and membership.tahfiz_group_id =
                    report.tahfiz_group_id

                and membership.is_active =
                    true

                and membership.left_at
                    is null
          )

          and (
              v_status is null

              or report.status =
                 v_status
          )

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
            report.week_start desc,
            report.updated_at desc,
            student.full_name,
            report.id

        limit
            v_limit

        offset
            v_offset
    ) as history_item;


    -- =====================================================
    -- G. RESPONSE
    -- =====================================================

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

        'filters',
        jsonb_build_object(
            'status',
            v_status,

            'search',
            v_search,

            'limit',
            v_limit,

            'offset',
            v_offset
        ),

        'summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_total_count,
                0
            ),

            'filtered_count',
            coalesce(
                v_filtered_count,
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

        'pagination',
        jsonb_build_object(
            'limit',
            v_limit,

            'offset',
            v_offset,

            'has_previous',
            v_offset > 0,

            'has_next',
            (
                v_offset +
                jsonb_array_length(
                    v_items
                )
            ) <
            v_filtered_count
        ),

        'items',
        v_items
    );

end;
$function$;


comment on function
public.get_pembina_tahfiz_weekly_report_history(
    text,
    text,
    integer,
    integer
)
is
'Riwayat Laporan Tahfiz Mingguan pada santri kelompok assignment aktif Pembina Tahfiz.';


revoke all on function
public.get_pembina_tahfiz_weekly_report_history(
    text,
    text,
    integer,
    integer
)
from public;


revoke all on function
public.get_pembina_tahfiz_weekly_report_history(
    text,
    text,
    integer,
    integer
)
from anon;


grant execute on function
public.get_pembina_tahfiz_weekly_report_history(
    text,
    text,
    integer,
    integer
)
to authenticated;


commit;