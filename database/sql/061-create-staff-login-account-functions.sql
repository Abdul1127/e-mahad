begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 061-create-staff-login-account-functions.sql
--
-- PURPOSE:
-- - Membentuk ID Pengguna akun staf
-- - Membentuk email Auth internal
-- - Menampilkan pilihan role staf
-- - Menghubungkan Auth user dengan data staf
-- - Menetapkan profiles.login_id
-- - Menambahkan satu atau beberapa role staf
-- - Menonaktifkan akses fungsi provisioning lama
--
-- FORMAT LOGIN:
-- STF-{legacy_staff_id}
--
-- CONTOH:
-- STF-24-P-007
--
-- EMAIL AUTH INTERNAL:
-- stf-24-p-007@login.emahad.id
-- =========================================================


-- =========================================================
-- 1. IDENTITAS LOGIN STAF
-- =========================================================

create or replace function
public.get_admin_staff_login_identity(
    p_staff_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_legacy_staff_id text;
    v_full_name text;
    v_position text;
    v_phone text;
    v_staff_is_active boolean;

    v_expected_login_id text;
    v_existing_login_id text;

    v_internal_auth_email text;
    v_existing_auth_email text;

    v_conflicting_profile_id uuid;
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
            message = 'Akses identitas login staf ditolak.';
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
    -- B. BACA DATA STAF
    -- =====================================================

    select
        staff.profile_id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.position,
        staff.phone,
        staff.is_active

    into
        v_profile_id,
        v_legacy_staff_id,
        v_full_name,
        v_position,
        v_phone,
        v_staff_is_active

    from public.staff as staff

    where staff.id = p_staff_id;

    if not found then
        raise exception
            'Data staf tidak ditemukan.';
    end if;

    if v_legacy_staff_id is null
       or btrim(v_legacy_staff_id) = '' then
        raise exception
            'ID staf belum tersedia.';
    end if;

    v_expected_login_id :=
        public.normalize_login_id(
            concat(
                'STF-',
                v_legacy_staff_id
            )
        );

    if v_expected_login_id is null
       or v_expected_login_id = '' then
        raise exception
            'ID Pengguna staf tidak dapat dibentuk.';
    end if;

    if char_length(v_expected_login_id) > 64 then
        raise exception
            'ID Pengguna staf melebihi 64 karakter.';
    end if;

    if v_expected_login_id !~
       '^STF-[A-Z0-9]+(-[A-Z0-9]+)*$' then
        raise exception
            'Format ID Pengguna staf tidak valid.';
    end if;

    v_internal_auth_email :=
        concat(
            lower(v_expected_login_id),
            '@login.emahad.id'
        );

    -- =====================================================
    -- C. AKUN SUDAH TERHUBUNG
    -- =====================================================

    if v_profile_id is not null then
        select
            profile.login_id,
            auth_user.email::text

        into
            v_existing_login_id,
            v_existing_auth_email

        from public.profiles as profile

        inner join auth.users as auth_user
            on auth_user.id = profile.id

        where profile.id = v_profile_id
          and auth_user.deleted_at is null;

        if v_existing_login_id is null then
            raise exception
                'Profile akun staf belum mempunyai ID Pengguna.';
        end if;

        if upper(v_existing_login_id) <>
           upper(v_expected_login_id) then
            raise exception
                'ID Pengguna akun staf tidak sesuai dengan ID staf.';
        end if;

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

        into v_roles

        from public.user_roles as user_role

        inner join public.roles as role
            on role.id = user_role.role_id

        where user_role.user_id = v_profile_id
          and role.is_active = true;

        return jsonb_build_object(
            'success',
            true,

            'status',
            'existing',

            'staff_id',
            p_staff_id,

            'profile_id',
            v_profile_id,

            'legacy_staff_id',
            v_legacy_staff_id,

            'full_name',
            v_full_name,

            'position',
            v_position,

            'phone',
            v_phone,

            'staff_is_active',
            v_staff_is_active,

            'login_id',
            v_existing_login_id,

            'internal_auth_email',
            v_existing_auth_email,

            'roles',
            v_roles
        );
    end if;

    -- =====================================================
    -- D. VALIDASI STAF BARU
    -- =====================================================

    if v_staff_is_active is not true then
        raise exception
            'Staf tidak aktif tidak dapat dibuatkan akun.';
    end if;

    select profile.id

    into v_conflicting_profile_id

    from public.profiles as profile

    where lower(profile.login_id) =
          lower(v_expected_login_id)

    limit 1;

    if v_conflicting_profile_id is not null then
        raise exception
            'ID Pengguna % sudah digunakan akun lain.',
            v_expected_login_id;
    end if;

    return jsonb_build_object(
        'success',
        true,

        'status',
        'candidate',

        'staff_id',
        p_staff_id,

        'profile_id',
        null,

        'legacy_staff_id',
        v_legacy_staff_id,

        'full_name',
        v_full_name,

        'position',
        v_position,

        'phone',
        v_phone,

        'staff_is_active',
        v_staff_is_active,

        'login_id',
        v_expected_login_id,

        'internal_auth_email',
        v_internal_auth_email,

        'roles',
        '[]'::jsonb
    );
end;
$function$;


comment on function
public.get_admin_staff_login_identity(uuid)
is
'Menghasilkan ID Pengguna dan email Auth internal untuk akun staf melalui Admin aktif.';


-- =========================================================
-- 2. PILIHAN ROLE STAF
-- =========================================================

create or replace function
public.get_admin_staff_role_options()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_result jsonb;
begin
    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses pilihan role staf ditolak.';
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

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'code',
                role.code,

                'name',
                role.name
            )
            order by role.name, role.code
        ),
        '[]'::jsonb
    )

    into v_result

    from public.roles as role

    where role.is_active = true

      and role.code not in (
          'admin',
          'guardian'
      );

    return v_result;
