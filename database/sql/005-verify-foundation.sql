-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 005-verify-foundation.sql
-- PURPOSE:
-- - Verifikasi hasil tahap fondasi
-- - File ini hanya membaca data
-- - Aman dijalankan lebih dari satu kali
-- =========================================================

-- =========================================================
-- 1. CHECK TABLES
-- =========================================================

select
    table_schema,
    table_name
from information_schema.tables
where table_schema = 'public'
  and table_name in (
      'profiles',
      'roles',
      'user_roles',
      'staff',
      'students',
      'guardians',
      'guardian_students'
  )
order by table_name;

-- =========================================================
-- 2. CHECK ROLE SEEDS
-- =========================================================

select
    id,
    code,
    name,
    is_active
from public.roles
order by id;

-- =========================================================
-- 3. CHECK RLS
-- =========================================================

select
    namespace.nspname as schema_name,
    class.relname as table_name,
    class.relrowsecurity as rls_enabled
from pg_class as class
inner join pg_namespace as namespace
    on namespace.oid = class.relnamespace
where namespace.nspname = 'public'
  and class.relname in (
      'profiles',
      'roles',
      'user_roles',
      'staff',
      'students',
      'guardians',
      'guardian_students'
  )
order by class.relname;

-- =========================================================
-- 4. CHECK POLICIES
-- =========================================================

select
    schemaname,
    tablename,
    policyname,
    roles,
    cmd
from pg_policies
where schemaname = 'public'
  and tablename in (
      'profiles',
      'roles',
      'user_roles',
      'staff',
      'students',
      'guardians',
      'guardian_students'
  )
order by tablename, policyname;

-- =========================================================
-- 5. CHECK AUTH PROFILE TRIGGER
-- =========================================================

select
    trigger_schema,
    event_object_schema,
    event_object_table,
    trigger_name,
    event_manipulation,
    action_timing
from information_schema.triggers
where event_object_schema = 'auth'
  and event_object_table = 'users'
  and trigger_name = 'on_auth_user_created';

-- =========================================================
-- 6. CHECK EXISTING AUTH USERS AND PROFILES
-- =========================================================

select
    auth_user.id,
    auth_user.email,
    auth_user.phone,
    profile.full_name,
    profile.is_active,
    case
        when profile.id is null then 'PROFILE_MISSING'
        else 'PROFILE_OK'
    end as profile_status
from auth.users as auth_user
left join public.profiles as profile
    on profile.id = auth_user.id
order by auth_user.created_at;