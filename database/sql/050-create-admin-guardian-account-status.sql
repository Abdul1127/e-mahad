begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 050-create-admin-guardian-account-status.sql
--
-- PURPOSE:
-- - Mengaktifkan atau menonaktifkan profile akun wali
-- - Memastikan akun benar-benar milik wali
-- - Memastikan role guardian tersedia
-- - Membatasi operasi hanya untuk Admin aktif
--
-- CATATAN:
-- - Fungsi ini mengubah profiles.is_active
-- - Pemblokiran Supabase Auth dilakukan oleh Server Action
-- - Data wali dan hubungan santri tidak dihapus
-- =========================================================

create or replace function
public.set_admin_guardian_account_profile_status(
    p_guardian_id uuid,
    p_is_active boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_profile_id uuid;

    v_guardian_full_name text;
    v_guardian_email text;
    v_guardian_is_active boolean;

    v_previous_profile_status boolean;
    v_auth_email text;
begin
    -- =====================================================
    -- 1. VALIDASI SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    -- =====================================================
    -- 2. VALIDASI ROLE ADMIN
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses pengelolaan akun wali ditolak.';
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
    -- 3. VALIDASI PARAMETER
    -- =====================================================

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
    end if;

    if p_is_active is null then
        raise exception
            'Status akun wajib diisi.';
    end if;

    -- =====================================================
    -- 4. KUNCI DAN BACA DATA WALI
    -- =====================================================

    select
        guardian.profile_id,
        guardian.full_name,
        guardian.email,
        guardian.is_active

    into
        v_profile_id,
        v_guardian_full_name,
        v_guardian_email,
        v_guardian_is_active

    from public.guardians as guardian

    where guardian.id = p_guardian_id

    for update;

    if not found then
        raise exception
            'Data wali tidak ditemukan.';
    end if;

    if v_profile_id is null then
        raise exception
            'Wali belum mempunyai akun login.';
    end if;

    -- Wali yang data utamanya tidak aktif
    -- tidak boleh diaktifkan akun loginnya.

    if p_is_active = true
       and v_guardian_is_active is not true then
        raise exception
            'Data wali tidak aktif. Aktifkan data wali terlebih dahulu.';
    end if;

    -- =====================================================
    -- 5. KUNCI DAN VALIDASI PROFILE
    -- =====================================================

    select profile.is_active

    into v_previous_profile_status

    from public.profiles as profile

    where profile.id = v_profile_id

    for update;

    if not found then
        raise exception
            'Profile akun wali tidak ditemukan.';
    end if;

    -- =====================================================
    -- 6. VALIDASI AUTH USER
    -- =====================================================

    select auth_user.email::text

    into v_auth_email

    from auth.users as auth_user

    where auth_user.id = v_profile_id
      and auth_user.deleted_at is null

    limit 1;

    if v_auth_email is null then
        raise exception
            'Auth user akun wali tidak ditemukan.';
    end if;

    -- =====================================================
    -- 7. VALIDASI ROLE GUARDIAN
    -- =====================================================

    if not exists (
        select 1

        from public.user_roles as user_role

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where user_role.user_id =
              v_profile_id

          and role.code =
              'guardian'

          and role.is_active = true
    ) then
        raise exception
            'Role guardian pada akun wali tidak ditemukan.';
    end if;

    -- =====================================================
    -- 8. UPDATE STATUS PROFILE
    -- =====================================================

    update public.profiles

    set
        is_active =
            p_is_active,

        updated_at =
            now()

    where id =
          v_profile_id;

    -- =====================================================
    -- 9. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'operation',
        case
            when p_is_active
                then 'activated'
            else 'deactivated'
        end,

        'guardian_id',
        p_guardian_id,

        'profile_id',
        v_profile_id,

        'full_name',
        v_guardian_full_name,

        'guardian_email',
        v_guardian_email,

        'auth_email',
        v_auth_email,

        'previous_status',
        v_previous_profile_status,

        'is_active',
        p_is_active
    );
end;
$$;


comment on function
public.set_admin_guardian_account_profile_status(
    uuid,
    boolean
)
is
'Mengaktifkan atau menonaktifkan profile akun wali melalui Admin aktif.';


revoke all on function
public.set_admin_guardian_account_profile_status(
    uuid,
    boolean
)
from public;

revoke all on function
public.set_admin_guardian_account_profile_status(
    uuid,
    boolean
)
from anon;

grant execute on function
public.set_admin_guardian_account_profile_status(
    uuid,
    boolean
)
to authenticated;

commit;