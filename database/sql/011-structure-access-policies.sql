begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 011-structure-access-policies.sql
-- PURPOSE:
-- - Helper authorization
-- - RLS tabel struktur
-- - Akses baca berdasarkan role dan assignment
-- =========================================================

-- =========================================================
-- HELPER: USER HAS ROLE
-- =========================================================

create or replace function public.has_role(
    target_role_code text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.user_roles as user_role
        inner join public.roles as role
            on role.id = user_role.role_id
        inner join public.profiles as profile
            on profile.id = user_role.user_id
        where user_role.user_id = auth.uid()
          and role.code = target_role_code
          and role.is_active = true
          and profile.is_active = true
    );
$$;

comment on function public.has_role(text) is
'Memeriksa apakah pengguna yang sedang login memiliki role aktif tertentu.';

revoke all on function public.has_role(text)
from public;

revoke all on function public.has_role(text)
from anon;

grant execute on function public.has_role(text)
to authenticated;

-- =========================================================
-- HELPER: CURRENT STAFF ID
-- =========================================================

create or replace function public.current_staff_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    select staff.id
    from public.staff as staff
    where staff.profile_id = auth.uid()
      and staff.is_active = true
    limit 1;
$$;

comment on function public.current_staff_id() is
'Mengambil ID staff aktif yang terhubung dengan pengguna saat ini.';

revoke all on function public.current_staff_id()
from public;

revoke all on function public.current_staff_id()
from anon;

grant execute on function public.current_staff_id()
to authenticated;

-- =========================================================
-- HELPER: GUARDIAN OF STUDENT
-- =========================================================

create or replace function public.is_guardian_of_student(
    target_student_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.guardians as guardian
        inner join public.guardian_students as guardian_student
            on guardian_student.guardian_id = guardian.id
        where guardian.profile_id = auth.uid()
          and guardian.is_active = true
          and guardian_student.student_id = target_student_id
    );
$$;

comment on function public.is_guardian_of_student(uuid) is
'Memeriksa apakah pengguna saat ini adalah wali dari santri tertentu.';

revoke all on function public.is_guardian_of_student(uuid)
from public;

revoke all on function public.is_guardian_of_student(uuid)
from anon;

grant execute on function public.is_guardian_of_student(uuid)
to authenticated;

-- =========================================================
-- HELPER: CAREGIVER OF STUDENT
-- =========================================================

create or replace function public.is_caregiver_of_student(
    target_student_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.caregiver_assignments as assignment
        inner join public.care_group_members as group_member
            on group_member.care_group_id = assignment.care_group_id
        where assignment.staff_id = public.current_staff_id()
          and assignment.is_active = true
          and group_member.student_id = target_student_id
          and group_member.is_active = true
    );
$$;

comment on function public.is_caregiver_of_student(uuid) is
'Memeriksa apakah santri berada dalam cakupan Pengasuh yang sedang login.';

revoke all on function public.is_caregiver_of_student(uuid)
from public;

revoke all on function public.is_caregiver_of_student(uuid)
from anon;

grant execute on function public.is_caregiver_of_student(uuid)
to authenticated;

-- =========================================================
-- HELPER: TAHFIZ SUPERVISOR OF STUDENT
-- =========================================================

create or replace function public.is_tahfiz_supervisor_of_student(
    target_student_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.tahfiz_supervisor_assignments as assignment
        inner join public.tahfiz_group_members as group_member
            on group_member.tahfiz_group_id = assignment.tahfiz_group_id
        where assignment.staff_id = public.current_staff_id()
          and assignment.is_active = true
          and group_member.student_id = target_student_id
          and group_member.is_active = true
    );
$$;

comment on function public.is_tahfiz_supervisor_of_student(uuid) is
'Memeriksa apakah santri berada dalam kelompok Pembina Tahfiz yang sedang login.';

revoke all on function public.is_tahfiz_supervisor_of_student(uuid)
from public;

revoke all on function public.is_tahfiz_supervisor_of_student(uuid)
from anon;

grant execute on function public.is_tahfiz_supervisor_of_student(uuid)
to authenticated;

-- =========================================================
-- ENABLE ROW LEVEL SECURITY
-- =========================================================

alter table public.academic_years
enable row level security;

alter table public.classes
enable row level security;

alter table public.class_enrollments
enable row level security;

alter table public.care_groups
enable row level security;

alter table public.care_group_members
enable row level security;

alter table public.caregiver_assignments
enable row level security;

alter table public.tahfiz_groups
enable row level security;

alter table public.tahfiz_group_members
enable row level security;

alter table public.tahfiz_supervisor_assignments
enable row level security;

-- =========================================================
-- TABLE PRIVILEGES
-- =========================================================

revoke all on table public.academic_years
from anon, authenticated;

revoke all on table public.classes
from anon, authenticated;

revoke all on table public.class_enrollments
from anon, authenticated;

revoke all on table public.care_groups
from anon, authenticated;

revoke all on table public.care_group_members
from anon, authenticated;

revoke all on table public.caregiver_assignments
from anon, authenticated;

