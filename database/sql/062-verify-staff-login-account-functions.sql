-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 062-verify-staff-login-account-functions.sql
--
-- PURPOSE:
-- - Memastikan fungsi baru tersedia
-- - Memastikan privilege benar
-- - Menguji akun Muh Lubis secara idempotent
-- - Memastikan login ID salah ditolak
-- - Memastikan role admin ditolak untuk akun staf
-- - Seluruh perubahan di-rollback
-- =========================================================


-- =========================================================
-- 1. FUNCTION DAN PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_staff_login_identity(uuid)'
    ) is not null
        as identity_function_exists,

    to_regprocedure(
        'public.get_admin_staff_role_options()'
    ) is not null
        as role_options_function_exists,

    to_regprocedure(
        'public.provision_admin_staff_login_account(uuid,uuid,text,text[])'
    ) is not null
        as provisioning_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_staff_login_identity(uuid)',
        'execute'
    ) as authenticated_can_get_identity,

    has_function_privilege(
        'anon',
        'public.get_admin_staff_login_identity(uuid)',
        'execute'
    ) as anon_can_get_identity,

    has_function_privilege(
        'authenticated',
        'public.get_admin_staff_role_options()',
        'execute'
    ) as authenticated_can_get_roles,

    has_function_privilege(
        'anon',
        'public.get_admin_staff_role_options()',
        'execute'
    ) as anon_can_get_roles,

    has_function_privilege(
        'authenticated',
        'public.provision_admin_staff_login_account(uuid,uuid,text,text[])',
        'execute'
    ) as authenticated_can_provision,

    has_function_privilege(
        'anon',
        'public.provision_admin_staff_login_account(uuid,uuid,text,text[])',
        'execute'
    ) as anon_can_provision,

    has_function_privilege(
        'authenticated',
        'public.provision_staff_account(text,text,text[],text)',
        'execute'
    ) as authenticated_can_use_old_function;


-- =========================================================
-- 2. TRANSAKSI VERIFIKASI
-- =========================================================

begin;


-- =========================================================
-- 3. EMULASI SESSION ADMIN
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
-- 4. ASSERTION
-- =========================================================

do $verification$
declare
    v_staff_id uuid;
    v_profile_id uuid;

    v_login_id text;
    v_auth_email text;

    v_role_codes text[];

    v_identity_response jsonb;
    v_role_options jsonb;
    v_provision_response jsonb;

    v_invalid_login_blocked boolean :=
        false;

    v_admin_role_blocked boolean :=
        false;
