-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 028-verify-auth-access-context.sql
-- PURPOSE:
-- - Memastikan fungsi konteks akses tersedia
-- - Memastikan authenticated boleh menjalankan
-- - Memastikan anon tidak boleh menjalankan
-- =========================================================

select
    exists (
        select 1
        from pg_proc as procedure

        inner join pg_namespace as namespace
            on namespace.oid = procedure.pronamespace

        where namespace.nspname = 'public'
          and procedure.proname = 'get_my_access_context'
          and procedure.pronargs = 0
    ) as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_my_access_context()',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_my_access_context()',
        'execute'
    ) as anon_can_execute;
    