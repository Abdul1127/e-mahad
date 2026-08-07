-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 064-verify-admin-staff-list-detail-functions.sql
--
-- PURPOSE:
-- - Memastikan fungsi daftar dan detail tersedia
-- - Memastikan privilege benar
-- - Memastikan akun staf existing terbaca
-- - Memastikan pencarian berdasarkan ID Pengguna bekerja
-- - Memastikan filter role bekerja
-- - Memastikan email Auth internal tidak dikembalikan
-- =========================================================


-- =========================================================
-- 1. FUNCTION DAN PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_staff_list(text,boolean,text,text,integer,integer)'
    ) is not null
        as list_function_exists,

    to_regprocedure(
        'public.get_admin_staff_detail(uuid)'
    ) is not null
        as detail_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_staff_list(text,boolean,text,text,integer,integer)',
        'execute'
    ) as authenticated_can_get_list,

    has_function_privilege(
        'anon',
        'public.get_admin_staff_list(text,boolean,text,text,integer,integer)',
        'execute'
    ) as anon_can_get_list,

    has_function_privilege(
        'authenticated',
        'public.get_admin_staff_detail(uuid)',
        'execute'
    ) as authenticated_can_get_detail,

    has_function_privilege(
        'anon',
        'public.get_admin_staff_detail(uuid)',
        'execute'
    ) as anon_can_get_detail;


begin;


-- =========================================================
-- 2. EMULASI SESSION ADMIN
-- =========================================================

select set_config(
    'request.jwt.claim.sub',
    (
        select profile.id::text

        from public.profiles as profile

        inner join public.user_roles as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where role.code = 'admin'
          and profile.is_active = true

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

        from public.profiles as profile

        inner join auth.users as auth_user
            on auth_user.id =
               profile.id

        inner join public.user_roles as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where role.code = 'admin'
          and profile.is_active = true

        order by
            profile.created_at,
            profile.id

        limit 1
    ),
    true
);


-- =========================================================
-- 3. ASSERTION
-- =========================================================

do $verification$
declare
    v_staff_id uuid;
    v_login_id text;
    v_role_code text;

    v_detail jsonb;
    v_list jsonb;
    v_search_result jsonb;
    v_role_result jsonb;
begin
    select
        staff.id,
        profile.login_id,
        role.code

    into
        v_staff_id,
        v_login_id,
        v_role_code

    from public.staff as staff

    inner join public.profiles as profile
        on profile.id =
           staff.profile_id

    inner join public.user_roles as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles as role
        on role.id =
           user_role.role_id

    where profile.login_id is not null
      and profile.is_active = true
      and role.is_active = true
      and role.code not in (
          'admin',
          'guardian'
      )

    order by
        staff.created_at,
        staff.id,
        role.code

    limit 1;

    if v_staff_id is null then
        raise exception
            'Pengujian gagal: akun staf existing tidak ditemukan.';
    end if;

    -- =====================================================
    -- A. DETAIL
    -- =====================================================

    v_detail :=
        public.get_admin_staff_detail(
            v_staff_id
        );

    if v_detail is null then
        raise exception
            'Pengujian gagal: detail staf kosong.';
    end if;

    if (
        v_detail
        -> 'account'
        ->> 'login_id'
    ) <> v_login_id then
        raise exception
            'Pengujian gagal: ID Pengguna detail tidak sesuai.';
    end if;

    if jsonb_array_length(
        v_detail -> 'roles'
    ) = 0 then
        raise exception
            'Pengujian gagal: role detail staf kosong.';
    end if;

    if v_detail::text ilike
       '%@login.emahad.id%' then
        raise exception
            'Pengujian gagal: email Auth internal tampil pada detail staf.';
    end if;

    -- =====================================================
    -- B. DAFTAR
    -- =====================================================

    v_list :=
        public.get_admin_staff_list(
            null,
            null,
            null,
            null,
            1,
            20
        );

    if jsonb_array_length(
        v_list -> 'items'
    ) = 0 then
        raise exception
            'Pengujian gagal: daftar staf kosong.';
    end if;

    if not (
        v_list
        -> 'items'
        -> 0
        ? 'account_login_id'
    ) then
        raise exception
            'Pengujian gagal: daftar belum memiliki account_login_id.';
    end if;

    if not (
        v_list
        -> 'items'
        -> 0
        ? 'roles'
    ) then
        raise exception
            'Pengujian gagal: daftar belum memiliki roles.';
    end if;

    if v_list::text ilike
       '%@login.emahad.id%' then
        raise exception
            'Pengujian gagal: email Auth internal tampil pada daftar staf.';
    end if;

    -- =====================================================
    -- C. PENCARIAN ID PENGGUNA
    -- =====================================================

    v_search_result :=
        public.get_admin_staff_list(
            v_login_id,
            null,
            'linked',
            null,
            1,
            20
        );

    if jsonb_array_length(
        v_search_result -> 'items'
    ) = 0 then
        raise exception
            'Pengujian gagal: ID Pengguna tidak dapat dicari.';
    end if;

    if not exists (
        select 1

        from jsonb_array_elements(
            v_search_result -> 'items'
        ) as item

        where item
              ->> 'account_login_id' =
              v_login_id
    ) then
        raise exception
            'Pengujian gagal: hasil pencarian ID Pengguna tidak sesuai.';
    end if;

    -- =====================================================
    -- D. FILTER ROLE
    -- =====================================================

    v_role_result :=
        public.get_admin_staff_list(
            null,
            null,
            'linked',
            v_role_code,
            1,
            20
        );

    if jsonb_array_length(
        v_role_result -> 'items'
    ) = 0 then
        raise exception
            'Pengujian gagal: filter role staf kosong.';
    end if;

    if not exists (
        select 1

        from jsonb_array_elements(
            v_role_result -> 'items'
        ) as item

        cross join lateral
            jsonb_array_elements(
                item -> 'roles'
            ) as item_role

        where item
              ->> 'id' =
              v_staff_id::text

          and item_role
              ->> 'code' =
              v_role_code
    ) then
        raise exception
            'Pengujian gagal: hasil filter role tidak sesuai.';
    end if;

    raise notice
        'STAFF ID: %',
        v_staff_id;

    raise notice
        'LOGIN ID: %',
        v_login_id;

    raise notice
        'ROLE CODE: %',
        v_role_code;

    raise notice
        'DETAIL ACCOUNT: %',
        v_detail -> 'account';

    raise notice
        'DETAIL ROLES: %',
        v_detail -> 'roles';

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


rollback;


-- =========================================================
-- 4. HASIL AKHIR
-- =========================================================

select
    'Daftar, detail, pencarian, dan filter role staf berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;