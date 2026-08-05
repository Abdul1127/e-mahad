-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 045-verify-admin-guardian-student-relations.sql
-- PURPOSE:
-- - Verifikasi fungsi hubungan wali-santri
-- - Verifikasi satu kontak utama per santri
-- - Verifikasi promosi kontak utama
-- - Seluruh data pengujian di-rollback
-- =========================================================


-- =========================================================
-- 1. CHECK FUNCTION DAN PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_guardian_student_options(uuid,text,integer)'
    ) is not null
        as options_function_exists,

    to_regprocedure(
        'public.create_admin_guardian_student_relation(uuid,uuid,text,boolean)'
    ) is not null
        as create_relation_function_exists,

    to_regprocedure(
        'public.update_admin_guardian_student_relation(uuid,text,boolean)'
    ) is not null
        as update_relation_function_exists,

    to_regprocedure(
        'public.delete_admin_guardian_student_relation(uuid)'
    ) is not null
        as delete_relation_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_guardian_student_options(uuid,text,integer)',
        'execute'
    ) as authenticated_can_get_options,

    has_function_privilege(
        'authenticated',
        'public.create_admin_guardian_student_relation(uuid,uuid,text,boolean)',
        'execute'
    ) as authenticated_can_create_relation,

    has_function_privilege(
        'authenticated',
        'public.update_admin_guardian_student_relation(uuid,text,boolean)',
        'execute'
    ) as authenticated_can_update_relation,

    has_function_privilege(
        'authenticated',
        'public.delete_admin_guardian_student_relation(uuid)',
        'execute'
    ) as authenticated_can_delete_relation,

    has_function_privilege(
        'anon',
        'public.create_admin_guardian_student_relation(uuid,uuid,text,boolean)',
        'execute'
    ) as anon_can_create_relation;


-- Hasil yang diharapkan:
--
-- options_function_exists          = true
-- create_relation_function_exists  = true
-- update_relation_function_exists  = true
-- delete_relation_function_exists  = true
-- authenticated_can_get_options    = true
-- authenticated_can_create_relation = true
-- authenticated_can_update_relation = true
-- authenticated_can_delete_relation = true
-- anon_can_create_relation          = false


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
    v_student_id uuid;
    v_student_name text;

    v_guardian_one_response jsonb;
    v_guardian_two_response jsonb;

    v_guardian_one_id uuid;
    v_guardian_two_id uuid;

    v_relation_one_response jsonb;
    v_relation_two_response jsonb;

    v_relation_one_id uuid;
    v_relation_two_id uuid;

    v_update_response jsonb;
    v_delete_response jsonb;
    v_options_response jsonb;

    v_primary_count integer;
