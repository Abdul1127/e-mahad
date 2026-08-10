-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 109-inspect-tahfiz-weekly-report-foundation.sql
--
-- PURPOSE:
-- Audit fondasi Laporan Tahfiz Mingguan.
--
-- READ ONLY:
-- Tidak membuat, mengubah, atau menghapus data.
--
-- CHECK:
-- 1. Existing Tahfiz related tables
-- 2. Existing report / hafalan / murajaah structures
-- 3. Existing columns
-- 4. Existing functions
-- 5. Existing enum / custom types
-- 6. Existing RLS / policies
-- 7. Existing triggers
-- 8. Current Tahfiz groups
-- 9. Current Tahfiz assignments
-- 10. Student coverage
-- 11. Existing weekly/report-like data
-- =========================================================


-- =========================================================
-- 1. CURRENT ACADEMIC YEAR
-- =========================================================

select
    academic_year.id
        as academic_year_id,

    academic_year.name
        as academic_year_name,

    academic_year.start_date,

    academic_year.end_date,

    academic_year.is_current

from public.academic_years
    as academic_year

where academic_year.is_current =
      true

order by
    academic_year.start_date desc;


-- =========================================================
-- 2. ALL EXISTING TAHFIZ / REPORT RELATED TABLES
--
-- We intentionally search broadly so we do not accidentally
-- create duplicate structures.
-- =========================================================

select
    table_schema,

    table_name

from information_schema.tables

where table_schema =
      'public'

  and table_type =
      'BASE TABLE'

  and (
      table_name ilike
      '%tahfiz%'

      or table_name ilike
         '%hafal%'

      or table_name ilike
         '%muraja%'

      or table_name ilike
         '%setoran%'

      or table_name ilike
         '%report%'

      or table_name ilike
         '%laporan%'

      or table_name ilike
         '%weekly%'

      or table_name ilike
         '%pekan%'

      or table_name ilike
         '%quran%'
  )

order by
    table_name;


-- =========================================================
-- 3. COLUMNS FROM TAHFIZ / REPORT RELATED TABLES
-- =========================================================

select
    column_data.table_name,

    column_data.ordinal_position,

    column_data.column_name,

    column_data.data_type,

    column_data.udt_name,

    column_data.is_nullable,

    column_data.column_default

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and column_data.table_name in (
      select
          table_data.table_name

      from information_schema.tables
          as table_data

      where table_data.table_schema =
            'public'

        and table_data.table_type =
            'BASE TABLE'

        and (
            table_data.table_name ilike
            '%tahfiz%'

            or table_data.table_name ilike
               '%hafal%'

            or table_data.table_name ilike
               '%muraja%'

            or table_data.table_name ilike
               '%setoran%'

            or table_data.table_name ilike
               '%report%'

            or table_data.table_name ilike
               '%laporan%'

            or table_data.table_name ilike
               '%weekly%'

            or table_data.table_name ilike
               '%pekan%'

            or table_data.table_name ilike
               '%quran%'
        )
  )

order by
    column_data.table_name,
    column_data.ordinal_position;


-- =========================================================
-- 4. SEARCH RELEVANT COLUMNS ACROSS ENTIRE PUBLIC SCHEMA
--
-- This detects report-related fields even when the table
-- itself has a generic name.
-- =========================================================

select
    column_data.table_name,

    column_data.column_name,

    column_data.data_type,

    column_data.udt_name,

    column_data.is_nullable

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and (
      column_data.column_name ilike
      '%tahfiz%'

      or column_data.column_name ilike
         '%hafal%'

      or column_data.column_name ilike
         '%muraja%'

      or column_data.column_name ilike
         '%setoran%'

      or column_data.column_name ilike
         '%surah%'

      or column_data.column_name ilike
         '%surat%'

      or column_data.column_name ilike
         '%juz%'

      or column_data.column_name ilike
         '%ayat%'

      or column_data.column_name ilike
         '%tajwid%'

      or column_data.column_name ilike
         '%kelancaran%'

      or column_data.column_name ilike
         '%quality%'

      or column_data.column_name ilike
         '%week%'

      or column_data.column_name ilike
         '%pekan%'

      or column_data.column_name ilike
         '%publish%'

      or column_data.column_name ilike
         '%laporan%'

      or column_data.column_name ilike
         '%report%'
  )

