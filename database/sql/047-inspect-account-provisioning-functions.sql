-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 047-inspect-account-provisioning-functions.sql
-- PURPOSE:
-- - Melihat isi handle_new_auth_user
-- - Melihat isi provision_staff_account
-- - Melihat pola metadata akun yang sudah berhasil
-- - Menjadi dasar provisioning akun Guardian
--
-- READ-ONLY
-- TIDAK MENGUBAH AKUN ATAU DATA
-- =========================================================

with existing_accounts as (
    select
        auth_user.id,
        auth_user.email::text as email,

        auth_user.raw_user_meta_data,
        auth_user.raw_app_meta_data,

        profile.full_name,
        profile.phone,
        profile.is_active,

        coalesce(
            role_data.roles,
            '[]'::jsonb
        ) as roles

    from auth.users as auth_user

    inner join public.profiles as profile
        on profile.id =
           auth_user.id

    left join lateral (
        select
            coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'role_id',
                        role.id,

                        'code',
                        role.code,

                        'name',
                        role.name,

                        'assigned_by',
                        user_role.assigned_by
                    )

                    order by role.id
                ),
                '[]'::jsonb
            ) as roles

        from public.user_roles as user_role

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where user_role.user_id =
              auth_user.id
    ) as role_data
        on true
),

function_definitions as (
    select
        pg_get_functiondef(
            'public.handle_new_auth_user()'
                ::regprocedure
        ) as handle_new_auth_user_definition,

        pg_get_functiondef(
            'public.provision_staff_account(text,text,text[],text)'
                ::regprocedure
        ) as provision_staff_account_definition
),

trigger_definition as (
    select
        pg_get_triggerdef(
            trigger_data.oid,
            true
        ) as definition

    from pg_trigger as trigger_data

    inner join pg_class as table_data
        on table_data.oid =
           trigger_data.tgrelid

    inner join pg_namespace as namespace_data
        on namespace_data.oid =
           table_data.relnamespace

    where namespace_data.nspname = 'auth'
      and table_data.relname = 'users'
      and trigger_data.tgname =
          'on_auth_user_created'

    limit 1
)

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Mekanisme provisioning akun berhasil diperiksa',

        'inspected_at',
        now(),

        'trigger',
        (
            select definition
            from trigger_definition
        ),

        'handle_new_auth_user',
        (
            select
                handle_new_auth_user_definition

            from function_definitions
        ),

        'provision_staff_account',
        (
            select
                provision_staff_account_definition

            from function_definitions
        ),

        'existing_account_examples',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'id',
                        account.id,

                        'email',
                        account.email,

                        'raw_user_meta_data',
                        account.raw_user_meta_data,

                        'raw_app_meta_data',
                        account.raw_app_meta_data,

                        'profile',
                        jsonb_build_object(
                            'full_name',
                            account.full_name,

                            'phone',
                            account.phone,

                            'is_active',
                            account.is_active
                        ),

                        'roles',
                        account.roles
                    )

                    order by account.email
                ),
                '[]'::jsonb
            )

            from existing_accounts as account
        )
    )
) as account_provisioning_inspection;