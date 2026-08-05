begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 019-import-students-2026-2027.sql
-- PURPOSE:
-- - Memindahkan 126 data santri dari staging
-- - Membuat enrollment kelas aktif
-- - Membuat keanggotaan pengasuhan
-- - Membuat keanggotaan kelompok tahfiz
-- - Tidak menggunakan temporary table
-- - Aman dijalankan ulang
-- =========================================================

-- =========================================================
-- 1. VALIDASI JUMLAH DAN KUALITAS DATA STAGING
-- =========================================================

do $$
declare
    total_row_count integer;
    invalid_row_count integer;
    duplicate_id_count integer;
    mapped_student_count integer;
begin
    -- Jumlah data harus tepat 126.
    select count(*)
    into total_row_count
    from staging.student_import_rows
    where batch_code = '2026-2027-initial';

    if total_row_count <> 126 then
        raise exception
            'Jumlah data staging harus 126, tetapi ditemukan %.',
            total_row_count;
    end if;

    -- Pastikan gender, kelas, dan kelompok sudah sesuai.
    select count(*)
    into invalid_row_count
    from staging.student_import_rows as source
    where source.batch_code = '2026-2027-initial'
      and (
          upper(btrim(source.gender_code)) not in ('L', 'P')
          or source.grade_level not in (7, 8, 9)
          or (
              upper(
                  regexp_replace(
                      btrim(source.tahfiz_group_name),
                      '\s+',
                      ' ',
                      'g'
                  )
              ) like '% PUTRA'
              and upper(btrim(source.gender_code)) <> 'L'
          )
          or (
              upper(
                  regexp_replace(
                      btrim(source.tahfiz_group_name),
                      '\s+',
                      ' ',
                      'g'
                  )
              ) like '% PUTRI'
              and upper(btrim(source.gender_code)) <> 'P'
          )
          or split_part(
              upper(
                  regexp_replace(
                      btrim(source.tahfiz_group_name),
                      '\s+',
                      ' ',
                      'g'
                  )
              ),
              ' ',
              1
          ) <> source.grade_level::text
      );

    if invalid_row_count > 0 then
        raise exception
            'Masih ditemukan % data staging yang tidak valid.',
            invalid_row_count;
    end if;

    -- Pastikan tidak ada ID santri ganda.
    select count(*)
    into duplicate_id_count
    from (
        select btrim(source.legacy_student_id)
        from staging.student_import_rows as source
        where source.batch_code = '2026-2027-initial'
        group by btrim(source.legacy_student_id)
        having count(*) > 1
    ) as duplicated_ids;

    if duplicate_id_count > 0 then
        raise exception
            'Masih ditemukan % ID santri ganda.',
            duplicate_id_count;
    end if;

    -- Pastikan seluruh data dapat dipetakan ke:
    -- - Tahun ajaran
    -- - Kelas
    -- - Kelompok pengasuhan
    -- - Kelompok tahfiz
    select count(*)
    into mapped_student_count
    from staging.student_import_rows as source

    inner join public.academic_years as academic_year
        on academic_year.name = '2026/2027'
       and academic_year.is_current = true

    inner join public.classes as class
        on class.academic_year_id = academic_year.id
       and class.grade_level = source.grade_level
       and class.is_active = true

    inner join public.care_groups as care_group
        on care_group.academic_year_id = academic_year.id
       and care_group.gender = case
            when upper(btrim(source.gender_code)) = 'L'
                then 'male'::public.gender_type
            when upper(btrim(source.gender_code)) = 'P'
                then 'female'::public.gender_type
       end
       and care_group.is_active = true

    inner join public.tahfiz_groups as tahfiz_group
        on tahfiz_group.academic_year_id = academic_year.id
       and upper(btrim(tahfiz_group.name)) = upper(
            regexp_replace(
                btrim(source.tahfiz_group_name),
                '\s+',
                ' ',
                'g'
            )
       )
       and tahfiz_group.is_active = true

    where source.batch_code = '2026-2027-initial';

    if mapped_student_count <> 126 then
        raise exception
            'Hanya % dari 126 santri yang dapat dipetakan ke struktur aktif.',
            mapped_student_count;
    end if;
end;
$$;

-- =========================================================
-- 2. IMPORT / UPDATE DATA SANTRI
-- =========================================================

insert into public.students (
    legacy_student_id,
    full_name,
    gender,
    status,
    deleted_at
)
select
    btrim(source.legacy_student_id),

    regexp_replace(
        btrim(source.full_name),
        '\s+',
        ' ',
        'g'
    ),

    case upper(btrim(source.gender_code))
        when 'L' then 'male'::public.gender_type
        when 'P' then 'female'::public.gender_type
    end,

    'active'::public.student_status,
    null

from staging.student_import_rows as source
where source.batch_code = '2026-2027-initial'