order by
    column_data.table_name,
    column_data.ordinal_position;


-- =========================================================
-- 5. EXISTING TAHFIZ / REPORT FUNCTIONS
-- =========================================================

select
    namespace.nspname
        as function_schema,

    procedure_data.proname
        as function_name,

    pg_get_function_identity_arguments(
        procedure_data.oid
    ) as arguments,

    pg_get_function_result(
        procedure_data.oid
    ) as result_type,

    procedure_data.prosecdef
        as security_definer

from pg_proc
    as procedure_data

inner join pg_namespace
    as namespace
    on namespace.oid =
       procedure_data.pronamespace

where namespace.nspname =
      'public'

  and (
      procedure_data.proname ilike
      '%tahfiz%'

      or procedure_data.proname ilike
         '%hafal%'

      or procedure_data.proname ilike
         '%muraja%'

      or procedure_data.proname ilike
         '%setoran%'

      or procedure_data.proname ilike
         '%report%'

      or procedure_data.proname ilike
         '%laporan%'

      or procedure_data.proname ilike
         '%weekly%'

      or procedure_data.proname ilike
         '%pekan%'

      or procedure_data.proname ilike
         '%publish%'
  )

order by
    procedure_data.proname,
    pg_get_function_identity_arguments(
        procedure_data.oid
    );


-- =========================================================
-- 6. EXISTING CUSTOM ENUMS / TYPES
--
-- Search for values that might already represent:
-- progress, quality, status, publication, etc.
-- =========================================================

select
    namespace.nspname
        as type_schema,

    type_data.typname
        as type_name,

    enum_data.enumsortorder,

    enum_data.enumlabel

from pg_type
    as type_data

inner join pg_namespace
    as namespace
    on namespace.oid =
       type_data.typnamespace

inner join pg_enum
    as enum_data
    on enum_data.enumtypid =
       type_data.oid

where namespace.nspname =
      'public'

  and (
      type_data.typname ilike
      '%tahfiz%'

      or type_data.typname ilike
         '%hafal%'

      or type_data.typname ilike
         '%report%'

      or type_data.typname ilike
         '%status%'

      or type_data.typname ilike
         '%quality%'

      or type_data.typname ilike
         '%publish%'
  )

order by
    type_data.typname,
    enum_data.enumsortorder;


-- =========================================================
-- 7. CONSTRAINTS ON EXISTING TAHFIZ TABLES
-- =========================================================

select
    constraint_data.table_name,

    constraint_data.constraint_name,

    constraint_data.constraint_type

from information_schema.table_constraints
    as constraint_data

where constraint_data.table_schema =
      'public'

  and constraint_data.table_name in (
      select
          table_data.table_name

      from information_schema.tables
          as table_data

      where table_data.table_schema =
            'public'

        and table_data.table_type =
            'BASE TABLE'

        and (
            table_data.table_name ilike
            '%tahfiz%'

            or table_data.table_name ilike
               '%hafal%'

            or table_data.table_name ilike
               '%muraja%'

            or table_data.table_name ilike
               '%setoran%'

            or table_data.table_name ilike
               '%report%'

            or table_data.table_name ilike
               '%laporan%'

            or table_data.table_name ilike
               '%weekly%'

            or table_data.table_name ilike
               '%pekan%'
        )
  )

order by
    constraint_data.table_name,
    constraint_data.constraint_type,
    constraint_data.constraint_name;


-- =========================================================
-- 8. INDEXES ON EXISTING TAHFIZ TABLES
-- =========================================================

