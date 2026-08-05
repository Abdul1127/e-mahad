begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 009-care-structure.sql
-- PURPOSE:
-- - Kelompok pengasuhan
-- - Anggota kelompok pengasuhan
-- - Assignment Pengasuh
-- =========================================================

-- =========================================================
-- TABLE: CARE GROUPS
-- =========================================================

create table public.care_groups (
    id uuid primary key default gen_random_uuid(),

    academic_year_id uuid not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    code text not null
        check (char_length(btrim(code)) > 0),

    name text not null
        check (char_length(btrim(name)) > 0),

    gender public.gender_type not null,

    description text,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint care_groups_academic_year_code_unique
        unique (academic_year_id, code),

    constraint care_groups_academic_year_name_unique
        unique (academic_year_id, name)
);

comment on table public.care_groups is
'Kelompok pengasuhan santri. Pada MVP digunakan untuk Pengasuhan Putra dan Pengasuhan Putri.';

comment on column public.care_groups.gender is
'Cakupan gender kelompok pengasuhan.';

create index care_groups_academic_year_id_idx
    on public.care_groups(academic_year_id);

create index care_groups_gender_idx
    on public.care_groups(gender);

create index care_groups_is_active_idx
    on public.care_groups(is_active);

create trigger set_care_groups_updated_at
before update on public.care_groups
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: CARE GROUP MEMBERS
-- =========================================================

create table public.care_group_members (
    id uuid primary key default gen_random_uuid(),

    care_group_id uuid not null
        references public.care_groups(id)
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

    constraint care_group_members_group_student_unique
        unique (care_group_id, student_id),

    constraint care_group_members_date_range_check
        check (
            left_at is null
            or left_at >= joined_at
        ),

    constraint care_group_members_active_left_at_check
        check (
            is_active = false
            or left_at is null
        )
);

comment on table public.care_group_members is
'Keanggotaan santri dalam kelompok pengasuhan.';

create unique index care_group_members_one_active_per_student_idx
    on public.care_group_members(student_id)
    where is_active = true;

create index care_group_members_care_group_id_idx
    on public.care_group_members(care_group_id);

create index care_group_members_student_id_idx
    on public.care_group_members(student_id);

create index care_group_members_is_active_idx
    on public.care_group_members(is_active);

create trigger set_care_group_members_updated_at
before update on public.care_group_members
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: CAREGIVER ASSIGNMENTS
-- =========================================================

create table public.caregiver_assignments (
    id uuid primary key default gen_random_uuid(),

    staff_id uuid not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    care_group_id uuid not null
        references public.care_groups(id)
        on update cascade
        on delete restrict,

    is_primary boolean not null default false,

    assigned_at date not null default current_date,
    ended_at date,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint caregiver_assignments_date_range_check
        check (
            ended_at is null
            or ended_at >= assigned_at
        ),

    constraint caregiver_assignments_active_ended_at_check
        check (
            is_active = false
            or ended_at is null
        )
);

comment on table public.caregiver_assignments is
'Assignment Pengasuh terhadap kelompok pengasuhan Putra atau Putri.';

create unique index caregiver_assignments_active_pair_unique_idx
    on public.caregiver_assignments(staff_id, care_group_id)
    where is_active = true;

create unique index caregiver_assignments_one_primary_per_group_idx
    on public.caregiver_assignments(care_group_id)
    where is_active = true
      and is_primary = true;

create index caregiver_assignments_staff_id_idx
    on public.caregiver_assignments(staff_id);

create index caregiver_assignments_care_group_id_idx
    on public.caregiver_assignments(care_group_id);

create index caregiver_assignments_is_active_idx
    on public.caregiver_assignments(is_active);

create trigger set_caregiver_assignments_updated_at
before update on public.caregiver_assignments
for each row
execute function public.set_updated_at();

commit;