begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 004-baseline-rls.sql
-- PURPOSE:
-- - Mengaktifkan Row Level Security
-- - Memberikan akses baca minimal
-- - Mencegah akses tabel melalui anon
-- =========================================================

-- =========================================================
-- ENABLE ROW LEVEL SECURITY
-- =========================================================

alter table public.profiles
enable row level security;

alter table public.roles
enable row level security;

alter table public.user_roles
enable row level security;

alter table public.staff
enable row level security;

alter table public.students
enable row level security;

alter table public.guardians
enable row level security;

alter table public.guardian_students
enable row level security;

-- =========================================================
-- TABLE PRIVILEGES
-- =========================================================

revoke all on table public.profiles
from anon, authenticated;

revoke all on table public.roles
from anon, authenticated;

revoke all on table public.user_roles
from anon, authenticated;

revoke all on table public.staff
from anon, authenticated;

revoke all on table public.students
from anon, authenticated;

revoke all on table public.guardians
from anon, authenticated;

revoke all on table public.guardian_students
from anon, authenticated;

grant usage on schema public
to authenticated;

grant select on table public.profiles
to authenticated;

grant select on table public.roles
to authenticated;

grant select on table public.user_roles
to authenticated;

grant select on table public.staff
to authenticated;

grant select on table public.students
to authenticated;

grant select on table public.guardians
to authenticated;

grant select on table public.guardian_students
to authenticated;

-- =========================================================
-- PROFILES POLICIES
-- =========================================================

create policy "Authenticated users can read own profile"
on public.profiles
for select
to authenticated
using (
    id = (select auth.uid())
);

-- =========================================================
-- ROLES POLICIES
-- =========================================================

create policy "Authenticated users can read active roles"
on public.roles
for select
to authenticated
using (
    is_active = true
);

-- =========================================================
-- USER ROLES POLICIES
-- =========================================================

create policy "Authenticated users can read own roles"
on public.user_roles
for select
to authenticated
using (
    user_id = (select auth.uid())
);

-- =========================================================
-- STAFF POLICIES
-- =========================================================

create policy "Staff users can read own staff record"
on public.staff
for select
to authenticated
using (
    profile_id = (select auth.uid())
);

-- =========================================================
-- GUARDIANS POLICIES
-- =========================================================

create policy "Guardians can read own guardian record"
on public.guardians
for select
to authenticated
using (
    profile_id = (select auth.uid())
);

-- =========================================================
-- GUARDIAN STUDENTS POLICIES
-- =========================================================

create policy "Guardians can read own student relationships"
on public.guardian_students
for select
to authenticated
using (
    exists (
        select 1
        from public.guardians
        where guardians.id = guardian_students.guardian_id
          and guardians.profile_id = (select auth.uid())
          and guardians.is_active = true
    )
);

-- =========================================================
-- STUDENTS POLICIES
-- =========================================================

create policy "Guardians can read linked students"
on public.students
for select
to authenticated
using (
    deleted_at is null
    and exists (
        select 1
        from public.guardian_students
        inner join public.guardians
            on guardians.id = guardian_students.guardian_id
        where guardian_students.student_id = students.id
          and guardians.profile_id = (select auth.uid())
          and guardians.is_active = true
    )
);

commit;