revoke all on table public.tahfiz_groups
from anon, authenticated;

revoke all on table public.tahfiz_group_members
from anon, authenticated;

revoke all on table public.tahfiz_supervisor_assignments
from anon, authenticated;

grant select on table public.academic_years
to authenticated;

grant select on table public.classes
to authenticated;

grant select on table public.class_enrollments
to authenticated;

grant select on table public.care_groups
to authenticated;

grant select on table public.care_group_members
to authenticated;

grant select on table public.caregiver_assignments
to authenticated;

grant select on table public.tahfiz_groups
to authenticated;

grant select on table public.tahfiz_group_members
to authenticated;

grant select on table public.tahfiz_supervisor_assignments
to authenticated;

-- =========================================================
-- ACADEMIC YEAR POLICIES
-- =========================================================

create policy "Authenticated users can read academic years"
on public.academic_years
for select
to authenticated
using (true);

-- =========================================================
-- CLASS POLICIES
-- =========================================================

create policy "Authenticated users can read active classes"
on public.classes
for select
to authenticated
using (
    is_active = true
);

-- =========================================================
-- CLASS ENROLLMENT POLICIES
-- =========================================================

create policy "Authorized users can read class enrollments"
on public.class_enrollments
for select
to authenticated
using (
    public.has_role('admin')
    or public.has_role('penanggung_jawab')
    or public.has_role('kepala_mahad')
    or public.is_guardian_of_student(student_id)
    or public.is_caregiver_of_student(student_id)
    or public.is_tahfiz_supervisor_of_student(student_id)
);

-- =========================================================
-- CARE GROUP POLICIES
-- =========================================================

create policy "Management can read all care groups"
on public.care_groups
for select
to authenticated
using (
    public.has_role('admin')
    or public.has_role('penanggung_jawab')
    or public.has_role('kepala_mahad')
);

create policy "Caregivers can read assigned care groups"
on public.care_groups
for select
to authenticated
using (
    public.has_role('pengasuh')
    and exists (
        select 1
        from public.caregiver_assignments as assignment
        where assignment.care_group_id = care_groups.id
          and assignment.staff_id = public.current_staff_id()
          and assignment.is_active = true
    )
);

-- =========================================================
-- CARE GROUP MEMBER POLICIES
-- =========================================================

create policy "Management can read all care group members"
on public.care_group_members
for select
to authenticated
using (
    public.has_role('admin')
    or public.has_role('penanggung_jawab')
    or public.has_role('kepala_mahad')
);

create policy "Caregivers can read assigned care group members"
on public.care_group_members
for select
to authenticated
using (
    public.has_role('pengasuh')
    and public.is_caregiver_of_student(student_id)
);

-- =========================================================
-- CAREGIVER ASSIGNMENT POLICIES
-- =========================================================

create policy "Management can read all caregiver assignments"
on public.caregiver_assignments
for select
to authenticated
using (
    public.has_role('admin')
    or public.has_role('penanggung_jawab')
    or public.has_role('kepala_mahad')
);

create policy "Caregivers can read own assignments"
on public.caregiver_assignments
for select
to authenticated
using (
    public.has_role('pengasuh')
    and staff_id = public.current_staff_id()
);

-- =========================================================
-- TAHFIZ GROUP POLICIES
-- =========================================================

create policy "Management can read all tahfiz groups"
on public.tahfiz_groups
for select
to authenticated
using (
    public.has_role('admin')
    or public.has_role('penanggung_jawab')
    or public.has_role('kepala_mahad')
);

create policy "Tahfiz supervisors can read assigned groups"
on public.tahfiz_groups
for select
to authenticated
using (
    public.has_role('pembina_tahfiz')
    and exists (
        select 1
        from public.tahfiz_supervisor_assignments as assignment
        where assignment.tahfiz_group_id = tahfiz_groups.id
          and assignment.staff_id = public.current_staff_id()
          and assignment.is_active = true
    )
);

-- =========================================================
-- TAHFIZ GROUP MEMBER POLICIES
-- =========================================================

create policy "Management can read all tahfiz group members"
on public.tahfiz_group_members
for select
to authenticated
using (
    public.has_role('admin')
    or public.has_role('penanggung_jawab')
    or public.has_role('kepala_mahad')
);

create policy "Tahfiz supervisors can read assigned members"
on public.tahfiz_group_members
for select
to authenticated
using (
    public.has_role('pembina_tahfiz')
    and public.is_tahfiz_supervisor_of_student(student_id)
);

-- =========================================================
-- TAHFIZ SUPERVISOR ASSIGNMENT POLICIES
-- =========================================================

create policy "Management can read all tahfiz assignments"
on public.tahfiz_supervisor_assignments
for select
to authenticated
using (
    public.has_role('admin')
    or public.has_role('penanggung_jawab')
    or public.has_role('kepala_mahad')
);

create policy "Tahfiz supervisors can read own assignments"
on public.tahfiz_supervisor_assignments
for select
to authenticated
using (
    public.has_role('pembina_tahfiz')
    and staff_id = public.current_staff_id()
);

commit;