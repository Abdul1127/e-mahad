-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 034-verify-admin-student-list.sql
-- PURPOSE:
-- - Memastikan fungsi daftar santri tersedia
-- - Memastikan privilege benar
-- - Menguji response menggunakan akun Admin
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
              'get_admin_student_list'
          and procedure.pronargs = 7
    ) as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_student_list(text,integer,text,uuid,uuid,integer,integer)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_admin_student_list(text,integer,text,uuid,uuid,integer,integer)',
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
    public.get_admin_student_list(
        p_search => null,
        p_grade_level => null,
        p_gender => null,
        p_care_group_id => null,
        p_tahfiz_group_id => null,
        p_page => 1,
        p_page_size => 20
    )
) as student_list_payload;

rollback;