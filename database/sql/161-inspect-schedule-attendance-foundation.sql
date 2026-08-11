-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 161-inspect-schedule-attendance-foundation.sql
--
-- PURPOSE:
-- Audit READ-ONLY untuk:
--
-- - Jadwal
-- - Absensi
-- - Kegiatan
-- - Kelompok / Asrama
-- - Relasi Santri
-- - Assignment Pengasuh
--
-- Script ini TIDAK mengasumsikan nama tabel kelompok.
--
-- TIDAK ADA:
-- INSERT
-- UPDATE
-- DELETE
-- ALTER
-- DROP
--
-- SAFE / READ ONLY
-- =========================================================


-- =========================================================
-- 1. SELURUH TABEL YANG BERKAITAN DENGAN
--    JADWAL / ABSENSI / KEGIATAN
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
          '%schedule%'

      or table_name ilike
          '%jadwal%'

      or table_name ilike
          '%attendance%'

      or table_name ilike
          '%absen%'

      or table_name ilike
          '%activity%'

      or table_name ilike
          '%kegiatan%'
  )

order by
    table_name;


-- =========================================================
-- 2. CARI TABEL KELOMPOK / ASRAMA / PENGASUH
--
-- Kita cari nama sebenarnya di database.
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
          '%group%'

      or table_name ilike
          '%kelompok%'

      or table_name ilike
          '%asrama%'

      or table_name ilike
          '%dorm%'

      or table_name ilike
          '%care%'

      or table_name ilike
          '%pengasuh%'
  )

order by
    table_name;


-- =========================================================
-- 3. COLUMNS DARI TABEL KELOMPOK / ASRAMA / PENGASUH
--
-- Ini membantu mengetahui:
--
-- - nama PK
-- - student_id
-- - staff_id
-- - group_id
-- - academic_year_id
-- - status aktif
-- =========================================================

select
    column_info.table_name,
    column_info.ordinal_position,
    column_info.column_name,
    column_info.data_type,
    column_info.udt_name,
    column_info.is_nullable,
    column_info.column_default

from information_schema.columns
    as column_info

where column_info.table_schema =
      'public'

  and exists (
      select 1

      from information_schema.tables
          as candidate_table

      where candidate_table.table_schema =
            'public'

        and candidate_table.table_name =
            column_info.table_name

        and candidate_table.table_type =
            'BASE TABLE'

        and (
            candidate_table.table_name ilike
                '%group%'

            or candidate_table.table_name ilike
                '%kelompok%'

            or candidate_table.table_name ilike
                '%asrama%'

            or candidate_table.table_name ilike
                '%dorm%'

            or candidate_table.table_name ilike
                '%care%'

            or candidate_table.table_name ilike
                '%pengasuh%'
        )
  )

order by
    column_info.table_name,
    column_info.ordinal_position;


-- =========================================================
-- 4. CANDIDATE FUNCTIONS
-- =========================================================

select
    routine_schema,
    routine_name,
    routine_type,
    data_type
        as return_type

from information_schema.routines

where routine_schema =
      'public'

  and (
      routine_name ilike
          '%schedule%'

      or routine_name ilike
          '%jadwal%'

      or routine_name ilike
          '%attendance%'

      or routine_name ilike
          '%absen%'

      or routine_name ilike
          '%activity%'

      or routine_name ilike
          '%kegiatan%'
  )

order by
    routine_name;


-- =========================================================
-- 5. ENUM YANG BERKAITAN
-- =========================================================

select
    namespace.nspname
        as schema_name,

    type.typname
        as type_name,

    enum.enumlabel
        as enum_value

from pg_type
    as type

inner join pg_enum
    as enum

    on enum.enumtypid =
       type.oid

inner join pg_namespace
    as namespace

    on namespace.oid =
       type.typnamespace

where namespace.nspname =
      'public'

  and (
      type.typname ilike
          '%attendance%'

      or type.typname ilike
          '%absen%'

      or type.typname ilike
          '%schedule%'

      or type.typname ilike
          '%jadwal%'

      or type.typname ilike
          '%activity%'

      or type.typname ilike
          '%kegiatan%'
  )

order by
    type.typname,
    enum.enumsortorder;


-- =========================================================
-- 6. MASTER TABLES YANG BENAR-BENAR TERSEDIA
-- =========================================================

select
    table_name

from information_schema.tables

