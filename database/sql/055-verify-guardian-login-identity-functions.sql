-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 055-verify-guardian-login-identity-functions.sql
--
-- PURPOSE:
-- - Memastikan fungsi identitas login tersedia
-- - Memastikan privilege benar
-- - Menguji akun wali existing
-- - Menguji provisioning idempotent
-- - Menguji penolakan login ID tidak sesuai
-- - Seluruh perubahan di-rollback
-- =========================================================


-- =========================================================
-- 1. FUNCTION DAN PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_guardian_login_identity(uuid)'
    ) is not null
        as identity_function_exists,

    to_regprocedure(
        'public.provision_admin_guardian_login_account(uuid,uuid,text)'
    ) is not null
        as provisioning_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_guardian_login_identity(uuid)',
        'execute'
    ) as authenticated_can_get_identity,

    has_function_privilege(
        'anon',
        'public.get_admin_guardian_login_identity(uuid)',
        'execute'
    ) as anon_can_get_identity,

    has_function_privilege(
        'authenticated',
        'public.provision_admin_guardian_login_account(uuid,uuid,text)',
        'execute'
    ) as authenticated_can_provision,

    has_function_privilege(
        'anon',
        'public.provision_admin_guardian_login_account(uuid,uuid,text)',
        'execute'
    ) as anon_can_provision;


-- =========================================================
-- 2. TRANSAKSI
-- =========================================================

begin;


-- =========================================================
-- 3. EMULASI SESSION ADMIN
-- =========================================================

select set_config(
    'request.jwt.claim.sub',
    (
        select auth_user.id::text

        from auth.users as auth_user

        where lower(
            auth_user.email::text
        ) = lower(
            'adm-001@login.emahad.id'
        )

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

        where lower(
            auth_user.email::text
        ) = lower(
            'adm-001@login.emahad.id'
        )

        limit 1
    ),
    true
);


-- =========================================================
-- 4. PENGUJIAN
-- =========================================================

do $verification$
declare
    v_guardian_id uuid;
    v_profile_id uuid;

    v_login_id text;
    v_auth_email text;
    v_contact_email_before text;
    v_contact_email_after text;

    v_identity_response jsonb;
    v_provision_response jsonb;

    v_invalid_login_blocked boolean :=
        false;
begin
    -- =====================================================
    -- A. CARI AKUN WALI EXISTING
    -- =====================================================

    select
        guardian.id,
        guardian.profile_id,
        profile.login_id,
        auth_user.email::text,
        guardian.email

    into
        v_guardian_id,
        v_profile_id,
        v_login_id,
        v_auth_email,
        v_contact_email_before

    from public.guardians as guardian

    inner join public.profiles as profile
        on profile.id =
           guardian.profile_id

    inner join auth.users as auth_user
        on auth_user.id =
           profile.id

    inner join public.user_roles as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles as role
        on role.id =
           user_role.role_id

    where role.code =
          'guardian'

      and profile.login_id
          is not null

      and auth_user.deleted_at
          is null

    order by
        guardian.created_at,
        guardian.id

    limit 1;

    if v_guardian_id is null then
        raise exception
            'Pengujian gagal: akun wali existing tidak ditemukan.';
    end if;

    -- =====================================================
    -- B. IDENTITAS EXISTING
    -- =====================================================

    v_identity_response :=
        public.get_admin_guardian_login_identity(
            v_guardian_id
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
            'Pengujian gagal: login ID response tidak sesuai.';
    end if;

    -- =====================================================
    -- C. PROVISIONING ULANG HARUS AMAN
    -- =====================================================

    v_provision_response :=
        public.provision_admin_guardian_login_account(
            p_guardian_id =>
                v_guardian_id,

            p_user_id =>
                v_profile_id,

            p_login_id =>
                v_login_id
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
    -- D. EMAIL KONTAK TIDAK BOLEH BERUBAH
    -- =====================================================

    select guardian.email

    into v_contact_email_after

    from public.guardians as guardian

    where guardian.id =
          v_guardian_id;

    if v_contact_email_after
       is distinct from
       v_contact_email_before then
        raise exception
            'Pengujian gagal: email kontak wali berubah.';
    end if;

    -- =====================================================
    -- E. LOGIN ID SALAH HARUS DITOLAK
    -- =====================================================

    begin
        perform
            public.provision_admin_guardian_login_account(
                p_guardian_id =>
                    v_guardian_id,

                p_user_id =>
                    v_profile_id,

                p_login_id =>
                    concat(
                        v_login_id,
                        '-SALAH'
                    )
            );

    exception
        when others then
            if sqlerrm ilike
               '%email auth tidak sesuai%' then
                v_invalid_login_blocked :=
                    true;
            else
                raise;
            end if;
    end;

    if v_invalid_login_blocked is not true then
        raise exception
            'Pengujian gagal: login ID yang tidak sesuai belum ditolak.';
    end if;

    -- =====================================================
    -- F. NOTICE
    -- =====================================================

    raise notice
        'GUARDIAN ID: %',
        v_guardian_id;

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
        'IDENTITY RESPONSE: %',
        v_identity_response;

    raise notice
        'PROVISION RESPONSE: %',
        v_provision_response;

    raise notice
        'INVALID LOGIN BLOCKED: %',
        v_invalid_login_blocked;

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


-- =========================================================
-- 5. ROLLBACK
-- =========================================================

rollback;


-- =========================================================
-- 6. HASIL AKHIR
-- =========================================================

select
    'Verifikasi identitas login dan provisioning akun wali berhasil.'
        as verification_status,

    now()
        as verified_at;