-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 161b-inspect-schedule-attendance-compact.sql
--
-- PURPOSE:
-- Audit compact READ-ONLY.
--
-- Semua informasi penting dikembalikan dalam SATU
-- result set supaya mudah dibaca dari Supabase SQL Editor.
--
-- TIDAK ADA:
-- INSERT
-- UPDATE
-- DELETE
-- ALTER
-- DROP
-- =========================================================


-- =========================================================
-- 1. SCHEDULE / ATTENDANCE TABLES
-- =========================================================

select
    '01_schedule_attendance_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                candidate.table_name
            )

            order by
                candidate.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
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
)
    as candidate


union all


-- =========================================================
-- 2. GROUP / ASRAMA / CARE TABLES
-- =========================================================

select
    '02_group_asrama_care_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                candidate.table_name
            )

            order by
                candidate.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
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
)
    as candidate


union all


-- =========================================================
-- 3. GROUP / ASRAMA / CARE COLUMNS
-- =========================================================

select
    '03_group_asrama_care_columns'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                candidate.table_name,

                'column_name',
                candidate.column_name,

                'data_type',
                candidate.data_type,

                'is_nullable',
                candidate.is_nullable
            )

            order by
                candidate.table_name,
                candidate.ordinal_position
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        column_info.table_name,
        column_info.column_name,
        column_info.data_type,
        column_info.is_nullable,
        column_info.ordinal_position

    from information_schema.columns
        as column_info

    where column_info.table_schema =
          'public'

      and (
          column_info.table_name ilike
              '%group%'

          or column_info.table_name ilike
              '%kelompok%'

          or column_info.table_name ilike
              '%asrama%'

          or column_info.table_name ilike
              '%dorm%'

          or column_info.table_name ilike
              '%care%'

          or column_info.table_name ilike
              '%pengasuh%'
      )
)
    as candidate


union all


-- =========================================================
-- 4. TABLES WITH STUDENT_ID / STAFF_ID / GROUP_ID
-- =========================================================

select
    '04_relationship_columns'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                candidate.table_name,

                'column_name',
                candidate.column_name,

                'data_type',
                candidate.data_type
            )

            order by
                candidate.table_name,
                candidate.column_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        column_info.table_name,
        column_info.column_name,
        column_info.data_type

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
)
    as candidate


union all


-- =========================================================
-- 5. FOREIGN KEYS -> STUDENTS
-- =========================================================

select
    '05_foreign_keys_to_students'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'source_table',
                candidate.source_table,

                'source_column',
                candidate.source_column,

                'target_table',
                candidate.target_table,

                'target_column',
                candidate.target_column,

                'constraint_name',
                candidate.constraint_name
            )

            order by
                candidate.source_table,
                candidate.source_column
        ),
        '[]'::jsonb
    )
        as data

from (
    select
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
)
    as candidate


union all


-- =========================================================
-- 6. FOREIGN KEYS -> STAFF
-- =========================================================

select
    '06_foreign_keys_to_staff'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'source_table',
                candidate.source_table,

                'source_column',
                candidate.source_column,

                'target_table',
                candidate.target_table,

                'target_column',
                candidate.target_column,

                'constraint_name',
                candidate.constraint_name
            )

            order by
                candidate.source_table,
                candidate.source_column
        ),
        '[]'::jsonb
    )
        as data

from (
    select
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
)
    as candidate


union all


-- =========================================================
-- 7. MASTER TABLES
-- =========================================================

select
    '07_master_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                candidate.table_name
            )

            order by
                candidate.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
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
          'guardians',
          'guardian_students',
          'care_groups',
          'care_group_memberships',
          'care_group_assignments'
      )
)
    as candidate


union all


-- =========================================================
-- 8. CURRENT ACADEMIC YEAR
-- =========================================================

select
    '08_current_academic_year'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                academic_year.id,

                'name',
                academic_year.name,

                'start_date',
                academic_year.start_date,

                'end_date',
                academic_year.end_date,

                'is_current',
                academic_year.is_current
            )
        ),
        '[]'::jsonb
    )
        as data

from public.academic_years
    as academic_year

where academic_year.is_current =
      true


union all


-- =========================================================
-- 9. ACTIVE STUDENT COUNT
-- =========================================================

select
    '09_active_students'
        as section,

    jsonb_build_object(
        'count',
        count(*)
    )
        as data

from public.students
    as student

where student.status =
      'active'

  and student.deleted_at
      is null


union all


-- =========================================================
-- 10. EXISTING RELEVANT FUNCTIONS
-- =========================================================

select
    '10_existing_functions'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'routine_name',
                candidate.routine_name
            )

            order by
                candidate.routine_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        routine_name

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
)
    as candidate


order by
    section;