end;
$function$;


comment on function
public.get_admin_staff_role_options()
is
'Menampilkan role aktif yang dapat diberikan kepada akun staf oleh Admin.';


-- =========================================================
-- 3. PROVISIONING AKUN STAF
-- =========================================================

create or replace function
public.provision_admin_staff_login_account(
    p_staff_id uuid,
    p_user_id uuid,
    p_login_id text,
    p_role_codes text[]
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_normalized_login_id text;
    v_expected_login_id text;
    v_expected_auth_email text;

    v_role_codes text[];
    v_requested_role_count integer;
    v_found_role_count integer;
    v_missing_role_codes text;

    v_profile_id uuid;
    v_legacy_staff_id text;
    v_full_name text;
    v_phone text;
    v_position text;
    v_staff_is_active boolean;

    v_auth_email text;
    v_existing_profile_login_id text;

    v_conflicting_profile_id uuid;
    v_other_staff_id uuid;

    v_linked_roles jsonb;
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
            message = 'Akses provisioning akun staf ditolak.';
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

    if p_user_id is null then
        raise exception
            'Auth user ID wajib diisi.';
    end if;

    v_normalized_login_id :=
        public.normalize_login_id(
            p_login_id
        );

    if v_normalized_login_id is null
       or v_normalized_login_id = '' then
        raise exception
            'ID Pengguna staf wajib diisi.';
    end if;

    if char_length(v_normalized_login_id) > 64 then
        raise exception
            'ID Pengguna staf maksimal 64 karakter.';
    end if;

    if v_normalized_login_id !~
       '^STF-[A-Z0-9]+(-[A-Z0-9]+)*$' then
        raise exception
            'Format ID Pengguna staf tidak valid.';
    end if;

    select array_agg(
        role_code
        order by role_code
    )

    into v_role_codes

    from (
        select distinct
            lower(
                btrim(input_role.role_code)
            ) as role_code

        from unnest(
            coalesce(
                p_role_codes,
                array[]::text[]
            )
        ) as input_role(role_code)

        where nullif(
            btrim(input_role.role_code),
            ''
        ) is not null
    ) as normalized_roles;

    v_requested_role_count :=
        coalesce(
            cardinality(v_role_codes),
            0
        );

    if v_requested_role_count = 0 then
        raise exception
            'Minimal satu role staf harus dipilih.';
    end if;

    -- =====================================================
    -- C. KUNCI DATA STAF
    -- =====================================================

    select
        staff.profile_id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.phone,
        staff.position,
        staff.is_active

    into
        v_profile_id,
        v_legacy_staff_id,
        v_full_name,
        v_phone,
        v_position,
        v_staff_is_active

    from public.staff as staff

    where staff.id = p_staff_id

    for update;

    if not found then
        raise exception
            'Data staf tidak ditemukan.';
    end if;

    if v_staff_is_active is not true then
        raise exception
            'Staf tidak aktif tidak dapat dibuatkan akun.';
    end if;

    if v_legacy_staff_id is null
       or btrim(v_legacy_staff_id) = '' then
        raise exception
            'ID staf belum tersedia.';
    end if;

    v_expected_login_id :=
        public.normalize_login_id(
            concat(
                'STF-',
                v_legacy_staff_id
            )
        );

    if upper(v_normalized_login_id) <>
       upper(v_expected_login_id) then
        raise exception
            'ID Pengguna tidak sesuai dengan ID staf.';
    end if;

    v_expected_auth_email :=
        concat(
            lower(v_expected_login_id),
            '@login.emahad.id'
        );

    -- =====================================================
    -- D. VALIDASI AUTH USER
    -- =====================================================

    select auth_user.email::text

    into v_auth_email

    from auth.users as auth_user

    where auth_user.id = p_user_id
      and auth_user.deleted_at is null

    limit 1;

    if v_auth_email is null then
        raise exception
            'Auth user akun staf tidak ditemukan.';
    end if;

    if lower(btrim(v_auth_email)) <>
       lower(v_expected_auth_email) then
        raise exception
            'Email Auth tidak sesuai dengan ID Pengguna staf.';
    end if;

    -- =====================================================
    -- E. CEGAH STAF TERHUBUNG KE AKUN LAIN
    -- =====================================================

    if v_profile_id is not null
       and v_profile_id <> p_user_id then
        raise exception
            'Data staf sudah terhubung dengan akun lain.';
    end if;

    -- =====================================================
    -- F. CEGAH AKUN DIPAKAI STAF LAIN
    -- =====================================================

    select staff.id

    into v_other_staff_id

    from public.staff as staff

    where staff.profile_id = p_user_id
      and staff.id <> p_staff_id

    limit 1;

    if v_other_staff_id is not null then
        raise exception
            'Auth user sudah terhubung dengan data staf lain.';
    end if;

    -- =====================================================
    -- G. VALIDASI PROFILE
    -- =====================================================

    select profile.login_id

    into v_existing_profile_login_id

    from public.profiles as profile

    where profile.id = p_user_id

    for update;

    if found
       and v_existing_profile_login_id is not null

       and lower(v_existing_profile_login_id) <>
           lower(v_normalized_login_id) then
        raise exception
            'Profile Auth user sudah mempunyai ID Pengguna lain.';
    end if;

    select profile.id

    into v_conflicting_profile_id

    from public.profiles as profile

    where lower(profile.login_id) =
          lower(v_normalized_login_id)

      and profile.id <> p_user_id

    limit 1;

    if v_conflicting_profile_id is not null then
        raise exception
            'ID Pengguna % sudah digunakan akun lain.',
            v_normalized_login_id;
    end if;

    -- =====================================================
    -- H. VALIDASI ROLE STAF
    -- =====================================================

    select count(*)::integer

    into v_found_role_count

    from public.roles as role

    where role.code = any(v_role_codes)
      and role.is_active = true

      and role.code not in (
          'admin',
          'guardian'
      );

    if v_found_role_count <>
       v_requested_role_count then
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

            where role.code =
                  requested_role.code

              and role.is_active = true

              and role.code not in (
                  'admin',
                  'guardian'
              )
        );

        raise exception
            'Role staf tidak valid atau tidak aktif: %.',
            coalesce(
                v_missing_role_codes,
                '-'
            );
    end if;

    -- =====================================================
    -- I. PROFILE
    -- =====================================================

    insert into public.profiles (
        id,
        full_name,
        phone,
        login_id,
        is_active
    )
    values (
        p_user_id,
        v_full_name,
        v_phone,
        v_normalized_login_id,
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

        login_id =
            excluded.login_id,

        is_active =
            true,

        updated_at =
            now();

    -- =====================================================
    -- J. HUBUNGKAN STAF
    -- =====================================================

    update public.staff

    set
        profile_id =
            p_user_id,

        updated_at =
            now()

    where id =
          p_staff_id;

    -- =====================================================
    -- K. TAMBAHKAN ROLE STAF
    -- =====================================================

    insert into public.user_roles (
        user_id,
        role_id,
        assigned_by
    )

    select
        p_user_id,
        role.id,
        auth.uid()

    from public.roles as role

    where role.code =
          any(v_role_codes)

      and role.is_active =
          true

    on conflict (
        user_id,
        role_id
    )
    do update set
        assigned_by =
            excluded.assigned_by;

    -- Fungsi provisioning hanya menambahkan role.
    -- Penghapusan atau perubahan role dilakukan melalui
    -- fungsi pengelolaan role staf pada tahap berikutnya.

    -- =====================================================
    -- L. RESPONSE
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
          p_user_id

      and role.is_active =
          true;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'provisioned',

        'staff_id',
        p_staff_id,

        'user_id',
        p_user_id,

        'profile_id',
        p_user_id,

        'legacy_staff_id',
        v_legacy_staff_id,

        'full_name',
        v_full_name,

        'position',
        v_position,

        'login_id',
        v_normalized_login_id,

        'internal_auth_email',
        v_expected_auth_email,

        'roles',
        v_linked_roles
    );
