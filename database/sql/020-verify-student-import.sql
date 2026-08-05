-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 020-verify-student-import.sql
-- PURPOSE:
-- - Memverifikasi hasil import 126 santri
-- - Memastikan kelas dan kelompok sudah benar
-- - Tidak mengubah data
-- =========================================================

-- =========================================================
-- 1. RINGKASAN SANTRI HASIL IMPORT
-- =========================================================

select
    count(*) as imported_student_count,

    count(*) filter (
        where student.gender = 'male'::public.gender_type
    ) as male_student_count,

    count(*) filter (
        where student.gender = 'female'::public.gender_type
    ) as female_student_count

from public.students as student
where student.legacy_student_id in (
    select import_row.legacy_student_id
    from staging.student_import_rows as import_row
    where import_row.batch_code = '2026-2027-initial'
);

-- Hasil:
-- imported_student_count = 126
-- male_student_count = 65
-- female_student_count = 61

-- =========================================================
-- 2. DISTRIBUSI KELAS AKTIF
-- =========================================================

select
    class.grade_level,
    class.name as class_name,
    count(*) as student_count
from public.class_enrollments as enrollment
inner join public.students as student
    on student.id = enrollment.student_id
inner join public.classes as class
    on class.id = enrollment.class_id
inner join public.academic_years as academic_year
    on academic_year.id = class.academic_year_id
where enrollment.is_active = true
  and academic_year.name = '2026/2027'
  and student.legacy_student_id in (
      select import_row.legacy_student_id
      from staging.student_import_rows as import_row
      where import_row.batch_code = '2026-2027-initial'
  )
group by
    class.grade_level,
    class.name
order by class.grade_level;

-- Hasil:
-- Kelas 7 = 44
-- Kelas 8 = 38
-- Kelas 9 = 44

-- =========================================================
-- 3. DISTRIBUSI KELOMPOK PENGASUHAN
-- =========================================================

select
    care_group.name as care_group_name,
    care_group.gender,
    count(*) as student_count
from public.care_group_members as membership
inner join public.students as student
    on student.id = membership.student_id
inner join public.care_groups as care_group
    on care_group.id = membership.care_group_id
inner join public.academic_years as academic_year
    on academic_year.id = care_group.academic_year_id
where membership.is_active = true
  and academic_year.name = '2026/2027'
  and student.legacy_student_id in (
      select import_row.legacy_student_id
      from staging.student_import_rows as import_row
      where import_row.batch_code = '2026-2027-initial'
  )
group by
    care_group.name,
    care_group.gender
order by care_group.gender;

-- Hasil:
-- Pengasuhan Putra = 65
-- Pengasuhan Putri = 61

-- =========================================================
-- 4. DISTRIBUSI KELOMPOK TAHFIZ
-- =========================================================

select
    tahfiz_group.name as tahfiz_group_name,
    count(*) as student_count
from public.tahfiz_group_members as membership
inner join public.students as student
    on student.id = membership.student_id
inner join public.tahfiz_groups as tahfiz_group
    on tahfiz_group.id = membership.tahfiz_group_id
inner join public.academic_years as academic_year
    on academic_year.id = tahfiz_group.academic_year_id
where membership.is_active = true
  and academic_year.name = '2026/2027'
  and student.legacy_student_id in (
      select import_row.legacy_student_id
      from staging.student_import_rows as import_row
      where import_row.batch_code = '2026-2027-initial'
  )
group by tahfiz_group.name
order by tahfiz_group.name;

-- Hasil:
-- 7 Putra = 24
-- 7 Putri = 20
-- 8 Putra = 18
-- 8 Putri = 20
-- 9 Putra = 23
-- 9 Putri = 21

-- =========================================================
-- 5. PEMERIKSAAN INTEGRITAS KEANGGOTAAN
-- =========================================================

