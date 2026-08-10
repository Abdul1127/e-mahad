-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 110-inspect-tahfiz-weekly-report-core-results.sql
--
-- PURPOSE:
-- Menampilkan hasil audit struktur Tahfiz / laporan
-- dalam SATU result set agar mudah dibaca di
-- Supabase SQL Editor.
--
-- READ ONLY
-- =========================================================


-- =========================================================
-- 1. RELATED TABLES
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


union all


-- =========================================================
-- 2. RELATED COLUMNS
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
      '%tahfiz%'

      or column_data.table_name ilike
         '%hafal%'

      or column_data.table_name ilike
         '%muraja%'

      or column_data.table_name ilike
         '%setoran%'

      or column_data.table_name ilike
         '%report%'

      or column_data.table_name ilike
         '%laporan%'

      or column_data.table_name ilike
         '%weekly%'

      or column_data.table_name ilike
         '%pekan%'

      or column_data.table_name ilike
         '%quran%'
  )


union all


-- =========================================================
-- 3. REPORT-LIKE COLUMNS IN ANY TABLE
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


union all


-- =========================================================
-- 4. EXISTING FUNCTIONS
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
    object_type,
    object_name,
    detail_1;