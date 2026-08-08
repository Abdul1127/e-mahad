-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 081-verify-admin-group-assignment-management.sql
--
-- PURPOSE:
-- - Verifikasi fungsi write assignment Admin
-- - Test tambah Pengasuh
-- - Test akhiri Pengasuh
-- - Test tambah Pembina Tahfiz
-- - Test ganti Pembina utama
-- - Test akhiri Pembina non-primary
-- - Pastikan primary tidak bisa diakhiri langsung
-- - Pastikan duplicate active assignment ditolak
--
-- SEMUA DATA TEST DI-ROLLBACK
-- =========================================================


-- =========================================================
-- 1. VERIFY FUNCTIONS + PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.add_admin_group_assignment(text,uuid,uuid)'
    ) is not null
        as add_function_exists,

    to_regprocedure(
        'public.end_admin_group_assignment(text,uuid)'
    ) is not null
        as end_function_exists,

    to_regprocedure(
        'public.set_admin_tahfiz_primary_assignment(uuid,uuid)'
    ) is not null
        as primary_function_exists,

    has_function_privilege(
        'authenticated',
        'public.add_admin_group_assignment(text,uuid,uuid)',
        'execute'
    ) as authenticated_can_add,

    has_function_privilege(
        'authenticated',
        'public.end_admin_group_assignment(text,uuid)',
        'execute'
    ) as authenticated_can_end,

    has_function_privilege(
        'authenticated',
        'public.set_admin_tahfiz_primary_assignment(uuid,uuid)',
        'execute'
    ) as authenticated_can_set_primary,

    has_function_privilege(
        'anon',
        'public.add_admin_group_assignment(text,uuid,uuid)',
        'execute'
    ) as anon_can_add,

    has_function_privilege(
        'anon',
        'public.end_admin_group_assignment(text,uuid)',
        'execute'
    ) as anon_can_end,

    has_function_privilege(
        'anon',
        'public.set_admin_tahfiz_primary_assignment(uuid,uuid)',
        'execute'
    ) as anon_can_set_primary;


-- =========================================================
-- 2. START TEST TRANSACTION
-- =========================================================

begin;


-- =========================================================
-- 3. EMULASI ADMIN
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
-- 4. WRITE VERIFICATION
-- =========================================================

do $verification$
declare

    -- =====================================================
    -- CARE
    -- =====================================================

    v_care_group_id uuid;
    v_care_group_name text;

    v_care_candidate_staff_id uuid;
    v_care_candidate_name text;

    v_care_added_result jsonb;
    v_care_assignment_id uuid;

    v_care_active_before integer;
    v_care_active_after_add integer;
    v_care_active_after_end integer;


    -- =====================================================
    -- TAHFIZ
    -- =====================================================

    v_tahfiz_group_id uuid;
    v_tahfiz_group_name text;

    v_old_primary_assignment_id uuid;
    v_old_primary_staff_id uuid;
    v_old_primary_name text;

    v_new_staff_id uuid;
    v_new_staff_name text;

    v_tahfiz_added_result jsonb;
    v_new_assignment_id uuid;

    v_tahfiz_active_before integer;
    v_tahfiz_active_after_add integer;

    v_primary_count integer;