with imported_students as (
    select student.id
    from public.students as student
    where student.legacy_student_id in (
        select import_row.legacy_student_id
        from staging.student_import_rows as import_row
        where import_row.batch_code = '2026-2027-initial'
    )
)
select
    (
        select count(*)
        from imported_students as imported
        where not exists (
            select 1
            from public.class_enrollments as enrollment
            where enrollment.student_id = imported.id
              and enrollment.is_active = true
        )
    ) as students_without_active_class,

    (
        select count(*)
        from imported_students as imported
        where not exists (
            select 1
            from public.care_group_members as membership
            where membership.student_id = imported.id
              and membership.is_active = true
        )
    ) as students_without_active_care_group,

    (
        select count(*)
        from imported_students as imported
        where not exists (
            select 1
            from public.tahfiz_group_members as membership
            where membership.student_id = imported.id
              and membership.is_active = true
        )
    ) as students_without_active_tahfiz_group,

    (
        select count(*)
        from (
            select enrollment.student_id
            from public.class_enrollments as enrollment
            inner join imported_students as imported
                on imported.id = enrollment.student_id
            where enrollment.is_active = true
            group by enrollment.student_id
            having count(*) > 1
        ) as duplicated_class_membership
    ) as students_with_multiple_active_classes,

    (
        select count(*)
        from (
            select membership.student_id
            from public.care_group_members as membership
            inner join imported_students as imported
                on imported.id = membership.student_id
            where membership.is_active = true
            group by membership.student_id
            having count(*) > 1
        ) as duplicated_care_membership
    ) as students_with_multiple_active_care_groups,

    (
        select count(*)
        from (
            select membership.student_id
            from public.tahfiz_group_members as membership
            inner join imported_students as imported
                on imported.id = membership.student_id
            where membership.is_active = true
            group by membership.student_id
            having count(*) > 1
        ) as duplicated_tahfiz_membership
    ) as students_with_multiple_active_tahfiz_groups;

-- Semua hasil harus 0.

-- =========================================================
-- 6. PEMERIKSAAN KESESUAIAN GENDER PENGASUHAN
-- =========================================================

select
    student.legacy_student_id,
    student.full_name,
    student.gender as student_gender,
    care_group.name as care_group_name,
    care_group.gender as care_group_gender
from public.students as student
inner join public.care_group_members as membership
    on membership.student_id = student.id
   and membership.is_active = true
inner join public.care_groups as care_group
    on care_group.id = membership.care_group_id
where student.legacy_student_id in (
    select import_row.legacy_student_id
    from staging.student_import_rows as import_row
    where import_row.batch_code = '2026-2027-initial'
)
and student.gender <> care_group.gender
order by student.full_name;

-- Hasil yang diharapkan: 0 baris.

-- =========================================================
-- 7. PEMERIKSAAN KESESUAIAN GENDER KELOMPOK TAHFIZ
-- =========================================================

select
    student.legacy_student_id,
    student.full_name,
    student.gender as student_gender,
    tahfiz_group.name as tahfiz_group_name,
    tahfiz_group.gender as tahfiz_group_gender
from public.students as student
inner join public.tahfiz_group_members as membership
    on membership.student_id = student.id
   and membership.is_active = true
inner join public.tahfiz_groups as tahfiz_group
    on tahfiz_group.id = membership.tahfiz_group_id
where student.legacy_student_id in (
    select import_row.legacy_student_id
    from staging.student_import_rows as import_row
    where import_row.batch_code = '2026-2027-initial'
)
and student.gender <> tahfiz_group.gender
order by student.full_name;

-- Hasil yang diharapkan: 0 baris.

-- =========================================================
-- 8. EMPAT DATA YANG SEBELUMNYA DIKOREKSI
-- =========================================================

select
    student.legacy_student_id,
    student.full_name,
    student.gender,
    class.name as class_name,
    care_group.name as care_group_name,
    tahfiz_group.name as tahfiz_group_name
from public.students as student

inner join public.class_enrollments as enrollment
    on enrollment.student_id = student.id
   and enrollment.is_active = true

inner join public.classes as class
    on class.id = enrollment.class_id

inner join public.care_group_members as care_membership
    on care_membership.student_id = student.id
   and care_membership.is_active = true

inner join public.care_groups as care_group
    on care_group.id = care_membership.care_group_id

inner join public.tahfiz_group_members as tahfiz_membership
    on tahfiz_membership.student_id = student.id
   and tahfiz_membership.is_active = true

inner join public.tahfiz_groups as tahfiz_group
    on tahfiz_group.id = tahfiz_membership.tahfiz_group_id

where student.legacy_student_id in (
    '247211',
    '247112',
    '257134',
    '267203'
)
order by student.legacy_student_id;