-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 092-inspect-care-journal-foundation.sql
--
-- PURPOSE:
-- - Audit fondasi Jurnal Pengasuhan
-- - Mencari tabel/function/policy lama yang mungkin terkait
-- - Audit struktur Pengasuh dan Kepala Ma'had
-- - Audit assignment kelompok aktif
-- - READ ONLY
--
-- TIDAK MENGUBAH DATA
-- =========================================================


with

-- =========================================================
-- 1. CURRENT ACADEMIC YEAR
-- =========================================================

current_academic_year as (
    select
        academic_year.id,
        academic_year.name,
        academic_year.start_date,
        academic_year.end_date

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
),


-- =========================================================
-- 2. PENGASUH AKTIF
-- =========================================================

active_pengasuh as (
    select distinct
        profile.id
            as profile_id,

        profile.login_id,

        staff.id
            as staff_id,

        staff.legacy_staff_id,

        staff.full_name,

        staff.position

    from public.profiles
        as profile

    inner join public.staff
        as staff
        on staff.profile_id =
           profile.id

    inner join public.user_roles
        as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles
        as role
        on role.id =
           user_role.role_id

    where role.code =
          'pengasuh'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true
),


-- =========================================================
-- 3. KEPALA MA'HAD AKTIF
-- =========================================================

active_kepala_mahad as (
    select distinct
        profile.id
            as profile_id,

        profile.login_id,

        staff.id
            as staff_id,

        staff.legacy_staff_id,

        staff.full_name,

        staff.position

    from public.profiles
        as profile

    inner join public.staff
        as staff
        on staff.profile_id =
           profile.id

    inner join public.user_roles
        as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles
        as role
        on role.id =
           user_role.role_id

    where role.code =
          'kepala_mahad'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true
),


-- =========================================================
-- 4. ACTIVE CARE ASSIGNMENTS
-- =========================================================

active_care_assignments as (
    select
        assignment.id
            as assignment_id,

        assignment.staff_id,

        assignment.care_group_id,

        assignment.assigned_at,

        assignment.is_primary,

        care_group.code
            as group_code,

        care_group.name
            as group_name,

        care_group.gender::text
            as group_gender,

        care_group.academic_year_id,

        care_group.is_active
            as group_is_active

    from public.caregiver_assignments
        as assignment

    inner join public.care_groups
        as care_group
        on care_group.id =
           assignment.care_group_id

    where assignment.is_active =
          true
),


-- =========================================================
-- 5. CURRENT CARE GROUP COUNTS
-- =========================================================

current_care_group_summary as (
    select
        care_group.id
            as care_group_id,

        care_group.code,

        care_group.name,

        care_group.gender::text
            as gender,

        count(
            distinct membership.student_id
        ) filter (
            where membership.is_active =
                  true

              and student.status =
                  'active'

              and student.deleted_at
                  is null
        )::integer
            as active_student_count,

        count(
            distinct assignment.id
        ) filter (
            where assignment.is_active =
                  true
        )::integer
            as active_caregiver_count

    from public.care_groups
        as care_group

    inner join current_academic_year
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

    left join public.care_group_members
        as membership
        on membership.care_group_id =
           care_group.id

    left join public.students
        as student
        on student.id =
           membership.student_id

    left join public.caregiver_assignments
        as assignment
        on assignment.care_group_id =
           care_group.id

    where care_group.is_active =
          true

    group by
        care_group.id,
        care_group.code,
        care_group.name,
        care_group.gender
),


-- =========================================================
-- 6. TABLES YANG MUNGKIN TERKAIT JURNAL
-- =========================================================

possible_journal_tables as (
    select
        table_schema,

        table_name,

        table_type

    from information_schema.tables

    where table_schema =
          'public'

      and (
          table_name ilike '%journal%'
          or table_name ilike '%jurnal%'
          or table_name ilike '%care_log%'
          or table_name ilike '%care_note%'
          or table_name ilike '%care_report%'
          or table_name ilike '%behavior%'
          or table_name ilike '%behaviour%'
          or table_name ilike '%disciplin%'
          or table_name ilike '%incident%'
          or table_name ilike '%review%'
      )
),


