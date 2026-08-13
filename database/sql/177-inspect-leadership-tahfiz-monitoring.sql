-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 177-inspect-leadership-tahfiz-monitoring.sql
--
-- PURPOSE:
-- Audit READ-ONLY sebelum membangun monitoring Tahfiz
-- untuk:
-- - Kepala Ma'had
-- - Penanggung Jawab
--
-- IMPORTANT:
-- Audit ini tidak mengasumsikan nama tabel assignment
-- Pembina Tahfiz.
--
-- TIDAK ADA:
-- INSERT
-- UPDATE
-- DELETE
-- ALTER
-- DROP
-- =========================================================


-- =========================================================
-- 01. TAHFIZ RELATED TABLES
-- =========================================================

select
    '01_tahfiz_tables'
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
              '%tahfiz%'

          or table_name ilike
              '%tahfid%'
      )
)
    as candidate


union all


-- =========================================================
-- 02. TAHFIZ TABLE COLUMNS
-- =========================================================

select
    '02_tahfiz_columns'
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
        column_data.table_name,
        column_data.column_name,
        column_data.data_type,
        column_data.is_nullable,
        column_data.ordinal_position

    from information_schema.columns
        as column_data

    where column_data.table_schema =
          'public'

      and (
          column_data.table_name ilike
              '%tahfiz%'

          or column_data.table_name ilike
              '%tahfid%'
      )
)
    as candidate


union all


-- =========================================================
-- 03. EXISTING TAHFIZ FUNCTIONS
-- =========================================================

select
    '03_tahfiz_functions'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'function_name',
                candidate.routine_name
            )
            order by
                candidate.routine_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select distinct
        routine_name

    from information_schema.routines

    where routine_schema =
          'public'

      and (
          routine_name ilike
              '%tahfiz%'

          or routine_name ilike
              '%tahfid%'
      )
)
    as candidate


union all


-- =========================================================
-- 04. CURRENT ACADEMIC YEAR
-- =========================================================

select
    '04_current_academic_year'
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
-- 05. ACTIVE TAHFIZ GROUPS
-- =========================================================

select
    '05_active_tahfiz_groups'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                tahfiz_group.id,

                'code',
                tahfiz_group.code,

                'name',
                tahfiz_group.name,

                'gender',
                tahfiz_group.gender,

                'is_active',
                tahfiz_group.is_active
            )
            order by
                tahfiz_group.code
        ),
        '[]'::jsonb
    )
        as data

from public.tahfiz_groups
    as tahfiz_group

inner join public.academic_years
    as academic_year

    on academic_year.id =
       tahfiz_group.academic_year_id

where tahfiz_group.is_active =
      true

  and academic_year.is_current =
      true


union all


-- =========================================================
-- 06. ACTIVE TAHFIZ MEMBERS
-- =========================================================

select
    '06_active_tahfiz_members'
        as section,

    jsonb_build_object(
        'member_count',
        count(*)::integer,

        'unique_student_count',
        count(
            distinct member.student_id
        )::integer
    )
        as data

from public.tahfiz_group_members
    as member

inner join public.tahfiz_groups
    as tahfiz_group

    on tahfiz_group.id =
       member.tahfiz_group_id

inner join public.academic_years
    as academic_year

    on academic_year.id =
       tahfiz_group.academic_year_id

where member.is_active =
      true

  and tahfiz_group.is_active =
      true

  and academic_year.is_current =
      true


union all


-- =========================================================
-- 07. WEEKLY REPORT SUMMARY
-- =========================================================

select
    '07_weekly_report_summary'
        as section,

    jsonb_build_object(
        'total_reports',
        count(*)::integer,

        'draft_reports',
        count(*) filter (
            where report.status =
                  'draft'
        )::integer,

        'published_reports',
        count(*) filter (
            where report.status =
                  'published'
        )::integer,

        'unique_students',
        count(
            distinct report.student_id
        )::integer
    )
        as data

from public.tahfiz_weekly_reports
    as report

inner join public.academic_years
    as academic_year

    on academic_year.id =
       report.academic_year_id

where academic_year.is_current =
      true


union all


-- =========================================================
-- 08. REPORT STATUS VALUES
-- =========================================================

select
    '08_report_status_values'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'status',
                candidate.status,

                'count',
                candidate.total
            )
            order by
                candidate.status
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        report.status,

        count(*)::integer
            as total

    from public.tahfiz_weekly_reports
        as report

    inner join public.academic_years
        as academic_year

        on academic_year.id =
           report.academic_year_id

    where academic_year.is_current =
          true

    group by
        report.status
)
    as candidate


union all


-- =========================================================
-- 09. REPORT WEEK RANGE
-- =========================================================

select
    '09_report_week_range'
        as section,

    jsonb_build_object(
        'first_week',
        min(
            report.week_start
        ),

        'latest_week',
        max(
            report.week_start
        )
    )
        as data

from public.tahfiz_weekly_reports
    as report

inner join public.academic_years
    as academic_year

    on academic_year.id =
       report.academic_year_id

where academic_year.is_current =
      true


union all


-- =========================================================
-- 10. DISCOVER TAHFIZ ASSIGNMENT CANDIDATE TABLES
--
-- Tidak lagi mengasumsikan:
-- public.tahfiz_coach_assignments
--
-- Cari tabel yang memiliki kolom staff_id dan
-- tahfiz_group_id, atau nama yang mengandung tahfiz
-- dan assignment/coach/pembina.
-- =========================================================

