-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 049-verify-admin-guardian-account-provisioning.sql
--
-- PURPOSE:
-- - Memastikan fungsi provisioning tersedia
-- - Memastikan privilege benar
-- - Menguji profile, role guardian, dan guardian.profile_id
-- - Menguji pencegahan satu akun untuk dua wali
-- - Seluruh perubahan di-rollback
-- =========================================================


-- =========================================================
-- 1. CHECK FUNCTION DAN PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.provision_admin_guardian_account(uuid,text)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.provision_admin_guardian_account(uuid,text)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.provision_admin_guardian_account(uuid,text)',
        'execute'
    ) as anon_can_execute;


-- Hasil:
--
-- function_exists              = true
-- authenticated_can_execute    = true
-- anon_can_execute             = false


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
    v_admin_user_id uuid;

    v_guardian_one_response jsonb;
    v_guardian_two_response jsonb;

    v_guardian_one_id uuid;
    v_guardian_two_id uuid;

    v_provision_response jsonb;

    v_guardian_role_count integer;
    v_duplicate_guardian_blocked boolean :=
        false;
begin
    -- =====================================================
    -- A. AMBIL ID ADMIN
    -- =====================================================

    select auth_user.id

    into v_admin_user_id

    from auth.users as auth_user

    where lower(
        auth_user.email::text
    ) = lower(
        'admin@emahad.id'
    )

    limit 1;

    if v_admin_user_id is null then
        raise exception
            'Pengujian gagal: akun Admin tidak ditemukan.';
    end if;

    -- =====================================================
    -- B. BUAT DUA WALI SEMENTARA
    -- =====================================================

    v_guardian_one_response :=
        public.create_admin_guardian(
            p_legacy_guardian_id =>
                'TEST-WALI-AKUN-001',

            p_full_name =>
                'Wali Pengujian Akun Satu',

            p_phone =>
                '081211110011',

            p_email =>
                'admin@emahad.id',

            p_is_active =>
                true
        );

    v_guardian_two_response :=
        public.create_admin_guardian(
            p_legacy_guardian_id =>
                'TEST-WALI-AKUN-002',

            p_full_name =>
                'Wali Pengujian Akun Dua',

            p_phone =>
                '081211110012',

            p_email =>
                'admin@emahad.id',

            p_is_active =>
                true
        );

    v_guardian_one_id :=
        (
            v_guardian_one_response
            ->> 'guardian_id'
        )::uuid;

    v_guardian_two_id :=
        (
            v_guardian_two_response
            ->> 'guardian_id'
        )::uuid;

    if v_guardian_one_id is null
       or v_guardian_two_id is null then
        raise exception
            'Pengujian gagal: guardian ID tidak tersedia.';
    end if;

    -- =====================================================
    -- C. PROVISIONING WALI PERTAMA
    -- =====================================================

    v_provision_response :=
        public.provision_admin_guardian_account(
            p_guardian_id =>
                v_guardian_one_id,

            p_user_email =>
                'admin@emahad.id'
        );

    if coalesce(
        (
            v_provision_response
            ->> 'success'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: provisioning tidak berhasil.';
    end if;

    if (
        v_provision_response
        ->> 'operation'
    ) <> 'provisioned' then
        raise exception
            'Pengujian gagal: operation provisioning tidak sesuai.';
    end if;

    if (
        v_provision_response
        ->> 'user_id'
    )::uuid <> v_admin_user_id then
        raise exception
            'Pengujian gagal: user ID hasil provisioning tidak sesuai.';
    end if;

    -- =====================================================
    -- D. VERIFIKASI GUARDIAN.PROFILE_ID
    -- =====================================================

    if not exists (
        select 1

        from public.guardians as guardian

        where guardian.id =
              v_guardian_one_id

          and guardian.profile_id =
              v_admin_user_id
    ) then
        raise exception
            'Pengujian gagal: guardian.profile_id tidak terhubung.';
    end if;

    -- =====================================================
    -- E. VERIFIKASI ROLE GUARDIAN
    -- =====================================================

    select count(*)::integer

    into v_guardian_role_count

    from public.user_roles as user_role

    inner join public.roles as role
        on role.id =
           user_role.role_id

    where user_role.user_id =
          v_admin_user_id

      and role.code =
          'guardian';

    if v_guardian_role_count <> 1 then
        raise exception
            'Pengujian gagal: role guardian tidak tepat satu.';
    end if;

    -- =====================================================
    -- F. PROVISIONING ULANG HARUS IDEMPOTENT
    -- =====================================================

    perform
        public.provision_admin_guardian_account(
            p_guardian_id =>
                v_guardian_one_id,

            p_user_email =>
                'admin@emahad.id'
        );

    select count(*)::integer

    into v_guardian_role_count

    from public.user_roles as user_role

    inner join public.roles as role
        on role.id =
           user_role.role_id

    where user_role.user_id =
          v_admin_user_id

      and role.code =
          'guardian';

    if v_guardian_role_count <> 1 then
        raise exception
            'Pengujian gagal: provisioning ulang membuat role ganda.';
    end if;

    -- =====================================================
    -- G. AKUN SAMA TIDAK BOLEH UNTUK WALI KEDUA
    -- =====================================================

    begin
        perform
            public.provision_admin_guardian_account(
                p_guardian_id =>
                    v_guardian_two_id,

                p_user_email =>
                    'admin@emahad.id'
            );

    exception
        when others then
            if sqlerrm ilike
               '%sudah terhubung dengan data wali lain%' then
                v_duplicate_guardian_blocked :=
                    true;
            else
                raise;
            end if;
    end;

    if v_duplicate_guardian_blocked is not true then
        raise exception
            'Pengujian gagal: satu akun masih dapat digunakan oleh dua wali.';
    end if;

    -- =====================================================
    -- H. OUTPUT NOTICE
    -- =====================================================

    raise notice
        'PROVISION RESPONSE: %',
        v_provision_response;

    raise notice
        'DUPLICATE GUARDIAN BLOCKED: %',
        v_duplicate_guardian_blocked;

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


-- =========================================================
-- 5. ROLLBACK SELURUH PERUBAHAN TEST
-- =========================================================

rollback;


-- =========================================================
-- 6. PASTIKAN DATA TEST BERSIH
-- =========================================================

select
    (
        select count(*)::integer

        from public.guardians

        where legacy_guardian_id in (
            'TEST-WALI-AKUN-001',
            'TEST-WALI-AKUN-002'
        )
    ) as remaining_test_guardians,

    (
        select count(*)::integer

        from public.user_roles
            as user_role

        inner join public.roles as role
            on role.id =
               user_role.role_id

        inner join auth.users
            as auth_user
            on auth_user.id =
               user_role.user_id

        where lower(
            auth_user.email::text
        ) = lower(
            'admin@emahad.id'
        )

          and role.code =
              'guardian'
    ) as admin_guardian_roles_after_rollback;