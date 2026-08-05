begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 013-seed-academic-year-2026-2027.sql
-- PURPOSE:
-- - Membuat tahun ajaran aktif 2026/2027
-- - Membuat kelas 7, 8, dan 9
-- - Membuat kelompok pengasuhan Putra dan Putri
-- - Membuat enam kelompok tahfiz
-- =========================================================

-- =========================================================
-- 1. ACADEMIC YEAR 2026/2027
-- =========================================================

insert into public.academic_years (
    name,
    start_date,
    end_date,
    is_current
)
values (
    '2026/2027',
    date '2026-07-01',
    date '2027-06-30',
    false
)
on conflict (name)
do update set
    start_date = excluded.start_date,
    end_date = excluded.end_date,
    updated_at = now();

-- Nonaktifkan tahun ajaran lain terlebih dahulu agar
-- partial unique index is_current tidak mengalami konflik.
update public.academic_years
set
    is_current = false,
    updated_at = now()
where name <> '2026/2027'
  and is_current = true;

update public.academic_years
set
    is_current = true,
    updated_at = now()
where name = '2026/2027';

-- =========================================================
-- 2. CLASSES
-- =========================================================

insert into public.classes (
    academic_year_id,
    code,
    name,
    grade_level,
    gender,
    is_active
)
select
    academic_year.id,
    seed.code,
    seed.name,
    seed.grade_level,
    null,
    true
from public.academic_years as academic_year
cross join (
    values
        ('CLASS-7', 'Kelas 7', 7::smallint),
        ('CLASS-8', 'Kelas 8', 8::smallint),
        ('CLASS-9', 'Kelas 9', 9::smallint)
) as seed (
    code,
    name,
    grade_level
)
where academic_year.name = '2026/2027'
on conflict (academic_year_id, code)
do update set
    name = excluded.name,
    grade_level = excluded.grade_level,
    gender = excluded.gender,
    is_active = true,
    updated_at = now();

-- =========================================================
-- 3. CARE GROUPS
-- =========================================================

insert into public.care_groups (
    academic_year_id,
    code,
    name,
    gender,
    description,
    is_active
)
select
    academic_year.id,
    seed.code,
    seed.name,
    seed.gender_value,
    seed.description,
    true
from public.academic_years as academic_year
cross join (
    values
        (
            'CARE-MALE',
            'Pengasuhan Putra',
            'male'::public.gender_type,
            'Kelompok pengasuhan untuk seluruh santri putra.'
        ),
        (
            'CARE-FEMALE',
            'Pengasuhan Putri',
            'female'::public.gender_type,
            'Kelompok pengasuhan untuk seluruh santri putri.'
        )
) as seed (
    code,
    name,
    gender_value,
    description
)
where academic_year.name = '2026/2027'
on conflict (academic_year_id, code)
do update set
    name = excluded.name,
    gender = excluded.gender,
    description = excluded.description,
    is_active = true,
    updated_at = now();

-- =========================================================
-- 4. TAHFIZ GROUPS
-- =========================================================

insert into public.tahfiz_groups (
    academic_year_id,
    code,
    name,
    grade_level,
    gender,
    description,
    is_active
)
select
    academic_year.id,
    seed.code,
    seed.name,
    seed.grade_level,
    seed.gender_value,
    seed.description,
    true
from public.academic_years as academic_year
cross join (
    values
        (
            'TAHFIZ-7-MALE',
            '7 Putra',
            7::smallint,
            'male'::public.gender_type,
            'Kelompok Tahfiz santri kelas 7 Putra.'
        ),
        (
            'TAHFIZ-7-FEMALE',
            '7 Putri',
            7::smallint,
            'female'::public.gender_type,
            'Kelompok Tahfiz santri kelas 7 Putri.'
        ),
        (
            'TAHFIZ-8-MALE',
            '8 Putra',
            8::smallint,
            'male'::public.gender_type,
            'Kelompok Tahfiz santri kelas 8 Putra.'
        ),
        (
            'TAHFIZ-8-FEMALE',
            '8 Putri',
            8::smallint,
            'female'::public.gender_type,
            'Kelompok Tahfiz santri kelas 8 Putri.'
        ),
        (
            'TAHFIZ-9-MALE',
            '9 Putra',
            9::smallint,
            'male'::public.gender_type,
            'Kelompok Tahfiz santri kelas 9 Putra.'
        ),
        (
            'TAHFIZ-9-FEMALE',
            '9 Putri',
            9::smallint,
            'female'::public.gender_type,
            'Kelompok Tahfiz santri kelas 9 Putri.'
        )
) as seed (
    code,
    name,
    grade_level,
    gender_value,
    description
)
where academic_year.name = '2026/2027'
on conflict (academic_year_id, code)
do update set
    name = excluded.name,
    grade_level = excluded.grade_level,
    gender = excluded.gender,
    description = excluded.description,
    is_active = true,
    updated_at = now();

commit;