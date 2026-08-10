-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 112-verify-tahfiz-weekly-report-structure.sql
--
-- PURPOSE:
-- - Verify struktur tahfiz_weekly_reports
-- - Verify RLS
-- - Verify privileges
-- - Verify constraints
-- - Verify unique report per student/week
-- - Verify publication consistency
--
-- TEST DATA IS ROLLED BACK
-- =========================================================


-- =========================================================
-- 1. STRUCTURE
-- =========================================================

select
    to_regclass(
        'public.tahfiz_weekly_reports'
    ) is not null
        as table_exists,

    (
        select
            table_data.relrowsecurity

        from pg_class
            as table_data

        inner join pg_namespace
            as namespace
            on namespace.oid =
               table_data.relnamespace

        where namespace.nspname =
              'public'

          and table_data.relname =
              'tahfiz_weekly_reports'
    ) as rls_enabled,

    has_table_privilege(
        'authenticated',
        'public.tahfiz_weekly_reports',
        'select'
    ) as authenticated_can_select,

    has_table_privilege(
        'authenticated',
        'public.tahfiz_weekly_reports',
        'insert'
    ) as authenticated_can_insert,

    has_table_privilege(
        'authenticated',
        'public.tahfiz_weekly_reports',
        'update'
    ) as authenticated_can_update,

    has_table_privilege(
        'authenticated',
        'public.tahfiz_weekly_reports',
        'delete'
    ) as authenticated_can_delete;


-- =========================================================
-- 2. COLUMN CHECK
-- =========================================================

select
    column_data.column_name,

    column_data.data_type,

    column_data.is_nullable,

    column_data.column_default

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and column_data.table_name =
      'tahfiz_weekly_reports'

order by
    column_data.ordinal_position;


-- =========================================================
-- 3. CONSTRAINT + INDEX + TRIGGER CHECK
-- =========================================================

select
    constraint_data.constraint_name,

    constraint_data.constraint_type

from information_schema.table_constraints
    as constraint_data

where constraint_data.table_schema =
      'public'

  and constraint_data.table_name =
      'tahfiz_weekly_reports'

order by
    constraint_data.constraint_name;


select
    index_data.indexname,

    index_data.indexdef

from pg_indexes
    as index_data

where index_data.schemaname =
      'public'

  and index_data.tablename =
      'tahfiz_weekly_reports'

order by
    index_data.indexname;


select
    trigger_data.trigger_name,

    trigger_data.action_timing,

    trigger_data.event_manipulation

from information_schema.triggers
    as trigger_data

where trigger_data.trigger_schema =
      'public'

  and trigger_data.event_object_table =
      'tahfiz_weekly_reports'

order by
    trigger_data.trigger_name;


-- =========================================================
-- 4. CONSTRAINT TESTS
-- =========================================================

begin;


do $verification$
declare
    v_academic_year_id uuid;

    v_group_id uuid;

    v_student_id uuid;

    v_staff_id uuid;

    v_week_start date;

    v_week_end date;

    v_report_id uuid;
