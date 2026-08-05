begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 024-create-staff-account-provisioning.sql
-- PURPOSE:
-- - Menghubungkan akun Supabase Auth dengan data staff
-- - Memperbarui profile berdasarkan data staff
-- - Memberikan satu atau beberapa role
-- - Hanya digunakan melalui Supabase SQL Editor
-- =========================================================

create or replace function public.provision_staff_account(
    p_user_email text,
    p_legacy_staff_id text,
    p_role_codes text[],
    p_assigned_by_email text default 'admin@emahad.id'
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_normalized_email text;
    v_normalized_staff_id text;
    v_normalized_assigner_email text;

    v_target_user_id uuid;
    v_assigned_by_user_id uuid;
    v_target_staff_id uuid;
    v_existing_staff_id uuid;
    v_existing_profile_id uuid;

    v_staff_full_name text;
    v_staff_phone text;

    v_role_codes text[];
    v_requested_role_count integer;
    v_found_role_count integer;

    v_missing_role_codes text;
    v_linked_roles jsonb;
begin
    -- =====================================================
    -- NORMALISASI INPUT
    -- =====================================================

    v_normalized_email := lower(btrim(p_user_email));
    v_normalized_staff_id := btrim(p_legacy_staff_id);
    v_normalized_assigner_email :=
        lower(btrim(p_assigned_by_email));

    if v_normalized_email is null
       or v_normalized_email = '' then
        raise exception
            'Email akun pengguna wajib diisi.';
    end if;

    if v_normalized_staff_id is null
       or v_normalized_staff_id = '' then
        raise exception
            'Legacy staff ID wajib diisi.';
    end if;

    if v_normalized_assigner_email is null
       or v_normalized_assigner_email = '' then
        raise exception
            'Email pemberi role wajib diisi.';
    end if;

    select array_agg(
        distinct lower(btrim(role_code))
        order by lower(btrim(role_code))
    )
    into v_role_codes
    from unnest(p_role_codes) as input_role(role_code)
    where nullif(btrim(role_code), '') is not null;

    v_requested_role_count :=
        coalesce(cardinality(v_role_codes), 0);

    if v_requested_role_count = 0 then
        raise exception
            'Minimal satu role harus diberikan.';
    end if;

    -- =====================================================
    -- CARI AKUN AUTH TARGET
    -- =====================================================

    select auth_user.id
    into v_target_user_id
    from auth.users as auth_user
    where lower(auth_user.email) = v_normalized_email
    limit 1;

    if v_target_user_id is null then
        raise exception
            'Akun Auth dengan email % tidak ditemukan.',
            v_normalized_email;
    end if;

    -- =====================================================
    -- CARI AKUN ADMIN PEMBERI ROLE
    -- =====================================================

    select auth_user.id
    into v_assigned_by_user_id
    from auth.users as auth_user
    where lower(auth_user.email) =
          v_normalized_assigner_email
    limit 1;

    if v_assigned_by_user_id is null then
        raise exception
            'Akun pemberi role dengan email % tidak ditemukan.',
            v_normalized_assigner_email;
    end if;

    if not exists (
        select 1
        from public.user_roles as user_role
        inner join public.roles as role
            on role.id = user_role.role_id
        inner join public.profiles as profile
            on profile.id = user_role.user_id
        where user_role.user_id = v_assigned_by_user_id
          and role.code = 'admin'
          and role.is_active = true
          and profile.is_active = true
    ) then
        raise exception
            'Akun % bukan Admin aktif.',
            v_normalized_assigner_email;
    end if;

    -- =====================================================
    -- CARI DATA STAFF
    -- =====================================================

    select
        staff.id,
        staff.full_name,
        staff.phone,
        staff.profile_id
    into
        v_target_staff_id,
        v_staff_full_name,
        v_staff_phone,
        v_existing_profile_id
    from public.staff as staff
    where staff.legacy_staff_id = v_normalized_staff_id
      and staff.is_active = true
    limit 1;

    if v_target_staff_id is null then
        raise exception
            'Staff aktif dengan ID % tidak ditemukan.',
            v_normalized_staff_id;
    end if;

    -- Staff tidak boleh terhubung ke akun lain.
    if v_existing_profile_id is not null
       and v_existing_profile_id <> v_target_user_id then
        raise exception
            'Staff % sudah terhubung dengan akun lain.',
            v_normalized_staff_id;
    end if;

    -- Akun tidak boleh terhubung ke staff lain.
    select staff.id
    into v_existing_staff_id
    from public.staff as staff
    where staff.profile_id = v_target_user_id
      and staff.id <> v_target_staff_id
    limit 1;

    if v_existing_staff_id is not null then
        raise exception
            'Akun % sudah terhubung dengan data staff lain.',
            v_normalized_email;
    end if;

    -- =====================================================
    -- VALIDASI ROLE
    -- =====================================================

    select count(*)
    into v_found_role_count
    from public.roles as role
    where role.code = any(v_role_codes)
      and role.is_active = true;

    if v_found_role_count <> v_requested_role_count then
        select string_agg(
            requested_role.code,
            ', '
            order by requested_role.code
        )
        into v_missing_role_codes
        from unnest(v_role_codes)
            as requested_role(code)
        where not exists (
            select 1
            from public.roles as role
            where role.code = requested_role.code
              and role.is_active = true
        );

        raise exception
            'Role berikut tidak ditemukan atau tidak aktif: %.',
            coalesce(v_missing_role_codes, '-');
    end if;

    -- =====================================================
    -- PASTIKAN PROFILE TERSEDIA
    -- =====================================================

    insert into public.profiles (
        id,
        full_name,
        phone,
        is_active
    )
    values (
        v_target_user_id,
        v_staff_full_name,
        v_staff_phone,
        true
    )
    on conflict (id)
    do update set
        full_name = excluded.full_name,
        phone = coalesce(
            public.profiles.phone,
            excluded.phone
        ),
        is_active = true,
        updated_at = now();

    -- =====================================================
    -- HUBUNGKAN PROFILE DENGAN STAFF
    -- =====================================================

    update public.staff
    set
        profile_id = v_target_user_id,
        updated_at = now()
    where id = v_target_staff_id;

    -- =====================================================
    -- BERIKAN ROLE
    -- =====================================================

    insert into public.user_roles (
        user_id,
        role_id,
        assigned_by
    )
    select
        v_target_user_id,
        role.id,
        v_assigned_by_user_id
    from public.roles as role
    where role.code = any(v_role_codes)
      and role.is_active = true

    on conflict (user_id, role_id)
    do update set
        assigned_by = excluded.assigned_by;

    -- =====================================================
    -- HASIL PROVISIONING
    -- =====================================================

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'code',
                role.code,

                'name',
                role.name
            )
            order by role.code
        ),
        '[]'::jsonb
    )
    into v_linked_roles
    from public.user_roles as user_role
    inner join public.roles as role
        on role.id = user_role.role_id
    where user_role.user_id = v_target_user_id
      and role.is_active = true;

    return jsonb_build_object(
        'success',
        true,

        'email',
        v_normalized_email,

        'user_id',
        v_target_user_id,

        'staff_id',
        v_target_staff_id,

        'legacy_staff_id',
        v_normalized_staff_id,

        'full_name',
        v_staff_full_name,

        'roles',
        v_linked_roles
    );
end;
$$;

comment on function public.provision_staff_account(
    text,
    text,
    text[],
    text
) is
'Menghubungkan akun Supabase Auth dengan staff dan memberikan role melalui SQL Editor.';

-- Fungsi ini tidak boleh dijalankan dari aplikasi.
revoke all on function public.provision_staff_account(
    text,
    text,
    text[],
    text
) from public;

revoke all on function public.provision_staff_account(
    text,
    text,
    text[],
    text
) from anon;

revoke all on function public.provision_staff_account(
    text,
    text,
    text[],
    text
) from authenticated;

commit;