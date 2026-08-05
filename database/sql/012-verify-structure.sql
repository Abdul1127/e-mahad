-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 012-verify-structure.sql
-- PURPOSE:
-- - Verifikasi struktur akademik
-- - Verifikasi pengasuhan
-- - Verifikasi tahfiz
-- - Verifikasi fungsi authorization dan RLS
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
      'academic_years',
      'classes',
      'class_enrollments',
      'care_groups',
      'care_group_members',
      'caregiver_assignments',
      'tahfiz_groups',
      'tahfiz_group_members',
      'tahfiz_supervisor_assignments'
  )
order by table_name;

-- =========================================================
-- 2. CHECK ROW LEVEL SECURITY
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
      'academic_years',
      'classes',
      'class_enrollments',
      'care_groups',
      'care_group_members',
      'caregiver_assignments',
      'tahfiz_groups',
      'tahfiz_group_members',
      'tahfiz_supervisor_assignments'
  )
order by class.relname;

-- =========================================================
-- 3. CHECK POLICIES
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
      'academic_years',
      'classes',
      'class_enrollments',
      'care_groups',
      'care_group_members',
      'caregiver_assignments',
      'tahfiz_groups',
      'tahfiz_group_members',
      'tahfiz_supervisor_assignments'
  )
order by tablename, policyname;

-- =========================================================
-- 4. CHECK AUTHORIZATION FUNCTIONS
-- =========================================================

select
    routine_schema,
    routine_name,
    data_type
from information_schema.routines
where routine_schema = 'public'
  and routine_name in (
      'has_role',
      'current_staff_id',
      'is_guardian_of_student',
      'is_caregiver_of_student',
      'is_tahfiz_supervisor_of_student'
  )
order by routine_name;

-- =========================================================
-- 5. CHECK IMPORTANT UNIQUE INDEXES
-- =========================================================

select
    schemaname,
    tablename,
    indexname,
    indexdef
from pg_indexes
where schemaname = 'public'
  and indexname in (
      'academic_years_single_current_idx',
      'class_enrollments_one_active_per_student_idx',
      'care_group_members_one_active_per_student_idx',
      'caregiver_assignments_active_pair_unique_idx',
      'caregiver_assignments_one_primary_per_group_idx',
      'tahfiz_group_members_one_active_per_student_idx',
      'tahfiz_supervisor_assignments_active_pair_unique_idx',
      'tahfiz_supervisor_assignments_one_primary_per_group_idx'
  )
order by indexname;

-- =========================================================
-- 6. CHECK CURRENT ADMIN ROLE FUNCTION
-- =========================================================

select
    public.has_role('admin') as current_user_is_admin,
    public.current_staff_id() as current_staff_id;

-- Catatan:
-- Ketika query dijalankan melalui SQL Editor sebagai postgres,
-- auth.uid() biasanya bernilai null.
-- Karena itu current_user_is_admin dapat bernilai false.
-- Pengujian role sebenarnya dilakukan setelah login dari aplikasi.