end;
$function$;


comment on function
public.provision_admin_staff_login_account(
    uuid,
    uuid,
    text,
    text[]
)
is
'Menghubungkan Auth user internal dengan staf, ID Pengguna, profile, dan satu atau beberapa role staf.';


-- =========================================================
-- 4. PRIVILEGE FUNGSI BARU
-- =========================================================

revoke all on function
public.get_admin_staff_login_identity(uuid)
from public;

revoke all on function
public.get_admin_staff_login_identity(uuid)
from anon;

grant execute on function
public.get_admin_staff_login_identity(uuid)
to authenticated;


revoke all on function
public.get_admin_staff_role_options()
from public;

revoke all on function
public.get_admin_staff_role_options()
from anon;

grant execute on function
public.get_admin_staff_role_options()
to authenticated;


revoke all on function
public.provision_admin_staff_login_account(
    uuid,
    uuid,
    text,
    text[]
)
from public;

revoke all on function
public.provision_admin_staff_login_account(
    uuid,
    uuid,
    text,
    text[]
)
from anon;

grant execute on function
public.provision_admin_staff_login_account(
    uuid,
    uuid,
    text,
    text[]
)
to authenticated;


-- =========================================================
-- 5. NONAKTIFKAN AKSES FUNGSI LAMA
-- =========================================================

revoke all on function
public.provision_staff_account(
    text,
    text,
    text[],
    text
)
from public;

revoke all on function
public.provision_staff_account(
    text,
    text,
    text[],
    text
)
from anon;

revoke all on function
public.provision_staff_account(
    text,
    text,
    text[],
    text
)
from authenticated;


comment on function
public.provision_staff_account(
    text,
    text,
    text[],
    text
)
is
'DEPRECATED: provisioning berbasis email lama. Gunakan provision_admin_staff_login_account.';

commit;