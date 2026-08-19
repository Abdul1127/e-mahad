-- ============================================================
-- E-MA'HAD
-- STAGE 191E-3A
--
-- AUDIT ADMIN STAFF ROLE PROVISIONING
--
-- READ ONLY
--
-- Tujuan:
-- Mengetahui kenapa role "admin" tampil sebagai pilihan
-- tetapi ditolak oleh provision_admin_staff_login_account().
-- ============================================================


with role_data as (

    select
        jsonb_build_object(
            'id',
            role.id,

            'code',
            role.code,

            'name',
            role.name,

            'is_active',
            role.is_active
        ) as data

    from public.roles
        as role

    where role.code =
          'admin'
),

function_data as (

    select
        jsonb_build_object(
            'schema',
            namespace.nspname,

            'function_name',
            procedure.proname,

            'identity_arguments',
            pg_get_function_identity_arguments(
                procedure.oid
            ),

            'security_definer',
            procedure.prosecdef,

            'definition',
            pg_get_functiondef(
                procedure.oid
            )
        ) as data

    from pg_proc
        as procedure

    inner join pg_namespace
        as namespace

        on namespace.oid =
           procedure.pronamespace

    where namespace.nspname =
          'public'

      and procedure.proname in (
          'get_admin_staff_role_options',
          'provision_admin_staff_login_account',
          'set_admin_staff_roles'
      )
)

select
    'ADMIN_ROLE'
        as section,

    coalesce(
        jsonb_pretty(
            jsonb_agg(
                role_data.data
            )
        ),
        '[]'
    )
        as result

from role_data


union all


select
    'STAFF_ROLE_FUNCTIONS'
        as section,

    coalesce(
        jsonb_pretty(
            jsonb_agg(
                function_data.data
                order by
                    function_data.data
                        ->> 'function_name'
            )
        ),
        '[]'
    )
        as result

from function_data;