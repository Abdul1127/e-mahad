-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 032-verify-admin-dashboard-summary.sql
-- PURPOSE:
-- - Memastikan fungsi Dashboard Admin tersedia
-- - Memastikan hak execute sudah sesuai
-- - Menguji payload menggunakan akun Admin
-- =========================================================

-- =========================================================
-- 1. CHECK FUNCTION AND PRIVILEGES
-- =========================================================

select
    exists (
        select 1
        from pg_proc as procedure

        inner join pg_namespace as namespace
            on namespace.oid =
               procedure.pronamespace

        where namespace.nspname = 'public'
          and procedure.proname =
              'get_admin_dashboard_summary'
          and procedure.pronargs = 0
    ) as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_dashboard_summary()',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_admin_dashboard_summary()',
        'execute'
    ) as anon_can_execute;

-- Hasil:
-- function_exists = true
-- authenticated_can_execute = true
-- anon_can_execute = false

-- =========================================================
-- 2. EMULATE ADMIN AUTH CONTEXT
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
    public.get_admin_dashboard_summary()
) as dashboard_payload;

rollback;