-- =========================================================
-- 7. COLUMNS DARI TABLE TERKAIT
-- =========================================================

possible_journal_columns as (
    select
        column_info.table_schema,

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

          from possible_journal_tables
              as journal_table

          where journal_table.table_schema =
                column_info.table_schema

            and journal_table.table_name =
                column_info.table_name
      )
),


-- =========================================================
-- 8. FUNCTIONS YANG MUNGKIN TERKAIT
-- =========================================================

possible_journal_functions as (
    select
        namespace.nspname
            as function_schema,

        procedure.proname
            as function_name,

        pg_get_function_identity_arguments(
            procedure.oid
        ) as arguments,

        pg_get_function_result(
            procedure.oid
        ) as return_type

    from pg_proc
        as procedure

    inner join pg_namespace
        as namespace
        on namespace.oid =
           procedure.pronamespace

    where namespace.nspname =
          'public'

      and (
          procedure.proname ilike '%journal%'
          or procedure.proname ilike '%jurnal%'
          or procedure.proname ilike '%care_log%'
          or procedure.proname ilike '%care_note%'
          or procedure.proname ilike '%care_report%'
          or procedure.proname ilike '%behavior%'
          or procedure.proname ilike '%disciplin%'
          or procedure.proname ilike '%incident%'
          or procedure.proname ilike '%review%'
      )
),


-- =========================================================
-- 9. POLICIES DARI TABLE TERKAIT
-- =========================================================

possible_journal_policies as (
    select
        policy.schemaname,

        policy.tablename,

        policy.policyname,

        policy.permissive,

        policy.roles,

        policy.cmd,

        policy.qual,

        policy.with_check

    from pg_policies
        as policy

    where policy.schemaname =
          'public'

      and exists (
          select 1

          from possible_journal_tables
              as journal_table

          where journal_table.table_name =
                policy.tablename
      )
),


-- =========================================================
-- 10. CONSTRAINTS DARI TABLE TERKAIT
-- =========================================================

possible_journal_constraints as (
    select
        namespace.nspname
            as table_schema,

        relation.relname
            as table_name,

        constraint_data.conname
            as constraint_name,

        constraint_data.contype
            as constraint_type,

        pg_get_constraintdef(
            constraint_data.oid,
            true
        ) as definition

    from pg_constraint
        as constraint_data

    inner join pg_class
        as relation
        on relation.oid =
           constraint_data.conrelid

    inner join pg_namespace
        as namespace
        on namespace.oid =
           relation.relnamespace

    where namespace.nspname =
          'public'

      and exists (
          select 1

          from possible_journal_tables
              as journal_table

          where journal_table.table_name =
                relation.relname
      )
),


-- =========================================================
-- 11. INDEXES DARI TABLE TERKAIT
-- =========================================================

possible_journal_indexes as (
    select
        index_data.schemaname,

        index_data.tablename,

        index_data.indexname,

        index_data.indexdef

    from pg_indexes
        as index_data

    where index_data.schemaname =
          'public'

      and exists (
          select 1

          from possible_journal_tables
              as journal_table

          where journal_table.table_name =
                index_data.tablename
      )
),


-- =========================================================
-- 12. ENUM YANG MUNGKIN TERKAIT
-- =========================================================

possible_journal_enums as (
    select
        namespace.nspname
            as enum_schema,

        type_data.typname
            as enum_name,

        jsonb_agg(
            enum_data.enumlabel

            order by
                enum_data.enumsortorder
        ) as values

    from pg_type
        as type_data

    inner join pg_enum
        as enum_data
        on enum_data.enumtypid =
           type_data.oid

    inner join pg_namespace
        as namespace
        on namespace.oid =
           type_data.typnamespace

    where namespace.nspname =
          'public'

      and (
          type_data.typname ilike '%journal%'
          or type_data.typname ilike '%jurnal%'
          or type_data.typname ilike '%care%'
          or type_data.typname ilike '%review%'
          or type_data.typname ilike '%behavior%'
          or type_data.typname ilike '%disciplin%'
      )

    group by
        namespace.nspname,
        type_data.typname
),


