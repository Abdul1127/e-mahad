-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 043-verify-admin-guardian-functions.sql
-- PURPOSE:
-- - Memastikan fungsi wali tersedia
-- - Memastikan privilege benar
-- - Menguji tambah, detail, dan edit wali
-- - Menggunakan variabel PL/pgSQL tanpa temporary table
-- - Seluruh data pengujian di-rollback
-- =========================================================


-- =========================================================
-- 1. PERIKSA FUNGSI DAN PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_guardian_detail(uuid)'
    ) is not null
        as detail_function_exists,

    to_regprocedure(
        'public.create_admin_guardian(text,text,text,text,boolean)'
    ) is not null
        as create_function_exists,

    to_regprocedure(
        'public.update_admin_guardian(uuid,text,text,text,text,boolean)'
    ) is not null
        as update_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_guardian_detail(uuid)',
        'execute'
    ) as authenticated_can_get_detail,

    has_function_privilege(
        'authenticated',
        'public.create_admin_guardian(text,text,text,text,boolean)',
        'execute'
    ) as authenticated_can_create,

    has_function_privilege(
        'authenticated',
        'public.update_admin_guardian(uuid,text,text,text,text,boolean)',
        'execute'
    ) as authenticated_can_update,

    has_function_privilege(
        'anon',
        'public.get_admin_guardian_detail(uuid)',
        'execute'
    ) as anon_can_get_detail,

    has_function_privilege(
        'anon',
        'public.create_admin_guardian(text,text,text,text,boolean)',
        'execute'
    ) as anon_can_create,

    has_function_privilege(
        'anon',
        'public.update_admin_guardian(uuid,text,text,text,text,boolean)',
        'execute'
    ) as anon_can_update;


-- Hasil yang diharapkan:
--
-- detail_function_exists        = true
-- create_function_exists        = true
-- update_function_exists        = true
-- authenticated_can_get_detail = true
-- authenticated_can_create     = true
-- authenticated_can_update     = true
-- anon_can_get_detail          = false
-- anon_can_create              = false
-- anon_can_update              = false


-- =========================================================
-- 2. MULAI TRANSAKSI PENGUJIAN
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


-- =========================================================
-- 4. PENGUJIAN DALAM SATU BLOK
-- =========================================================

do $verification$
declare
    v_create_response jsonb;
    v_update_response jsonb;

    v_detail_before jsonb;
    v_detail_after jsonb;

    v_guardian_id uuid;

    v_database_count integer;