select
    index_data.tablename
        as table_name,

    index_data.indexname
        as index_name,

    index_data.indexdef
        as index_definition

from pg_indexes
    as index_data

where index_data.schemaname =
      'public'

  and (
      index_data.tablename ilike
      '%tahfiz%'

      or index_data.tablename ilike
         '%hafal%'

      or index_data.tablename ilike
         '%muraja%'

      or index_data.tablename ilike
         '%setoran%'

      or index_data.tablename ilike
         '%report%'

      or index_data.tablename ilike
         '%laporan%'

      or index_data.tablename ilike
         '%weekly%'

      or index_data.tablename ilike
         '%pekan%'
  )

order by
    index_data.tablename,
    index_data.indexname;


-- =========================================================
-- 9. RLS STATUS
-- =========================================================

select
    namespace.nspname
        as table_schema,

    table_data.relname
        as table_name,

    table_data.relrowsecurity
        as rls_enabled,

    table_data.relforcerowsecurity
        as rls_forced

from pg_class
    as table_data

inner join pg_namespace
    as namespace
    on namespace.oid =
       table_data.relnamespace

where namespace.nspname =
      'public'

  and table_data.relkind =
      'r'

  and (
      table_data.relname ilike
      '%tahfiz%'

      or table_data.relname ilike
         '%hafal%'

      or table_data.relname ilike
         '%muraja%'

      or table_data.relname ilike
         '%setoran%'

      or table_data.relname ilike
         '%report%'

      or table_data.relname ilike
         '%laporan%'

      or table_data.relname ilike
         '%weekly%'

      or table_data.relname ilike
         '%pekan%'
  )

order by
    table_data.relname;


-- =========================================================
-- 10. EXISTING RLS POLICIES
-- =========================================================

select
    policy_data.schemaname
        as table_schema,

    policy_data.tablename
        as table_name,

    policy_data.policyname
        as policy_name,

    policy_data.permissive,

    policy_data.roles,

    policy_data.cmd,

    policy_data.qual,

    policy_data.with_check

from pg_policies
    as policy_data

where policy_data.schemaname =
      'public'

  and (
      policy_data.tablename ilike
      '%tahfiz%'

      or policy_data.tablename ilike
         '%hafal%'

      or policy_data.tablename ilike
         '%muraja%'

      or policy_data.tablename ilike
         '%setoran%'

      or policy_data.tablename ilike
         '%report%'

      or policy_data.tablename ilike
         '%laporan%'

      or policy_data.tablename ilike
         '%weekly%'

      or policy_data.tablename ilike
         '%pekan%'
  )

order by
    policy_data.tablename,
    policy_data.policyname;


-- =========================================================
-- 11. EXISTING TRIGGERS
-- =========================================================

select
    event_object_table
        as table_name,

    trigger_name,

    action_timing,

    event_manipulation,

    action_statement

from information_schema.triggers

where trigger_schema =
      'public'

  and (
      event_object_table ilike
      '%tahfiz%'

      or event_object_table ilike
         '%hafal%'

      or event_object_table ilike
         '%muraja%'

      or event_object_table ilike
         '%setoran%'

      or event_object_table ilike
         '%report%'

      or event_object_table ilike
         '%laporan%'

      or event_object_table ilike
         '%weekly%'

      or event_object_table ilike
         '%pekan%'
  )

order by
    event_object_table,
    trigger_name;


-- =========================================================
-- 12. CURRENT TAHFIZ GROUP SNAPSHOT
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    tahfiz_group.id
        as tahfiz_group_id,

    tahfiz_group.code,

    tahfiz_group.name,

    tahfiz_group.grade_level,

    tahfiz_group.gender,

    tahfiz_group.is_active,

    count(
        distinct membership.student_id
    ) filter (
        where membership.is_active =
              true

          and membership.left_at
              is null

          and student.status =
              'active'

          and student.deleted_at
              is null
    )::integer
        as active_student_count,

    count(
        distinct assignment.staff_id
    ) filter (
        where assignment.is_active =
              true

          and assignment.ended_at
              is null
    )::integer
        as active_supervisor_count

