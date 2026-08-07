-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 060-inspect-complete-staff-foundation.sql
--
-- PURPOSE:
-- - Menampilkan seluruh audit staff dalam satu hasil JSON
-- - Memeriksa tabel terkait staff
-- - Memeriksa kolom dan foreign key staff
-- - Memeriksa fungsi database terkait staff
-- - Memeriksa akun, login ID, dan role setiap staff
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
          table_name ilike '%staff%'
          or table_name ilike '%position%'
          or table_name ilike '%employee%'
      )
),

staff_columns as (
    select
        column_name,
        data_type,
        udt_name,
        is_nullable,
        column_default,
        ordinal_position

    from information_schema.columns

    where table_schema = 'public'
      and table_name = 'staff'
),

staff_constraints as (
    select
        table_constraint.constraint_name,
        table_constraint.constraint_type,

        key_column.column_name,

        foreign_column.table_schema
            as referenced_schema,

        foreign_column.table_name
            as referenced_table,

        foreign_column.column_name
            as referenced_column

    from information_schema.table_constraints
        as table_constraint

    left join information_schema.key_column_usage
        as key_column
        on key_column.constraint_name =
           table_constraint.constraint_name

       and key_column.table_schema =
           table_constraint.table_schema

       and key_column.table_name =
           table_constraint.table_name

    left join information_schema.constraint_column_usage
        as foreign_column
        on foreign_column.constraint_name =
           table_constraint.constraint_name

       and foreign_column.constraint_schema =
           table_constraint.table_schema

    where table_constraint.table_schema =
          'public'

      and table_constraint.table_name =
          'staff'
),

staff_functions as (
    select
        routine.proname
            as function_name,

        pg_get_function_identity_arguments(
            routine.oid
        ) as arguments,

        pg_get_function_result(
            routine.oid
        ) as result_type,

        case routine.provolatile
            when 'i' then 'immutable'
            when 's' then 'stable'
            when 'v' then 'volatile'
            else routine.provolatile::text
        end as volatility,

        routine.prosecdef
            as security_definer,

        pg_get_functiondef(
            routine.oid
        ) as definition

    from pg_proc as routine

    inner join pg_namespace as namespace
        on namespace.oid =
           routine.pronamespace

    where namespace.nspname =
          'public'

      and routine.prokind =
          'f'

      and routine.proname
          ilike '%staff%'
),

staff_accounts as (
    select
        staff.id
            as staff_id,

        staff.legacy_staff_id,

        staff.full_name,

        staff.profile_id,

        staff.is_active
            as staff_is_active,

        profile.login_id,

        auth_user.email::text
            as internal_auth_email,

        coalesce(
            profile.is_active,
            false
        ) as account_is_active,

        case
            when staff.legacy_staff_id
                 is null then null

            when btrim(
                staff.legacy_staff_id
            ) = '' then null

            else public.normalize_login_id(
                concat(
                    'STF-',
                    staff.legacy_staff_id
                )
            )
        end as expected_login_id,

        coalesce(
            (
                select jsonb_agg(
                    role.code
                    order by role.code
                )

                from public.user_roles
                    as user_role

                inner join public.roles
                    as role
                    on role.id =
                       user_role.role_id

                where user_role.user_id =
                      staff.profile_id
            ),
            '[]'::jsonb
        ) as roles

    from public.staff
        as staff

    left join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    left join auth.users
        as auth_user
        on auth_user.id =
           staff.profile_id
),

staff_summary as (
    select
        count(*)::integer
            as total_staff,

        count(*) filter (
            where staff_is_active = true
        )::integer
            as active_staff,

        count(*) filter (
            where profile_id is not null
        )::integer
            as staff_with_account,

        count(*) filter (
            where profile_id is null
        )::integer
            as staff_without_account,

        count(*) filter (
            where profile_id is not null
              and login_id is not null
        )::integer
            as staff_with_login_id,

        count(*) filter (
            where profile_id is not null
              and login_id is null
        )::integer
            as linked_without_login_id,

        count(*) filter (
            where legacy_staff_id is null
               or btrim(
                   legacy_staff_id
               ) = ''
        )::integer
            as staff_without_legacy_id

    from staff_accounts
)

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Fondasi akun staff berhasil diperiksa',

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

        'staff_columns',
        (
            select coalesce(
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
                        column_default
                    )

                    order by ordinal_position
                ),
                '[]'::jsonb
            )

            from staff_columns
        ),

        'staff_constraints',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'constraint_name',
                        constraint_name,

                        'constraint_type',
                        constraint_type,

                        'column_name',
                        column_name,

                        'referenced_schema',
                        referenced_schema,

                        'referenced_table',
                        referenced_table,

                        'referenced_column',
                        referenced_column
                    )

                    order by
                        constraint_type,
                        constraint_name,
                        column_name
                ),
                '[]'::jsonb
            )

            from staff_constraints
        ),

        'staff_functions',
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

                        'volatility',
                        volatility,

                        'security_definer',
                        security_definer,

                        'definition',
                        definition
                    )

                    order by
                        function_name,
                        arguments
                ),
                '[]'::jsonb
            )

            from staff_functions
        ),

        'staff_accounts',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'staff_id',
                        staff_id,

                        'legacy_staff_id',
                        legacy_staff_id,

                        'full_name',
                        full_name,

                        'staff_is_active',
                        staff_is_active,

                        'profile_id',
                        profile_id,

                        'login_id',
                        login_id,

                        'expected_login_id',
                        expected_login_id,

                        'internal_auth_email',
                        internal_auth_email,

                        'account_is_active',
                        account_is_active,

                        'roles',
                        roles
                    )

                    order by
                        legacy_staff_id
                            nulls last,

                        lower(
                            full_name
                        ),

                        staff_id
                ),
                '[]'::jsonb
            )

            from staff_accounts
        ),

        'summary',
        (
            select jsonb_build_object(
                'total_staff',
                total_staff,

                'active_staff',
                active_staff,

                'staff_with_account',
                staff_with_account,

                'staff_without_account',
                staff_without_account,

                'staff_with_login_id',
                staff_with_login_id,

                'linked_without_login_id',
                linked_without_login_id,

                'staff_without_legacy_id',
                staff_without_legacy_id
            )

            from staff_summary
        )
    )
) as complete_staff_foundation_inspection;