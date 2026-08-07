-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 046-audit-guardian-account-schema.sql
-- PURPOSE:
-- - Audit struktur akun untuk role Guardian
-- - Audit profiles, roles, user_roles, dan auth.users
-- - Audit constraint, index, RLS, trigger, dan function
-- - Menjadi dasar provisioning akun wali
--
-- READ-ONLY
-- TIDAK MENGUBAH DATA ATAU AKUN
-- =========================================================


with candidate_tables as (
    select
        table_schema,
        table_name,
        table_type

    from information_schema.tables

    where (
        table_schema = 'public'

        and (
            table_name ilike '%profile%'
            or table_name ilike '%role%'
            or table_name ilike '%user%'
            or table_name ilike '%guardian%'
            or table_name ilike '%account%'
        )
    )

    or (
        table_schema = 'auth'
        and table_name = 'users'
    )
),

public_account_columns as (
    select
        columns_data.table_name,
        columns_data.ordinal_position,
        columns_data.column_name,
        columns_data.data_type,
        columns_data.udt_name,
        columns_data.is_nullable,
        columns_data.column_default,
        columns_data.character_maximum_length

    from information_schema.columns
        as columns_data

    where columns_data.table_schema =
          'public'

      and columns_data.table_name in (
          'profiles',
          'roles',
          'user_roles',
          'guardians'
      )
),

auth_user_columns as (
    select
        columns_data.ordinal_position,
        columns_data.column_name,
        columns_data.data_type,
        columns_data.udt_name,
        columns_data.is_nullable,
        columns_data.column_default

    from information_schema.columns
        as columns_data

    where columns_data.table_schema =
          'auth'

      and columns_data.table_name =
          'users'
),

account_constraints as (
    select
        table_data.relname
            as table_name,

        constraint_data.conname
            as constraint_name,

        constraint_data.contype
            as constraint_type,

        pg_get_constraintdef(
            constraint_data.oid,
            true
        ) as definition

    from pg_constraint as constraint_data

    inner join pg_class as table_data
        on table_data.oid =
           constraint_data.conrelid

    inner join pg_namespace as namespace_data
        on namespace_data.oid =
           table_data.relnamespace

    where namespace_data.nspname =
          'public'

      and table_data.relname in (
          'profiles',
          'roles',
          'user_roles',
          'guardians'
      )
),

account_indexes as (
    select
        indexes_data.tablename
            as table_name,

        indexes_data.indexname
            as index_name,

        indexes_data.indexdef
            as definition

    from pg_indexes as indexes_data

    where indexes_data.schemaname =
          'public'

      and indexes_data.tablename in (
          'profiles',
          'roles',
          'user_roles',
          'guardians'
      )
),

rls_status as (
    select
        table_data.relname
            as table_name,

        table_data.relrowsecurity
            as rls_enabled,

        table_data.relforcerowsecurity
            as rls_forced

    from pg_class as table_data

    inner join pg_namespace as namespace_data
        on namespace_data.oid =
           table_data.relnamespace

    where namespace_data.nspname =
          'public'

      and table_data.relname in (
          'profiles',
          'roles',
          'user_roles',
          'guardians'
      )
),

rls_policies as (
    select
        policies_data.tablename
            as table_name,

        policies_data.policyname
            as policy_name,

        policies_data.permissive,
        policies_data.roles,
        policies_data.cmd
            as command,

        policies_data.qual
            as using_expression,

        policies_data.with_check
            as check_expression

    from pg_policies as policies_data

    where policies_data.schemaname =
          'public'

      and policies_data.tablename in (
          'profiles',
          'roles',
          'user_roles',
          'guardians'
      )
),

account_functions as (
    select
        procedure_data.proname
            as function_name,

        pg_get_function_identity_arguments(
            procedure_data.oid
        ) as arguments,

        pg_get_function_result(
            procedure_data.oid
        ) as result_type,

        procedure_data.prosecdef
            as security_definer,

        owner_data.rolname
            as function_owner

    from pg_proc as procedure_data

    inner join pg_namespace as namespace_data
        on namespace_data.oid =
           procedure_data.pronamespace

    inner join pg_roles as owner_data
        on owner_data.oid =
           procedure_data.proowner

    where namespace_data.nspname =
          'public'

      and (
          procedure_data.proname ilike
              '%account%'

          or procedure_data.proname ilike
              '%profile%'

          or procedure_data.proname ilike
              '%role%'

          or procedure_data.proname ilike
              '%user%'

          or procedure_data.proname ilike
              '%provision%'

          or procedure_data.proname ilike
              '%auth%'

          or procedure_data.proname ilike
              '%guardian%'
      )
),

