-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 058-verify-guardian-account-display-functions.sql
--
-- PURPOSE:
-- - Memastikan detail wali mengembalikan login_id
-- - Memastikan daftar wali mengembalikan account_login_id
-- - Memastikan pencarian login ID bekerja
-- - Seluruh proses hanya membaca data
-- =========================================================


begin;


-- =========================================================
-- 1. EMULASI SESSION ADMIN
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
-- 2. ASSERTION
-- =========================================================

do $verification$
declare
    v_guardian_id uuid;
    v_login_id text;

    v_detail jsonb;
    v_list jsonb;
    v_search_result jsonb;
begin
    select
        guardian.id,
        profile.login_id

    into
        v_guardian_id,
        v_login_id

    from public.guardians
        as guardian

    inner join public.profiles
        as profile
        on profile.id =
           guardian.profile_id

    where profile.login_id
          is not null

    order by
        guardian.created_at,
        guardian.id

    limit 1;

    if v_guardian_id is null then
        raise exception
            'Pengujian gagal: akun wali dengan login ID tidak ditemukan.';
    end if;

    v_detail :=
        public.get_admin_guardian_detail(
            v_guardian_id
        );

    if not (
        v_detail
        -> 'account'
        ? 'login_id'
    ) then
        raise exception
            'Pengujian gagal: detail wali belum memiliki login_id.';
    end if;

    if (
        v_detail
        -> 'account'
        ->> 'login_id'
    ) <> v_login_id then
        raise exception
            'Pengujian gagal: login_id detail tidak sesuai.';
    end if;

    v_list :=
        public.get_admin_guardian_list(
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
            'Pengujian gagal: daftar wali kosong.';
    end if;

    if not (
        v_list
        -> 'items'
        -> 0
        ? 'account_login_id'
    ) then
        raise exception
            'Pengujian gagal: item daftar belum memiliki account_login_id.';
    end if;

    v_search_result :=
        public.get_admin_guardian_list(
            v_login_id,
            null,
            'linked',
            1,
            20
        );

    if jsonb_array_length(
        v_search_result -> 'items'
    ) = 0 then
        raise exception
            'Pengujian gagal: login ID tidak dapat digunakan untuk pencarian.';
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
            'Pengujian gagal: hasil pencarian login ID tidak sesuai.';
    end if;

    raise notice
        'GUARDIAN ID: %',
        v_guardian_id;

    raise notice
        'LOGIN ID: %',
        v_login_id;

    raise notice
        'DETAIL ACCOUNT: %',
        v_detail -> 'account';

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


rollback;


select
    'Detail, daftar, dan pencarian login ID wali berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;