begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 054-create-guardian-login-identity-functions.sql
--
-- PURPOSE:
-- - Membentuk kandidat login ID akun wali
-- - Membentuk email Auth internal
-- - Menghubungkan Auth user dengan data wali
-- - Menetapkan profiles.login_id
-- - Memberikan role guardian
-- - Tidak mewajibkan email kontak asli wali
--
-- FORMAT:
-- Login ID:
-- ORT-{ID/NIS-SANTRI}-{URUTAN}
--
-- Email internal:
-- {login-id-lowercase}@login.emahad.id
-- =========================================================


-- =========================================================
-- 1. KANDIDAT IDENTITAS LOGIN WALI
-- =========================================================

create or replace function
public.get_admin_guardian_login_identity(
    p_guardian_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_profile_id uuid;

    v_guardian_full_name text;
    v_legacy_guardian_id text;
    v_guardian_is_active boolean;

    v_existing_login_id text;
    v_existing_auth_email text;

    v_student_seed text;
    v_normalized_seed text;

    v_login_id_base text;
    v_candidate_login_id text;
    v_internal_auth_email text;

    v_sequence integer;
    v_candidate_available boolean :=
        false;
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
            message = 'Akses identitas login wali ditolak.';
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
    -- B. BACA DATA WALI
    -- =====================================================

    select
        guardian.profile_id,
        guardian.full_name,
        guardian.legacy_guardian_id,
        guardian.is_active

    into
        v_profile_id,
        v_guardian_full_name,
        v_legacy_guardian_id,
        v_guardian_is_active

    from public.guardians as guardian

    where guardian.id = p_guardian_id;

    if not found then
        raise exception
            'Data wali tidak ditemukan.';
    end if;

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
            on auth_user.id =
               profile.id

        where profile.id =
              v_profile_id

          and auth_user.deleted_at
              is null;

        if v_existing_login_id is null then
            raise exception
                'Profile akun wali belum mempunyai login ID.';
        end if;

        return jsonb_build_object(
            'success',
            true,

            'status',
            'existing',

            'guardian_id',
            p_guardian_id,

            'profile_id',
            v_profile_id,

            'full_name',
            v_guardian_full_name,

            'login_id',
            v_existing_login_id,

            'internal_auth_email',
            v_existing_auth_email
        );
    end if;

    -- =====================================================
    -- D. VALIDASI WALI BARU
    -- =====================================================

    if v_guardian_is_active is not true then
        raise exception
            'Wali tidak aktif tidak dapat dibuatkan akun.';
    end if;

    if not exists (
        select 1

        from public.guardian_students
            as guardian_student

        where guardian_student.guardian_id =
              p_guardian_id
    ) then
        raise exception
            'Hubungkan wali dengan minimal satu santri sebelum membuat akun.';
    end if;

    -- =====================================================
    -- E. AMBIL SUMBER ID/NIS SANTRI
    -- =====================================================

    select
        student.legacy_student_id

    into
        v_student_seed

    from public.guardian_students
        as guardian_student

    inner join public.students as student
        on student.id =
           guardian_student.student_id

    where guardian_student.guardian_id =
          p_guardian_id

    order by
        guardian_student.is_primary_contact
            desc,

        student.legacy_student_id
            nulls last,

        student.id

    limit 1;

    -- Prioritas sumber:
    -- 1. ID/NIS santri
    -- 2. Legacy ID wali
    -- 3. Potongan UUID wali

    v_normalized_seed :=
        public.normalize_login_id(
            coalesce(
                nullif(
                    btrim(v_student_seed),
                    ''
                ),

                nullif(
                    btrim(v_legacy_guardian_id),
                    ''
                ),

                left(
                    p_guardian_id::text,
                    8
                )
            )
        );

    if v_normalized_seed is null
       or v_normalized_seed = '' then
        raise exception
            'Sumber login ID wali tidak dapat dibentuk.';
    end if;

    v_login_id_base :=
        concat(
            'ORT-',
            v_normalized_seed
        );

    -- =====================================================
    -- F. CARI NOMOR URUT YANG MASIH TERSEDIA
    -- =====================================================

    for v_sequence in 1..9999 loop
        v_candidate_login_id :=
            concat(
                v_login_id_base,
                '-',
                lpad(
                    v_sequence::text,
                    2,
                    '0'
                )
            );

        if not exists (
            select 1

            from public.profiles as profile

            where lower(
                profile.login_id
            ) = lower(
                v_candidate_login_id
            )
        ) then
            v_candidate_available :=
                true;

            exit;
        end if;
    end loop;

    if v_candidate_available is not true then
        raise exception
            'Nomor urut login ID wali tidak tersedia.';
    end if;

    v_internal_auth_email :=
        concat(
            lower(
                v_candidate_login_id
            ),
            '@login.emahad.id'
        );

    return jsonb_build_object(
        'success',
        true,

        'status',
        'candidate',

        'guardian_id',
        p_guardian_id,

        'profile_id',
        null,

        'full_name',
        v_guardian_full_name,

        'student_seed',
        v_normalized_seed,

        'login_id',
        v_candidate_login_id,

        'internal_auth_email',
        v_internal_auth_email
    );
end;
$$;


comment on function
public.get_admin_guardian_login_identity(uuid)
is
'Menghasilkan login ID dan email internal untuk akun wali melalui Admin aktif.';


-- =========================================================
-- 2. PROVISIONING AUTH USER KE DATA WALI
-- =========================================================

create or replace function
public.provision_admin_guardian_login_account(
    p_guardian_id uuid,
    p_user_id uuid,
    p_login_id text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_normalized_login_id text;
    v_expected_auth_email text;

    v_guardian_profile_id uuid;
    v_guardian_full_name text;
    v_guardian_phone text;
    v_guardian_contact_email text;
    v_guardian_is_active boolean;

    v_auth_email text;

    v_existing_profile_login_id text;
    v_other_guardian_id uuid;
    v_conflicting_profile_id uuid;

    v_guardian_role_id smallint;
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
    -- B. VALIDASI PARAMETER
    -- =====================================================

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
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
            'Login ID wali wajib diisi.';
    end if;

    if char_length(
        v_normalized_login_id
    ) > 64 then
        raise exception
            'Login ID maksimal 64 karakter.';
    end if;

    if v_normalized_login_id !~
       '^ORT-[A-Z0-9]+(-[A-Z0-9]+)*$' then
        raise exception
            'Format login ID wali tidak valid.';
    end if;

    v_expected_auth_email :=
        concat(
            lower(
                v_normalized_login_id
            ),
            '@login.emahad.id'
        );

    -- =====================================================
    -- C. KUNCI DATA WALI
    -- =====================================================

    select
        guardian.profile_id,
        guardian.full_name,
        guardian.phone,
        guardian.email,
        guardian.is_active

    into
        v_guardian_profile_id,
        v_guardian_full_name,
        v_guardian_phone,
        v_guardian_contact_email,
        v_guardian_is_active

    from public.guardians as guardian

    where guardian.id =
          p_guardian_id

    for update;

    if not found then
        raise exception
            'Data wali tidak ditemukan.';
    end if;

    if v_guardian_is_active is not true then
        raise exception
            'Wali tidak aktif tidak dapat dibuatkan akun.';
    end if;

    if not exists (
        select 1

        from public.guardian_students
            as guardian_student

        where guardian_student.guardian_id =
              p_guardian_id
    ) then
        raise exception
            'Hubungkan wali dengan minimal satu santri sebelum membuat akun.';
    end if;

    -- =====================================================
    -- D. VALIDASI AUTH USER
    -- =====================================================

    select
        auth_user.email::text

    into
        v_auth_email

    from auth.users as auth_user

    where auth_user.id =
          p_user_id

      and auth_user.deleted_at
          is null

    limit 1;

    if v_auth_email is null then
        raise exception
            'Auth user akun wali tidak ditemukan.';
    end if;

    if lower(
        btrim(v_auth_email)
    ) <> v_expected_auth_email then
        raise exception
            'Email Auth tidak sesuai dengan login ID wali.';
    end if;

    -- =====================================================
    -- E. CEGAH WALI TERHUBUNG KE AKUN LAIN
    -- =====================================================

    if v_guardian_profile_id is not null
       and v_guardian_profile_id <>
           p_user_id then
        raise exception
            'Data wali sudah terhubung dengan akun lain.';
    end if;

    -- =====================================================
    -- F. CEGAH AKUN DIPAKAI WALI LAIN
    -- =====================================================

    select guardian.id

    into v_other_guardian_id

    from public.guardians as guardian

    where guardian.profile_id =
          p_user_id

      and guardian.id <>
          p_guardian_id

    limit 1;

    if v_other_guardian_id is not null then
        raise exception
            'Auth user sudah terhubung dengan data wali lain.';
    end if;

    -- =====================================================
    -- G. KUNCI PROFILE HASIL TRIGGER AUTH
    -- =====================================================

    select profile.login_id

    into v_existing_profile_login_id

    from public.profiles as profile

    where profile.id =
          p_user_id

    for update;

    if found
       and v_existing_profile_login_id
           is not null

       and lower(
           v_existing_profile_login_id
       ) <> lower(
           v_normalized_login_id
       ) then
        raise exception
            'Profile Auth user sudah mempunyai login ID lain.';
    end if;

    -- =====================================================
    -- H. CEGAH LOGIN ID DUPLIKAT
    -- =====================================================

    select profile.id

    into v_conflicting_profile_id

    from public.profiles as profile

    where lower(
        profile.login_id
    ) = lower(
        v_normalized_login_id
    )

      and profile.id <>
          p_user_id

    limit 1;

    if v_conflicting_profile_id is not null then
        raise exception
            'Login ID % sudah digunakan akun lain.',
            v_normalized_login_id;
    end if;

    -- =====================================================
    -- I. ROLE GUARDIAN
    -- =====================================================

    select role.id

    into v_guardian_role_id

    from public.roles as role

    where role.code =
          'guardian'

      and role.is_active =
          true

    limit 1;

    if v_guardian_role_id is null then
        raise exception
            'Role guardian tidak ditemukan atau tidak aktif.';
    end if;

    -- =====================================================
    -- J. PROFILE
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
        v_guardian_full_name,
        v_guardian_phone,
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
    -- K. HUBUNGKAN WALI
    -- =====================================================

    update public.guardians

    set
        profile_id =
            p_user_id,

        updated_at =
            now()

    where id =
          p_guardian_id;

    -- guardians.email tidak diubah.
    -- Kolom tersebut tetap menjadi email kontak opsional.

    -- =====================================================
    -- L. BERIKAN ROLE GUARDIAN
    -- =====================================================

    insert into public.user_roles (
        user_id,
        role_id,
        assigned_by
    )
    values (
        p_user_id,
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
    -- M. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'provisioned',

        'guardian_id',
        p_guardian_id,

        'user_id',
        p_user_id,

        'profile_id',
        p_user_id,

        'full_name',
        v_guardian_full_name,

        'login_id',
        v_normalized_login_id,

        'internal_auth_email',
        v_expected_auth_email,

        'contact_email',
        v_guardian_contact_email,

        'role',
        'guardian'
    );
end;
$$;


comment on function
public.provision_admin_guardian_login_account(
    uuid,
    uuid,
    text
)
is
'Menghubungkan Auth user internal dengan wali, login ID, profile, dan role guardian.';


-- =========================================================
-- 3. PRIVILEGES
-- =========================================================

revoke all on function
public.get_admin_guardian_login_identity(uuid)
from public;

revoke all on function
public.get_admin_guardian_login_identity(uuid)
from anon;

grant execute on function
public.get_admin_guardian_login_identity(uuid)
to authenticated;


revoke all on function
public.provision_admin_guardian_login_account(
    uuid,
    uuid,
    text
)
from public;

revoke all on function
public.provision_admin_guardian_login_account(
    uuid,
    uuid,
    text
)
from anon;

grant execute on function
public.provision_admin_guardian_login_account(
    uuid,
    uuid,
    text
)
to authenticated;

commit;