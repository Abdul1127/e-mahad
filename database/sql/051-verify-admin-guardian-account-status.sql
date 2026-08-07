-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 051-verify-admin-guardian-account-status.sql
--
-- PURPOSE:
-- - Memastikan fungsi status akun tersedia
-- - Memastikan privilege benar
-- - Menguji nonaktifkan dan aktifkan profile wali
-- - Memastikan hanya akun wali yang valid yang diproses
-- - Seluruh perubahan di-rollback
-- =========================================================


-- =========================================================
-- 1. CHECK FUNCTION DAN PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.set_admin_guardian_account_profile_status(uuid,boolean)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.set_admin_guardian_account_profile_status(uuid,boolean)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.set_admin_guardian_account_profile_status(uuid,boolean)',
        'execute'
    ) as anon_can_execute;


-- Hasil:
--
-- function_exists           = true
-- authenticated_can_execute = true
-- anon_can_execute          = false


-- =========================================================
-- 2. MULAI TRANSAKSI
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
            'admin@emahad.id'
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
            'admin@emahad.id'
        )

        limit 1
    ),
    true
);


-- =========================================================
-- 4. PENGUJIAN DALAM SATU BLOK
-- =========================================================

do $verification$
declare
    v_guardian_id uuid;
    v_profile_id uuid;

    v_original_status boolean;

    v_deactivate_response jsonb;
    v_activate_response jsonb;
begin
    -- =====================================================
    -- A. CARI WALI AKTIF YANG SUDAH MEMPUNYAI AKUN
    -- =====================================================

    select
        guardian.id,
        guardian.profile_id,
        profile.is_active

    into
        v_guardian_id,
        v_profile_id,
        v_original_status

    from public.guardians as guardian

    inner join public.profiles as profile
        on profile.id =
           guardian.profile_id

    inner join public.user_roles as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles as role
        on role.id =
           user_role.role_id

    where guardian.is_active = true
      and guardian.profile_id is not null
      and role.code = 'guardian'
      and role.is_active = true

    order by guardian.created_at

    limit 1;

    if v_guardian_id is null then
        raise exception
            'Pengujian gagal: belum ada wali aktif yang mempunyai akun guardian.';
    end if;

    -- =====================================================
    -- B. NONAKTIFKAN PROFILE
    -- =====================================================

    v_deactivate_response :=
        public.set_admin_guardian_account_profile_status(
            p_guardian_id =>
                v_guardian_id,

            p_is_active =>
                false
        );

    if coalesce(
        (
            v_deactivate_response
            ->> 'success'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: response nonaktif tidak berhasil.';
    end if;

    if (
        v_deactivate_response
        ->> 'operation'
    ) <> 'deactivated' then
        raise exception
            'Pengujian gagal: operation nonaktif tidak sesuai.';
    end if;

    if exists (
        select 1

        from public.profiles as profile

        where profile.id =
              v_profile_id

          and profile.is_active = true
    ) then
        raise exception
            'Pengujian gagal: profile masih aktif setelah dinonaktifkan.';
    end if;

    -- =====================================================
    -- C. AKTIFKAN KEMBALI PROFILE
    -- =====================================================

    v_activate_response :=
        public.set_admin_guardian_account_profile_status(
            p_guardian_id =>
                v_guardian_id,

            p_is_active =>
                true
        );

    if coalesce(
        (
            v_activate_response
            ->> 'success'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: response aktivasi tidak berhasil.';
    end if;

    if (
        v_activate_response
        ->> 'operation'
    ) <> 'activated' then
        raise exception
            'Pengujian gagal: operation aktivasi tidak sesuai.';
    end if;

    if not exists (
        select 1

        from public.profiles as profile

        where profile.id =
              v_profile_id

          and profile.is_active = true
    ) then
        raise exception
            'Pengujian gagal: profile tidak aktif setelah diaktifkan.';
    end if;

    -- =====================================================
    -- D. OUTPUT NOTICE
    -- =====================================================

    raise notice
        'GUARDIAN ID: %',
        v_guardian_id;

    raise notice
        'PROFILE ID: %',
        v_profile_id;

    raise notice
        'ORIGINAL STATUS: %',
        v_original_status;

    raise notice
        'DEACTIVATE RESPONSE: %',
        v_deactivate_response;

    raise notice
        'ACTIVATE RESPONSE: %',
        v_activate_response;

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


-- =========================================================
-- 5. ROLLBACK SELURUH PERUBAHAN
-- =========================================================

rollback;


-- =========================================================
-- 6. HASIL AKHIR
-- =========================================================

select
    'Verifikasi status profile akun wali berhasil dan seluruh perubahan telah di-rollback.'
        as verification_status,

    now()
        as verified_at;