where table_schema =
      'public'

  and table_type =
      'BASE TABLE'

  and table_name in (
      'students',
      'staff',
      'profiles',
      'roles',
      'user_roles',
      'academic_years',
      'classes',
      'student_classes',
      'care_groups',
      'care_group_memberships',
      'care_group_assignments',
      'guardians',
      'guardian_students'
  )

order by
    table_name;


-- =========================================================
-- 7. STUDENT COLUMNS
-- =========================================================

select
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default

from information_schema.columns

where table_schema =
      'public'

  and table_name =
      'students'

order by
    ordinal_position;


-- =========================================================
-- 8. STAFF COLUMNS
-- =========================================================

select
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default

from information_schema.columns

where table_schema =
      'public'

  and table_name =
      'staff'

order by
    ordinal_position;


-- =========================================================
-- 9. ACADEMIC YEAR COLUMNS
-- =========================================================

select
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default

from information_schema.columns

where table_schema =
      'public'

  and table_name =
      'academic_years'

order by
    ordinal_position;


-- =========================================================
-- 10. CURRENT ACADEMIC YEAR
-- =========================================================

select
    id,
    name,
    start_date,
    end_date,
    is_current

from public.academic_years

where is_current =
      true

order by
    start_date desc;


-- =========================================================
-- 11. ACTIVE STUDENT SUMMARY
-- =========================================================

select
    count(*)
        as active_student_count

from public.students

where status =
      'active'

  and deleted_at
      is null;


-- =========================================================
-- 12. FOREIGN KEYS YANG MENGARAH KE STUDENTS
--
-- Sangat penting:
-- ini akan membantu menemukan tabel membership sebenarnya.
-- =========================================================

select
    source_namespace.nspname
        as source_schema,

    source_table.relname
        as source_table,

    source_column.attname
        as source_column,

    target_namespace.nspname
        as target_schema,

    target_table.relname
        as target_table,

    target_column.attname
        as target_column,

    constraint_info.conname
        as constraint_name

from pg_constraint
    as constraint_info

inner join pg_class
    as source_table

    on source_table.oid =
       constraint_info.conrelid

inner join pg_namespace
    as source_namespace

    on source_namespace.oid =
       source_table.relnamespace

inner join pg_class
    as target_table

    on target_table.oid =
       constraint_info.confrelid

inner join pg_namespace
    as target_namespace

    on target_namespace.oid =
       target_table.relnamespace

inner join lateral
    unnest(
        constraint_info.conkey
    )
    with ordinality
    as source_key(
        attnum,
        ordinality
    )

    on true

inner join lateral
    unnest(
        constraint_info.confkey
    )
    with ordinality
    as target_key(
        attnum,
        ordinality
    )

    on target_key.ordinality =
       source_key.ordinality

inner join pg_attribute
    as source_column

    on source_column.attrelid =
       source_table.oid

   and source_column.attnum =
       source_key.attnum

inner join pg_attribute
    as target_column

    on target_column.attrelid =
       target_table.oid

   and target_column.attnum =
       target_key.attnum

where constraint_info.contype =
      'f'

  and source_namespace.nspname =
      'public'

  and target_namespace.nspname =
      'public'

  and target_table.relname =
      'students'

order by
    source_table.relname,
    source_column.attname;


-- =========================================================
-- 13. FOREIGN KEYS YANG MENGARAH KE STAFF
--
-- Membantu menemukan assignment pengasuh sebenarnya.
-- =========================================================

select
    source_namespace.nspname
        as source_schema,

    source_table.relname
        as source_table,

    source_column.attname
        as source_column,

    target_namespace.nspname
        as target_schema,

    target_table.relname
        as target_table,

    target_column.attname
        as target_column,

    constraint_info.conname
        as constraint_name

from pg_constraint
    as constraint_info

inner join pg_class
    as source_table

    on source_table.oid =
       constraint_info.conrelid

inner join pg_namespace
    as source_namespace

    on source_namespace.oid =
       source_table.relnamespace

inner join pg_class
    as target_table

    on target_table.oid =
       constraint_info.confrelid

inner join pg_namespace
    as target_namespace

    on target_namespace.oid =
       target_table.relnamespace

inner join lateral
    unnest(
        constraint_info.conkey
    )
    with ordinality
    as source_key(
        attnum,
        ordinality
    )

    on true

inner join lateral
    unnest(
        constraint_info.confkey
    )
    with ordinality
    as target_key(
        attnum,
        ordinality
    )

    on target_key.ordinality =
       source_key.ordinality

inner join pg_attribute
    as source_column

    on source_column.attrelid =
       source_table.oid

   and source_column.attnum =
       source_key.attnum

