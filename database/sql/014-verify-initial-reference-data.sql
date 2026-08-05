-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 014-verify-initial-reference-data.sql
-- PURPOSE:
-- - Memverifikasi tahun ajaran aktif
-- - Memverifikasi kelas
-- - Memverifikasi kelompok pengasuhan
-- - Memverifikasi kelompok tahfiz
-- =========================================================

-- =========================================================
-- 1. ACTIVE ACADEMIC YEAR
-- =========================================================

select
    id,
    name,
    start_date,
    end_date,
    is_current
from public.academic_years
order by start_date desc;

-- =========================================================
-- 2. CLASSES
-- =========================================================

select
    academic_year.name as academic_year,
    class.code,
    class.name,
    class.grade_level,
    class.gender,
    class.is_active
from public.classes as class
inner join public.academic_years as academic_year
    on academic_year.id = class.academic_year_id
where academic_year.name = '2026/2027'
order by class.grade_level, class.name;

-- =========================================================
-- 3. CARE GROUPS
-- =========================================================

select
    academic_year.name as academic_year,
    care_group.code,
    care_group.name,
    care_group.gender,
    care_group.description,
    care_group.is_active
from public.care_groups as care_group
inner join public.academic_years as academic_year
    on academic_year.id = care_group.academic_year_id
where academic_year.name = '2026/2027'
order by care_group.gender;

-- =========================================================
-- 4. TAHFIZ GROUPS
-- =========================================================

select
    academic_year.name as academic_year,
    tahfiz_group.code,
    tahfiz_group.name,
    tahfiz_group.grade_level,
    tahfiz_group.gender,
    tahfiz_group.is_active
from public.tahfiz_groups as tahfiz_group
inner join public.academic_years as academic_year
    on academic_year.id = tahfiz_group.academic_year_id
where academic_year.name = '2026/2027'
order by
    tahfiz_group.grade_level,
    tahfiz_group.gender;

-- =========================================================
-- 5. SUMMARY COUNTS
-- =========================================================

select
    (
        select count(*)
        from public.academic_years
        where name = '2026/2027'
          and is_current = true
    ) as active_academic_year_count,

    (
        select count(*)
        from public.classes as class
        inner join public.academic_years as academic_year
            on academic_year.id = class.academic_year_id
        where academic_year.name = '2026/2027'
          and class.is_active = true
    ) as class_count,

    (
        select count(*)
        from public.care_groups as care_group
        inner join public.academic_years as academic_year
            on academic_year.id = care_group.academic_year_id
        where academic_year.name = '2026/2027'
          and care_group.is_active = true
    ) as care_group_count,

    (
        select count(*)
        from public.tahfiz_groups as tahfiz_group
        inner join public.academic_years as academic_year
            on academic_year.id = tahfiz_group.academic_year_id
        where academic_year.name = '2026/2027'
          and tahfiz_group.is_active = true
    ) as tahfiz_group_count;