from public.tahfiz_groups
    as tahfiz_group

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

left join public.tahfiz_group_members
    as membership
    on membership.tahfiz_group_id =
       tahfiz_group.id

left join public.students
    as student
    on student.id =
       membership.student_id

left join public.tahfiz_supervisor_assignments
    as assignment
    on assignment.tahfiz_group_id =
       tahfiz_group.id

where tahfiz_group.is_active =
      true

group by
    tahfiz_group.id,
    tahfiz_group.code,
    tahfiz_group.name,
    tahfiz_group.grade_level,
    tahfiz_group.gender,
    tahfiz_group.is_active

order by
    tahfiz_group.grade_level,
    tahfiz_group.gender,
    tahfiz_group.name;


-- =========================================================
-- 13. CURRENT PEMBINA ASSIGNMENT SNAPSHOT
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    staff.id
        as staff_id,

    staff.legacy_staff_id,

    staff.full_name,

    profile.login_id,

    tahfiz_group.id
        as tahfiz_group_id,

    tahfiz_group.code
        as tahfiz_group_code,

    tahfiz_group.name
        as tahfiz_group_name,

    tahfiz_group.grade_level,

    tahfiz_group.gender,

    assignment.is_primary,

    assignment.assigned_at,

    (
        select
            count(*)::integer

        from public.tahfiz_group_members
            as membership

        inner join public.students
            as student
            on student.id =
               membership.student_id

        where membership.tahfiz_group_id =
              tahfiz_group.id

          and membership.is_active =
              true

          and membership.left_at
              is null

          and student.status =
              'active'

          and student.deleted_at
              is null
    ) as active_student_count

from public.tahfiz_supervisor_assignments
    as assignment

inner join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       assignment.tahfiz_group_id

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

inner join public.staff
    as staff
    on staff.id =
       assignment.staff_id

left join public.profiles
    as profile
    on profile.id =
       staff.profile_id

where assignment.is_active =
      true

  and assignment.ended_at
      is null

  and tahfiz_group.is_active =
      true

order by
    tahfiz_group.name,
    staff.full_name;


-- =========================================================
-- 14. CURRENT STUDENT COVERAGE
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
),

active_students as (
    select
        student.id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null
),

covered_students as (
    select distinct
        membership.student_id

    from public.tahfiz_group_members
        as membership

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           membership.tahfiz_group_id

    inner join current_year
        on current_year.id =
           tahfiz_group.academic_year_id

    inner join active_students
        on active_students.id =
           membership.student_id

    where membership.is_active =
          true

      and membership.left_at
          is null

      and tahfiz_group.is_active =
          true
)

select
    (
        select
            count(*)::integer

        from active_students
    ) as active_student_count,

    (
        select
            count(*)::integer

        from covered_students
    ) as tahfiz_covered_student_count,

    (
        select
            count(*)::integer

        from active_students
    )

    -

    (
        select
            count(*)::integer

        from covered_students
    ) as uncovered_student_count;


-- =========================================================
-- 15. TABLE ROW COUNTS FOR EXISTING TAHFIZ FOUNDATION
-- =========================================================

select
    'tahfiz_groups'
        as table_name,

    count(*)::bigint
        as row_count

from public.tahfiz_groups

union all

select
    'tahfiz_group_members',

    count(*)::bigint

from public.tahfiz_group_members

union all

select
    'tahfiz_supervisor_assignments',

    count(*)::bigint

from public.tahfiz_supervisor_assignments

order by
    table_name;


-- =========================================================
-- 16. FINAL AUDIT MARKER
-- =========================================================

select
    'Audit struktur Laporan Tahfiz Mingguan selesai.'
        as audit_status,

    now()
        as audited_at;