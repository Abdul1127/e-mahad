-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 173-inspect-kepala-mahad-journal-foundation.sql
--
-- PURPOSE:
-- Audit READ-ONLY sebelum membangun:
--
-- JURNAL KEPALA MA'HAD
--
-- Audit:
-- - kandidat tabel jurnal Kepala Ma'had
-- - kandidat function
-- - staff / profile structure
-- - role Kepala Ma'had
-- - current Kepala Ma'had account
-- - current academic year
-- - storage bucket existing
-- - storage policy existing
--
-- TIDAK ADA:
-- INSERT
-- UPDATE
-- DELETE
-- ALTER
-- DROP
-- =========================================================


-- =========================================================
-- 01. EXISTING CANDIDATE TABLES
-- =========================================================

select
    '01_candidate_tables'
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
              '%mahad%'

          or table_name ilike
              '%headmaster%'

          or table_name ilike
              '%kepala%'

          or table_name ilike
              '%journal%'

          or table_name ilike
              '%jurnal%'
      )
)
    as candidate


union all


-- =========================================================
-- 02. EXISTING CANDIDATE FUNCTIONS
-- =========================================================

select
    '02_candidate_functions'
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
              '%mahad%'

          or routine_name ilike
              '%headmaster%'

          or routine_name ilike
              '%kepala%'

          or routine_name ilike
              '%journal%'

          or routine_name ilike
              '%jurnal%'
      )
)
    as candidate


union all


-- =========================================================
-- 03. STAFF COLUMNS
-- =========================================================

select
    '03_staff_columns'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'column_name',
                candidate.column_name,

                'data_type',
                candidate.data_type,

                'is_nullable',
                candidate.is_nullable
            )
            order by
                candidate.ordinal_position
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        column_name,
        data_type,
        is_nullable,
        ordinal_position

    from information_schema.columns

    where table_schema =
          'public'

      and table_name =
          'staff'
)
    as candidate


union all


-- =========================================================
-- 04. PROFILE COLUMNS
-- =========================================================

select
    '04_profile_columns'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'column_name',
                candidate.column_name,

                'data_type',
                candidate.data_type,

                'is_nullable',
                candidate.is_nullable
            )
            order by
                candidate.ordinal_position
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        column_name,
        data_type,
        is_nullable,
        ordinal_position

    from information_schema.columns

    where table_schema =
          'public'

      and table_name =
          'profiles'
)
    as candidate


union all


-- =========================================================
-- 05. KEPALA MA'HAD ROLE
-- =========================================================

select
    '05_kepala_mahad_role'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                role.id,

                'code',
                role.code,

                'name',
                role.name,

                'is_active',
                role.is_active
            )
        ),
        '[]'::jsonb
    )
        as data

from public.roles
    as role

where role.code =
      'kepala_mahad'


union all


-- =========================================================
-- 06. ACTIVE KEPALA MA'HAD ACCOUNT
-- =========================================================

select
    '06_active_kepala_mahad_accounts'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'profile_id',
                profile.id,

                'login_id',
                profile.login_id,

                'profile_active',
                profile.is_active,

                'staff_id',
                staff.id,

                'staff_name',
                staff.full_name,

                'legacy_staff_id',
                staff.legacy_staff_id,

                'position',
                staff.position,

                'staff_active',
                staff.is_active
            )
            order by
                staff.full_name
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


union all


-- =========================================================
-- 07. PENANGGUNG JAWAB ACCOUNT
--
-- Nanti role ini akan menjadi monitoring read-only.
-- =========================================================

select
    '07_active_penanggung_jawab_accounts'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'profile_id',
                profile.id,

                'login_id',
                profile.login_id,

                'profile_active',
                profile.is_active,

                'staff_id',
                staff.id,

                'staff_name',
                staff.full_name,

                'legacy_staff_id',
                staff.legacy_staff_id,

                'position',
                staff.position,

                'staff_active',
                staff.is_active
            )
            order by
                staff.full_name
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


union all


-- =========================================================
-- 08. CURRENT ACADEMIC YEAR
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
-- 09. STORAGE BUCKETS
-- =========================================================

select
    '09_storage_buckets'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                bucket.id,

                'name',
                bucket.name,

                'public',
                bucket.public,

                'file_size_limit',
                bucket.file_size_limit,

                'allowed_mime_types',
                bucket.allowed_mime_types
            )
            order by
                bucket.name
        ),
        '[]'::jsonb
    )
        as data

from storage.buckets
    as bucket


union all


-- =========================================================
-- 10. STORAGE POLICIES
-- =========================================================

select
    '10_storage_policies'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'policy_name',
                policy.policyname,

                'command',
                policy.cmd,

                'roles',
                policy.roles
            )
            order by
                policy.policyname
        ),
        '[]'::jsonb
    )
        as data

from pg_policies
    as policy

where policy.schemaname =
      'storage'

  and policy.tablename =
      'objects'


union all


-- =========================================================
-- 11. EXISTING JOURNAL RELATED TABLE COLUMNS
--
-- Berguna untuk melihat pola audit dari care_journals.
-- =========================================================

select
    '11_existing_journal_columns'
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
        table_name,
        column_name,
        data_type,
        is_nullable,
        ordinal_position

    from information_schema.columns

    where table_schema =
          'public'

      and (
          table_name ilike
              '%journal%'

          or table_name ilike
              '%jurnal%'
      )
)
    as candidate


union all


-- =========================================================
-- 12. SET_UPDATED_AT FUNCTION
-- =========================================================

select
    '12_updated_at_function'
        as section,

    jsonb_build_object(
        'exists',
        to_regprocedure(
            'public.set_updated_at()'
        ) is not null
    )
        as data


union all


-- =========================================================
-- 13. HAS_ROLE FUNCTION
-- =========================================================

select
    '13_has_role_function'
        as section,

    jsonb_build_object(
        'exists',
        to_regprocedure(
            'public.has_role(text)'
        ) is not null
    )
        as data


union all


-- =========================================================
-- 14. FINAL
-- =========================================================

select
    '14_audit_status'
        as section,

    jsonb_build_object(
        'status',
        'Audit Jurnal Kepala Ma''had selesai.',

        'audited_at',
        now()
    )
        as data


order by
    section;