-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 025-verify-account-provisioning.sql
-- PURPOSE:
-- - Memastikan fungsi provisioning tersedia
-- - Memastikan akun Admin pertama tersedia
-- - Menampilkan staff yang sudah atau belum mempunyai akun
-- - Tidak mengubah data
-- =========================================================

with expected_staff_ids as (
    select unnest(
        array[
            '22-P-001',
            '20-P-002',
            '20-P-003',
            '22-P-004',
            '22-P-005',
            '22-P-006',
            '24-P-007',
            '24-P-008',
            '25-P-009',
            '25-P-010',
            '25-P-011',
            '26-P-012'
        ]::text[]
    ) as legacy_staff_id
),

function_check as (
    select exists (
        select 1
        from pg_proc as procedure
        inner join pg_namespace as namespace
            on namespace.oid =
               procedure.pronamespace
        where namespace.nspname = 'public'
          and procedure.proname =
              'provision_staff_account'
    ) as function_exists
),

admin_check as (
    select
        auth_user.id as user_id,
        auth_user.email,
        profile.full_name,
        profile.is_active,

        exists (
            select 1
            from public.user_roles as user_role
            inner join public.roles as role
                on role.id = user_role.role_id
            where user_role.user_id = auth_user.id
              and role.code = 'admin'
              and role.is_active = true
        ) as has_admin_role

    from auth.users as auth_user

    inner join public.profiles as profile
        on profile.id = auth_user.id

    where lower(auth_user.email) =
          lower('admin@emahad.id')
),

staff_accounts as (
    select
        staff.legacy_staff_id,
        staff.full_name,
        staff.position,
        staff.is_active,

        staff.profile_id,

        auth_user.email,

        staff.profile_id is not null
            as account_linked,

        coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'code',
                        role.code,

                        'name',
                        role.name
                    )
                    order by role.code
                )
                from public.user_roles as user_role
                inner join public.roles as role
                    on role.id = user_role.role_id
                where user_role.user_id =
                      staff.profile_id
            ),
            '[]'::jsonb
        ) as roles

    from public.staff as staff

    inner join expected_staff_ids as expected
        on expected.legacy_staff_id =
           staff.legacy_staff_id

    left join auth.users as auth_user
        on auth_user.id = staff.profile_id
),

summary as (
    select
        count(*) as staff_count,

        count(*) filter (
            where account_linked = true
        ) as linked_account_count,

        count(*) filter (
            where account_linked = false
        ) as unlinked_account_count

    from staff_accounts
)

select jsonb_pretty(
    jsonb_build_object(
        'provisioning_ready',
        (
            select
                function_check.function_exists = true
                and exists (
                    select 1
                    from admin_check
                    where admin_check.is_active = true
                      and admin_check.has_admin_role = true
                )
                and summary.staff_count = 12
            from function_check
            cross join summary
        ),

        'function_exists',
        (
            select function_exists
            from function_check
        ),

        'admin_account',
        (
            select coalesce(
                jsonb_build_object(
                    'email',
                    email,

                    'full_name',
                    full_name,

                    'is_active',
                    is_active,

                    'has_admin_role',
                    has_admin_role
                ),
                '{}'::jsonb
            )
            from admin_check
        ),

        'summary',
        (
            select jsonb_build_object(
                'staff_count',
                staff_count,

                'linked_account_count',
                linked_account_count,

                'unlinked_account_count',
                unlinked_account_count
            )
            from summary
        ),

        'staff_accounts',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'legacy_staff_id',
                        legacy_staff_id,

                        'full_name',
                        full_name,

                        'position',
                        position,

                        'account_linked',
                        account_linked,

                        'email',
                        email,

                        'roles',
                        roles
                    )
                    order by legacy_staff_id
                ),
                '[]'::jsonb
            )
            from staff_accounts
        )
    )
) as verification_result;