-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 059-inspect-staff-account-foundation.sql
--
-- PURPOSE:
-- - Memeriksa struktur tabel staff
-- - Memeriksa akun Auth dan login ID staff
-- - Memeriksa role yang dimiliki staff
-- - Mencari fungsi database terkait staff
--
-- READ ONLY
-- TIDAK MENGUBAH DATA
-- =========================================================


-- =========================================================
-- 1. STRUKTUR KOLOM STAFF
-- =========================================================

select
    column_name,
    data_type,
    udt_name,
    is_nullable,
    column_default

from information_schema.columns

where table_schema = 'public'
  and table_name = 'staff'

order by ordinal_position;


-- =========================================================
-- 2. FUNGSI DATABASE TERKAIT STAFF
-- =========================================================

select
    routine.proname
        as function_name,

    pg_get_function_identity_arguments(
        routine.oid
    ) as arguments,

    pg_get_function_result(
        routine.oid
    ) as result_type,

    case routine.provolatile
        when 'i' then 'immutable'
        when 's' then 'stable'
        when 'v' then 'volatile'
        else routine.provolatile::text
    end as volatility,

    routine.prosecdef
        as security_definer

from pg_proc as routine

inner join pg_namespace as namespace
    on namespace.oid =
       routine.pronamespace

where namespace.nspname = 'public'

  and routine.prokind = 'f'

  and (
      routine.proname ilike '%staff%'

      or routine.proname ilike '%employee%'

      or routine.proname ilike '%account%'

      or routine.proname ilike '%profile%'
  )

order by
    routine.proname,
    arguments;


-- =========================================================
-- 3. SAMPLE AKUN STAFF
-- =========================================================

select
    staff.id
        as staff_id,

    staff.legacy_staff_id,

    staff.full_name,

    staff.profile_id,

    profile.login_id,

    auth_user.email::text
        as internal_auth_email,

    staff.is_active
        as staff_is_active,

    coalesce(
        profile.is_active,
        false
    ) as account_is_active,

    coalesce(
        jsonb_agg(
            distinct role.code
        ) filter (
            where role.code
                  is not null
        ),
        '[]'::jsonb
    ) as roles

from public.staff as staff

left join public.profiles as profile
    on profile.id =
       staff.profile_id

left join auth.users as auth_user
    on auth_user.id =
       profile.id

left join public.user_roles as user_role
    on user_role.user_id =
       profile.id

left join public.roles as role
    on role.id =
       user_role.role_id

group by
    staff.id,
    staff.legacy_staff_id,
    staff.full_name,
    staff.profile_id,
    profile.login_id,
    auth_user.email,
    staff.is_active,
    profile.is_active

order by
    staff.legacy_staff_id,
    staff.full_name,
    staff.id;


-- =========================================================
-- 4. RINGKASAN AKUN STAFF
-- =========================================================

select
    count(*)
        as total_staff,

    count(*) filter (
        where staff.is_active = true
    ) as active_staff,

    count(*) filter (
        where staff.profile_id is not null
    ) as staff_with_account,

    count(*) filter (
        where staff.profile_id is null
    ) as staff_without_account,

    count(*) filter (
        where staff.profile_id is not null
          and profile.login_id is not null
    ) as staff_with_login_id,

    count(*) filter (
        where staff.profile_id is not null
          and profile.login_id is null
    ) as linked_without_login_id

from public.staff as staff

left join public.profiles as profile
    on profile.id =
       staff.profile_id;