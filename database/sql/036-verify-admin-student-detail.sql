-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 036-verify-admin-student-detail.sql
-- PURPOSE:
-- - Memastikan fungsi detail santri tersedia
-- - Memastikan privilege benar
-- - Menguji response dengan akun Admin
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
              'get_admin_student_detail'
          and procedure.pronargs = 1
    ) as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_student_detail(uuid)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_admin_student_detail(uuid)',
        'execute'
    ) as anon_can_execute;

-- Hasil:
-- function_exists = true
-- authenticated_can_execute = true
-- anon_can_execute = false

-- =========================================================
-- 2. EMULATE ADMIN SESSION
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
    public.get_admin_student_detail(
        (
            select student.id
            from public.students as student
            where student.legacy_student_id = '247211'
            limit 1
        )
    )
) as student_detail_payload;

rollback;