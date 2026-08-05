begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 010-tahfiz-structure.sql
-- PURPOSE:
-- - Kelompok tahfiz
-- - Anggota kelompok tahfiz
-- - Assignment Pembina Tahfiz
-- =========================================================

-- =========================================================
-- TABLE: TAHFIZ GROUPS
-- =========================================================

create table public.tahfiz_groups (
    id uuid primary key default gen_random_uuid(),

    academic_year_id uuid not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    code text not null
        check (char_length(btrim(code)) > 0),

    name text not null
        check (char_length(btrim(name)) > 0),

    grade_level smallint
        check (
            grade_level is null
            or grade_level between 1 and 12
        ),

    gender public.gender_type not null,

    description text,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint tahfiz_groups_academic_year_code_unique
        unique (academic_year_id, code),

    constraint tahfiz_groups_academic_year_name_unique
        unique (academic_year_id, name)
);

comment on table public.tahfiz_groups is
'Kelompok tahfiz berdasarkan tahun ajaran, tingkat kelas, dan gender.';

create index tahfiz_groups_academic_year_id_idx
    on public.tahfiz_groups(academic_year_id);

create index tahfiz_groups_grade_level_idx
    on public.tahfiz_groups(grade_level);

create index tahfiz_groups_gender_idx
    on public.tahfiz_groups(gender);

create index tahfiz_groups_is_active_idx
    on public.tahfiz_groups(is_active);

create trigger set_tahfiz_groups_updated_at
before update on public.tahfiz_groups
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: TAHFIZ GROUP MEMBERS
-- =========================================================

create table public.tahfiz_group_members (
    id uuid primary key default gen_random_uuid(),

    tahfiz_group_id uuid not null
        references public.tahfiz_groups(id)
        on update cascade
        on delete restrict,

    student_id uuid not null
        references public.students(id)
        on update cascade
        on delete restrict,

    joined_at date not null default current_date,
    left_at date,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint tahfiz_group_members_group_student_unique
        unique (tahfiz_group_id, student_id),

    constraint tahfiz_group_members_date_range_check
        check (
            left_at is null
            or left_at >= joined_at
        ),

    constraint tahfiz_group_members_active_left_at_check
        check (
            is_active = false
            or left_at is null
        )
);

comment on table public.tahfiz_group_members is
'Keanggotaan santri dalam kelompok tahfiz.';

create unique index tahfiz_group_members_one_active_per_student_idx
    on public.tahfiz_group_members(student_id)
    where is_active = true;

create index tahfiz_group_members_tahfiz_group_id_idx
    on public.tahfiz_group_members(tahfiz_group_id);

create index tahfiz_group_members_student_id_idx
    on public.tahfiz_group_members(student_id);

create index tahfiz_group_members_is_active_idx
    on public.tahfiz_group_members(is_active);

create trigger set_tahfiz_group_members_updated_at
before update on public.tahfiz_group_members
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: TAHFIZ SUPERVISOR ASSIGNMENTS
-- =========================================================

create table public.tahfiz_supervisor_assignments (
    id uuid primary key default gen_random_uuid(),

    staff_id uuid not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    tahfiz_group_id uuid not null
        references public.tahfiz_groups(id)
        on update cascade
        on delete restrict,

    is_primary boolean not null default false,

    assigned_at date not null default current_date,
    ended_at date,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint tahfiz_supervisor_assignments_date_range_check
        check (
            ended_at is null
            or ended_at >= assigned_at
        ),

    constraint tahfiz_supervisor_assignments_active_ended_at_check
        check (
            is_active = false
            or ended_at is null
        )
);

comment on table public.tahfiz_supervisor_assignments is
'Assignment Pembina Tahfiz terhadap kelompok tahfiz yang diampu.';

create unique index tahfiz_supervisor_assignments_active_pair_unique_idx
    on public.tahfiz_supervisor_assignments(
        staff_id,
        tahfiz_group_id
    )
    where is_active = true;

create unique index tahfiz_supervisor_assignments_one_primary_per_group_idx
    on public.tahfiz_supervisor_assignments(tahfiz_group_id)
    where is_active = true
      and is_primary = true;

create index tahfiz_supervisor_assignments_staff_id_idx
    on public.tahfiz_supervisor_assignments(staff_id);

create index tahfiz_supervisor_assignments_group_id_idx
    on public.tahfiz_supervisor_assignments(tahfiz_group_id);

create index tahfiz_supervisor_assignments_is_active_idx
    on public.tahfiz_supervisor_assignments(is_active);

create trigger set_tahfiz_supervisor_assignments_updated_at
before update on public.tahfiz_supervisor_assignments
for each row
execute function public.set_updated_at();

commit;