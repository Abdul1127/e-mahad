-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 039-audit-guardian-schema.sql
-- PURPOSE:
-- - Audit ringkas tabel guardians
-- - Audit ringkas tabel guardian_students
-- - Menghasilkan satu payload JSON
--
-- READ-ONLY: tidak mengubah data
-- =========================================================

with guardian_columns as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'column_name',
                    column_name,

                    'data_type',
                    data_type,

                    'udt_name',
                    udt_name,

                    'is_nullable',
                    is_nullable,

                    'column_default',
                    column_default,

                    'maximum_length',
                    character_maximum_length
                )
                order by ordinal_position
            ),
            '[]'::jsonb
        ) as data

    from information_schema.columns

    where table_schema = 'public'
      and table_name = 'guardians'
),

guardian_student_columns as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'column_name',
                    column_name,

                    'data_type',
                    data_type,

                    'udt_name',
                    udt_name,

                    'is_nullable',
                    is_nullable,

                    'column_default',
                    column_default,

                    'maximum_length',
                    character_maximum_length
                )
                order by ordinal_position
            ),
            '[]'::jsonb
        ) as data

    from information_schema.columns

    where table_schema = 'public'
      and table_name = 'guardian_students'
),

guardian_constraints as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'constraint_name',
                    constraint_data.conname,

                    'constraint_type',
                    constraint_data.contype,

                    'definition',
                    pg_get_constraintdef(
                        constraint_data.oid,
                        true
                    )
                )
                order by
                    constraint_data.contype,
                    constraint_data.conname
            ),
            '[]'::jsonb
        ) as data

    from pg_constraint as constraint_data

    inner join pg_class as table_data
        on table_data.oid =
           constraint_data.conrelid

    inner join pg_namespace as namespace_data
        on namespace_data.oid =
           table_data.relnamespace

    where namespace_data.nspname = 'public'
      and table_data.relname = 'guardians'
),

guardian_student_constraints as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'constraint_name',
                    constraint_data.conname,

                    'constraint_type',
                    constraint_data.contype,

                    'definition',
                    pg_get_constraintdef(
                        constraint_data.oid,
                        true
                    )
                )
                order by
                    constraint_data.contype,
                    constraint_data.conname
            ),
            '[]'::jsonb
        ) as data

    from pg_constraint as constraint_data

    inner join pg_class as table_data
        on table_data.oid =
           constraint_data.conrelid

    inner join pg_namespace as namespace_data
        on namespace_data.oid =
           table_data.relnamespace

    where namespace_data.nspname = 'public'
      and table_data.relname =
          'guardian_students'
),

guardian_indexes as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'index_name',
                    indexname,

                    'definition',
                    indexdef
                )
                order by indexname
            ),
            '[]'::jsonb
        ) as data

    from pg_indexes

    where schemaname = 'public'
      and tablename = 'guardians'
),

guardian_student_indexes as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'index_name',
                    indexname,

                    'definition',
                    indexdef
                )
                order by indexname
            ),
            '[]'::jsonb
        ) as data

    from pg_indexes

    where schemaname = 'public'
      and tablename =
          'guardian_students'
),

rls_status as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'table_name',
                    table_data.relname,

                    'rls_enabled',
                    table_data.relrowsecurity,

                    'rls_forced',
                    table_data.relforcerowsecurity
                )
                order by table_data.relname
            ),
            '[]'::jsonb
        ) as data

    from pg_class as table_data

    inner join pg_namespace as namespace_data
        on namespace_data.oid =
           table_data.relnamespace

    where namespace_data.nspname = 'public'

      and table_data.relname in (
          'guardians',
          'guardian_students'
      )
),

rls_policies as (
    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'table_name',
                    tablename,

                    'policy_name',
                    policyname,

                    'roles',
                    roles,

                    'command',
                    cmd,

                    'using_expression',
                    qual,

                    'check_expression',
                    with_check
                )
                order by
                    tablename,
                    policyname
            ),
            '[]'::jsonb
        ) as data

    from pg_policies

    where schemaname = 'public'

      and tablename in (
          'guardians',
          'guardian_students'
      )
),

data_counts as (
    select
        (
            select count(*)::integer
            from public.guardians
        ) as total_guardians,

        (
            select count(*)::integer
            from public.guardians
            where is_active = true
        ) as active_guardians,

        (
            select count(*)::integer
            from public.guardians
            where profile_id is not null
        ) as guardians_with_accounts,

        (
            select count(*)::integer
            from public.guardian_students
        ) as total_guardian_student_links,

        (
            select count(*)::integer

            from public.students as student

            where student.status =
                  'active'::public.student_status

              and student.deleted_at is null

              and not exists (
                  select 1

                  from public.guardian_students
                      as guardian_student

                  where guardian_student.student_id =
                        student.id
              )
        ) as active_students_without_guardians
)

select jsonb_pretty(
    jsonb_build_object(
        'audit_status',
        'Audit struktur wali selesai',

        'audited_at',
        now(),

        'tables',
        jsonb_build_object(
            'guardians_exists',
            to_regclass(
                'public.guardians'
            ) is not null,

            'guardian_students_exists',
            to_regclass(
                'public.guardian_students'
            ) is not null
        ),

        'guardians',
        jsonb_build_object(
            'columns',
            (
                select data
                from guardian_columns
            ),

            'constraints',
            (
                select data
                from guardian_constraints
            ),

            'indexes',
            (
                select data
                from guardian_indexes
            )
        ),

        'guardian_students',
        jsonb_build_object(
            'columns',
            (
                select data
                from guardian_student_columns
            ),

            'constraints',
            (
                select data
                from guardian_student_constraints
            ),

            'indexes',
            (
                select data
                from guardian_student_indexes
            )
        ),

        'security',
        jsonb_build_object(
            'rls_status',
            (
                select data
                from rls_status
            ),

            'policies',
            (
                select data
                from rls_policies
            )
        ),

        'counts',
        (
            select jsonb_build_object(
                'total_guardians',
                total_guardians,

                'active_guardians',
                active_guardians,

                'guardians_with_accounts',
                guardians_with_accounts,

                'total_guardian_student_links',
                total_guardian_student_links,

                'active_students_without_guardians',
                active_students_without_guardians
            )

            from data_counts
        )
    )
) as guardian_schema_audit;