begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 066-create-admin-staff-account-management-functions.sql
--
-- PURPOSE:
-- - Mengubah status aktif profile akun staf
-- - Mengganti seluruh role aplikasi staf
-- - Minimal satu role staf harus tetap tersedia
-- - Role admin dan guardian tidak dapat diberikan
-- - Menggunakan struktur aktual user_roles:
--   id, user_id, role_id, assigned_by, created_at
-- =========================================================


-- =========================================================
-- 1. STATUS PROFILE AKUN STAF
-- =========================================================

create or replace function
public.set_admin_staff_account_profile_status(
    p_staff_id uuid,
    p_is_active boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_full_name text;
    v_staff_is_active boolean;
begin
    -- =====================================================
    -- A. VALIDASI ADMIN
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses pengelolaan akun staf ditolak.';
    end if;

    if not exists (
        select 1
        from public.profiles as profile
        where profile.id = auth.uid()
          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;

    -- =====================================================
    -- B. VALIDASI PARAMETER
    -- =====================================================

    if p_staff_id is null then
        raise exception
            'Staff ID wajib diisi.';
    end if;

    if p_is_active is null then
        raise exception
            'Status akun wajib diisi.';
    end if;

    -- =====================================================
    -- C. KUNCI DATA STAF
    -- =====================================================

    select
        staff.profile_id,
        staff.full_name,
        staff.is_active

    into
        v_profile_id,
        v_full_name,
        v_staff_is_active

    from public.staff as staff

    where staff.id = p_staff_id

    for update;

    if not found then
        raise exception
            'Data staf tidak ditemukan.';
    end if;

    if v_profile_id is null then
        raise exception
            'Staf belum mempunyai akun login.';
    end if;

    -- Akun tidak boleh diaktifkan jika data staf nonaktif.
    if p_is_active = true
       and v_staff_is_active is not true then
        raise exception
            'Data staf tidak aktif. Aktifkan data staf terlebih dahulu.';
    end if;

    if not exists (
        select 1

        from public.profiles as profile

        where profile.id =
              v_profile_id
    ) then
        raise exception
            'Profile akun staf tidak ditemukan.';
    end if;

    -- =====================================================
    -- D. UPDATE PROFILE
    -- =====================================================

    update public.profiles

    set
        is_active =
            p_is_active,

        updated_at =
            now()

    where id =
          v_profile_id;

    return jsonb_build_object(
        'success',
        true,

        'staff_id',
        p_staff_id,

        'profile_id',
        v_profile_id,

        'full_name',
        v_full_name,

        'is_active',
        p_is_active
    );
end;
$function$;


comment on function
public.set_admin_staff_account_profile_status(
    uuid,
    boolean
)
is
'Mengubah status aktif profile akun staf melalui Admin aktif.';


-- =========================================================
-- 2. KELOLA ROLE AKUN STAF
-- =========================================================

create or replace function
public.set_admin_staff_roles(
    p_staff_id uuid,
    p_role_codes text[]
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_full_name text;

    v_role_codes text[];

    v_requested_role_count integer;
    v_found_role_count integer;

    v_invalid_role_codes text;

    v_roles jsonb;
begin
    -- =====================================================
    -- A. VALIDASI ADMIN
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses pengelolaan role staf ditolak.';
    end if;

    if not exists (
        select 1

        from public.profiles as profile

        where profile.id = auth.uid()
          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;

    -- =====================================================
    -- B. VALIDASI STAFF ID
    -- =====================================================

    if p_staff_id is null then
        raise exception
            'Staff ID wajib diisi.';
    end if;

    -- =====================================================
    -- C. NORMALISASI ROLE
    -- =====================================================

    select
        array_agg(
            normalized_role.code
            order by normalized_role.code
        )

    into
        v_role_codes

    from (
        select distinct
            lower(
                btrim(
                    input_role.role_code
                )
            ) as code

        from unnest(
            coalesce(
                p_role_codes,
                array[]::text[]
            )
        ) as input_role(role_code)

        where nullif(
            btrim(
                input_role.role_code
            ),
            ''
        ) is not null
    ) as normalized_role;

    v_requested_role_count :=
        coalesce(
            cardinality(
                v_role_codes
            ),
            0
        );

    if v_requested_role_count = 0 then
        raise exception
            'Minimal satu role staf harus dipilih.';
    end if;

    -- =====================================================
    -- D. KUNCI DATA STAF
    -- =====================================================

    select
        staff.profile_id,
        staff.full_name

    into
        v_profile_id,
        v_full_name

    from public.staff as staff

    where staff.id =
          p_staff_id

    for update;

    if not found then
        raise exception
            'Data staf tidak ditemukan.';
    end if;

    if v_profile_id is null then
        raise exception
            'Staf belum mempunyai akun login.';
    end if;

    if not exists (
        select 1

        from public.profiles as profile

        where profile.id =
              v_profile_id
    ) then
        raise exception
            'Profile akun staf tidak ditemukan.';
    end if;

    -- =====================================================
    -- E. VALIDASI ROLE
    -- =====================================================

    select
        count(*)::integer

    into
        v_found_role_count

    from public.roles as role

    where role.code =
          any(v_role_codes)

      and role.is_active =
          true

      and role.code not in (
          'admin',
          'guardian'
      );

    if v_found_role_count <>
       v_requested_role_count then

        select
            string_agg(
                requested_role.code,
                ', '
                order by requested_role.code
            )

        into
            v_invalid_role_codes

        from unnest(
            v_role_codes
        ) as requested_role(code)

        where not exists (
            select 1

            from public.roles as role

            where role.code =
                  requested_role.code

              and role.is_active =
                  true

              and role.code not in (
                  'admin',
                  'guardian'
              )
        );

        raise exception
            'Role staf tidak valid atau tidak aktif: %.',
            coalesce(
                v_invalid_role_codes,
                '-'
            );
    end if;

    -- =====================================================
    -- F. HAPUS ROLE STAF YANG TIDAK DIPILIH
    -- =====================================================
    --
    -- Role admin/guardian sengaja tidak disentuh.
    -- Fungsi ini hanya mengelola role operasional staf.
    -- =====================================================

    delete from public.user_roles
        as user_role

    using public.roles
        as role

    where user_role.user_id =
          v_profile_id

      and role.id =
          user_role.role_id

      and role.code not in (
          'admin',
          'guardian'
      )

      and not (
          role.code =
          any(v_role_codes)
      );

    -- =====================================================
    -- G. TAMBAHKAN / PERBARUI ROLE TERPILIH
    -- =====================================================

    insert into public.user_roles (
        user_id,
        role_id,
        assigned_by
    )

    select
        v_profile_id,
        role.id,
        auth.uid()

    from public.roles as role

    where role.code =
          any(v_role_codes)

      and role.is_active =
          true

      and role.code not in (
          'admin',
          'guardian'
      )

    on conflict (
        user_id,
        role_id
    )
    do update set
        assigned_by =
            excluded.assigned_by;

    -- =====================================================
    -- H. RESPONSE ROLE AKHIR
    -- =====================================================

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'code',
                role.code,

                'name',
                role.name,

                'assigned_by',
                user_role.assigned_by,

                'created_at',
                user_role.created_at
            )

            order by
                role.name,
                role.code
        ),
        '[]'::jsonb
    )

    into
        v_roles

    from public.user_roles as user_role

    inner join public.roles as role
        on role.id =
           user_role.role_id

    where user_role.user_id =
          v_profile_id

      and role.is_active =
          true

      and role.code not in (
          'admin',
          'guardian'
      );

    return jsonb_build_object(
        'success',
        true,

        'staff_id',
        p_staff_id,

        'profile_id',
        v_profile_id,

        'full_name',
        v_full_name,

        'roles',
        v_roles
    );
end;
$function$;


comment on function
public.set_admin_staff_roles(
    uuid,
    text[]
)
is
'Mengganti role operasional akun staf. Minimal satu role wajib tersedia.';


-- =========================================================
-- 3. PRIVILEGES
-- =========================================================

revoke all on function
public.set_admin_staff_account_profile_status(
    uuid,
    boolean
)
from public;

revoke all on function
public.set_admin_staff_account_profile_status(
    uuid,
    boolean
)
from anon;

grant execute on function
public.set_admin_staff_account_profile_status(
    uuid,
    boolean
)
to authenticated;


revoke all on function
public.set_admin_staff_roles(
    uuid,
    text[]
)
from public;

revoke all on function
public.set_admin_staff_roles(
    uuid,
    text[]
)
from anon;

grant execute on function
public.set_admin_staff_roles(
    uuid,
    text[]
)
to authenticated;

commit;