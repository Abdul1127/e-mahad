-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 076-verify-student-placement-history-fix.sql
--
-- PURPOSE:
-- - Memverifikasi hasil migration 075
-- - Memastikan unique lama sudah dihapus
-- - Memastikan satu active placement tetap dijaga
-- - Simulasi nonaktif -> aktif kembali
-- - Memastikan periode baru dibuat
-- - Memastikan edit tanpa pindah tidak membuat row baru
--
-- SELURUH PERUBAHAN TEST DI-ROLLBACK
-- =========================================================


-- =========================================================
-- 1. VERIFY STRUCTURE
-- =========================================================

do $structure_verification$
begin

    -- =====================================================
    -- UNIQUE LAMA HARUS SUDAH HILANG
    -- =====================================================

    if exists (
        select 1

        from pg_constraint

        where conname =
              'class_enrollments_student_class_unique'

          and conrelid =
              'public.class_enrollments'::regclass
    ) then
        raise exception
            'Constraint class_enrollments_student_class_unique masih ada.';
    end if;


    if exists (
        select 1

        from pg_constraint

        where conname =
              'care_group_members_group_student_unique'

          and conrelid =
              'public.care_group_members'::regclass
    ) then
        raise exception
            'Constraint care_group_members_group_student_unique masih ada.';
    end if;


    if exists (
        select 1

        from pg_constraint

        where conname =
              'tahfiz_group_members_group_student_unique'

          and conrelid =
              'public.tahfiz_group_members'::regclass
    ) then
        raise exception
            'Constraint tahfiz_group_members_group_student_unique masih ada.';
    end if;


    -- =====================================================
    -- INDEX HISTORY BARU HARUS ADA
    -- =====================================================

    if to_regclass(
        'public.class_enrollments_student_class_idx'
    ) is null then
        raise exception
            'Index class history belum tersedia.';
    end if;


    if to_regclass(
        'public.care_group_members_group_student_idx'
    ) is null then
        raise exception
            'Index care history belum tersedia.';
    end if;


    if to_regclass(
        'public.tahfiz_group_members_group_student_idx'
    ) is null then
        raise exception
            'Index tahfiz history belum tersedia.';
    end if;


    -- =====================================================
    -- UNIQUE ACTIVE PER STUDENT HARUS TETAP ADA
    -- =====================================================

    if to_regclass(
        'public.class_enrollments_one_active_per_student_idx'
    ) is null then
        raise exception
            'Unique active class index tidak ditemukan.';
    end if;


    if to_regclass(
        'public.care_group_members_one_active_per_student_idx'
    ) is null then
        raise exception
            'Unique active care index tidak ditemukan.';
    end if;


    if to_regclass(
        'public.tahfiz_group_members_one_active_per_student_idx'
    ) is null then
        raise exception
            'Unique active tahfiz index tidak ditemukan.';
    end if;


    raise notice
        'STRUCTURE VERIFICATION SUCCESS';

end;
$structure_verification$;


-- =========================================================
-- 2. VERIFY FUNCTION
-- =========================================================

select
    to_regprocedure(
        'public.update_admin_student(uuid,text,text,text,text,text,uuid,uuid,uuid)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.update_admin_student(uuid,text,text,text,text,text,uuid,uuid,uuid)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.update_admin_student(uuid,text,text,text,text,text,uuid,uuid,uuid)',
        'execute'
    ) as anon_can_execute;


-- =========================================================
-- 3. MULAI TEST TRANSACTION
-- =========================================================

begin;


-- =========================================================
-- 4. EMULASI ADMIN
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
-- 5. SIMULASI HISTORY
-- =========================================================