begin

    -- =====================================================
    -- 4A. CARE TARGET
    -- =====================================================

    select
        care_group.id,
        care_group.name

    into
        v_care_group_id,
        v_care_group_name

    from public.care_groups
        as care_group

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

    where care_group.is_active = true
      and academic_year.is_current = true

    order by
        care_group.name,
        care_group.id

    limit 1;


    if v_care_group_id is null then
        raise exception
            'Kelompok Pengasuhan aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- CARE CANDIDATE
    --
    -- Harus:
    -- - staff aktif
    -- - profile aktif
    -- - role pengasuh
    -- - belum aktif pada target group
    -- =====================================================

    select
        staff.id,
        staff.full_name

    into
        v_care_candidate_staff_id,
        v_care_candidate_name

    from public.staff
        as staff

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    where staff.is_active = true
      and profile.is_active = true

      and exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'pengasuh'
      )

      and not exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.staff_id =
                staff.id

            and assignment.care_group_id =
                v_care_group_id

            and assignment.is_active = true
      )

    order by
        staff.full_name,
        staff.id

    limit 1;


    if v_care_candidate_staff_id is null then
        raise exception
            'Tidak ditemukan kandidat Pengasuh untuk simulasi.';
    end if;


    select count(*)::integer

    into v_care_active_before

    from public.caregiver_assignments

    where care_group_id =
          v_care_group_id

      and is_active = true;


    -- =====================================================
    -- ADD CARE ASSIGNMENT
    -- =====================================================

    v_care_added_result :=
        public.add_admin_group_assignment(
            'care',
            v_care_group_id,
            v_care_candidate_staff_id
        );


    v_care_assignment_id :=
        (
            v_care_added_result
            ->> 'assignment_id'
        )::uuid;


    if v_care_assignment_id is null then
        raise exception
            'Tambah Pengasuh tidak menghasilkan assignment_id.';
    end if;


    if (
        v_care_added_result
        ->> 'operation'
    ) <> 'assignment_added' then
        raise exception
            'Operation tambah Pengasuh tidak sesuai.';
    end if;


    if (
        v_care_added_result
        ->> 'is_primary'
    )::boolean <> false then
        raise exception
            'Assignment Pengasuh tidak boleh primary.';
    end if;


    if not exists (
        select 1

        from public.caregiver_assignments

        where id =
              v_care_assignment_id

          and staff_id =
              v_care_candidate_staff_id

          and care_group_id =
              v_care_group_id

          and is_active = true

          and is_primary = false

          and ended_at is null
    ) then
        raise exception
            'Assignment Pengasuh baru tidak tersimpan dengan benar.';
    end if;


    select count(*)::integer

    into v_care_active_after_add

    from public.caregiver_assignments

    where care_group_id =
          v_care_group_id

      and is_active = true;


    if v_care_active_after_add <>
       v_care_active_before + 1 then
        raise exception
            'Jumlah Pengasuh aktif tidak bertambah 1.';
    end if;


    raise notice
        'CARE ADD SUCCESS: % -> %',
        v_care_candidate_name,
        v_care_group_name;


    -- =====================================================
    -- DUPLICATE ACTIVE CARE MUST FAIL
    -- =====================================================

    begin

        perform
            public.add_admin_group_assignment(
                'care',
                v_care_group_id,
                v_care_candidate_staff_id
            );

        raise exception
            'Duplicate assignment Pengasuh tidak ditolak.';

    exception
        when others then

            if sqlerrm not ilike
               '%sudah aktif sebagai Pengasuh%'
            then
                raise;
            end if;

    end;


    raise notice
        'CARE DUPLICATE PROTECTION SUCCESS';


    -- =====================================================
    -- END CARE ASSIGNMENT
    -- =====================================================

    perform
        public.end_admin_group_assignment(
            'care',
            v_care_assignment_id
        );


    if not exists (
        select 1

        from public.caregiver_assignments

        where id =
              v_care_assignment_id

          and is_active = false

          and is_primary = false

          and ended_at is not null
    ) then
        raise exception
            'Assignment Pengasuh tidak menjadi history.';
    end if;


    select count(*)::integer

    into v_care_active_after_end

    from public.caregiver_assignments

    where care_group_id =
          v_care_group_id

      and is_active = true;


    if v_care_active_after_end <>
       v_care_active_before then
        raise exception
            'Jumlah Pengasuh aktif tidak kembali ke kondisi awal.';
    end if;


    raise notice
        'CARE END/HISTORY SUCCESS';


    -- =====================================================
    -- 4B. TAHFIZ TARGET
    --
    -- Pilih kelompok yang sudah punya primary.
    -- =====================================================

    select
        tahfiz_group.id,
        tahfiz_group.name,
        assignment.id,
        assignment.staff_id,
        staff.full_name

    into
        v_tahfiz_group_id,
        v_tahfiz_group_name,
        v_old_primary_assignment_id,
        v_old_primary_staff_id,
        v_old_primary_name

    from public.tahfiz_groups
        as tahfiz_group

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           tahfiz_group.academic_year_id

    inner join public.tahfiz_supervisor_assignments
        as assignment
        on assignment.tahfiz_group_id =
           tahfiz_group.id

       and assignment.is_active = true

       and assignment.is_primary = true

    inner join public.staff
        as staff
        on staff.id =
           assignment.staff_id

    where tahfiz_group.is_active = true
      and academic_year.is_current = true

    order by
        tahfiz_group.grade_level,
        tahfiz_group.gender,
        tahfiz_group.name,
        tahfiz_group.id

    limit 1;


    if v_tahfiz_group_id is null then
        raise exception
            'Kelompok Tahfiz dengan Pembina utama tidak ditemukan.';
    end if;


    -- =====================================================
    -- TAHFIZ CANDIDATE
    -- =====================================================

    select
        staff.id,
        staff.full_name

    into
        v_new_staff_id,
        v_new_staff_name

    from public.staff
        as staff

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    where staff.is_active = true
      and profile.is_active = true

      and exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'pembina_tahfiz'
      )

      and not exists (
          select 1

          from public.tahfiz_supervisor_assignments
              as assignment

          where assignment.staff_id =
                staff.id

            and assignment.tahfiz_group_id =
                v_tahfiz_group_id

            and assignment.is_active = true
      )

    order by
        staff.full_name,
        staff.id

    limit 1;


    if v_new_staff_id is null then
        raise exception
            'Tidak ditemukan kandidat Pembina Tahfiz untuk simulasi.';
    end if;


    select count(*)::integer

    into v_tahfiz_active_before

    from public.tahfiz_supervisor_assignments

    where tahfiz_group_id =
          v_tahfiz_group_id

      and is_active = true;


    -- =====================================================
    -- ADD TAHFIZ ASSIGNMENT
    --
    -- Karena target sudah punya primary,
    -- assignment baru HARUS non-primary.
    -- =====================================================

    v_tahfiz_added_result :=
        public.add_admin_group_assignment(
            'tahfiz',
            v_tahfiz_group_id,
            v_new_staff_id
        );


    v_new_assignment_id :=
        (
            v_tahfiz_added_result
            ->> 'assignment_id'
        )::uuid;


    if v_new_assignment_id is null then
        raise exception
            'Tambah Pembina tidak menghasilkan assignment_id.';
    end if;


    if (
        v_tahfiz_added_result
        ->> 'operation'
    ) <> 'assignment_added' then
        raise exception
            'Operation tambah Pembina tidak sesuai.';
    end if;


    if (
        v_tahfiz_added_result
        ->> 'is_primary'
    )::boolean <> false then
        raise exception
            'Pembina baru seharusnya belum menjadi primary.';
    end if;


    select count(*)::integer

    into v_tahfiz_active_after_add

    from public.tahfiz_supervisor_assignments

    where tahfiz_group_id =
          v_tahfiz_group_id

      and is_active = true;


    if v_tahfiz_active_after_add <>
       v_tahfiz_active_before + 1 then
        raise exception
            'Jumlah Pembina aktif tidak bertambah 1.';
    end if;


    select count(*)::integer

    into v_primary_count

    from public.tahfiz_supervisor_assignments

    where tahfiz_group_id =
          v_tahfiz_group_id

      and is_active = true

      and is_primary = true;


    if v_primary_count <> 1 then
        raise exception
            'Setelah tambah Pembina, jumlah primary bukan 1.';
    end if;


    raise notice
        'TAHFIZ ADD SUCCESS: % -> %',
        v_new_staff_name,
        v_tahfiz_group_name;


    -- =====================================================
    -- PRIMARY CANNOT BE ENDED DIRECTLY
    --
    -- Sebelum diganti, primary lama harus ditolak.
    -- =====================================================

    begin

        perform
            public.end_admin_group_assignment(
                'tahfiz',
                v_old_primary_assignment_id
            );

        raise exception
            'Pembina primary dapat diakhiri langsung.';

    exception
        when others then

            if sqlerrm not ilike
               '%Pembina Tahfiz utama tidak dapat diakhiri%'
            then
                raise;
            end if;

    end;


    raise notice
        'TAHFIZ PRIMARY END PROTECTION SUCCESS';


    -- =====================================================
    -- PROMOTE NEW SUPERVISOR
    -- =====================================================

    perform
        public.set_admin_tahfiz_primary_assignment(
            v_tahfiz_group_id,
            v_new_assignment_id
        );


    if not exists (
        select 1

        from public.tahfiz_supervisor_assignments

        where id =
              v_new_assignment_id

          and is_active = true

          and is_primary = true
    ) then
        raise exception
            'Pembina baru gagal menjadi primary.';
    end if;


    if not exists (
        select 1

        from public.tahfiz_supervisor_assignments

        where id =
              v_old_primary_assignment_id

          and is_active = true

          and is_primary = false
    ) then
        raise exception
            'Primary lama gagal diturunkan.';
    end if;


    select count(*)::integer

    into v_primary_count

    from public.tahfiz_supervisor_assignments

    where tahfiz_group_id =
          v_tahfiz_group_id

      and is_active = true

      and is_primary = true;


    if v_primary_count <> 1 then
        raise exception
            'Setelah pergantian, jumlah primary bukan tepat 1.';
    end if;


    raise notice
        'TAHFIZ PRIMARY CHANGE SUCCESS: % -> %',
        v_old_primary_name,
        v_new_staff_name;


    -- =====================================================
    -- END OLD PRIMARY AFTER DEMOTION
    --
    -- Sekarang sudah non-primary sehingga boleh diakhiri.
    -- =====================================================

    perform
        public.end_admin_group_assignment(
            'tahfiz',
            v_old_primary_assignment_id
        );


    if not exists (
        select 1

        from public.tahfiz_supervisor_assignments

        where id =
              v_old_primary_assignment_id

          and is_active = false

          and is_primary = false

          and ended_at is not null
    ) then
        raise exception
            'Primary lama gagal disimpan sebagai riwayat.';
    end if;


    raise notice
        'TAHFIZ OLD PRIMARY HISTORY SUCCESS';


    -- =====================================================
    -- NEW PRIMARY STILL CANNOT BE ENDED
    -- =====================================================

    begin

        perform
            public.end_admin_group_assignment(
                'tahfiz',
                v_new_assignment_id
            );

        raise exception
            'Primary baru dapat diakhiri langsung.';

    exception
        when others then

            if sqlerrm not ilike
               '%Pembina Tahfiz utama tidak dapat diakhiri%'
            then
                raise;
            end if;

    end;


    raise notice
        'TAHFIZ NEW PRIMARY PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL TAHFIZ PRIMARY COUNT
    -- =====================================================

    select count(*)::integer

    into v_primary_count

    from public.tahfiz_supervisor_assignments

    where tahfiz_group_id =
          v_tahfiz_group_id

      and is_active = true

      and is_primary = true;


    if v_primary_count <> 1 then
        raise exception
            'Kondisi akhir test Tahfiz tidak memiliki tepat satu primary.';
    end if;


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'CARE TEST GROUP: %',
        v_care_group_name;


    raise notice
        'CARE TEMP STAFF: %',
        v_care_candidate_name;


    raise notice
        'TAHFIZ TEST GROUP: %',
        v_tahfiz_group_name;


    raise notice
        'TAHFIZ OLD PRIMARY: %',
        v_old_primary_name;


    raise notice
        'TAHFIZ TEMP PRIMARY: %',
        v_new_staff_name;


    raise notice
        'GROUP ASSIGNMENT MANAGEMENT VERIFICATION SUCCESS';

end;
$verification$;


-- =========================================================
-- 5. ROLLBACK ALL TEST CHANGES
-- =========================================================

rollback;


-- =========================================================
-- 6. FINAL OUTPUT
-- =========================================================

select
    'Kelola Assignment Admin berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;