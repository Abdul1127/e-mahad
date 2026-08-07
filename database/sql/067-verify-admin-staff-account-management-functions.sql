-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 067-verify-admin-staff-account-management-functions.sql
--
-- PURPOSE:
-- - Verifikasi fungsi status profile staf
-- - Verifikasi fungsi perubahan multi-role
-- - Role admin harus ditolak
-- - Role kosong harus ditolak
-- - Verifikasi privilege
-- - Seluruh perubahan di-rollback
-- =========================================================


-- =========================================================
-- 1. FUNCTION & PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.set_admin_staff_account_profile_status(uuid,boolean)'
    ) is not null
        as status_function_exists,

    to_regprocedure(
        'public.set_admin_staff_roles(uuid,text[])'
    ) is not null
        as role_function_exists,

    has_function_privilege(
        'authenticated',
        'public.set_admin_staff_account_profile_status(uuid,boolean)',
        'execute'
    ) as authenticated_can_set_status,

    has_function_privilege(
        'anon',
        'public.set_admin_staff_account_profile_status(uuid,boolean)',
        'execute'
    ) as anon_can_set_status,

    has_function_privilege(
        'authenticated',
        'public.set_admin_staff_roles(uuid,text[])',
        'execute'
    ) as authenticated_can_set_roles,

    has_function_privilege(
        'anon',
        'public.set_admin_staff_roles(uuid,text[])',
        'execute'
    ) as anon_can_set_roles;


-- =========================================================
-- 2. TRANSACTION
-- =========================================================

begin;


-- =========================================================
-- 3. EMULASI ADMIN
-- =========================================================

select set_config(
    'request.jwt.claim.sub',
    (
        select profile.id::text

        from public.profiles as profile

        inner join public.user_roles as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where role.code =
              'admin'

          and profile.is_active =
              true

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

        from public.profiles as profile

        inner join auth.users as auth_user
            on auth_user.id =
               profile.id

        inner join public.user_roles as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where role.code =
              'admin'

          and profile.is_active =
              true

        order by
            profile.created_at,
            profile.id

        limit 1
    ),
    true
);


-- =========================================================
-- 4. ASSERTIONS
-- =========================================================

do $verification$
declare
    v_staff_id uuid;
    v_profile_id uuid;

    v_original_profile_active boolean;

    v_original_role_codes text[];
    v_current_role_codes text[];

    v_status_response jsonb;
    v_role_response jsonb;

    v_admin_role_blocked boolean :=
        false;

    v_empty_role_blocked boolean :=
        false;
begin
    -- =====================================================
    -- A. PILIH STAF EXISTING
    -- =====================================================

    select
        staff.id,
        staff.profile_id,
        profile.is_active

    into
        v_staff_id,
        v_profile_id,
        v_original_profile_active

    from public.staff as staff

    inner join public.profiles as profile
        on profile.id =
           staff.profile_id

    where staff.is_active =
          true

      and exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                staff.profile_id

            and role.is_active =
                true

            and role.code not in (
                'admin',
                'guardian'
            )
      )

    order by
        staff.created_at,
        staff.id

    limit 1;

    if v_staff_id is null then
        raise exception
            'Pengujian gagal: akun staf existing tidak ditemukan.';
    end if;

    -- =====================================================
    -- B. SIMPAN ROLE ORIGINAL
    -- =====================================================

    select
        array_agg(
            role.code
            order by role.code
        )

    into
        v_original_role_codes

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

    if coalesce(
        cardinality(
            v_original_role_codes
        ),
        0
    ) = 0 then
        raise exception
            'Pengujian gagal: role original staf kosong.';
    end if;

    -- =====================================================
    -- C. ROLE IDEMPOTENT
    -- =====================================================

    v_role_response :=
        public.set_admin_staff_roles(
            p_staff_id =>
                v_staff_id,

            p_role_codes =>
                v_original_role_codes
        );

    select
        array_agg(
            role.code
            order by role.code
        )

    into
        v_current_role_codes

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

    if v_current_role_codes
       is distinct from
       v_original_role_codes then
        raise exception
            'Pengujian gagal: role berubah setelah operasi idempotent.';
    end if;

    -- =====================================================
    -- D. ROLE ADMIN HARUS DITOLAK
    -- =====================================================

    begin
        perform
            public.set_admin_staff_roles(
                p_staff_id =>
                    v_staff_id,

                p_role_codes =>
                    array['admin']
            );

    exception
        when others then
            if sqlerrm ilike
               '%role staf tidak valid%' then
                v_admin_role_blocked :=
                    true;
            else
                raise;
            end if;
    end;

    if v_admin_role_blocked is not true then
        raise exception
            'Pengujian gagal: role admin belum ditolak.';
    end if;

    -- =====================================================
    -- E. ROLE KOSONG HARUS DITOLAK
    -- =====================================================

    begin
        perform
            public.set_admin_staff_roles(
                p_staff_id =>
                    v_staff_id,

                p_role_codes =>
                    array[]::text[]
            );

    exception
        when others then
            if sqlerrm ilike
               '%minimal satu role%' then
                v_empty_role_blocked :=
                    true;
            else
                raise;
            end if;
    end;

    if v_empty_role_blocked is not true then
        raise exception
            'Pengujian gagal: role kosong belum ditolak.';
    end if;

    -- =====================================================
    -- F. NONAKTIFKAN PROFILE
    -- =====================================================

    v_status_response :=
        public.set_admin_staff_account_profile_status(
            p_staff_id =>
                v_staff_id,

            p_is_active =>
                false
        );

    if (
        select profile.is_active

        from public.profiles as profile

        where profile.id =
              v_profile_id
    ) is not false then
        raise exception
            'Pengujian gagal: profile staf belum nonaktif.';
    end if;

    -- =====================================================
    -- G. AKTIFKAN KEMBALI BILA ORIGINAL AKTIF
    -- =====================================================

    if v_original_profile_active = true then
        perform
            public.set_admin_staff_account_profile_status(
                p_staff_id =>
                    v_staff_id,

                p_is_active =>
                    true
            );

        if (
            select profile.is_active

            from public.profiles as profile

            where profile.id =
                  v_profile_id
        ) is not true then
            raise exception
                'Pengujian gagal: profile staf belum aktif kembali.';
        end if;
    end if;

    -- =====================================================
    -- H. NOTICE
    -- =====================================================

    raise notice
        'STAFF ID: %',
        v_staff_id;

    raise notice
        'PROFILE ID: %',
        v_profile_id;

    raise notice
        'ORIGINAL ROLES: %',
        v_original_role_codes;

    raise notice
        'ROLE RESPONSE: %',
        v_role_response;

    raise notice
        'STATUS RESPONSE: %',
        v_status_response;

    raise notice
        'ADMIN ROLE BLOCKED: %',
        v_admin_role_blocked;

    raise notice
        'EMPTY ROLE BLOCKED: %',
        v_empty_role_blocked;

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


-- =========================================================
-- 5. ROLLBACK
-- =========================================================

rollback;


-- =========================================================
-- 6. FINAL RESULT
-- =========================================================

select
    'Status akun dan pengelolaan multi-role staf berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;