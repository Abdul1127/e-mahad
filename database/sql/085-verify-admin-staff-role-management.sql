-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 085-verify-admin-staff-role-management.sql
--
-- PURPOSE:
-- - Pastikan Admin muncul dalam role options
-- - Pastikan Guardian tidak muncul
-- - Test pemberian role Admin kepada staf Admin
-- - Seluruh perubahan test di-ROLLBACK
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_staff_role_options()'
    ) is not null
        as role_options_function_exists,

    to_regprocedure(
        'public.set_admin_staff_roles(uuid,text[])'
    ) is not null
        as set_roles_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_staff_role_options()',
        'execute'
    ) as authenticated_can_get_options,

    has_function_privilege(
        'authenticated',
        'public.set_admin_staff_roles(uuid,text[])',
        'execute'
    ) as authenticated_can_set_roles,

    has_function_privilege(
        'anon',
        'public.get_admin_staff_role_options()',
        'execute'
    ) as anon_can_get_options,

    has_function_privilege(
        'anon',
        'public.set_admin_staff_roles(uuid,text[])',
        'execute'
    ) as anon_can_set_roles;


begin;


-- =========================================================
-- 2. EMULASI ADMIN
-- =========================================================

select set_config(
    'request.jwt.claim.sub',
    (
        select profile.id::text

        from public.profiles
            as profile

        inner join public.user_roles
            as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where role.code =
              'admin'

          and profile.is_active =
              true

        order by
            profile.created_at,
            profile.id

        limit 1
    ),
    true
);


select set_config(
    'request.jwt.claims',
    (
        select jsonb_build_object(
            'sub',
            profile.id,

            'role',
            'authenticated',

            'email',
            auth_user.email
        )::text

        from public.profiles
            as profile

        inner join auth.users
            as auth_user
            on auth_user.id =
               profile.id

        inner join public.user_roles
            as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where role.code =
              'admin'

          and profile.is_active =
              true

        order by
            profile.created_at,
            profile.id

        limit 1
    ),
    true
);


-- =========================================================
-- 3. VERIFICATION
-- =========================================================

do $verification$
declare
    v_options jsonb;

    v_staff_id uuid;

    v_profile_id uuid;

    v_result jsonb;
begin

    -- =====================================================
    -- ROLE OPTIONS
    -- =====================================================

    v_options :=
        public.get_admin_staff_role_options();


    if not exists (
        select 1

        from jsonb_array_elements(
            v_options
        ) as option_data(item)

        where option_data.item
              ->> 'code' =
              'admin'
    ) then
        raise exception
            'Role Admin belum muncul pada role options.';
    end if;


    if exists (
        select 1

        from jsonb_array_elements(
            v_options
        ) as option_data(item)

        where option_data.item
              ->> 'code' =
              'guardian'
    ) then
        raise exception
            'Role Guardian tidak boleh muncul pada role staf.';
    end if;


    raise notice
        'ADMIN ROLE OPTION SUCCESS';


    -- =====================================================
    -- CARI STAF DENGAN POSITION ADMIN
    -- =====================================================

    select
        staff.id,
        staff.profile_id

    into
        v_staff_id,
        v_profile_id

    from public.staff
        as staff

    where staff.is_active = true

      and staff.profile_id is not null

      and lower(
          btrim(
              coalesce(
                  staff.position,
                  ''
              )
          )
      ) = 'admin'

    order by
        staff.created_at,
        staff.id

    limit 1;


    if v_staff_id is null
       or v_profile_id is null
    then
        raise exception
            'Staf Admin untuk pengujian tidak ditemukan.';
    end if;


    -- =====================================================
    -- SET ROLE ADMIN SAJA
    --
    -- Ini hanya test karena transaction akan rollback.
    -- =====================================================

    v_result :=
        public.set_admin_staff_roles(
            v_staff_id,
            array[
                'admin'
            ]::text[]
        );


    if not exists (
        select 1

        from public.user_roles
            as user_role

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where user_role.user_id =
              v_profile_id

          and role.code =
              'admin'
    ) then
        raise exception
            'Role Admin gagal diberikan kepada staf Admin.';
    end if;


    if exists (
        select 1

        from public.user_roles
            as user_role

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where user_role.user_id =
              v_profile_id

          and role.code =
              'pengasuh'
    ) then
        raise exception
            'Role Pengasuh masih tersisa setelah diganti menjadi Admin.';
    end if;


    if not (
        v_result
        -> 'roles'
        @> '[{"code":"admin"}]'::jsonb
    ) then
        raise exception
            'Response fungsi tidak memuat role Admin.';
    end if;


    raise notice
        'SET ADMIN STAFF ROLE SUCCESS';


    -- =====================================================
    -- GUARDIAN MUST FAIL
    -- =====================================================

    begin

        perform
            public.set_admin_staff_roles(
                v_staff_id,
                array[
                    'guardian'
                ]::text[]
            );


        raise exception
            'Role Guardian dapat diberikan kepada staf.';

    exception
        when others then

            if sqlerrm not ilike
               '%Role staf tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'GUARDIAN ROLE PROTECTION SUCCESS';


    raise notice
        'ADMIN STAFF ROLE MANAGEMENT VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Role Admin pada akun staf berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;