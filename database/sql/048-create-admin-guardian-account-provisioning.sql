begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 048-create-admin-guardian-account-provisioning.sql
--
-- PURPOSE:
-- - Menghubungkan Auth user yang sudah tersedia
--   dengan data wali
-- - Menyelaraskan profiles
-- - Memberikan role guardian
-- - Mencegah satu akun digunakan oleh dua data wali
-- - Memastikan email Auth sama dengan email data wali
--
-- CATATAN:
-- Fungsi ini TIDAK membuat auth.users.
-- Auth user dibuat dari server menggunakan
-- Supabase Admin Auth pada tahap frontend berikutnya.
-- =========================================================

create or replace function
public.provision_admin_guardian_account(
    p_guardian_id uuid,
    p_user_email text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_normalized_email text;

    v_target_user_id uuid;
    v_existing_profile_id uuid;
    v_existing_guardian_id uuid;

    v_guardian_full_name text;
    v_guardian_phone text;
    v_guardian_email text;
    v_guardian_active boolean;

    v_guardian_role_id smallint;

    v_linked_roles jsonb;
begin
    -- =====================================================
    -- 1. VALIDASI SESSION DAN ROLE ADMIN
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses provisioning akun wali ditolak.';
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
    -- 2. VALIDASI PARAMETER
    -- =====================================================

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
    end if;

    v_normalized_email :=
        lower(
            btrim(
                coalesce(
                    p_user_email,
                    ''
                )
            )
        );

    if v_normalized_email = '' then
        raise exception
            'Email akun wali wajib diisi.';
    end if;

    if length(v_normalized_email) > 254 then
        raise exception
            'Email maksimal 254 karakter.';
    end if;

    if v_normalized_email !~*
       '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
        raise exception
            'Format email akun wali tidak valid.';
    end if;

    -- =====================================================
    -- 3. KUNCI DAN BACA DATA WALI
    -- =====================================================

    select
        guardian.profile_id,
        guardian.full_name,
        guardian.phone,
        guardian.email,
        guardian.is_active

    into
        v_existing_profile_id,
        v_guardian_full_name,
        v_guardian_phone,
        v_guardian_email,
        v_guardian_active

    from public.guardians as guardian

    where guardian.id = p_guardian_id

    for update;

    if not found then
        raise exception
            'Data wali tidak ditemukan.';
    end if;

    if v_guardian_active is not true then
        raise exception
            'Wali tidak aktif tidak dapat dibuatkan akun.';
    end if;

    if v_guardian_email is null
       or btrim(v_guardian_email) = '' then
        raise exception
            'Email pada data wali belum diisi.';
    end if;

    if lower(
        btrim(v_guardian_email)
    ) <> v_normalized_email then
        raise exception
            'Email akun harus sama dengan email pada data wali.';
    end if;

    -- =====================================================
    -- 4. CARI AUTH USER BERDASARKAN EMAIL
    -- =====================================================

    select auth_user.id

    into v_target_user_id

    from auth.users as auth_user

    where lower(
        auth_user.email::text
    ) = v_normalized_email

      and auth_user.deleted_at is null

    limit 1;

    if v_target_user_id is null then
        raise exception
            'Akun Auth dengan email % belum tersedia.',
            v_normalized_email;
    end if;

    -- =====================================================
    -- 5. CEGAH DATA WALI TERHUBUNG KE AKUN LAIN
    -- =====================================================

    if v_existing_profile_id is not null
       and v_existing_profile_id <>
           v_target_user_id then
        raise exception
            'Data wali sudah terhubung dengan akun lain.';
    end if;

    -- =====================================================
    -- 6. CEGAH AKUN DIPAKAI WALI LAIN
    -- =====================================================

    select guardian.id

    into v_existing_guardian_id

    from public.guardians as guardian

    where guardian.profile_id =
          v_target_user_id

      and guardian.id <>
          p_guardian_id

    limit 1;

    if v_existing_guardian_id is not null then
        raise exception
            'Akun % sudah terhubung dengan data wali lain.',
            v_normalized_email;
    end if;

    -- =====================================================
    -- 7. PASTIKAN ROLE GUARDIAN TERSEDIA
    -- =====================================================

    select role.id

    into v_guardian_role_id

    from public.roles as role

    where role.code = 'guardian'
      and role.is_active = true

    limit 1;

    if v_guardian_role_id is null then
        raise exception
            'Role guardian tidak ditemukan atau tidak aktif.';
    end if;

    -- =====================================================
    -- 8. PASTIKAN PROFILE TERSEDIA DAN AKTIF
    -- =====================================================

    insert into public.profiles (
        id,
        full_name,
        phone,
        is_active
    )
    values (
        v_target_user_id,
        v_guardian_full_name,
        v_guardian_phone,
        true
    )

    on conflict (id)
    do update set
        full_name =
            excluded.full_name,

        phone =
            coalesce(
                excluded.phone,
                public.profiles.phone
            ),

        is_active =
            true,

        updated_at =
            now();

    -- =====================================================
    -- 9. HUBUNGKAN PROFILE DENGAN DATA WALI
    -- =====================================================

    update public.guardians

    set
        profile_id =
            v_target_user_id,

        email =
            v_normalized_email,

        updated_at =
            now()

    where id =
          p_guardian_id;

    -- =====================================================
    -- 10. BERIKAN ROLE GUARDIAN
    -- =====================================================

    insert into public.user_roles (
        user_id,
        role_id,
        assigned_by
    )
    values (
        v_target_user_id,
        v_guardian_role_id,
        auth.uid()
    )

    on conflict (
        user_id,
        role_id
    )
    do update set
        assigned_by =
            excluded.assigned_by;

    -- =====================================================
    -- 11. SUSUN ROLE AKUN
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
        on role.id =
           user_role.role_id

    where user_role.user_id =
          v_target_user_id

      and role.is_active = true;

    -- =====================================================
    -- 12. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'provisioned',

        'guardian_id',
        p_guardian_id,

        'user_id',
        v_target_user_id,

        'profile_id',
        v_target_user_id,

        'email',
        v_normalized_email,

        'full_name',
        v_guardian_full_name,

        'roles',
        v_linked_roles
    );
end;
$$;


comment on function
public.provision_admin_guardian_account(
    uuid,
    text
)
is
'Menghubungkan Auth user dengan data wali dan memberikan role guardian melalui Admin aktif.';


revoke all on function
public.provision_admin_guardian_account(
    uuid,
    text
)
from public;

revoke all on function
public.provision_admin_guardian_account(
    uuid,
    text
)
from anon;

grant execute on function
public.provision_admin_guardian_account(
    uuid,
    text
)
to authenticated;

commit;