do $verification$
declare

    -- =====================================================
    -- STUDENT
    -- =====================================================

    v_student_id uuid;

    v_legacy_student_id text;
    v_nis text;
    v_full_name text;
    v_gender text;


    -- =====================================================
    -- CURRENT PLACEMENT
    -- =====================================================

    v_class_id uuid;
    v_care_group_id uuid;
    v_tahfiz_group_id uuid;


    -- =====================================================
    -- ORIGINAL ACTIVE ROW ID
    -- =====================================================

    v_old_class_enrollment_id uuid;
    v_old_care_membership_id uuid;
    v_old_tahfiz_membership_id uuid;


    -- =====================================================
    -- NEW ACTIVE ROW ID
    -- =====================================================

    v_new_class_enrollment_id uuid;
    v_new_care_membership_id uuid;
    v_new_tahfiz_membership_id uuid;


    -- =====================================================
    -- COUNTS
    -- =====================================================

    v_class_count_before integer;
    v_care_count_before integer;
    v_tahfiz_count_before integer;

    v_class_count_after integer;
    v_care_count_after integer;
    v_tahfiz_count_after integer;

    v_class_count_final integer;
    v_care_count_final integer;
    v_tahfiz_count_final integer;

begin

    -- =====================================================
    -- 5A. PILIH 1 SANTRI AKTIF LENGKAP
    -- =====================================================

    select
        student.id,

        student.legacy_student_id,

        student.nis,

        student.full_name,

        student.gender::text,

        enrollment.class_id,

        care_membership.care_group_id,

        tahfiz_membership.tahfiz_group_id,

        enrollment.id,

        care_membership.id,

        tahfiz_membership.id

    into
        v_student_id,

        v_legacy_student_id,

        v_nis,

        v_full_name,

        v_gender,

        v_class_id,

        v_care_group_id,

        v_tahfiz_group_id,

        v_old_class_enrollment_id,

        v_old_care_membership_id,

        v_old_tahfiz_membership_id

    from public.students
        as student

    inner join public.class_enrollments
        as enrollment
        on enrollment.student_id =
           student.id

       and enrollment.is_active = true

    inner join public.care_group_members
        as care_membership
        on care_membership.student_id =
           student.id

       and care_membership.is_active = true

    inner join public.tahfiz_group_members
        as tahfiz_membership
        on tahfiz_membership.student_id =
           student.id

       and tahfiz_membership.is_active = true

    where student.status = 'active'
      and student.deleted_at is null

    order by
        student.legacy_student_id
            nulls last,

        student.full_name,

        student.id

    limit 1;


    if v_student_id is null then
        raise exception
            'Tidak ditemukan santri aktif yang mempunyai placement lengkap.';
    end if;


    raise notice
        'TEST STUDENT: % (%).',
        v_full_name,
        v_legacy_student_id;


    -- =====================================================
    -- 5B. HITUNG JUMLAH PERIOD SEBELUM TEST
    -- =====================================================

    select count(*)::integer

    into v_class_count_before

    from public.class_enrollments

    where student_id =
          v_student_id

      and class_id =
          v_class_id;


    select count(*)::integer

    into v_care_count_before

    from public.care_group_members

    where student_id =
          v_student_id

      and care_group_id =
          v_care_group_id;


    select count(*)::integer

    into v_tahfiz_count_before

    from public.tahfiz_group_members

    where student_id =
          v_student_id

      and tahfiz_group_id =
          v_tahfiz_group_id;


    -- =====================================================
    -- 5C. NONAKTIFKAN SANTRI
    -- =====================================================

    perform public.update_admin_student(
        v_student_id,
        v_legacy_student_id,
        v_nis,
        v_full_name,
        v_gender,
        'inactive',
        null,
        null,
        null
    );


    -- =====================================================
    -- STATUS STUDENT HARUS NONACTIVE
    -- =====================================================

    if not exists (
        select 1

        from public.students

        where id =
              v_student_id

          and status = 'inactive'
    ) then
        raise exception
            'Status santri gagal menjadi inactive.';
    end if;


    -- =====================================================
    -- TIDAK BOLEH ADA PLACEMENT AKTIF
    -- =====================================================

    if exists (
        select 1

        from public.class_enrollments

        where student_id =
              v_student_id

          and is_active = true
    ) then
        raise exception
            'Masih ada kelas aktif setelah santri dinonaktifkan.';
    end if;


    if exists (
        select 1

        from public.care_group_members

        where student_id =
              v_student_id

          and is_active = true
    ) then
        raise exception
            'Masih ada kelompok pengasuhan aktif setelah santri dinonaktifkan.';
    end if;


    if exists (
        select 1

        from public.tahfiz_group_members

        where student_id =
              v_student_id

          and is_active = true
    ) then
        raise exception
            'Masih ada kelompok tahfiz aktif setelah santri dinonaktifkan.';
    end if;


    -- =====================================================
    -- ORIGINAL ROW HARUS MENJADI HISTORY
    -- =====================================================

    if not exists (
        select 1

        from public.class_enrollments

        where id =
              v_old_class_enrollment_id

          and is_active = false

          and left_at is not null
    ) then
        raise exception
            'Riwayat kelas lama tidak ditutup dengan benar.';
    end if;


    if not exists (
        select 1

        from public.care_group_members

        where id =
              v_old_care_membership_id

          and is_active = false

          and left_at is not null
    ) then
        raise exception
            'Riwayat pengasuhan lama tidak ditutup dengan benar.';
    end if;


    if not exists (
        select 1

        from public.tahfiz_group_members

        where id =
              v_old_tahfiz_membership_id

          and is_active = false

          and left_at is not null
    ) then
        raise exception
            'Riwayat tahfiz lama tidak ditutup dengan benar.';
    end if;


    raise notice
        'NONACTIVE TEST SUCCESS';


    -- =====================================================
    -- 5D. AKTIFKAN KEMBALI KE DESTINATION YANG SAMA
    -- =====================================================

    perform public.update_admin_student(
        v_student_id,
        v_legacy_student_id,
        v_nis,
        v_full_name,
        v_gender,
        'active',
        v_class_id,
        v_care_group_id,
        v_tahfiz_group_id
    );


    -- =====================================================
    -- STATUS HARUS ACTIVE
    -- =====================================================

    if not exists (
        select 1

        from public.students

        where id =
              v_student_id

          and status = 'active'
    ) then
        raise exception
            'Status santri gagal kembali menjadi active.';
    end if;


    -- =====================================================
    -- TEPAT 1 PLACEMENT AKTIF
    -- =====================================================

    if (
        select count(*)

        from public.class_enrollments

        where student_id =
              v_student_id

          and is_active = true
    ) <> 1 then
        raise exception
            'Jumlah kelas aktif setelah reaktivasi bukan 1.';
    end if;


    if (
        select count(*)

        from public.care_group_members

        where student_id =
              v_student_id

          and is_active = true
    ) <> 1 then
        raise exception
            'Jumlah kelompok pengasuhan aktif setelah reaktivasi bukan 1.';
    end if;


    if (
        select count(*)

        from public.tahfiz_group_members

        where student_id =
              v_student_id

          and is_active = true
    ) <> 1 then
        raise exception
            'Jumlah kelompok tahfiz aktif setelah reaktivasi bukan 1.';
    end if;


    -- =====================================================
    -- AMBIL ID ROW BARU
    -- =====================================================

    select id

    into v_new_class_enrollment_id

    from public.class_enrollments

    where student_id =
          v_student_id

      and class_id =
          v_class_id

      and is_active = true

    limit 1;


    select id

    into v_new_care_membership_id

    from public.care_group_members

    where student_id =
          v_student_id

      and care_group_id =
          v_care_group_id

      and is_active = true

    limit 1;


    select id

    into v_new_tahfiz_membership_id

    from public.tahfiz_group_members

    where student_id =
          v_student_id

      and tahfiz_group_id =
          v_tahfiz_group_id

      and is_active = true

    limit 1;


    -- =====================================================
    -- ROW BARU TIDAK BOLEH SAMA DENGAN ROW LAMA
    -- =====================================================

    if v_new_class_enrollment_id =
       v_old_class_enrollment_id then
        raise exception
            'Kelas lama diaktifkan kembali. Seharusnya membuat row baru.';
    end if;


    if v_new_care_membership_id =
       v_old_care_membership_id then
        raise exception
            'Membership pengasuhan lama diaktifkan kembali. Seharusnya membuat row baru.';
    end if;


    if v_new_tahfiz_membership_id =
       v_old_tahfiz_membership_id then
        raise exception
            'Membership tahfiz lama diaktifkan kembali. Seharusnya membuat row baru.';
    end if;


    -- =====================================================
    -- JUMLAH PERIOD HARUS +1
    -- =====================================================

    select count(*)::integer

    into v_class_count_after

    from public.class_enrollments

    where student_id =
          v_student_id

      and class_id =
          v_class_id;


    select count(*)::integer

    into v_care_count_after

    from public.care_group_members

    where student_id =
          v_student_id

      and care_group_id =
          v_care_group_id;


    select count(*)::integer

    into v_tahfiz_count_after

    from public.tahfiz_group_members

    where student_id =
          v_student_id

      and tahfiz_group_id =
          v_tahfiz_group_id;


    if v_class_count_after <>
       v_class_count_before + 1 then
        raise exception
            'Periode kelas baru tidak tersimpan dengan benar.';
    end if;


    if v_care_count_after <>
       v_care_count_before + 1 then
        raise exception
            'Periode pengasuhan baru tidak tersimpan dengan benar.';
    end if;


    if v_tahfiz_count_after <>
       v_tahfiz_count_before + 1 then
        raise exception
            'Periode tahfiz baru tidak tersimpan dengan benar.';
    end if;


    raise notice
        'REACTIVATION HISTORY TEST SUCCESS';


    -- =====================================================
    -- 5E. EDIT TANPA MENGUBAH PLACEMENT
    --
    -- Panggil update lagi dengan placement yang sama.
    -- Jumlah row TIDAK boleh bertambah.
    -- =====================================================

    perform public.update_admin_student(
        v_student_id,
        v_legacy_student_id,
        v_nis,
        v_full_name,
        v_gender,
        'active',
        v_class_id,
        v_care_group_id,
        v_tahfiz_group_id
    );


    select count(*)::integer

    into v_class_count_final

    from public.class_enrollments

    where student_id =
          v_student_id

      and class_id =
          v_class_id;


    select count(*)::integer

    into v_care_count_final

    from public.care_group_members

    where student_id =
          v_student_id

      and care_group_id =
          v_care_group_id;


    select count(*)::integer

    into v_tahfiz_count_final

    from public.tahfiz_group_members

    where student_id =
          v_student_id

      and tahfiz_group_id =
          v_tahfiz_group_id;


    if v_class_count_final <>
       v_class_count_after then
        raise exception
            'Edit tanpa pindah membuat row kelas tambahan.';
    end if;


    if v_care_count_final <>
       v_care_count_after then
        raise exception
            'Edit tanpa pindah membuat row pengasuhan tambahan.';
    end if;


    if v_tahfiz_count_final <>
       v_tahfiz_count_after then
        raise exception
            'Edit tanpa pindah membuat row tahfiz tambahan.';
    end if;


    -- =====================================================
    -- ACTIVE ROW HARUS TETAP ROW BARU YANG SAMA
    -- =====================================================

    if not exists (
        select 1

        from public.class_enrollments

        where id =
              v_new_class_enrollment_id

          and is_active = true
    ) then
        raise exception
            'Active class row berubah saat edit tanpa pindah.';
    end if;


    if not exists (
        select 1

        from public.care_group_members

        where id =
              v_new_care_membership_id

          and is_active = true
    ) then
        raise exception
            'Active care row berubah saat edit tanpa pindah.';
    end if;


    if not exists (
        select 1

        from public.tahfiz_group_members

        where id =
              v_new_tahfiz_membership_id

          and is_active = true
    ) then
        raise exception
            'Active tahfiz row berubah saat edit tanpa pindah.';
    end if;


    raise notice
        'UNCHANGED PLACEMENT TEST SUCCESS';


    -- =====================================================
    -- FINAL RESULT
    -- =====================================================

    raise notice
        'CLASS PERIOD BEFORE: %, AFTER: %',
        v_class_count_before,
        v_class_count_after;


    raise notice
        'CARE PERIOD BEFORE: %, AFTER: %',
        v_care_count_before,
        v_care_count_after;


    raise notice
        'TAHFIZ PERIOD BEFORE: %, AFTER: %',
        v_tahfiz_count_before,
        v_tahfiz_count_after;


    raise notice
        'STUDENT PLACEMENT HISTORY VERIFICATION SUCCESS';

end;
$verification$;


-- =========================================================
-- 6. ROLLBACK SELURUH DATA TEST
-- =========================================================

rollback;


-- =========================================================
-- 7. FINAL OUTPUT
-- =========================================================

select
    'Perbaikan riwayat placement santri berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;