begin
    -- =====================================================
    -- A. BUAT WALI SEMENTARA
    -- =====================================================

    v_create_response :=
        public.create_admin_guardian(
            p_legacy_guardian_id =>
                'TEST-WALI-DB-001',

            p_full_name =>
                'Wali Pengujian Database',

            p_phone =>
                '+62 812-3456-7890',

            p_email =>
                'wali.database@example.com',

            p_is_active =>
                true
        );

    v_guardian_id :=
        (
            v_create_response
            ->> 'guardian_id'
        )::uuid;

    if v_guardian_id is null then
        raise exception
            'Pengujian gagal: create tidak menghasilkan guardian_id.';
    end if;

    if coalesce(
        (
            v_create_response
            ->> 'success'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: response create tidak berhasil.';
    end if;

    if (
        v_create_response
        ->> 'operation'
    ) <> 'created' then
        raise exception
            'Pengujian gagal: operation create tidak sesuai.';
    end if;


    -- =====================================================
    -- B. BACA DETAIL SEBELUM UPDATE
    -- =====================================================

    v_detail_before :=
        public.get_admin_guardian_detail(
            v_guardian_id
        );

    if v_detail_before is null then
        raise exception
            'Pengujian gagal: detail wali tidak ditemukan setelah create.';
    end if;

    if (
        v_detail_before
        #>> '{guardian,full_name}'
    ) <> 'Wali Pengujian Database' then
        raise exception
            'Pengujian gagal: nama wali sebelum update tidak sesuai.';
    end if;

    if coalesce(
        (
            v_detail_before
            #>> '{guardian,is_active}'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: status wali sebelum update seharusnya aktif.';
    end if;

    if coalesce(
        (
            v_detail_before
            #>> '{account,linked}'
        )::boolean,
        false
    ) is not false then
        raise exception
            'Pengujian gagal: wali pengujian seharusnya belum memiliki akun.';
    end if;

    if jsonb_array_length(
        coalesce(
            v_detail_before
            -> 'children',
            '[]'::jsonb
        )
    ) <> 0 then
        raise exception
            'Pengujian gagal: wali pengujian seharusnya belum memiliki anak terhubung.';
    end if;


    -- =====================================================
    -- C. UPDATE WALI
    -- =====================================================

    v_update_response :=
        public.update_admin_guardian(
            p_guardian_id =>
                v_guardian_id,

            p_legacy_guardian_id =>
                'TEST-WALI-DB-001',

            p_full_name =>
                'Wali Pengujian Diperbarui',

            p_phone =>
                '0812-0000-0000',

            p_email =>
                'wali.diperbarui@example.com',

            p_is_active =>
                false
        );

    if coalesce(
        (
            v_update_response
            ->> 'success'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: response update tidak berhasil.';
    end if;

    if (
        v_update_response
        ->> 'operation'
    ) <> 'updated' then
        raise exception
            'Pengujian gagal: operation update tidak sesuai.';
    end if;


    -- =====================================================
    -- D. BACA DETAIL SETELAH UPDATE
    -- =====================================================

    v_detail_after :=
        public.get_admin_guardian_detail(
            v_guardian_id
        );

    if v_detail_after is null then
        raise exception
            'Pengujian gagal: detail wali tidak ditemukan setelah update.';
    end if;

    if (
        v_detail_after
        #>> '{guardian,full_name}'
    ) <> 'Wali Pengujian Diperbarui' then
        raise exception
            'Pengujian gagal: nama wali setelah update tidak sesuai.';
    end if;

    if (
        v_detail_after
        #>> '{guardian,phone}'
    ) <> '0812-0000-0000' then
        raise exception
            'Pengujian gagal: nomor telepon setelah update tidak sesuai.';
    end if;

    if (
        v_detail_after
        #>> '{guardian,email}'
    ) <> 'wali.diperbarui@example.com' then
        raise exception
            'Pengujian gagal: email setelah update tidak sesuai.';
    end if;

    if coalesce(
        (
            v_detail_after
            #>> '{guardian,is_active}'
        )::boolean,
        true
    ) is not false then
        raise exception
            'Pengujian gagal: status wali setelah update seharusnya tidak aktif.';
    end if;


    -- =====================================================
    -- E. VERIFIKASI LANGSUNG KE DATABASE
    -- =====================================================

    select count(*)::integer

    into v_database_count

    from public.guardians as guardian

    where guardian.id =
          v_guardian_id

      and guardian.legacy_guardian_id =
          'TEST-WALI-DB-001'

      and guardian.full_name =
          'Wali Pengujian Diperbarui'

      and guardian.phone =
          '0812-0000-0000'

      and guardian.email =
          'wali.diperbarui@example.com'

      and guardian.is_active = false

      and guardian.profile_id is null;

    if v_database_count <> 1 then
        raise exception
            'Pengujian gagal: hasil akhir database tidak sesuai.';
    end if;


    -- =====================================================
    -- F. OUTPUT NOTICE
    -- =====================================================

    raise notice
        'CREATE RESPONSE: %',
        v_create_response;

    raise notice
        'DETAIL BEFORE UPDATE: %',
        v_detail_before;

    raise notice
        'UPDATE RESPONSE: %',
        v_update_response;

    raise notice
        'DETAIL AFTER UPDATE: %',
        v_detail_after;

    raise notice
        'VERIFICATION SUCCESS: guardian_id=%',
        v_guardian_id;
end;
$verification$;


-- =========================================================
-- 5. ROLLBACK DATA PENGUJIAN
-- =========================================================

rollback;


-- =========================================================
-- 6. PASTIKAN DATA TEST SUDAH BERSIH
-- =========================================================

select
    count(*)::integer
        as remaining_test_guardians

from public.guardians

where legacy_guardian_id =
      'TEST-WALI-DB-001';