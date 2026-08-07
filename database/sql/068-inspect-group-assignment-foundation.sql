-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 068-inspect-group-assignment-foundation.sql
--
-- PURPOSE:
-- - Memeriksa fondasi kelompok dan assignment
-- - Mencari tabel terkait asrama, tahfiz, kelompok,
--   assignment, staff, dan student
-- - Memeriksa fungsi database yang sudah tersedia
--
-- READ ONLY
-- TIDAK MENGUBAH DATA
-- =========================================================

with related_tables as (
    select
        table_name

    from information_schema.tables

    where table_schema = 'public'

      and (
          table_name ilike '%group%'
          or table_name ilike '%kelompok%'
          or table_name ilike '%assignment%'
          or table_name ilike '%tahfiz%'
          or table_name ilike '%tahfidz%'
          or table_name ilike '%asrama%'
          or table_name ilike '%dorm%'
          or table_name ilike '%staff%'
          or table_name ilike '%student%'
      )
),

related_columns as (
    select
        table_name,
        column_name,
        data_type,
        udt_name,
        is_nullable,
        column_default,
        ordinal_position

    from information_schema.columns

    where table_schema = 'public'

      and table_name in (
          select table_name
          from related_tables
      )
),

related_constraints as (
    select
        tc.table_name,
        tc.constraint_name,
        tc.constraint_type,

        kcu.column_name,

        ccu.table_name
            as referenced_table,

        ccu.column_name
            as referenced_column

    from information_schema.table_constraints
        as tc

    left join information_schema.key_column_usage
        as kcu
        on kcu.constraint_name =
           tc.constraint_name

       and kcu.table_schema =
           tc.table_schema

       and kcu.table_name =
           tc.table_name

    left join information_schema.constraint_column_usage
        as ccu
        on ccu.constraint_name =
           tc.constraint_name

       and ccu.constraint_schema =
           tc.table_schema

    where tc.table_schema = 'public'

      and tc.table_name in (
          select table_name
          from related_tables
      )
),

related_functions as (
    select
        routine.proname
            as function_name,

        pg_get_function_identity_arguments(
            routine.oid
        ) as arguments,

        pg_get_function_result(
            routine.oid
        ) as result_type,

        routine.prosecdef
            as security_definer

    from pg_proc as routine

    inner join pg_namespace as namespace
        on namespace.oid =
           routine.pronamespace

    where namespace.nspname = 'public'

      and routine.prokind = 'f'

      and (
          routine.proname ilike '%group%'
          or routine.proname ilike '%kelompok%'
          or routine.proname ilike '%assignment%'
          or routine.proname ilike '%tahfiz%'
          or routine.proname ilike '%tahfidz%'
          or routine.proname ilike '%asrama%'
          or routine.proname ilike '%dorm%'
      )
)

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Fondasi kelompok dan assignment berhasil diperiksa',

        'inspected_at',
        now(),

        'related_tables',
        (
            select coalesce(
                jsonb_agg(
                    table_name
                    order by table_name
                ),
                '[]'::jsonb
            )

            from related_tables
        ),

        'related_columns',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        table_name,

                        'column_name',
                        column_name,

                        'data_type',
                        data_type,

                        'udt_name',
                        udt_name,

                        'is_nullable',
                        is_nullable,

                        'column_default',
                        column_default
                    )

                    order by
                        table_name,
                        ordinal_position
                ),
                '[]'::jsonb
            )

            from related_columns
        ),

        'related_constraints',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        table_name,

                        'constraint_name',
                        constraint_name,

                        'constraint_type',
                        constraint_type,

                        'column_name',
                        column_name,

                        'referenced_table',
                        referenced_table,

                        'referenced_column',
                        referenced_column
                    )

                    order by
                        table_name,
                        constraint_type,
                        constraint_name,
                        column_name
                ),
                '[]'::jsonb
            )

            from related_constraints
        ),

        'related_functions',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'function_name',
                        function_name,

                        'arguments',
                        arguments,

                        'result_type',
                        result_type,

                        'security_definer',
                        security_definer
                    )

                    order by
                        function_name,
                        arguments
                ),
                '[]'::jsonb
            )

            from related_functions
        )
    )
) as group_assignment_foundation_inspection;