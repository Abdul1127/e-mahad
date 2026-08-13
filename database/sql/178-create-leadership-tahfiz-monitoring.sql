begin;

-- =========================================================
-- E-MA'HAD
-- 178-create-leadership-tahfiz-monitoring.sql
--
-- MONITORING TAHFIZ PIMPINAN
--
-- ACCESS:
-- - Kepala Ma'had       READ ONLY
-- - Penanggung Jawab    READ ONLY
--
-- IMPORTANT:
-- - current academic year only
-- - published reports only
-- - draft Pembina tidak pernah diekspos
-- - tidak ada fungsi edit/publish untuk pimpinan
--
-- STUDENT ACTIVE RULE:
-- student.status = 'active'::public.student_status
-- AND student.deleted_at IS NULL
-- =========================================================


-- =========================================================
-- 01. OVERVIEW
-- =========================================================

create or replace function
public.get_leadership_tahfiz_monitoring_overview(
    p_week_start date default null,
    p_search text default null,
    p_group_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

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
    v_published_count integer := 0;
    v_missing_count integer := 0;
    v_attention_count integer := 0;

    v_groups jsonb := '[]'::jsonb;
    v_items jsonb := '[]'::jsonb;
begin

    -- =====================================================
    -- AUTHORIZATION
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not (
        public.has_role(
            'kepala_mahad'
        )
        or
        public.has_role(
            'penanggung_jawab'
        )
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses monitoring Tahfiz pimpinan ditolak.';
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
            message = 'Profil pengguna tidak aktif.';
    end if;


    -- =====================================================
    -- CURRENT ACADEMIC YEAR
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
    -- WEEK
    -- =====================================================

    v_week_start :=
        coalesce(
            p_week_start,
            date_trunc(
                'week',
                current_date
            )::date
        );


    v_week_end :=
        v_week_start + 6;


    if extract(
        isodow
        from v_week_start
    ) <> 1 then
        raise exception
            'Awal pekan harus hari Senin.';
    end if;


    if v_week_start <
       v_academic_year_start

       or v_week_end >
          v_academic_year_end
    then
        raise exception
            'Pekan berada di luar tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- SEARCH
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
    -- GROUP VALIDATION
    -- =====================================================

    if p_group_id is not null then

        if not exists (
            select 1

            from public.tahfiz_groups
                as tahfiz_group

            where tahfiz_group.id =
                  p_group_id

              and tahfiz_group.academic_year_id =
                  v_academic_year_id

              and tahfiz_group.is_active =
                  true
        ) then
            raise exception
                'Kelompok Tahfiz tidak valid.';
        end if;

    end if;


    -- =====================================================
    -- TOTAL ACTIVE GROUPS
    -- =====================================================

    select
        count(*)::integer

    into
        v_group_count

    from public.tahfiz_groups
        as tahfiz_group

    where tahfiz_group.academic_year_id =
          v_academic_year_id

      and tahfiz_group.is_active =
          true;


    -- =====================================================
    -- TOTAL ACTIVE STUDENTS ON SELECTED WEEK
    -- =====================================================

    select
        count(
            distinct member.student_id
        )::integer

    into
        v_student_count

    from public.tahfiz_group_members
        as member

    inner join public.tahfiz_groups
        as tahfiz_group

        on tahfiz_group.id =
           member.tahfiz_group_id

    inner join public.students
        as student

        on student.id =
           member.student_id

    where tahfiz_group.academic_year_id =
          v_academic_year_id

      and tahfiz_group.is_active =
          true

      and student.status =
          'active'::public.student_status

      and student.deleted_at
          is null

      and member.joined_at <=
          v_week_end

      and (
          member.left_at is null
          or member.left_at >=
             v_week_start
      );


    -- =====================================================
    -- FILTERED STUDENTS
    -- =====================================================

    select
        count(*)::integer

    into
        v_filtered_count

    from (
        select distinct
            member.student_id

        from public.tahfiz_group_members
            as member

        inner join public.tahfiz_groups
            as tahfiz_group

            on tahfiz_group.id =
               member.tahfiz_group_id

        inner join public.students
            as student

            on student.id =
               member.student_id

        where tahfiz_group.academic_year_id =
              v_academic_year_id

          and tahfiz_group.is_active =
              true

          and student.status =
              'active'::public.student_status

          and student.deleted_at
              is null

          and member.joined_at <=
              v_week_end

          and (
              member.left_at is null
              or member.left_at >=
                 v_week_start
          )

          and (
              p_group_id is null
              or tahfiz_group.id =
                 p_group_id
          )

          and (
              v_search is null

              or student.full_name
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                     student.nis,
                     ''
                 )
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                     student.legacy_student_id,
                     ''
                 )
                 ilike
                 '%' || v_search || '%'

              or tahfiz_group.name
                 ilike
                 '%' || v_search || '%'

              or tahfiz_group.code
                 ilike
                 '%' || v_search || '%'
          )
    )
        as filtered_student;


    -- =====================================================
    -- PUBLISHED REPORT COUNT
    -- =====================================================

    select
        count(
            distinct report.student_id
        )::integer

    into
        v_published_count

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

      and report.week_start =
          v_week_start

      and report.status =
          'published'

      and student.status =
          'active'::public.student_status

      and student.deleted_at
          is null

      and tahfiz_group.is_active =
          true

      and (
          p_group_id is null
          or tahfiz_group.id =
             p_group_id
      )

      and (
          v_search is null

          or student.full_name
             ilike
             '%' || v_search || '%'

          or coalesce(
                 student.nis,
                 ''
             )
             ilike
             '%' || v_search || '%'

          or coalesce(
                 student.legacy_student_id,
                 ''
             )
             ilike
             '%' || v_search || '%'

          or tahfiz_group.name
             ilike
             '%' || v_search || '%'

          or tahfiz_group.code
             ilike
             '%' || v_search || '%'
      );


    v_missing_count :=
        greatest(
            v_filtered_count -
            v_published_count,
            0
        );


    -- =====================================================
    -- NEEDS GUIDANCE
    -- =====================================================

    select
        count(*)::integer

    into
        v_attention_count

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

      and report.week_start =
          v_week_start

      and report.status =
          'published'

      and student.status =
          'active'::public.student_status

      and student.deleted_at
          is null

      and tahfiz_group.is_active =
          true

      and (
          report.fluency_rating =
              'needs_guidance'

          or report.tajwid_rating =
              'needs_guidance'

          or report.consistency_rating =
              'needs_guidance'
      )

      and (
          p_group_id is null
          or tahfiz_group.id =
             p_group_id
      )

      and (
          v_search is null

          or student.full_name
             ilike
             '%' || v_search || '%'

          or coalesce(
                 student.nis,
                 ''
             )
             ilike
             '%' || v_search || '%'

          or coalesce(
                 student.legacy_student_id,
                 ''
             )
             ilike
             '%' || v_search || '%'

          or tahfiz_group.name
             ilike
             '%' || v_search || '%'

          or tahfiz_group.code
             ilike
             '%' || v_search || '%'
      );


    -- =====================================================
    -- GROUP SUMMARY
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                group_data.payload

                order by
                    group_data.grade_level nulls last,
                    group_data.gender,
                    group_data.name
            ),
            '[]'::jsonb
        )

    into
        v_groups

    from (
        select
            tahfiz_group.grade_level,
            tahfiz_group.gender,
            tahfiz_group.name,

            jsonb_build_object(
                'id',
                tahfiz_group.id,

                'code',
                tahfiz_group.code,

                'name',
                tahfiz_group.name,

                'gender',
                tahfiz_group.gender,

                'grade_level',
                tahfiz_group.grade_level,

                'member_count',
                (
                    select
                        count(
                            distinct member.student_id
                        )::integer

                    from public.tahfiz_group_members
                        as member

                    inner join public.students
                        as student

                        on student.id =
                           member.student_id

                    where member.tahfiz_group_id =
                          tahfiz_group.id

                      and student.status =
                          'active'::public.student_status

                      and student.deleted_at
                          is null

                      and member.joined_at <=
                          v_week_end

                      and (
                          member.left_at is null
                          or member.left_at >=
                             v_week_start
                      )
                ),

                'published_count',
                (
                    select
                        count(
                            distinct report.student_id
                        )::integer

                    from public.tahfiz_weekly_reports
                        as report

                    inner join public.students
                        as student

                        on student.id =
                           report.student_id

                    where report.tahfiz_group_id =
                          tahfiz_group.id

                      and report.academic_year_id =
                          v_academic_year_id

                      and report.week_start =
                          v_week_start

                      and report.status =
                          'published'

                      and student.status =
                          'active'::public.student_status

                      and student.deleted_at
                          is null
                ),

                'missing_count',
                greatest(
                    (
                        select
                            count(
                                distinct member.student_id
                            )::integer

                        from public.tahfiz_group_members
                            as member

                        inner join public.students
                            as student

                            on student.id =
                               member.student_id

                        where member.tahfiz_group_id =
                              tahfiz_group.id

                          and student.status =
                              'active'::public.student_status

                          and student.deleted_at
                              is null

                          and member.joined_at <=
                              v_week_end

                          and (
                              member.left_at is null
                              or member.left_at >=
                                 v_week_start
                          )
                    )
                    -
                    (
                        select
                            count(
                                distinct report.student_id
                            )::integer

                        from public.tahfiz_weekly_reports
                            as report

                        inner join public.students
                            as student

                            on student.id =
                               report.student_id

                        where report.tahfiz_group_id =
                              tahfiz_group.id

                          and report.academic_year_id =
                              v_academic_year_id

                          and report.week_start =
                              v_week_start

                          and report.status =
                              'published'

                          and student.status =
                              'active'::public.student_status

                          and student.deleted_at
                              is null
                    ),
                    0
                ),

                'supervisors',
                coalesce(
                    (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'staff_id',
                                    staff.id,

                                    'full_name',
                                    staff.full_name,

                                    'is_primary',
                                    assignment.is_primary
                                )

                                order by
                                    assignment.is_primary desc,
                                    staff.full_name
                            )

                        from public.tahfiz_supervisor_assignments
                            as assignment

                        inner join public.staff
                            as staff

                            on staff.id =
                               assignment.staff_id

                        where assignment.tahfiz_group_id =
                              tahfiz_group.id

                          and assignment.is_active =
                              true

                          and staff.is_active =
                              true

                          and assignment.assigned_at <=
                              v_week_end

                          and (
                              assignment.ended_at is null
                              or assignment.ended_at >=
                                 v_week_start
                          )
                    ),
                    '[]'::jsonb
                )
            )
                as payload

        from public.tahfiz_groups
            as tahfiz_group

        where tahfiz_group.academic_year_id =
              v_academic_year_id

          and tahfiz_group.is_active =
              true
    )
        as group_data;


    -- =====================================================
    -- STUDENT ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                item_data.payload

                order by
                    item_data.grade_level nulls last,
                    item_data.group_name,
                    item_data.student_name
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            tahfiz_group.grade_level,

            tahfiz_group.name
                as group_name,

            student.full_name
                as student_name,

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
                    student.gender
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
                    tahfiz_group.gender,

                    'grade_level',
                    tahfiz_group.grade_level
                ),

                'supervisors',
                coalesce(
                    (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'staff_id',
                                    staff.id,

                                    'full_name',
                                    staff.full_name,

                                    'is_primary',
                                    assignment.is_primary
                                )

                                order by
                                    assignment.is_primary desc,
                                    staff.full_name
                            )

                        from public.tahfiz_supervisor_assignments
                            as assignment

                        inner join public.staff
                            as staff

                            on staff.id =
                               assignment.staff_id

                        where assignment.tahfiz_group_id =
                              tahfiz_group.id

                          and assignment.is_active =
                              true

                          and staff.is_active =
                              true

                          and assignment.assigned_at <=
                              v_week_end

                          and (
                              assignment.ended_at is null
                              or assignment.ended_at >=
                                 v_week_start
                          )
                    ),
                    '[]'::jsonb
                ),

                'report',
                case
                    when report.id is null
                        then null

                    else
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

                            'updated_at',
                            report.updated_at
                        )
                end
            )
                as payload

        from public.tahfiz_group_members
            as member

        inner join public.tahfiz_groups
            as tahfiz_group

            on tahfiz_group.id =
               member.tahfiz_group_id

        inner join public.students
            as student

            on student.id =
               member.student_id

        left join lateral (
            select
                report_data.*

            from public.tahfiz_weekly_reports
                as report_data

            where report_data.academic_year_id =
                  v_academic_year_id

              and report_data.tahfiz_group_id =
                  tahfiz_group.id

              and report_data.student_id =
                  student.id

              and report_data.week_start =
                  v_week_start

              and report_data.status =
                  'published'

            order by
                report_data.published_at desc nulls last,
                report_data.updated_at desc

            limit 1
        )
            as report

            on true

        where tahfiz_group.academic_year_id =
              v_academic_year_id

          and tahfiz_group.is_active =
              true

          and student.status =
              'active'::public.student_status

          and student.deleted_at
              is null

          and member.joined_at <=
              v_week_end

          and (
              member.left_at is null
              or member.left_at >=
                 v_week_start
          )

          and (
              p_group_id is null
              or tahfiz_group.id =
                 p_group_id
          )

          and (
              v_search is null

              or student.full_name
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                     student.nis,
                     ''
                 )
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                     student.legacy_student_id,
                     ''
                 )
                 ilike
                 '%' || v_search || '%'

              or tahfiz_group.name
                 ilike
                 '%' || v_search || '%'

              or tahfiz_group.code
                 ilike
                 '%' || v_search || '%'
          )
    )
        as item_data;


    -- =====================================================
    -- RESPONSE
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
            v_search,

            'group_id',
            p_group_id
        ),

        'summary',
        jsonb_build_object(
            'group_count',
            v_group_count,

            'student_count',
            v_student_count,

            'filtered_count',
            v_filtered_count,

            'published_count',
            v_published_count,

            'missing_count',
            v_missing_count,

            'attention_count',
            v_attention_count
        ),

        'groups',
        v_groups,

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- 02. STUDENT PUBLISHED HISTORY
-- =========================================================

