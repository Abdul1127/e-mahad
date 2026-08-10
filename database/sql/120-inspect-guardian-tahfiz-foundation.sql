-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 120-inspect-guardian-tahfiz-foundation.sql
--
-- PURPOSE:
-- Audit fondasi Modul Orang Tua/Wali sebelum membuat
-- akses Laporan Tahfiz Published.
--
-- READ ONLY
--
-- OUTPUT dibuat dalam SATU result set agar mudah
-- dibaca dari Supabase SQL Editor.
-- =========================================================


-- =========================================================
-- 1. GUARDIAN / PARENT / WALI RELATED TABLES
-- =========================================================

select
    'TABLE'
        as object_type,

    table_data.table_name
        as object_name,

    null::text
        as detail_1,

    null::text
        as detail_2,

    null::text
        as detail_3

from information_schema.tables
    as table_data

where table_data.table_schema =
      'public'

  and table_data.table_type =
      'BASE TABLE'

  and (
      table_data.table_name ilike
      '%guardian%'

      or table_data.table_name ilike
         '%parent%'

      or table_data.table_name ilike
         '%wali%'
  )


union all


-- =========================================================
-- 2. COLUMNS OF GUARDIAN RELATED TABLES
-- =========================================================

select
    'COLUMN'
        as object_type,

    column_data.table_name
        as object_name,

    column_data.column_name
        as detail_1,

    column_data.data_type
        as detail_2,

    case
        when column_data.is_nullable =
             'YES'
        then 'nullable'
        else 'required'
    end
        as detail_3

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and (
      column_data.table_name ilike
      '%guardian%'

      or column_data.table_name ilike
         '%parent%'

      or column_data.table_name ilike
         '%wali%'
  )


union all


-- =========================================================
-- 3. GUARDIAN-LIKE COLUMNS ELSEWHERE
-- =========================================================

select
    'RELATED_COLUMN'
        as object_type,

    column_data.table_name
        as object_name,

    column_data.column_name
        as detail_1,

    column_data.data_type
        as detail_2,

    case
        when column_data.is_nullable =
             'YES'
        then 'nullable'
        else 'required'
    end
        as detail_3

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and (
      column_data.column_name ilike
      '%guardian%'

      or column_data.column_name ilike
         '%parent%'

      or column_data.column_name ilike
         '%wali%'
  )


union all


-- =========================================================
-- 4. GUARDIAN RELATED FUNCTIONS
-- =========================================================

select
    'FUNCTION'
        as object_type,

    procedure_data.proname
        as object_name,

    pg_get_function_identity_arguments(
        procedure_data.oid
    ) as detail_1,

    pg_get_function_result(
        procedure_data.oid
    ) as detail_2,

    case
        when procedure_data.prosecdef
        then 'security definer'
        else 'security invoker'
    end
        as detail_3

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
      '%guardian%'

      or procedure_data.proname ilike
         '%parent%'

      or procedure_data.proname ilike
         '%wali%'
  )


union all


-- =========================================================
-- 5. FOREIGN KEYS INVOLVING GUARDIAN RELATED TABLES
-- =========================================================

select
    'FOREIGN_KEY'
        as object_type,

    source_table.relname
        as object_name,

    constraint_data.conname
        as detail_1,

    target_table.relname
        as detail_2,

    pg_get_constraintdef(
        constraint_data.oid
    )
        as detail_3

from pg_constraint
    as constraint_data

inner join pg_class
    as source_table
    on source_table.oid =
       constraint_data.conrelid

inner join pg_namespace
    as source_namespace
    on source_namespace.oid =
       source_table.relnamespace

inner join pg_class
    as target_table
    on target_table.oid =
       constraint_data.confrelid

where constraint_data.contype =
      'f'

  and source_namespace.nspname =
      'public'

  and (
      source_table.relname ilike
      '%guardian%'

      or source_table.relname ilike
         '%parent%'

      or source_table.relname ilike
         '%wali%'

      or target_table.relname ilike
         '%guardian%'

      or target_table.relname ilike
         '%parent%'

      or target_table.relname ilike
         '%wali%'
  )


union all


-- =========================================================
-- 6. CURRENT TAHFIZ WEEKLY REPORT STRUCTURE
-- =========================================================

select
    'TAHFIZ_REPORT_COLUMN'
        as object_type,

    'tahfiz_weekly_reports'
        as object_name,

    column_data.column_name
        as detail_1,

    column_data.data_type
        as detail_2,

    case
        when column_data.is_nullable =
             'YES'
        then 'nullable'
        else 'required'
    end
        as detail_3

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and column_data.table_name =
      'tahfiz_weekly_reports'


union all


-- =========================================================
-- 7. REPORT STATUS COUNTS
-- =========================================================

select
    'REPORT_COUNT'
        as object_type,

    report.status
        as object_name,

    count(*)::text
        as detail_1,

    null::text
        as detail_2,

    null::text
        as detail_3

from public.tahfiz_weekly_reports
    as report

group by
    report.status


union all


-- =========================================================
-- 8. ROLE RELATED FUNCTIONS
-- =========================================================

select
    'ROLE_FUNCTION'
        as object_type,

    procedure_data.proname
        as object_name,

    pg_get_function_identity_arguments(
        procedure_data.oid
    ) as detail_1,

    pg_get_function_result(
        procedure_data.oid
    ) as detail_2,

    case
        when procedure_data.prosecdef
        then 'security definer'
        else 'security invoker'
    end
        as detail_3

from pg_proc
    as procedure_data

inner join pg_namespace
    as namespace
    on namespace.oid =
       procedure_data.pronamespace

where namespace.nspname =
      'public'

  and procedure_data.proname in (
      'has_role',
      'is_tahfiz_supervisor_of_student'
  )


order by
    object_type,
    object_name,
    detail_1;