account_triggers as (
    select
        trigger_namespace.nspname
            as table_schema,

        trigger_table.relname
            as table_name,

        trigger_data.tgname
            as trigger_name,

        pg_get_triggerdef(
            trigger_data.oid,
            true
        ) as trigger_definition,

        function_namespace.nspname
            as function_schema,

        function_data.proname
            as function_name

    from pg_trigger as trigger_data

    inner join pg_class as trigger_table
        on trigger_table.oid =
           trigger_data.tgrelid

    inner join pg_namespace
        as trigger_namespace
        on trigger_namespace.oid =
           trigger_table.relnamespace

    inner join pg_proc as function_data
        on function_data.oid =
           trigger_data.tgfoid

    inner join pg_namespace
        as function_namespace
        on function_namespace.oid =
           function_data.pronamespace

    where trigger_data.tgisinternal =
          false

      and (
          (
              trigger_namespace.nspname =
                  'public'

              and trigger_table.relname in (
                  'profiles',
                  'roles',
                  'user_roles',
                  'guardians'
              )
          )

          or (
              trigger_namespace.nspname =
                  'auth'

              and trigger_table.relname =
                  'users'
          )
      )
),

guardian_role_data as (
    select
        to_jsonb(role_data)
            as data

    from public.roles as role_data

    where role_data.code =
          'guardian'

    limit 1
),

data_counts as (
    select
        (
            select count(*)::integer
            from auth.users
        ) as total_auth_users,

        (
            select count(*)::integer
            from public.profiles
        ) as total_profiles,

        (
            select count(*)::integer
            from public.roles
        ) as total_roles,

        (
            select count(*)::integer
            from public.user_roles
        ) as total_user_roles,

        (
            select count(*)::integer
            from public.guardians
        ) as total_guardians,

        (
            select count(*)::integer

            from public.guardians
                as guardian

            where guardian.profile_id
                  is not null
        ) as guardians_with_profile,

        (
            select count(*)::integer

            from public.guardians
                as guardian

            where guardian.profile_id
                  is null
        ) as guardians_without_profile,

        (
            select count(*)::integer

            from public.guardians
                as guardian

            inner join public.profiles
                as profile
                on profile.id =
                   guardian.profile_id
        ) as valid_guardian_profile_links,

        (
            select count(*)::integer

            from public.guardians
                as guardian

            left join public.profiles
                as profile
                on profile.id =
                   guardian.profile_id

            where guardian.profile_id
                  is not null

              and profile.id is null
        ) as broken_guardian_profile_links
),

duplicate_guardian_emails as (
    select
        lower(
            btrim(
                guardian.email
            )
        ) as normalized_email,

        count(*)::integer
            as duplicate_count

    from public.guardians as guardian

    where guardian.email is not null
      and btrim(guardian.email) <> ''

    group by
        lower(
            btrim(
                guardian.email
            )
        )

    having count(*) > 1
),

guardian_auth_email_matches as (
    select
        guardian.id
            as guardian_id,

        guardian.full_name
            as guardian_name,

        guardian.email
            as guardian_email,

        auth_user.id
            as auth_user_id,

        auth_user.email::text
            as auth_email,

        guardian.profile_id,

        case
            when guardian.profile_id =
                 auth_user.id
                then true
            else false
        end as already_linked_to_matching_auth_user

    from public.guardians as guardian

    inner join auth.users as auth_user
        on lower(
            auth_user.email::text
        ) = lower(
            btrim(
                guardian.email
            )
        )

    where guardian.email is not null
      and btrim(guardian.email) <> ''
),

profile_auth_integrity as (
    select
        profile.id
            as profile_id,

        auth_user.id
            as auth_user_id,

        auth_user.id is not null
            as auth_user_exists

    from public.profiles as profile

    left join auth.users as auth_user
        on auth_user.id =
           profile.id
)