select
    '10_tahfiz_assignment_candidates'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                candidate.table_name,

                'columns',
                candidate.columns
            )
            order by
                candidate.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        table_data.table_name,

        jsonb_agg(
            jsonb_build_object(
                'column_name',
                table_data.column_name,

                'data_type',
                table_data.data_type,

                'is_nullable',
                table_data.is_nullable
            )
            order by
                table_data.ordinal_position
        )
            as columns

    from information_schema.columns
        as table_data

    where table_data.table_schema =
          'public'

      and table_data.table_name in (
          select
              column_data.table_name

          from information_schema.columns
              as column_data

          where column_data.table_schema =
                'public'

          group by
              column_data.table_name

          having
              (
                  bool_or(
                      column_data.column_name =
                      'staff_id'
                  )

                  and

                  bool_or(
                      column_data.column_name =
                      'tahfiz_group_id'
                  )
              )

              or

              (
                  (
                      max(
                          column_data.table_name
                      ) ilike '%tahfiz%'

                      or

                      max(
                          column_data.table_name
                      ) ilike '%tahfid%'
                  )

                  and

                  (
                      max(
                          column_data.table_name
                      ) ilike '%assign%'

                      or

                      max(
                          column_data.table_name
                      ) ilike '%coach%'

                      or

                      max(
                          column_data.table_name
                      ) ilike '%pembina%'
                  )
              )
      )

    group by
        table_data.table_name
)
    as candidate


union all


-- =========================================================
-- 11. STAFF-RELATED TABLES WITH TAHFIZ RELATIONSHIP
--
-- Audit tambahan untuk menemukan kemungkinan tabel
-- assignment dengan nama yang tidak memakai "tahfiz".
-- =========================================================

select
    '11_staff_group_relation_candidates'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                candidate.table_name,

                'column_names',
                candidate.column_names
            )
            order by
                candidate.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        column_data.table_name,

        jsonb_agg(
            column_data.column_name
            order by
                column_data.ordinal_position
        )
            as column_names

    from information_schema.columns
        as column_data

    where column_data.table_schema =
          'public'

    group by
        column_data.table_name

    having
        bool_or(
            column_data.column_name =
            'staff_id'
        )

        and (
            bool_or(
                column_data.column_name =
                'tahfiz_group_id'
            )

            or

            bool_or(
                column_data.column_name =
                'group_id'
            )
        )
)
    as candidate


union all


-- =========================================================
-- 12. KEPALA MA'HAD ACCOUNT
-- =========================================================

select
    '12_kepala_mahad_account'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'profile_id',
                profile.id,

                'login_id',
                profile.login_id,

                'staff_id',
                staff.id,

                'staff_name',
                staff.full_name,

                'position',
                staff.position
            )
        ),
        '[]'::jsonb
    )
        as data

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


union all


-- =========================================================
-- 13. PENANGGUNG JAWAB ACCOUNT
-- =========================================================

select
    '13_penanggung_jawab_account'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'profile_id',
                profile.id,

                'login_id',
                profile.login_id,

                'staff_id',
                staff.id,

                'staff_name',
                staff.full_name,

                'position',
                staff.position
            )
        ),
        '[]'::jsonb
    )
        as data

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
      'penanggung_jawab'

  and role.is_active =
      true

  and profile.is_active =
      true

  and staff.is_active =
      true


union all


-- =========================================================
-- 14. TAHFIZ GROUP FOREIGN KEYS
--
-- Berguna untuk mengetahui tabel mana yang terhubung
-- langsung dengan tahfiz_groups.
-- =========================================================

select
    '14_tahfiz_group_foreign_keys'
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
                candidate.target_column
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

        source_attribute.attname
            as source_column,

        target_table.relname
            as target_table,

        target_attribute.attname
            as target_column

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

    inner join pg_namespace
        as target_namespace

        on target_namespace.oid =
           target_table.relnamespace

    inner join lateral
        unnest(
            constraint_data.conkey
        )
        with ordinality
        as source_key(
            attnum,
            position
        )

        on true

    inner join lateral
        unnest(
            constraint_data.confkey
        )
        with ordinality
        as target_key(
            attnum,
            position
        )

        on target_key.position =
           source_key.position

    inner join pg_attribute
        as source_attribute

        on source_attribute.attrelid =
           source_table.oid

       and source_attribute.attnum =
           source_key.attnum

    inner join pg_attribute
        as target_attribute

        on target_attribute.attrelid =
           target_table.oid

       and target_attribute.attnum =
           target_key.attnum

    where constraint_data.contype =
          'f'

      and source_namespace.nspname =
          'public'

      and target_namespace.nspname =
          'public'

      and target_table.relname =
          'tahfiz_groups'
)
    as candidate


union all


-- =========================================================
-- 15. TAHFIZ WEEKLY REPORT COLUMNS
--
-- Kita butuh exact structure untuk monitoring pimpinan.
-- =========================================================

select
    '15_weekly_report_columns'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'column_name',
                column_data.column_name,

                'data_type',
                column_data.data_type,

                'is_nullable',
                column_data.is_nullable
            )
            order by
                column_data.ordinal_position
        ),
        '[]'::jsonb
    )
        as data

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and column_data.table_name =
      'tahfiz_weekly_reports'


union all


-- =========================================================
-- 16. FINAL
-- =========================================================

select
    '16_audit_status'
        as section,

    jsonb_build_object(
        'status',
        'Audit monitoring Tahfiz pimpinan selesai.',

        'audited_at',
        now()
    )
        as data


order by
    section;