begin

    -- =====================================================
    -- A. PICK CURRENT TAHFIZ FOUNDATION
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
            'Tahun ajaran aktif tidak ditemukan.';
    end if;


    select
        tahfiz_group.id,
        student.id,
        assignment.staff_id

    into
        v_group_id,
        v_student_id,
        v_staff_id

    from public.tahfiz_groups
        as tahfiz_group

    inner join public.tahfiz_group_members
        as membership
        on membership.tahfiz_group_id =
           tahfiz_group.id

    inner join public.students
        as student
        on student.id =
           membership.student_id

    inner join public.tahfiz_supervisor_assignments
        as assignment
        on assignment.tahfiz_group_id =
           tahfiz_group.id

    where tahfiz_group.academic_year_id =
          v_academic_year_id

      and tahfiz_group.is_active =
          true

      and membership.is_active =
          true

      and membership.left_at
          is null

      and student.status =
          'active'

      and student.deleted_at
          is null

      and assignment.is_active =
          true

      and assignment.ended_at
          is null

    order by
        tahfiz_group.name,
        student.full_name

    limit 1;


    if v_group_id is null
       or v_student_id is null
       or v_staff_id is null
    then
        raise exception
            'Fondasi Tahfiz untuk verification tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. FIND A MONDAY INSIDE CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        generated.day_value::date

    into
        v_week_start

    from generate_series(
        (
            select
                start_date::timestamp

            from public.academic_years

            where id =
                  v_academic_year_id
        ),

        (
            select
                end_date::timestamp

            from public.academic_years

            where id =
                  v_academic_year_id
        ),

        interval '1 day'
    ) as generated(day_value)

    where extract(
        isodow
        from generated.day_value
    ) = 1

    order by
        generated.day_value

    limit 1;


    if v_week_start is null then
        raise exception
            'Tanggal Senin untuk verification tidak ditemukan.';
    end if;


    v_week_end :=
        v_week_start + 6;


    -- =====================================================
    -- C. VALID DRAFT INSERT
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
        v_student_id,
        v_week_start,
        v_week_end,
        'QS. Test ayat 1-10',
        'Murajaah test',
        'good',
        'good',
        'excellent',
        'Catatan verification.',
        'Target verification.',
        'draft',
        v_staff_id,
        v_staff_id
    )

    returning id
    into v_report_id;


    if v_report_id is null then
        raise exception
            'Valid draft report gagal dibuat.';
    end if;


    raise notice
        'VALID DRAFT INSERT SUCCESS';


    -- =====================================================
    -- D. UNIQUE STUDENT/WEEK MUST FAIL
    -- =====================================================

    begin

        insert into public.tahfiz_weekly_reports (
            academic_year_id,
            tahfiz_group_id,
            student_id,
            week_start,
            week_end,
            status,
            created_by_staff_id,
            updated_by_staff_id
        )

        values (
            v_academic_year_id,
            v_group_id,
            v_student_id,
            v_week_start,
            v_week_end,
            'draft',
            v_staff_id,
            v_staff_id
        );


        raise exception
            'EXPECTED_UNIQUE_FAILURE';

    exception
        when unique_violation then
            null;
    end;


    raise notice
        'UNIQUE STUDENT WEEK PROTECTION SUCCESS';


    -- =====================================================
    -- E. INVALID WEEK END MUST FAIL
    -- =====================================================

    begin

        update public.tahfiz_weekly_reports

        set week_end =
            v_week_start + 5

        where id =
              v_report_id;


        raise exception
            'EXPECTED_INVALID_WEEK_END_FAILURE';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'WEEK END CONSTRAINT SUCCESS';


    -- =====================================================
    -- F. WEEK START MUST BE MONDAY
    -- =====================================================

    begin

        update public.tahfiz_weekly_reports

        set
            week_start =
                v_week_start + 1,

            week_end =
                v_week_start + 7

        where id =
              v_report_id;


        raise exception
            'EXPECTED_NON_MONDAY_FAILURE';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'MONDAY WEEK START CONSTRAINT SUCCESS';


    -- =====================================================
    -- G. INVALID STATUS MUST FAIL
    -- =====================================================

    begin

        update public.tahfiz_weekly_reports

        set status =
            'invalid_status'

        where id =
              v_report_id;


        raise exception
            'EXPECTED_STATUS_FAILURE';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'STATUS CONSTRAINT SUCCESS';


    -- =====================================================
    -- H. INVALID RATING MUST FAIL
    -- =====================================================

    begin

        update public.tahfiz_weekly_reports

        set fluency_rating =
            'perfect'

        where id =
              v_report_id;


        raise exception
            'EXPECTED_RATING_FAILURE';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'RATING CONSTRAINT SUCCESS';


    -- =====================================================
    -- I. PUBLISHED WITHOUT AUDIT MUST FAIL
    -- =====================================================

    begin

        update public.tahfiz_weekly_reports

        set status =
            'published'

        where id =
              v_report_id;


        raise exception
            'EXPECTED_PUBLICATION_AUDIT_FAILURE';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'PUBLICATION AUDIT CONSTRAINT SUCCESS';


    -- =====================================================
    -- J. VALID PUBLISH STATE
    -- =====================================================

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
          v_report_id;


    if not exists (
        select 1

        from public.tahfiz_weekly_reports
            as report

        where report.id =
              v_report_id

          and report.status =
              'published'

          and report.published_at
              is not null

          and report.published_by_staff_id =
              v_staff_id
    ) then
        raise exception
            'Valid published state gagal.';
    end if;


    raise notice
        'VALID PUBLISHED STATE SUCCESS';


    -- =====================================================
    -- K. DRAFT CANNOT KEEP PUBLISH AUDIT
    -- =====================================================

    begin

        update public.tahfiz_weekly_reports

        set status =
            'draft'

        where id =
              v_report_id;


        raise exception
            'EXPECTED_DRAFT_PUBLICATION_AUDIT_FAILURE';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'DRAFT PUBLICATION CONSISTENCY SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'TAHFIZ WEEKLY REPORT STRUCTURE VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Struktur Laporan Tahfiz Mingguan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;