-- =========================================================
-- 13. SUMMARY
-- =========================================================

summary_data as (
    select
        (
            select count(*)::integer

            from active_pengasuh
        ) as active_pengasuh_count,

        (
            select count(*)::integer

            from active_kepala_mahad
        ) as active_kepala_mahad_count,

        (
            select count(*)::integer

            from active_care_assignments
                as assignment

            inner join current_academic_year
                as academic_year
                on academic_year.id =
                   assignment.academic_year_id

            where assignment.group_is_active =
                  true
        ) as current_caregiver_assignment_count,

        (
            select count(*)::integer

            from current_care_group_summary
        ) as current_care_group_count,

        (
            select coalesce(
                sum(
                    group_summary.active_student_count
                ),
                0
            )::integer

            from current_care_group_summary
                as group_summary
        ) as current_active_student_count,

        (
            select count(*)::integer

            from possible_journal_tables
        ) as possible_journal_table_count,

        (
            select count(*)::integer

            from possible_journal_functions
        ) as possible_journal_function_count
)


-- =========================================================
-- 14. FINAL JSON
-- =========================================================

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Fondasi Jurnal Pengasuhan berhasil diperiksa',

        'inspected_at',
        now(),

        'current_academic_year',
        (
            select
                case
                    when academic_year.id
                         is null
                    then null

                    else jsonb_build_object(
                        'id',
                        academic_year.id,

                        'name',
                        academic_year.name,

                        'start_date',
                        academic_year.start_date,

                        'end_date',
                        academic_year.end_date
                    )
                end

            from current_academic_year
                as academic_year
        ),

        'summary',
        (
            select
                to_jsonb(
                    summary_row
                )

            from summary_data
                as summary_row
        ),

        'active_pengasuh',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        pengasuh
                    )

                    order by
                        pengasuh.full_name
                ),
                '[]'::jsonb
            )

            from active_pengasuh
                as pengasuh
        ),

        'active_kepala_mahad',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        kepala_mahad
                    )

                    order by
                        kepala_mahad.full_name
                ),
                '[]'::jsonb
            )

            from active_kepala_mahad
                as kepala_mahad
        ),

        'care_groups',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        group_summary
                    )

                    order by
                        group_summary.name
                ),
                '[]'::jsonb
            )

            from current_care_group_summary
                as group_summary
        ),

        'possible_existing_journal_tables',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        journal_table
                    )

                    order by
                        journal_table.table_name
                ),
                '[]'::jsonb
            )

            from possible_journal_tables
                as journal_table
        ),

        'possible_existing_journal_columns',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        column_data
                    )

                    order by
                        column_data.table_name,
                        column_data.ordinal_position
                ),
                '[]'::jsonb
            )

            from possible_journal_columns
                as column_data
        ),

        'possible_existing_journal_functions',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        function_data
                    )

                    order by
                        function_data.function_name,
                        function_data.arguments
                ),
                '[]'::jsonb
            )

            from possible_journal_functions
                as function_data
        ),

        'possible_existing_journal_policies',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        policy_data
                    )

                    order by
                        policy_data.tablename,
                        policy_data.policyname
                ),
                '[]'::jsonb
            )

            from possible_journal_policies
                as policy_data
        ),

        'possible_existing_journal_constraints',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        constraint_data
                    )

                    order by
                        constraint_data.table_name,
                        constraint_data.constraint_name
                ),
                '[]'::jsonb
            )

            from possible_journal_constraints
                as constraint_data
        ),

        'possible_existing_journal_indexes',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        index_data
                    )

                    order by
                        index_data.tablename,
                        index_data.indexname
                ),
                '[]'::jsonb
            )

            from possible_journal_indexes
                as index_data
        ),

        'possible_existing_journal_enums',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(
                        enum_data
                    )

                    order by
                        enum_data.enum_name
                ),
                '[]'::jsonb
            )

            from possible_journal_enums
                as enum_data
        )
    )
) as care_journal_foundation_inspection;