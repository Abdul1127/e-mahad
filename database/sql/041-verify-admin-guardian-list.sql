-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 041-verify-admin-guardian-list.sql
-- PURPOSE:
-- - Memastikan fungsi daftar wali tersedia
-- - Memastikan privilege benar
-- - Menguji response melalui akun Admin
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_guardian_list(text,boolean,text,integer,integer)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_guardian_list(text,boolean,text,integer,integer)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_admin_guardian_list(text,boolean,text,integer,integer)',
        'execute'
    ) as anon_can_execute;

-- Hasil:
-- function_exists           = true
-- authenticated_can_execute = true
-- anon_can_execute          = false


-- =========================================================
-- EMULATE ADMIN SESSION
-- =========================================================

begin;

select set_config(
    'request.jwt.claim.sub',
    (
        select auth_user.id::text

        from auth.users as auth_user

        where lower(auth_user.email) =
              lower('admin@emahad.id')

        limit 1
    ),
    true
);

select set_config(
    'request.jwt.claims',
    (
        select jsonb_build_object(
            'sub',
            auth_user.id,

            'role',
            'authenticated',

            'email',
            auth_user.email
        )::text

        from auth.users as auth_user

        where lower(auth_user.email) =
              lower('admin@emahad.id')

        limit 1
    ),
    true
);

select jsonb_pretty(
    public.get_admin_guardian_list(
        p_search => null,
        p_is_active => null,
        p_account_status => null,
        p_page => 1,
        p_page_size => 20
    )
) as guardian_list_payload;

rollback;