inner join pg_attribute
    as target_column

    on target_column.attrelid =
       target_table.oid

   and target_column.attnum =
       target_key.attnum

where constraint_info.contype =
      'f'

  and source_namespace.nspname =
      'public'

  and target_namespace.nspname =
      'public'

  and target_table.relname =
      'staff'

order by
    source_table.relname,
    source_column.attname;


-- =========================================================
-- 14. FOREIGN KEYS YANG MENGARAH KE ACADEMIC YEARS
-- =========================================================

select
    source_namespace.nspname
        as source_schema,

    source_table.relname
        as source_table,

    source_column.attname
        as source_column,

    target_table.relname
        as target_table,

    target_column.attname
        as target_column,

    constraint_info.conname
        as constraint_name

from pg_constraint
    as constraint_info

inner join pg_class
    as source_table

    on source_table.oid =
       constraint_info.conrelid

inner join pg_namespace
    as source_namespace

    on source_namespace.oid =
       source_table.relnamespace

inner join pg_class
    as target_table

    on target_table.oid =
       constraint_info.confrelid

inner join lateral
    unnest(
        constraint_info.conkey
    )
    with ordinality
    as source_key(
        attnum,
        ordinality
    )

    on true

inner join lateral
    unnest(
        constraint_info.confkey
    )
    with ordinality
    as target_key(
        attnum,
        ordinality
    )

    on target_key.ordinality =
       source_key.ordinality

inner join pg_attribute
    as source_column

    on source_column.attrelid =
       source_table.oid

   and source_column.attnum =
       source_key.attnum

inner join pg_attribute
    as target_column

    on target_column.attrelid =
       target_table.oid

   and target_column.attnum =
       target_key.attnum

where constraint_info.contype =
      'f'

  and source_namespace.nspname =
      'public'

  and target_table.relname =
      'academic_years'

order by
    source_table.relname,
    source_column.attname;


-- =========================================================
-- 15. SEMUA PUBLIC TABLE YANG MEMILIKI STUDENT_ID,
--     STAFF_ID, GROUP_ID, CARE_GROUP_ID ATAU ASSIGNMENT_ID
--
-- Ini sangat membantu mengetahui desain yang sudah ada.
-- =========================================================

select
    column_info.table_name,
    column_info.column_name,
    column_info.data_type,
    column_info.is_nullable

from information_schema.columns
    as column_info

where column_info.table_schema =
      'public'

  and column_info.column_name in (
      'student_id',
      'staff_id',
      'group_id',
      'care_group_id',
      'assignment_id',
      'academic_year_id'
  )

order by
    column_info.table_name,
    column_info.column_name;


-- =========================================================
-- 16. RLS UNTUK CANDIDATE TABLES
-- =========================================================

select
    namespace.nspname
        as schema_name,

    class.relname
        as table_name,

    class.relrowsecurity
        as rls_enabled

from pg_class
    as class

inner join pg_namespace
    as namespace

    on namespace.oid =
       class.relnamespace

where namespace.nspname =
      'public'

  and class.relkind =
      'r'

  and (
      class.relname ilike
          '%schedule%'

      or class.relname ilike
          '%jadwal%'

      or class.relname ilike
          '%attendance%'

      or class.relname ilike
          '%absen%'

      or class.relname ilike
          '%activity%'

      or class.relname ilike
          '%kegiatan%'

      or class.relname ilike
          '%group%'

      or class.relname ilike
          '%kelompok%'

      or class.relname ilike
          '%asrama%'

      or class.relname ilike
          '%care%'
  )

order by
    class.relname;


-- =========================================================
-- 17. EXISTING POLICIES FOR CANDIDATE TABLES
-- =========================================================

select
    schemaname,
    tablename,
    policyname,
    cmd,
    roles

from pg_policies

where schemaname =
      'public'

  and (
      tablename ilike
          '%schedule%'

      or tablename ilike
          '%jadwal%'

      or tablename ilike
          '%attendance%'

      or tablename ilike
          '%absen%'

      or tablename ilike
          '%activity%'

      or tablename ilike
          '%kegiatan%'

      or tablename ilike
          '%group%'

      or tablename ilike
          '%kelompok%'

      or tablename ilike
          '%asrama%'

      or tablename ilike
          '%care%'
  )

order by
    tablename,
    policyname;


-- =========================================================
-- FINAL
-- =========================================================

select
    'Audit Jadwal & Absensi selesai.'
        as audit_status,

    now()
        as audited_at;