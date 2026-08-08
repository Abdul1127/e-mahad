begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 084-allow-admin-staff-role-management.sql
--
-- PURPOSE:
-- - Mengizinkan role "admin" pada akun staf
-- - Tetap melarang role "guardian" pada staf
-- - Role Admin muncul pada pilihan Kelola Role Staf
-- - Role Admin dapat disimpan melalui set_admin_staff_roles
-- - Mencegah Admin menghapus role admin miliknya sendiri
-- - Mencegah penghapusan admin aktif terakhir
-- =========================================================


-- =========================================================
-- 1. ROLE OPTIONS
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

    -- =====================================================
    -- AUTH
    -- =====================================================

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
    -- ROLE OPTIONS
    --
    -- Admin sekarang BOLEH menjadi role staf.
    -- Guardian tetap tidak boleh diberikan kepada staf.
    -- =====================================================

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'code',
                role.code,

                'name',
                role.name
            )

            order by
                case
                    when role.code = 'admin'
                        then 0
                    else 1
                end,

                role.name,
                role.code
        ),
        '[]'::jsonb
    )

    into v_result

    from public.roles
        as role

    where role.is_active = true

      and role.code <> 'guardian';


    return v_result;

end;
$function$;


comment on function
public.get_admin_staff_role_options()
is
'Mengambil role aktif yang dapat diberikan kepada staf. Role admin diperbolehkan, sedangkan guardian dikecualikan.';


-- =========================================================
-- 2. SET STAFF ROLES
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

    v_currently_admin boolean := false;

    v_admin_requested boolean := false;

    v_other_active_admin_count integer := 0;
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

            order by
                normalized_role.code
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
    -- D. LOCK DATA STAF
    -- =====================================================

    select
        staff.profile_id,
        staff.full_name

    into
        v_profile_id,
        v_full_name

    from public.staff
        as staff

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

        from public.profiles
            as profile

        where profile.id =
              v_profile_id
    ) then
        raise exception
            'Profile akun staf tidak ditemukan.';
    end if;


    -- =====================================================
    -- E. VALIDASI ROLE
    --
    -- Semua role aktif diperbolehkan kecuali guardian.
    -- =====================================================

    select
        count(*)::integer

    into
        v_found_role_count

    from public.roles
        as role

    where role.code =
          any(v_role_codes)

      and role.is_active = true

      and role.code <> 'guardian';


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
            v_invalid_role_codes

        from unnest(
            v_role_codes
        ) as requested_role(code)

        where not exists (
            select 1

            from public.roles
                as role

            where role.code =
                  requested_role.code

              and role.is_active = true

              and role.code <>
                  'guardian'
        );


        raise exception
            'Role staf tidak valid atau tidak aktif: %.',
            coalesce(
                v_invalid_role_codes,
                '-'
            );

    end if;


    -- =====================================================
    -- F. CEK STATUS ADMIN TARGET
    -- =====================================================

    select exists (
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
              'admin'

          and role.is_active = true
    )

    into
        v_currently_admin;


    v_admin_requested :=
        'admin' =
        any(v_role_codes);


    -- =====================================================
    -- G. PROTEKSI PENGHAPUSAN ROLE ADMIN
    -- =====================================================

    if v_currently_admin = true
       and v_admin_requested = false
    then

        -- Admin tidak boleh mencabut role admin sendiri.
        if v_profile_id =
           auth.uid()
        then
            raise exception
                'Role Admin pada akun yang sedang digunakan tidak dapat dihapus sendiri.';
        end if;


        -- Hitung Admin aktif lain.
        select
            count(
                distinct profile.id
            )::integer

        into
            v_other_active_admin_count

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

        where role.code =
              'admin'

          and role.is_active = true

          and profile.is_active = true

          and profile.id <>
              v_profile_id;


        if v_other_active_admin_count = 0 then
            raise exception
                'Role Admin tidak dapat dihapus karena akun ini merupakan Admin aktif terakhir.';
        end if;

    end if;


    -- =====================================================
    -- H. HAPUS ROLE YANG TIDAK DIPILIH
    --
    -- Guardian tidak dikelola oleh fungsi staf.
    -- Admin sekarang ikut dikelola.
    -- =====================================================

    delete from public.user_roles
        as user_role

    using public.roles
        as role

    where user_role.user_id =
          v_profile_id

      and role.id =
          user_role.role_id

      and role.code <>
          'guardian'

      and not (
          role.code =
          any(v_role_codes)
      );


    -- =====================================================
    -- I. TAMBAHKAN / PERBARUI ROLE TERPILIH
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

    from public.roles
        as role

    where role.code =
          any(v_role_codes)

      and role.is_active = true

      and role.code <>
          'guardian'

    on conflict (
        user_id,
        role_id
    )
    do update set
        assigned_by =
            excluded.assigned_by;


    -- =====================================================
    -- J. RESPONSE ROLE AKHIR
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
                case
                    when role.code = 'admin'
                        then 0
                    else 1
                end,

                role.name,
                role.code
        ),
        '[]'::jsonb
    )

    into
        v_roles

    from public.user_roles
        as user_role

    inner join public.roles
        as role
        on role.id =
           user_role.role_id

    where user_role.user_id =
          v_profile_id

      and role.is_active = true

      and role.code <>
          'guardian';


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
'Mengelola role akun staf termasuk role admin. Guardian dikecualikan. Mencegah penghapusan role admin sendiri dan admin aktif terakhir.';


-- =========================================================
-- 3. PRIVILEGES
-- =========================================================

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