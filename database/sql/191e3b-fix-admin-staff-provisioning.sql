-- ============================================================
-- E-MA'HAD
-- STAGE 191E-3B
--
-- FIX ADMIN STAFF ACCOUNT PROVISIONING
--
-- MASALAH:
-- get_admin_staff_role_options() memperbolehkan role Admin,
-- tetapi provision_admin_staff_login_account() masih
-- menggunakan aturan lama yang menolak:
--
--     admin
--     guardian
--
-- HASIL SETELAH FIX:
-- - Admin diperbolehkan sebagai role staf.
-- - Guardian tetap tidak diperbolehkan sebagai role staf.
-- - Aturan konsisten dengan:
--   get_admin_staff_role_options()
--   set_admin_staff_roles()
-- ============================================================


create or replace function public.provision_admin_staff_login_account(
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

    -- ========================================================
    -- A. VALIDASI ADMIN YANG MENJALANKAN PROVISIONING
    -- ========================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message =
                'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'admin'
    ) then
        raise exception using
            errcode = '42501',
            message =
                'Akses provisioning akun staf ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              auth.uid()

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message =
                'Profile Admin tidak aktif.';
    end if;


    -- ========================================================
    -- B. VALIDASI PARAMETER
    -- ========================================================

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
       or v_normalized_login_id = ''
    then
        raise exception
            'ID Pengguna staf wajib diisi.';
    end if;


    if char_length(
        v_normalized_login_id
    ) > 64
    then
        raise exception
            'ID Pengguna staf maksimal 64 karakter.';
    end if;


    /*
     * Akun staf baru tetap dibuat menggunakan
     * format dasar:
     *
     * STF-{legacy_staff_id}
     *
     * Custom login seperti ADM-20-P-001
     * dapat diberikan setelah akun berhasil
     * diprovisioning.
     */
    if v_normalized_login_id !~
       '^STF-[A-Z0-9]+(-[A-Z0-9]+)*$'
    then
        raise exception
            'Format ID Pengguna staf tidak valid.';
    end if;


    -- ========================================================
    -- C. NORMALISASI ROLE REQUEST
    -- ========================================================

    select
        array_agg(
            normalized_role.role_code
            order by
                normalized_role.role_code
        )

    into
        v_role_codes

    from (
        select distinct
            lower(
                btrim(
                    input_role.role_code
                )
            ) as role_code

        from unnest(
            coalesce(
                p_role_codes,
                array[]::text[]
            )
        ) as input_role(
            role_code
        )

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


    if v_requested_role_count = 0
    then
        raise exception
            'Minimal satu role staf harus dipilih.';
    end if;


    -- ========================================================
    -- D. KUNCI DATA STAF
    -- ========================================================

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

    from public.staff
        as staff

    where staff.id =
          p_staff_id

    for update;


    if not found then
        raise exception
            'Data staf tidak ditemukan.';
    end if;


    if v_staff_is_active is not true
    then
        raise exception
            'Staf tidak aktif tidak dapat dibuatkan akun.';
    end if;


    if v_legacy_staff_id is null
       or btrim(
           v_legacy_staff_id
       ) = ''
    then
        raise exception
            'ID staf belum tersedia.';
    end if;


    -- ========================================================
    -- E. VALIDASI LOGIN ID BERDASARKAN LEGACY STAFF ID
    -- ========================================================

    v_expected_login_id :=
        public.normalize_login_id(
            concat(
                'STF-',
                v_legacy_staff_id
            )
        );


    if upper(
        v_normalized_login_id
    ) <>
       upper(
           v_expected_login_id
       )
    then
        raise exception
            'ID Pengguna tidak sesuai dengan ID staf.';
    end if;


    v_expected_auth_email :=
        concat(
            lower(
                v_expected_login_id
            ),
            '@login.emahad.id'
        );


    -- ========================================================
    -- F. VALIDASI AUTH USER
    -- ========================================================

    select
        auth_user.email::text

    into
        v_auth_email

    from auth.users
        as auth_user

    where auth_user.id =
          p_user_id

      and auth_user.deleted_at
          is null

    limit 1;


    if v_auth_email is null then
        raise exception
            'Auth user akun staf tidak ditemukan.';
    end if;


    if lower(
        btrim(
            v_auth_email
        )
    ) <>
       lower(
           v_expected_auth_email
       )
    then
        raise exception
            'Email Auth tidak sesuai dengan ID Pengguna staf.';
    end if;


    -- ========================================================
    -- G. CEGAH STAF TERHUBUNG KE AKUN LAIN
    -- ========================================================

    if v_profile_id is not null
       and v_profile_id <>
           p_user_id
    then
        raise exception
            'Data staf sudah terhubung dengan akun lain.';
    end if;


    -- ========================================================
    -- H. CEGAH AUTH USER DIPAKAI STAF LAIN
    -- ========================================================

    select
        staff.id

    into
        v_other_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          p_user_id

      and staff.id <>
          p_staff_id

    limit 1;


    if v_other_staff_id is not null
    then
        raise exception
            'Auth user sudah terhubung dengan data staf lain.';
    end if;


    -- ========================================================
    -- I. VALIDASI PROFILE
    -- ========================================================

    select
        profile.login_id

    into
        v_existing_profile_login_id

    from public.profiles
        as profile

    where profile.id =
          p_user_id

    for update;


    if found
       and v_existing_profile_login_id
           is not null

       and lower(
           v_existing_profile_login_id
       ) <>
           lower(
               v_normalized_login_id
           )
    then
        raise exception
            'Profile Auth user sudah mempunyai ID Pengguna lain.';
    end if;


    select
        profile.id

    into
        v_conflicting_profile_id

    from public.profiles
        as profile

    where lower(
        profile.login_id
    ) =
          lower(
              v_normalized_login_id
          )

      and profile.id <>
          p_user_id

    limit 1;


    if v_conflicting_profile_id
       is not null
    then
        raise exception
            'ID Pengguna % sudah digunakan akun lain.',
            v_normalized_login_id;
    end if;


    -- ========================================================
    -- J. VALIDASI ROLE STAF
    --
    -- PERBAIKAN STAGE 191E-3B:
    --
    -- Semua role aplikasi yang aktif diperbolehkan
    -- untuk staf, TERMASUK ADMIN.
    --
    -- Guardian tetap tidak boleh karena guardian
    -- merupakan akun Orang Tua/Wali, bukan staf.
    -- ========================================================

    select
        count(*)::integer

    into
        v_found_role_count

    from public.roles
        as role

    where role.code =
          any(
              v_role_codes
          )

      and role.is_active =
          true

      and role.code <>
          'guardian';


    if v_found_role_count <>
       v_requested_role_count
    then

        select
            string_agg(
                requested_role.code,
                ', '
                order by
                    requested_role.code
            )

        into
            v_missing_role_codes

        from unnest(
            v_role_codes
        ) as requested_role(
            code
        )

        where not exists (
            select 1

            from public.roles
                as role

            where role.code =
                  requested_role.code

              and role.is_active =
                  true

              and role.code <>
                  'guardian'
        );


        raise exception
            'Role staf tidak valid atau tidak aktif: %.',
            coalesce(
                v_missing_role_codes,
                '-'
            );

    end if;


    -- ========================================================
    -- K. CREATE / UPDATE PROFILE
    -- ========================================================

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

    on conflict (
        id
    )

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


    -- ========================================================
    -- L. HUBUNGKAN STAF DENGAN PROFILE
    -- ========================================================

    update public.staff

    set
        profile_id =
            p_user_id,

        updated_at =
            now()

    where id =
          p_staff_id;


    -- ========================================================
    -- M. TAMBAHKAN ROLE STAF
    -- ========================================================

    insert into public.user_roles (
        user_id,
        role_id,
        assigned_by
    )

    select
        p_user_id,
        role.id,
        auth.uid()

    from public.roles
        as role

    where role.code =
          any(
              v_role_codes
          )

      and role.is_active =
          true

      and role.code <>
          'guardian'

    on conflict (
        user_id,
        role_id
    )

    do update set
        assigned_by =
            excluded.assigned_by;


    -- ========================================================
    -- N. RESPONSE ROLE AKHIR
    -- ========================================================

    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'code',
                    role.code,

                    'name',
                    role.name
                )

                order by
                    case
                        when role.code =
                             'admin'
                        then 0

                        else 1
                    end,

                    role.name,
                    role.code
            ),
            '[]'::jsonb
        )

    into
        v_linked_roles

    from public.user_roles
        as user_role

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    where user_role.user_id =
          p_user_id

      and role.is_active =
          true;


    -- ========================================================
    -- O. FINAL RESPONSE
    -- ========================================================

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


-- ============================================================
-- VERIFY FUNCTION
-- ============================================================

select
    procedure.proname
        as function_name,

    procedure.prosecdef
        as security_definer,

    pg_get_function_identity_arguments(
        procedure.oid
    )
        as arguments,

    case
        when pg_get_functiondef(
            procedure.oid
        ) like
             '%role.code <>%guardian%'
        then
            'PASS'
        else
            'CHECK'
    end
        as guardian_exclusion_check

from pg_proc
    as procedure

inner join pg_namespace
    as namespace

    on namespace.oid =
       procedure.pronamespace

where namespace.nspname =
      'public'

  and procedure.proname =
      'provision_admin_staff_login_account';