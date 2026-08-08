begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 080-create-admin-group-assignment-management.sql
--
-- PURPOSE:
-- - Tambah assignment Pengasuh / Pembina Tahfiz
-- - Akhiri assignment tanpa menghapus riwayat
-- - Ganti Pembina Tahfiz utama
-- - Validasi staf aktif
-- - Validasi akun aktif
-- - Validasi role aplikasi
-- - Hanya Admin aktif
--
-- RULE:
-- CARE:
-- - Tidak menggunakan Pengasuh utama
--
-- TAHFIZ:
-- - Harus memiliki maksimal satu Pembina utama
-- - Assignment pertama otomatis menjadi utama
-- - Pembina utama tidak dapat diakhiri sebelum
--   Pembina lain dijadikan utama
-- =========================================================


-- =========================================================
-- 1. ADD ASSIGNMENT
-- =========================================================

create or replace function
public.add_admin_group_assignment(
    p_group_type text,
    p_group_id uuid,
    p_staff_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_group_type text;

    v_profile_id uuid;

    v_required_role text;

    v_assignment_id uuid;

    v_group_name text;

    v_staff_name text;

    v_is_primary boolean := false;
begin

    -- =====================================================
    -- SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- ADMIN
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses perubahan assignment ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              auth.uid()

          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;


    -- =====================================================
    -- PARAMETER
    -- =====================================================

    if p_group_id is null then
        raise exception
            'Group ID wajib diisi.';
    end if;


    if p_staff_id is null then
        raise exception
            'Staff ID wajib diisi.';
    end if;


    v_group_type :=
        lower(
            btrim(
                coalesce(
                    p_group_type,
                    ''
                )
            )
        );


    if v_group_type not in (
        'care',
        'tahfiz'
    ) then
        raise exception
            'Tipe kelompok tidak valid.';
    end if;


    -- =====================================================
    -- LOCK + VALIDASI STAFF
    -- =====================================================

    select
        staff.profile_id,
        staff.full_name

    into
        v_profile_id,
        v_staff_name

    from public.staff
        as staff

    where staff.id =
          p_staff_id

      and staff.is_active = true

    for update;


    if not found then
        raise exception
            'Staf aktif tidak ditemukan.';
    end if;


    if v_profile_id is null then
        raise exception
            'Staf belum memiliki akun E-Ma''had.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active = true
    ) then
        raise exception
            'Akun staf tidak aktif.';
    end if;


    -- =====================================================
    -- CARE
    -- =====================================================

    if v_group_type = 'care' then

        v_required_role :=
            'pengasuh';


        -- =================================================
        -- LOCK + VALIDASI GROUP
        -- =================================================

        select
            care_group.name

        into
            v_group_name

        from public.care_groups
            as care_group

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               care_group.academic_year_id

        where care_group.id =
              p_group_id

          and care_group.is_active = true

          and academic_year.is_current = true

        for update of care_group;


        if not found then
            raise exception
                'Kelompok pengasuhan aktif tidak ditemukan.';
        end if;


        -- =================================================
        -- ROLE
        -- =================================================

        if not exists (
            select 1

            from public.user_roles
                as user_role

            inner join public.roles
                as role
                on role.id =
                   user_role.role_id

            where user_role.user_id =
                  v_profile_id

              and role.code =
                  v_required_role
        ) then
            raise exception
                'Staf tidak memiliki role Pengasuh.';
        end if;


        -- =================================================
        -- DUPLICATE ACTIVE ASSIGNMENT
        -- =================================================

        if exists (
            select 1

            from public.caregiver_assignments
                as assignment

            where assignment.staff_id =
                  p_staff_id

              and assignment.care_group_id =
                  p_group_id

              and assignment.is_active = true
        ) then
            raise exception
                'Staf sudah aktif sebagai Pengasuh pada kelompok ini.';
        end if;


        -- =================================================
        -- INSERT
        --
        -- Pengasuhan tidak memakai primary.
        -- =================================================

        insert into public.caregiver_assignments (
            staff_id,
            care_group_id,
            is_primary,
            assigned_at,
            ended_at,
            is_active
        )
        values (
            p_staff_id,
            p_group_id,
            false,
            current_date,
            null,
            true
        )

        returning id
        into v_assignment_id;


        return jsonb_build_object(
            'success',
            true,

            'operation',
            'assignment_added',

            'group_type',
            'care',

            'group_id',
            p_group_id,

            'group_name',
            v_group_name,

            'assignment_id',
            v_assignment_id,

            'staff_id',
            p_staff_id,

            'staff_name',
            v_staff_name,

            'is_primary',
            false
        );

    end if;


    -- =====================================================
    -- TAHFIZ
    -- =====================================================

    v_required_role :=
        'pembina_tahfiz';


    -- =====================================================
    -- LOCK + VALIDASI GROUP
    -- =====================================================

    select
        tahfiz_group.name

    into
        v_group_name

    from public.tahfiz_groups
        as tahfiz_group

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           tahfiz_group.academic_year_id

    where tahfiz_group.id =
          p_group_id

      and tahfiz_group.is_active = true

      and academic_year.is_current = true

    for update of tahfiz_group;


    if not found then
        raise exception
            'Kelompok Tahfiz aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- ROLE
    -- =====================================================

    if not exists (
        select 1

        from public.user_roles
            as user_role

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where user_role.user_id =
              v_profile_id

          and role.code =
              v_required_role
    ) then
        raise exception
            'Staf tidak memiliki role Pembina Tahfiz.';
    end if;


    -- =====================================================
    -- DUPLICATE ACTIVE
    -- =====================================================

    if exists (
        select 1

        from public.tahfiz_supervisor_assignments
            as assignment

        where assignment.staff_id =
              p_staff_id

          and assignment.tahfiz_group_id =
              p_group_id

          and assignment.is_active = true
    ) then
        raise exception
            'Staf sudah aktif sebagai Pembina Tahfiz pada kelompok ini.';
    end if;


    -- =====================================================
    -- FIRST SUPERVISOR BECOMES PRIMARY
    -- =====================================================

    v_is_primary :=
        not exists (
            select 1

            from public.tahfiz_supervisor_assignments
                as assignment

            where assignment.tahfiz_group_id =
                  p_group_id

              and assignment.is_active = true

              and assignment.is_primary = true
        );


    -- =====================================================
    -- INSERT
    -- =====================================================

    insert into public.tahfiz_supervisor_assignments (
        staff_id,
        tahfiz_group_id,
        is_primary,
        assigned_at,
        ended_at,
        is_active
    )
    values (
        p_staff_id,
        p_group_id,
        v_is_primary,
        current_date,
        null,
        true
    )

    returning id
    into v_assignment_id;


    return jsonb_build_object(
        'success',
        true,

        'operation',
        'assignment_added',

        'group_type',
        'tahfiz',

        'group_id',
        p_group_id,

        'group_name',
        v_group_name,

        'assignment_id',
        v_assignment_id,

        'staff_id',
        p_staff_id,

        'staff_name',
        v_staff_name,

        'is_primary',
        v_is_primary
    );