on conflict (legacy_student_id)
do update set
    full_name = excluded.full_name,
    gender = excluded.gender,
    status = 'active'::public.student_status,
    deleted_at = null,
    updated_at = now();

-- =========================================================
-- 3. NONAKTIFKAN ENROLLMENT KELAS LAMA YANG BERBEDA
-- =========================================================

with target as (
    select
        student.id as student_id,
        class.id as class_id
    from staging.student_import_rows as source

    inner join public.students as student
        on student.legacy_student_id =
           btrim(source.legacy_student_id)

    inner join public.academic_years as academic_year
        on academic_year.name = '2026/2027'
       and academic_year.is_current = true

    inner join public.classes as class
        on class.academic_year_id = academic_year.id
       and class.grade_level = source.grade_level
       and class.is_active = true

    where source.batch_code = '2026-2027-initial'
)
update public.class_enrollments as enrollment
set
    is_active = false,
    left_at = coalesce(
        enrollment.left_at,
        current_date
    ),
    updated_at = now()
from target
where enrollment.student_id = target.student_id
  and enrollment.is_active = true
  and enrollment.class_id <> target.class_id;

-- =========================================================
-- 4. BUAT / AKTIFKAN ENROLLMENT KELAS
-- =========================================================

with target as (
    select
        student.id as student_id,
        class.id as class_id,
        academic_year.start_date as enrolled_at
    from staging.student_import_rows as source

    inner join public.students as student
        on student.legacy_student_id =
           btrim(source.legacy_student_id)

    inner join public.academic_years as academic_year
        on academic_year.name = '2026/2027'
       and academic_year.is_current = true

    inner join public.classes as class
        on class.academic_year_id = academic_year.id
       and class.grade_level = source.grade_level
       and class.is_active = true

    where source.batch_code = '2026-2027-initial'
)
insert into public.class_enrollments as enrollment (
    student_id,
    class_id,
    enrolled_at,
    left_at,
    is_active
)
select
    target.student_id,
    target.class_id,
    target.enrolled_at,
    null,
    true
from target

on conflict (student_id, class_id)
do update set
    enrolled_at = least(
        enrollment.enrolled_at,
        excluded.enrolled_at
    ),
    left_at = null,
    is_active = true,
    updated_at = now();

-- =========================================================
-- 5. NONAKTIFKAN KELOMPOK PENGASUHAN LAMA YANG BERBEDA
-- =========================================================

with target as (
    select
        student.id as student_id,
        care_group.id as care_group_id
    from staging.student_import_rows as source

    inner join public.students as student
        on student.legacy_student_id =
           btrim(source.legacy_student_id)

    inner join public.academic_years as academic_year
        on academic_year.name = '2026/2027'
       and academic_year.is_current = true

    inner join public.care_groups as care_group
        on care_group.academic_year_id = academic_year.id
       and care_group.gender = case
            when upper(btrim(source.gender_code)) = 'L'
                then 'male'::public.gender_type
            when upper(btrim(source.gender_code)) = 'P'
                then 'female'::public.gender_type
       end
       and care_group.is_active = true

    where source.batch_code = '2026-2027-initial'
)
update public.care_group_members as membership
set
    is_active = false,
    left_at = coalesce(
        membership.left_at,
        current_date
    ),
    updated_at = now()
from target
where membership.student_id = target.student_id
  and membership.is_active = true
  and membership.care_group_id <> target.care_group_id;

-- =========================================================
-- 6. BUAT / AKTIFKAN KELOMPOK PENGASUHAN
-- =========================================================

with target as (
    select
        student.id as student_id,
        care_group.id as care_group_id,
        academic_year.start_date as joined_at
    from staging.student_import_rows as source

    inner join public.students as student
        on student.legacy_student_id =
           btrim(source.legacy_student_id)

    inner join public.academic_years as academic_year
        on academic_year.name = '2026/2027'
       and academic_year.is_current = true

    inner join public.care_groups as care_group
        on care_group.academic_year_id = academic_year.id
       and care_group.gender = case
            when upper(btrim(source.gender_code)) = 'L'
                then 'male'::public.gender_type
            when upper(btrim(source.gender_code)) = 'P'
                then 'female'::public.gender_type
       end
       and care_group.is_active = true

    where source.batch_code = '2026-2027-initial'
)
insert into public.care_group_members as membership (
    care_group_id,
    student_id,
    joined_at,
    left_at,
    is_active
)
select
    target.care_group_id,
    target.student_id,
    target.joined_at,
    null,
    true
from target

on conflict (care_group_id, student_id)
do update set
    joined_at = least(
        membership.joined_at,
        excluded.joined_at
    ),
    left_at = null,
    is_active = true,
    updated_at = now();