create or replace function
public.get_leadership_tahfiz_student_history(
    p_student_id uuid,
    p_limit integer default 10,
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

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_limit integer;
    v_offset integer;

    v_student jsonb;
    v_current_group jsonb;

    v_published_count integer := 0;
    v_attention_count integer := 0;

    v_items jsonb := '[]'::jsonb;
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


    if not (
        public.has_role(
            'kepala_mahad'
        )
        or
        public.has_role(
            'penanggung_jawab'
        )
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses monitoring Tahfiz pimpinan ditolak.';
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
            message = 'Profil pengguna tidak aktif.';
    end if;


    -- =====================================================
    -- PAGINATION
    -- =====================================================

    v_limit :=
        least(
            greatest(
                coalesce(
                    p_limit,
                    10
                ),
                1
            ),
            50
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
    -- ACADEMIC YEAR
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
            student.gender
        )

    into
        v_student

    from public.students
        as student

    where student.id =
          p_student_id

      and student.status =
          'active'::public.student_status

      and student.deleted_at
          is null

      and exists (
          select 1

          from public.tahfiz_group_members
              as member

          inner join public.tahfiz_groups
              as tahfiz_group

              on tahfiz_group.id =
                 member.tahfiz_group_id

          where member.student_id =
                student.id

            and tahfiz_group.academic_year_id =
                v_academic_year_id
      )

    limit 1;


    if v_student is null then
        raise exception using
            errcode = '42501',
            message = 'Santri Tahfiz tidak ditemukan atau tidak dapat diakses.';
    end if;


    -- =====================================================
    -- CURRENT GROUP
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
            tahfiz_group.gender,

            'grade_level',
            tahfiz_group.grade_level,

            'supervisors',
            coalesce(
                (
                    select
                        jsonb_agg(
                            jsonb_build_object(
                                'staff_id',
                                staff.id,

                                'full_name',
                                staff.full_name,

                                'is_primary',
                                assignment.is_primary
                            )

                            order by
                                assignment.is_primary desc,
                                staff.full_name
                        )

                    from public.tahfiz_supervisor_assignments
                        as assignment

                    inner join public.staff
                        as staff

                        on staff.id =
                           assignment.staff_id

                    where assignment.tahfiz_group_id =
                          tahfiz_group.id

                      and assignment.is_active =
                          true

                      and staff.is_active =
                          true
                ),
                '[]'::jsonb
            )
        )

    into
        v_current_group

    from public.tahfiz_group_members
        as member

    inner join public.tahfiz_groups
        as tahfiz_group

        on tahfiz_group.id =
           member.tahfiz_group_id

    where member.student_id =
          p_student_id

      and tahfiz_group.academic_year_id =
          v_academic_year_id

      and tahfiz_group.is_active =
          true

      and member.is_active =
          true

    order by
        member.joined_at desc

    limit 1;


    -- =====================================================
    -- SUMMARY
    -- =====================================================

    select
        count(*)::integer,

        count(*) filter (
            where report.fluency_rating =
                      'needs_guidance'

               or report.tajwid_rating =
                      'needs_guidance'

               or report.consistency_rating =
                      'needs_guidance'
        )::integer

    into
        v_published_count,
        v_attention_count

    from public.tahfiz_weekly_reports
        as report

    where report.academic_year_id =
          v_academic_year_id

      and report.student_id =
          p_student_id

      and report.status =
          'published';


    -- =====================================================
    -- ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                report_data.payload

                order by
                    report_data.week_start desc
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            report.week_start,

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

                'updated_at',
                report.updated_at,

                'tahfiz_group',
                jsonb_build_object(
                    'id',
                    tahfiz_group.id,

                    'code',
                    tahfiz_group.code,

                    'name',
                    tahfiz_group.name,

                    'gender',
                    tahfiz_group.gender,

                    'grade_level',
                    tahfiz_group.grade_level
                ),

                'published_by',
                case
                    when publisher.id is null
                        then null

                    else
                        jsonb_build_object(
                            'staff_id',
                            publisher.id,

                            'full_name',
                            publisher.full_name
                        )
                end
            )
                as payload

        from public.tahfiz_weekly_reports
            as report

        inner join public.tahfiz_groups
            as tahfiz_group

            on tahfiz_group.id =
               report.tahfiz_group_id

        left join public.staff
            as publisher

            on publisher.id =
               report.published_by_staff_id

        where report.academic_year_id =
              v_academic_year_id

          and report.student_id =
              p_student_id

          and report.status =
              'published'

        order by
            report.week_start desc

        limit
            v_limit

        offset
            v_offset
    )
        as report_data;


    -- =====================================================
    -- RESPONSE
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

        'student',
        v_student,

        'current_group',
        v_current_group,

        'summary',
        jsonb_build_object(
            'published_report_count',
            v_published_count,

            'attention_report_count',
            v_attention_count
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
                v_limit
            ) <
            v_published_count
        ),

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- 03. PRIVILEGES
-- =========================================================

revoke all
on function
public.get_leadership_tahfiz_monitoring_overview(
    date,
    text,
    uuid
)
from public,
     anon;


grant execute
on function
public.get_leadership_tahfiz_monitoring_overview(
    date,
    text,
    uuid
)
to authenticated;


revoke all
on function
public.get_leadership_tahfiz_student_history(
    uuid,
    integer,
    integer
)
from public,
     anon;


grant execute
on function
public.get_leadership_tahfiz_student_history(
    uuid,
    integer,
    integer
)
to authenticated;


commit;