begin
    -- =====================================================
    -- A. PILIH SANTRI AKTIF
    -- =====================================================

    select
        student.id,
        student.full_name

    into
        v_student_id,
        v_student_name

    from public.students as student

    where student.status =
          'active'::public.student_status

      and student.deleted_at is null

    order by
        lower(student.full_name),
        student.id

    limit 1;

    if v_student_id is null then
        raise exception
            'Pengujian gagal: tidak ada santri aktif.';
    end if;

    -- =====================================================
    -- B. BERSIHKAN SISA TEST DALAM TRANSAKSI
    -- =====================================================

    delete from public.guardians

    where legacy_guardian_id in (
        'TEST-WALI-REL-001',
        'TEST-WALI-REL-002'
    );

    -- =====================================================
    -- C. BUAT DUA WALI SEMENTARA
    -- =====================================================

    v_guardian_one_response :=
        public.create_admin_guardian(
            p_legacy_guardian_id =>
                'TEST-WALI-REL-001',

            p_full_name =>
                'Ayah Pengujian Relasi',

            p_phone =>
                '081211110001',

            p_email =>
                'ayah.relasi@example.com',

            p_is_active =>
                true
        );

    v_guardian_two_response :=
        public.create_admin_guardian(
            p_legacy_guardian_id =>
                'TEST-WALI-REL-002',

            p_full_name =>
                'Ibu Pengujian Relasi',

            p_phone =>
                '081211110002',

            p_email =>
                'ibu.relasi@example.com',

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
    -- D. HUBUNGKAN WALI PERTAMA
    -- =====================================================

    v_relation_one_response :=
        public.create_admin_guardian_student_relation(
            p_guardian_id =>
                v_guardian_one_id,

            p_student_id =>
                v_student_id,

            p_relationship_type =>
                'father',

            p_is_primary_contact =>
                false
        );

    v_relation_one_id :=
        (
            v_relation_one_response
            ->> 'relation_id'
        )::uuid;

    -- Hubungan pertama harus otomatis utama.

    if coalesce(
        (
            v_relation_one_response
            ->> 'is_primary_contact'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: hubungan pertama tidak otomatis menjadi kontak utama.';
    end if;

    -- =====================================================
    -- E. HUBUNGKAN WALI KEDUA
    -- =====================================================

    v_relation_two_response :=
        public.create_admin_guardian_student_relation(
            p_guardian_id =>
                v_guardian_two_id,

            p_student_id =>
                v_student_id,

            p_relationship_type =>
                'mother',

            p_is_primary_contact =>
                false
        );

    v_relation_two_id :=
        (
            v_relation_two_response
            ->> 'relation_id'
        )::uuid;

    if coalesce(
        (
            v_relation_two_response
            ->> 'is_primary_contact'
        )::boolean,
        true
    ) is not false then
        raise exception
            'Pengujian gagal: wali kedua seharusnya bukan kontak utama.';
    end if;

    -- =====================================================
    -- F. PASTIKAN HANYA SATU KONTAK UTAMA
    -- =====================================================

    select count(*)::integer

    into v_primary_count

    from public.guardian_students
        as relation

    where relation.student_id =
          v_student_id

      and relation.is_primary_contact = true;

    if v_primary_count <> 1 then
        raise exception
            'Pengujian gagal: jumlah kontak utama bukan satu.';
    end if;

    -- =====================================================
    -- G. PINDAHKAN KONTAK UTAMA KE WALI KEDUA
    -- =====================================================

    v_update_response :=
        public.update_admin_guardian_student_relation(
            p_relation_id =>
                v_relation_two_id,

            p_relationship_type =>
                'mother',

            p_is_primary_contact =>
                true
        );

    if coalesce(
        (
            v_update_response
            ->> 'is_primary_contact'
        )::boolean,
        false
    ) is not true then
        raise exception
            'Pengujian gagal: wali kedua tidak menjadi kontak utama.';
    end if;

    if exists (
        select 1

        from public.guardian_students
            as relation

        where relation.id =
              v_relation_one_id

          and relation.is_primary_contact = true
    ) then
        raise exception
            'Pengujian gagal: wali pertama masih menjadi kontak utama.';
    end if;

    -- =====================================================
    -- H. LEPASKAN WALI KEDUA
    -- =====================================================

    v_delete_response :=
        public.delete_admin_guardian_student_relation(
            p_relation_id =>
                v_relation_two_id
        );

    -- Wali pertama harus otomatis kembali utama.

    if not exists (
        select 1

        from public.guardian_students
            as relation

        where relation.id =
              v_relation_one_id

          and relation.is_primary_contact = true
    ) then
        raise exception
            'Pengujian gagal: kontak utama pengganti tidak dipromosikan.';
    end if;

    -- =====================================================
    -- I. PILIHAN SANTRI HARUS MENGECUALIKAN
    --    SANTRI YANG SUDAH TERHUBUNG
    -- =====================================================

    v_options_response :=
        public.get_admin_guardian_student_options(
            p_guardian_id =>
                v_guardian_one_id,

            p_search =>
                v_student_name,

            p_limit =>
                20
        );

    if exists (
        select 1

        from jsonb_array_elements(
            coalesce(
                v_options_response -> 'items',
                '[]'::jsonb
            )
        ) as option

        where option ->> 'student_id' =
              v_student_id::text
    ) then
        raise exception
            'Pengujian gagal: santri yang sudah terhubung masih muncul pada pilihan.';
    end if;

    -- =====================================================
    -- J. LEPASKAN HUBUNGAN PERTAMA
    -- =====================================================

    perform
        public.delete_admin_guardian_student_relation(
            p_relation_id =>
                v_relation_one_id
        );

    if exists (
        select 1

        from public.guardian_students
            as relation

        where relation.guardian_id in (
            v_guardian_one_id,
            v_guardian_two_id
        )
    ) then
        raise exception
            'Pengujian gagal: hubungan test masih tersisa.';
    end if;

    -- =====================================================
    -- K. OUTPUT NOTICE
    -- =====================================================

    raise notice
        'STUDENT TEST: % (%)',
        v_student_name,
        v_student_id;

    raise notice
        'RELATION ONE CREATE: %',
        v_relation_one_response;

    raise notice
        'RELATION TWO CREATE: %',
        v_relation_two_response;

    raise notice
        'PRIMARY UPDATE: %',
        v_update_response;

    raise notice
        'DELETE PRIMARY: %',
        v_delete_response;

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


-- =========================================================
-- 5. ROLLBACK SELURUH DATA TEST
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
            'TEST-WALI-REL-001',
            'TEST-WALI-REL-002'
        )
    ) as remaining_test_guardians,

    (
        select count(*)::integer

        from public.guardian_students
            as relation

        inner join public.guardians
            as guardian
            on guardian.id =
               relation.guardian_id

        where guardian.legacy_guardian_id in (
            'TEST-WALI-REL-001',
            'TEST-WALI-REL-002'
        )
    ) as remaining_test_relations;