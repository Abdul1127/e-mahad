-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 038-verify-admin-student-form-functions.sql
-- PURPOSE:
-- - Memastikan tiga fungsi tersedia
-- - Memastikan privilege benar
-- - Menampilkan opsi form
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_student_form_options()'
    ) is not null
        as options_function_exists,

    to_regprocedure(
        'public.create_admin_student(text,text,text,text,text,uuid,uuid,uuid)'
    ) is not null
        as create_function_exists,

    to_regprocedure(
        'public.update_admin_student(uuid,text,text,text,text,text,uuid,uuid,uuid)'
    ) is not null
        as update_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_student_form_options()',
        'execute'
    ) as authenticated_can_get_options,

    has_function_privilege(
        'anon',
        'public.get_admin_student_form_options()',
        'execute'
    ) as anon_can_get_options;

-- Hasil:
-- options_function_exists       = true
-- create_function_exists        = true
-- update_function_exists        = true
-- authenticated_can_get_options = true
-- anon_can_get_options          = false


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
    public.get_admin_student_form_options()
) as form_options;

rollback;