-- =========================================================
-- 7. NONAKTIFKAN KELOMPOK TAHFIZ LAMA YANG BERBEDA
-- =========================================================

with target as (
    select
        student.id as student_id,
        tahfiz_group.id as tahfiz_group_id
    from staging.student_import_rows as source

    inner join public.students as student
        on student.legacy_student_id =
           btrim(source.legacy_student_id)

    inner join public.academic_years as academic_year
        on academic_year.name = '2026/2027'
       and academic_year.is_current = true

    inner join public.tahfiz_groups as tahfiz_group
        on tahfiz_group.academic_year_id = academic_year.id
       and upper(btrim(tahfiz_group.name)) = upper(
            regexp_replace(
                btrim(source.tahfiz_group_name),
                '\s+',
                ' ',
                'g'
            )
       )
       and tahfiz_group.is_active = true

    where source.batch_code = '2026-2027-initial'
)
update public.tahfiz_group_members as membership
set
    is_active = false,
    left_at = coalesce(
        membership.left_at,
        current_date
    ),
    updated_at = now()
from target
where membership.student_id = target.student_id
  and membership.is_active = true
  and membership.tahfiz_group_id <> target.tahfiz_group_id;

-- =========================================================
-- 8. BUAT / AKTIFKAN KELOMPOK TAHFIZ
-- =========================================================

with target as (
    select
        student.id as student_id,
        tahfiz_group.id as tahfiz_group_id,
        academic_year.start_date as joined_at
    from staging.student_import_rows as source

    inner join public.students as student
        on student.legacy_student_id =
           btrim(source.legacy_student_id)

    inner join public.academic_years as academic_year
        on academic_year.name = '2026/2027'
       and academic_year.is_current = true

    inner join public.tahfiz_groups as tahfiz_group
        on tahfiz_group.academic_year_id = academic_year.id
       and upper(btrim(tahfiz_group.name)) = upper(
            regexp_replace(
                btrim(source.tahfiz_group_name),
                '\s+',
                ' ',
                'g'
            )
       )
       and tahfiz_group.is_active = true

    where source.batch_code = '2026-2027-initial'
)
insert into public.tahfiz_group_members as membership (
    tahfiz_group_id,
    student_id,
    joined_at,
    left_at,
    is_active
)
select
    target.tahfiz_group_id,
    target.student_id,
    target.joined_at,
    null,
    true
from target

on conflict (tahfiz_group_id, student_id)
do update set
    joined_at = least(
        membership.joined_at,
        excluded.joined_at
    ),
    left_at = null,
    is_active = true,
    updated_at = now();

-- =========================================================
-- 9. VERIFIKASI AKHIR DI DALAM TRANSAKSI
-- =========================================================

do $$
declare
    imported_student_count integer;
    active_class_count integer;
    active_care_group_count integer;
    active_tahfiz_group_count integer;
begin
    select count(*)
    into imported_student_count
    from public.students as student
    where student.legacy_student_id in (
        select btrim(source.legacy_student_id)
        from staging.student_import_rows as source
        where source.batch_code = '2026-2027-initial'
    );

    select count(*)
    into active_class_count
    from public.class_enrollments as enrollment
    inner join public.students as student
        on student.id = enrollment.student_id
    where enrollment.is_active = true
      and student.legacy_student_id in (
          select btrim(source.legacy_student_id)
          from staging.student_import_rows as source
          where source.batch_code = '2026-2027-initial'
      );

    select count(*)
    into active_care_group_count
    from public.care_group_members as membership
    inner join public.students as student
        on student.id = membership.student_id
    where membership.is_active = true
      and student.legacy_student_id in (
          select btrim(source.legacy_student_id)
          from staging.student_import_rows as source
          where source.batch_code = '2026-2027-initial'
      );

    select count(*)
    into active_tahfiz_group_count
    from public.tahfiz_group_members as membership
    inner join public.students as student
        on student.id = membership.student_id
    where membership.is_active = true
      and student.legacy_student_id in (
          select btrim(source.legacy_student_id)
          from staging.student_import_rows as source
          where source.batch_code = '2026-2027-initial'
      );

    if imported_student_count <> 126 then
        raise exception
            'Jumlah santri hasil import harus 126, tetapi ditemukan %.',
            imported_student_count;
    end if;

    if active_class_count <> 126 then
        raise exception
            'Jumlah enrollment kelas aktif harus 126, tetapi ditemukan %.',
            active_class_count;
    end if;

    if active_care_group_count <> 126 then
        raise exception
            'Jumlah kelompok pengasuhan aktif harus 126, tetapi ditemukan %.',
            active_care_group_count;
    end if;

    if active_tahfiz_group_count <> 126 then
        raise exception
            'Jumlah kelompok tahfiz aktif harus 126, tetapi ditemukan %.',
            active_tahfiz_group_count;
    end if;
end;
$$;

commit;