end;
$function$;


-- =========================================================
-- 2. END ASSIGNMENT
-- =========================================================

create or replace function
public.end_admin_group_assignment(
    p_group_type text,
    p_assignment_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_group_type text;

    v_group_id uuid;

    v_staff_id uuid;

    v_group_name text;

    v_staff_name text;

    v_is_primary boolean;
begin

    -- =====================================================
    -- SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- ADMIN
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses perubahan assignment ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              auth.uid()

          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;


    -- =====================================================
    -- PARAMETER
    -- =====================================================

    if p_assignment_id is null then
        raise exception
            'Assignment ID wajib diisi.';
    end if;


    v_group_type :=
        lower(
            btrim(
                coalesce(
                    p_group_type,
                    ''
                )
            )
        );


    if v_group_type not in (
        'care',
        'tahfiz'
    ) then
        raise exception
            'Tipe kelompok tidak valid.';
    end if;


    -- =====================================================
    -- CARE
    -- =====================================================

    if v_group_type = 'care' then

        select
            assignment.care_group_id,

            assignment.staff_id,

            care_group.name,

            staff.full_name

        into
            v_group_id,

            v_staff_id,

            v_group_name,

            v_staff_name

        from public.caregiver_assignments
            as assignment

        inner join public.care_groups
            as care_group
            on care_group.id =
               assignment.care_group_id

        inner join public.staff
            as staff
            on staff.id =
               assignment.staff_id

        where assignment.id =
              p_assignment_id

          and assignment.is_active = true

        for update of assignment;


        if not found then
            raise exception
                'Assignment Pengasuh aktif tidak ditemukan.';
        end if;


        update public.caregiver_assignments

        set
            is_active = false,

            is_primary = false,

            ended_at =
                current_date,

            updated_at =
                now()

        where id =
              p_assignment_id;


        return jsonb_build_object(
            'success',
            true,

            'operation',
            'assignment_ended',

            'group_type',
            'care',

            'group_id',
            v_group_id,

            'group_name',
            v_group_name,

            'assignment_id',
            p_assignment_id,

            'staff_id',
            v_staff_id,

            'staff_name',
            v_staff_name,

            'ended_at',
            current_date
        );

    end if;


    -- =====================================================
    -- TAHFIZ
    -- =====================================================

    select
        assignment.tahfiz_group_id,

        assignment.staff_id,

        assignment.is_primary,

        tahfiz_group.name,

        staff.full_name

    into
        v_group_id,

        v_staff_id,

        v_is_primary,

        v_group_name,

        v_staff_name

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           assignment.tahfiz_group_id

    inner join public.staff
        as staff
        on staff.id =
           assignment.staff_id

    where assignment.id =
          p_assignment_id

      and assignment.is_active = true

    for update of assignment;


    if not found then
        raise exception
            'Assignment Pembina Tahfiz aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- PRIMARY CANNOT BE ENDED DIRECTLY
    -- =====================================================

    if v_is_primary = true then
        raise exception
            'Pembina Tahfiz utama tidak dapat diakhiri. Tentukan Pembina utama pengganti terlebih dahulu.';
    end if;


    update public.tahfiz_supervisor_assignments

    set
        is_active = false,

        is_primary = false,

        ended_at =
            current_date,

        updated_at =
            now()

    where id =
          p_assignment_id;


    return jsonb_build_object(
        'success',
        true,

        'operation',
        'assignment_ended',

        'group_type',
        'tahfiz',

        'group_id',
        v_group_id,

        'group_name',
        v_group_name,

        'assignment_id',
        p_assignment_id,

        'staff_id',
        v_staff_id,

        'staff_name',
        v_staff_name,

        'ended_at',
        current_date
    );

end;
$function$;


-- =========================================================
-- 3. SET PRIMARY TAHFIZ SUPERVISOR
-- =========================================================

create or replace function
public.set_admin_tahfiz_primary_assignment(
    p_group_id uuid,
    p_assignment_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_staff_id uuid;

    v_profile_id uuid;

    v_group_name text;

    v_staff_name text;

    v_already_primary boolean;
begin

    -- =====================================================
    -- SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- ADMIN
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses perubahan Pembina utama ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              auth.uid()

          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;


    -- =====================================================
    -- PARAMETER
    -- =====================================================

    if p_group_id is null then
        raise exception
            'Group ID wajib diisi.';
    end if;


    if p_assignment_id is null then
        raise exception
            'Assignment ID wajib diisi.';
    end if;


    -- =====================================================
    -- LOCK GROUP
    -- =====================================================

    select
        tahfiz_group.name

    into
        v_group_name

    from public.tahfiz_groups
        as tahfiz_group

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           tahfiz_group.academic_year_id

    where tahfiz_group.id =
          p_group_id

      and tahfiz_group.is_active = true

      and academic_year.is_current = true

    for update of tahfiz_group;


    if not found then
        raise exception
            'Kelompok Tahfiz aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- TARGET ASSIGNMENT
    -- =====================================================

    select
        assignment.staff_id,

        assignment.is_primary,

        staff.profile_id,

        staff.full_name

    into
        v_staff_id,

        v_already_primary,

        v_profile_id,

        v_staff_name

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.staff
        as staff
        on staff.id =
           assignment.staff_id

    where assignment.id =
          p_assignment_id

      and assignment.tahfiz_group_id =
          p_group_id

      and assignment.is_active = true

      and staff.is_active = true

    for update of assignment;


    if not found then
        raise exception
            'Assignment Pembina Tahfiz aktif tidak ditemukan pada kelompok ini.';
    end if;


    -- =====================================================
    -- ACCOUNT
    -- =====================================================

    if v_profile_id is null then
        raise exception
            'Pembina belum memiliki akun E-Ma''had.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active = true
    ) then
        raise exception
            'Akun Pembina Tahfiz tidak aktif.';
    end if;


    -- =====================================================
    -- ROLE
    -- =====================================================

    if not exists (
        select 1

        from public.user_roles
            as user_role

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where user_role.user_id =
              v_profile_id

          and role.code =
              'pembina_tahfiz'
    ) then
        raise exception
            'Staf tidak memiliki role Pembina Tahfiz.';
    end if;


    -- =====================================================
    -- ALREADY PRIMARY
    -- =====================================================

    if v_already_primary = true then
        return jsonb_build_object(
            'success',
            true,

            'operation',
            'primary_unchanged',

            'group_id',
            p_group_id,

            'group_name',
            v_group_name,

            'assignment_id',
            p_assignment_id,

            'staff_id',
            v_staff_id,

            'staff_name',
            v_staff_name,

            'is_primary',
            true
        );
    end if;


    -- =====================================================
    -- DEMOTE OLD PRIMARY
    -- =====================================================

    update public.tahfiz_supervisor_assignments

    set
        is_primary = false,

        updated_at = now()

    where tahfiz_group_id =
          p_group_id

      and is_active = true

      and is_primary = true;


    -- =====================================================
    -- PROMOTE TARGET
    -- =====================================================

    update public.tahfiz_supervisor_assignments

    set
        is_primary = true,

        updated_at = now()

    where id =
          p_assignment_id;


    return jsonb_build_object(
        'success',
        true,

        'operation',
        'primary_changed',

        'group_id',
        p_group_id,

        'group_name',
        v_group_name,

        'assignment_id',
        p_assignment_id,

        'staff_id',
        v_staff_id,

        'staff_name',
        v_staff_name,

        'is_primary',
        true
    );

end;
$function$;


-- =========================================================
-- 4. COMMENTS
-- =========================================================

comment on function
public.add_admin_group_assignment(
    text,
    uuid,
    uuid
)
is
'Menambahkan assignment aktif Pengasuh atau Pembina Tahfiz. Riwayat assignment lama tidak digunakan kembali.';


comment on function
public.end_admin_group_assignment(
    text,
    uuid
)
is
'Mengakhiri assignment aktif dan mempertahankan row sebagai riwayat. Pembina Tahfiz utama harus diganti terlebih dahulu.';


comment on function
public.set_admin_tahfiz_primary_assignment(
    uuid,
    uuid
)
is
'Menentukan satu assignment aktif sebagai Pembina Tahfiz utama dan menurunkan status primary sebelumnya.';


-- =========================================================
-- 5. PRIVILEGES
-- =========================================================

revoke all on function
public.add_admin_group_assignment(
    text,
    uuid,
    uuid
)
from public;

revoke all on function
public.add_admin_group_assignment(
    text,
    uuid,
    uuid
)
from anon;

grant execute on function
public.add_admin_group_assignment(
    text,
    uuid,
    uuid
)
to authenticated;


revoke all on function
public.end_admin_group_assignment(
    text,
    uuid
)
from public;

revoke all on function
public.end_admin_group_assignment(
    text,
    uuid
)
from anon;

grant execute on function
public.end_admin_group_assignment(
    text,
    uuid
)
to authenticated;


revoke all on function
public.set_admin_tahfiz_primary_assignment(
    uuid,
    uuid
)
from public;

revoke all on function
public.set_admin_tahfiz_primary_assignment(
    uuid,
    uuid
)
from anon;

grant execute on function
public.set_admin_tahfiz_primary_assignment(
    uuid,
    uuid
)
to authenticated;


commit;