select jsonb_pretty(
    jsonb_build_object(
        'audit_status',
        'Audit akun wali selesai',

        'audited_at',
        now(),

        'candidate_tables',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'schema',
                        candidate.table_schema,

                        'table',
                        candidate.table_name,

                        'type',
                        candidate.table_type
                    )

                    order by
                        candidate.table_schema,
                        candidate.table_name
                ),
                '[]'::jsonb
            )

            from candidate_tables
                as candidate
        ),

        'public_account_columns',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        column_data.table_name,

                        'column_name',
                        column_data.column_name,

                        'data_type',
                        column_data.data_type,

                        'udt_name',
                        column_data.udt_name,

                        'is_nullable',
                        column_data.is_nullable,

                        'column_default',
                        column_data.column_default,

                        'maximum_length',
                        column_data.character_maximum_length
                    )

                    order by
                        column_data.table_name,
                        column_data.ordinal_position
                ),
                '[]'::jsonb
            )

            from public_account_columns
                as column_data
        ),

        'auth_user_columns',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'column_name',
                        column_data.column_name,

                        'data_type',
                        column_data.data_type,

                        'udt_name',
                        column_data.udt_name,

                        'is_nullable',
                        column_data.is_nullable,

                        'column_default',
                        column_data.column_default
                    )

                    order by
                        column_data.ordinal_position
                ),
                '[]'::jsonb
            )

            from auth_user_columns
                as column_data
        ),

        'constraints',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        constraint_data.table_name,

                        'constraint_name',
                        constraint_data.constraint_name,

                        'constraint_type',
                        constraint_data.constraint_type,

                        'definition',
                        constraint_data.definition
                    )

                    order by
                        constraint_data.table_name,
                        constraint_data.constraint_type,
                        constraint_data.constraint_name
                ),
                '[]'::jsonb
            )

            from account_constraints
                as constraint_data
        ),

        'indexes',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        index_data.table_name,

                        'index_name',
                        index_data.index_name,

                        'definition',
                        index_data.definition
                    )

                    order by
                        index_data.table_name,
                        index_data.index_name
                ),
                '[]'::jsonb
            )

            from account_indexes
                as index_data
        ),

        'security',
        jsonb_build_object(
            'rls_status',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'table_name',
                            security_data.table_name,

                            'rls_enabled',
                            security_data.rls_enabled,

                            'rls_forced',
                            security_data.rls_forced
                        )

                        order by
                            security_data.table_name
                    ),
                    '[]'::jsonb
                )

                from rls_status
                    as security_data
            ),

            'policies',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'table_name',
                            policy_data.table_name,

                            'policy_name',
                            policy_data.policy_name,

                            'permissive',
                            policy_data.permissive,

                            'roles',
                            policy_data.roles,

                            'command',
                            policy_data.command,

                            'using_expression',
                            policy_data.using_expression,

                            'check_expression',
                            policy_data.check_expression
                        )

                        order by
                            policy_data.table_name,
                            policy_data.policy_name
                    ),
                    '[]'::jsonb
                )

                from rls_policies
                    as policy_data
            )
        ),

        'functions',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'function_name',
                        function_data.function_name,

                        'arguments',
                        function_data.arguments,

                        'result_type',
                        function_data.result_type,

                        'security_definer',
                        function_data.security_definer,

                        'owner',
                        function_data.function_owner
                    )

                    order by
                        function_data.function_name,
                        function_data.arguments
                ),
                '[]'::jsonb
            )

            from account_functions
                as function_data
        ),

        'triggers',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_schema',
                        trigger_data.table_schema,

                        'table_name',
                        trigger_data.table_name,

                        'trigger_name',
                        trigger_data.trigger_name,

                        'trigger_definition',
                        trigger_data.trigger_definition,

                        'function_schema',
                        trigger_data.function_schema,

                        'function_name',
                        trigger_data.function_name
                    )

                    order by
                        trigger_data.table_schema,
                        trigger_data.table_name,
                        trigger_data.trigger_name
                ),
                '[]'::jsonb
            )

            from account_triggers
                as trigger_data
        ),

        'guardian_role',
        (
            select role_data.data

            from guardian_role_data
                as role_data
        ),

        'counts',
        (
            select jsonb_build_object(
                'total_auth_users',
                count_data.total_auth_users,

                'total_profiles',
                count_data.total_profiles,

                'total_roles',
                count_data.total_roles,

                'total_user_roles',
                count_data.total_user_roles,

                'total_guardians',
                count_data.total_guardians,

                'guardians_with_profile',
                count_data.guardians_with_profile,

                'guardians_without_profile',
                count_data.guardians_without_profile,

                'valid_guardian_profile_links',
                count_data.valid_guardian_profile_links,

                'broken_guardian_profile_links',
                count_data.broken_guardian_profile_links
            )

            from data_counts
                as count_data
        ),

        'duplicate_guardian_emails',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'normalized_email',
                        duplicate_data.normalized_email,

                        'duplicate_count',
                        duplicate_data.duplicate_count
                    )

                    order by
                        duplicate_data.normalized_email
                ),
                '[]'::jsonb
            )

            from duplicate_guardian_emails
                as duplicate_data
        ),

        'existing_auth_email_matches',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'guardian_id',
                        match_data.guardian_id,

                        'guardian_name',
                        match_data.guardian_name,

                        'guardian_email',
                        match_data.guardian_email,

                        'auth_user_id',
                        match_data.auth_user_id,

                        'auth_email',
                        match_data.auth_email,

                        'profile_id',
                        match_data.profile_id,

                        'already_linked',
                        match_data.already_linked_to_matching_auth_user
                    )

                    order by
                        lower(
                            match_data.guardian_name
                        ),
                        match_data.guardian_id
                ),
                '[]'::jsonb
            )

            from guardian_auth_email_matches
                as match_data
        ),

        'profile_auth_integrity',
        jsonb_build_object(
            'total_profiles',
            (
                select count(*)::integer

                from profile_auth_integrity
            ),

            'profiles_with_auth_user',
            (
                select count(*)::integer

                from profile_auth_integrity

                where auth_user_exists = true
            ),

            'profiles_without_auth_user',
            (
                select count(*)::integer

                from profile_auth_integrity

                where auth_user_exists = false
            )
        )
    )
) as guardian_account_schema_audit;