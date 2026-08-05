begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 008-academic-structure.sql
-- PURPOSE:
-- - Tahun ajaran
-- - Kelas
-- - Riwayat kelas santri
-- =========================================================

-- =========================================================
-- TABLE: ACADEMIC YEARS
-- =========================================================

create table public.academic_years (
    id uuid primary key default gen_random_uuid(),

    name text not null unique
        check (char_length(btrim(name)) >= 3),

    start_date date not null,
    end_date date not null,

    is_current boolean not null default false,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint academic_years_date_range_check
        check (start_date < end_date)
);

comment on table public.academic_years is
'Tahun ajaran yang digunakan untuk kelas, kelompok pengasuhan, dan kelompok tahfiz.';

comment on column public.academic_years.is_current is
'Hanya satu tahun ajaran yang boleh ditandai sebagai tahun ajaran aktif.';

create unique index academic_years_single_current_idx
    on public.academic_years ((is_current))
    where is_current = true;

create index academic_years_start_date_idx
    on public.academic_years(start_date);

create index academic_years_end_date_idx
    on public.academic_years(end_date);

create trigger set_academic_years_updated_at
before update on public.academic_years
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: CLASSES
-- =========================================================

create table public.classes (
    id uuid primary key default gen_random_uuid(),

    academic_year_id uuid not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    code text not null
        check (char_length(btrim(code)) > 0),

    name text not null
        check (char_length(btrim(name)) > 0),

    grade_level smallint not null
        check (grade_level between 1 and 12),

    gender public.gender_type,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint classes_academic_year_code_unique
        unique (academic_year_id, code),

    constraint classes_academic_year_name_unique
        unique (academic_year_id, name)
);

comment on table public.classes is
'Kelas santri pada satu tahun ajaran.';

comment on column public.classes.gender is
'Boleh kosong jika kelas tidak dibedakan berdasarkan gender.';

create index classes_academic_year_id_idx
    on public.classes(academic_year_id);

create index classes_grade_level_idx
    on public.classes(grade_level);

create index classes_gender_idx
    on public.classes(gender);

create index classes_is_active_idx
    on public.classes(is_active);

create trigger set_classes_updated_at
before update on public.classes
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: CLASS ENROLLMENTS
-- =========================================================

create table public.class_enrollments (
    id uuid primary key default gen_random_uuid(),

    student_id uuid not null
        references public.students(id)
        on update cascade
        on delete restrict,

    class_id uuid not null
        references public.classes(id)
        on update cascade
        on delete restrict,

    enrolled_at date not null default current_date,
    left_at date,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint class_enrollments_student_class_unique
        unique (student_id, class_id),

    constraint class_enrollments_date_range_check
        check (
            left_at is null
            or left_at >= enrolled_at
        ),

    constraint class_enrollments_active_left_at_check
        check (
            is_active = false
            or left_at is null
        )
);

comment on table public.class_enrollments is
'Riwayat kelas santri. Hanya satu enrollment aktif diperbolehkan untuk setiap santri.';

create unique index class_enrollments_one_active_per_student_idx
    on public.class_enrollments(student_id)
    where is_active = true;

create index class_enrollments_student_id_idx
    on public.class_enrollments(student_id);

create index class_enrollments_class_id_idx
    on public.class_enrollments(class_id);

create index class_enrollments_is_active_idx
    on public.class_enrollments(is_active);

create trigger set_class_enrollments_updated_at
before update on public.class_enrollments
for each row
execute function public.set_updated_at();

commit;