begin
    -- =====================================================
    -- A. CARI AKUN STAF EXISTING
    -- =====================================================

    select
        staff.id,
        staff.profile_id,
        profile.login_id,
        auth_user.email::text,

        array_agg(
            role.code
            order by role.code
        )

    into
        v_staff_id,
        v_profile_id,
        v_login_id,
        v_auth_email,
        v_role_codes

    from public.staff as staff

    inner join public.profiles as profile
        on profile.id =
           staff.profile_id

    inner join auth.users as auth_user
        on auth_user.id =
           profile.id

    inner join public.user_roles as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles as role
        on role.id =
           user_role.role_id

    where profile.login_id is not null
      and auth_user.deleted_at is null

    group by
        staff.id,
        staff.profile_id,
        profile.login_id,
        auth_user.email

    order by
        staff.created_at,
        staff.id

    limit 1;

    if v_staff_id is null then
        raise exception
            'Pengujian gagal: akun staf existing tidak ditemukan.';
    end if;

    if coalesce(
        cardinality(v_role_codes),
        0
    ) = 0 then
        raise exception
            'Pengujian gagal: akun staf tidak mempunyai role.';
    end if;

    -- =====================================================
    -- B. IDENTITAS EXISTING
    -- =====================================================

    v_identity_response :=
        public.get_admin_staff_login_identity(
            v_staff_id
        );

    if (
        v_identity_response
        ->> 'status'
    ) <> 'existing' then
        raise exception
            'Pengujian gagal: status identitas bukan existing.';
    end if;

    if (
        v_identity_response
        ->> 'login_id'
    ) <> v_login_id then
        raise exception
            'Pengujian gagal: ID Pengguna response tidak sesuai.';
    end if;

    -- =====================================================
    -- C. PILIHAN ROLE
    -- =====================================================

    v_role_options :=
        public.get_admin_staff_role_options();

    if jsonb_array_length(
        v_role_options
    ) = 0 then
        raise exception
            'Pengujian gagal: pilihan role staf kosong.';
    end if;

    if exists (
        select 1

        from jsonb_array_elements(
            v_role_options
        ) as role_option

        where role_option ->> 'code'
              in ('admin', 'guardian')
    ) then
        raise exception
            'Pengujian gagal: role admin atau guardian muncul pada pilihan staf.';
    end if;

    -- =====================================================
    -- D. PROVISIONING ULANG HARUS AMAN
    -- =====================================================

    v_provision_response :=
        public.provision_admin_staff_login_account(
            p_staff_id =>
                v_staff_id,

            p_user_id =>
                v_profile_id,

            p_login_id =>
                v_login_id,

            p_role_codes =>
                v_role_codes
        );

    if coalesce(
        (
            v_provision_response
            ->> 'success'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: provisioning idempotent tidak berhasil.';
    end if;

    -- =====================================================
    -- E. LOGIN ID SALAH HARUS DITOLAK
    -- =====================================================

    begin
        perform
            public.provision_admin_staff_login_account(
                p_staff_id =>
                    v_staff_id,

                p_user_id =>
                    v_profile_id,

                p_login_id =>
                    concat(
                        v_login_id,
                        '-SALAH'
                    ),

                p_role_codes =>
                    v_role_codes
            );

    exception
        when others then
            if sqlerrm ilike
               '%tidak sesuai dengan ID staf%' then
                v_invalid_login_blocked :=
                    true;
            else
                raise;
            end if;
    end;

    if v_invalid_login_blocked is not true then
        raise exception
            'Pengujian gagal: ID Pengguna yang salah belum ditolak.';
    end if;

    -- =====================================================
    -- F. ROLE ADMIN HARUS DITOLAK
    -- =====================================================

    begin
        perform
            public.provision_admin_staff_login_account(
                p_staff_id =>
                    v_staff_id,

                p_user_id =>
                    v_profile_id,

                p_login_id =>
                    v_login_id,

                p_role_codes =>
                    array_append(
                        v_role_codes,
                        'admin'
                    )
            );

    exception
        when others then
            if sqlerrm ilike
               '%role staf tidak valid%' then
                v_admin_role_blocked :=
                    true;
            else
                raise;
            end if;
    end;

    if v_admin_role_blocked is not true then
        raise exception
            'Pengujian gagal: role admin belum ditolak.';
    end if;

    -- =====================================================
    -- G. NOTICE
    -- =====================================================

    raise notice
        'STAFF ID: %',
        v_staff_id;

    raise notice
        'PROFILE ID: %',
        v_profile_id;

    raise notice
        'LOGIN ID: %',
        v_login_id;

    raise notice
        'AUTH EMAIL: %',
        v_auth_email;

    raise notice
        'ROLE CODES: %',
        v_role_codes;

    raise notice
        'IDENTITY RESPONSE: %',
        v_identity_response;

    raise notice
        'PROVISION RESPONSE: %',
        v_provision_response;

    raise notice
        'INVALID LOGIN BLOCKED: %',
        v_invalid_login_blocked;

    raise notice
        'ADMIN ROLE BLOCKED: %',
        v_admin_role_blocked;

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


rollback;


-- =========================================================
-- 5. HASIL AKHIR
-- =========================================================

select
    'Identitas login, pilihan role, dan provisioning akun staf berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;