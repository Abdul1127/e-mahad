-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 017-validate-student-staging.sql
-- PURPOSE:
-- - Memeriksa kualitas data mentah santri
-- - Tidak mengubah data
-- - Aman dijalankan berulang kali
-- =========================================================

-- =========================================================
-- 1. RINGKASAN DATA
-- =========================================================

select
    count(*) as total_rows,
    count(distinct legacy_student_id) as distinct_student_ids,
    count(distinct lower(btrim(full_name)))
        as distinct_student_names,
    count(*) filter (
        where upper(btrim(gender_code)) = 'L'
    ) as male_rows,
    count(*) filter (
        where upper(btrim(gender_code)) = 'P'
    ) as female_rows
from staging.student_import_rows
where batch_code = '2026-2027-initial';

-- Hasil yang diharapkan:
-- total_rows = 126
-- distinct_student_ids = 126
-- distinct_student_names = 126
-- male_rows = 65
-- female_rows = 61

-- =========================================================
-- 2. DISTRIBUSI KELAS
-- =========================================================

select
    grade_level,
    count(*) as student_count
from staging.student_import_rows
where batch_code = '2026-2027-initial'
group by grade_level
order by grade_level;

-- Hasil yang diharapkan:
-- Kelas 7 = 44
-- Kelas 8 = 38
-- Kelas 9 = 44

-- =========================================================
-- 3. DISTRIBUSI KELOMPOK TAHFIZ
-- =========================================================

select
    upper(
        regexp_replace(
            btrim(tahfiz_group_name),
            '\s+',
            ' ',
            'g'
        )
    ) as tahfiz_group_name,
    count(*) as student_count
from staging.student_import_rows
where batch_code = '2026-2027-initial'
group by 1
order by 1;

-- Hasil yang diharapkan:
-- 7 PUTRA = 24
-- 7 PUTRI = 20
-- 8 PUTRA = 18
-- 8 PUTRI = 20
-- 9 PUTRA = 23
-- 9 PUTRI = 21

-- =========================================================
-- 4. DUPLIKASI ID SANTRI
-- =========================================================

select
    legacy_student_id,
    count(*) as duplicate_count
from staging.student_import_rows
where batch_code = '2026-2027-initial'
group by legacy_student_id
having count(*) > 1
order by legacy_student_id;

-- Hasil yang diharapkan: 0 baris.

-- =========================================================
-- 5. DUPLIKASI NAMA
-- =========================================================

select
    lower(btrim(full_name)) as normalized_name,
    count(*) as duplicate_count,
    string_agg(
        legacy_student_id,
        ', '
        order by legacy_student_id
    ) as student_ids
from staging.student_import_rows
where batch_code = '2026-2027-initial'
group by lower(btrim(full_name))
having count(*) > 1
order by normalized_name;

-- Hasil yang diharapkan: 0 baris.

-- =========================================================
-- 6. DAFTAR MASALAH DATA
-- =========================================================

with normalized as (
    select
        source_row,
        legacy_student_id,
        btrim(full_name) as full_name,
        upper(btrim(gender_code)) as gender_code,
        grade_level,
        upper(
            regexp_replace(
                btrim(tahfiz_group_name),
                '\s+',
                ' ',
                'g'
            )
        ) as tahfiz_group_name,
        btrim(supervisor_name) as supervisor_name
    from staging.student_import_rows
    where batch_code = '2026-2027-initial'
),
issues as (
    select
        source_row,
        legacy_student_id,
        full_name,
        'INVALID_GENDER'::text as issue_code,
        format(
            'Gender harus L atau P, tetapi bernilai "%s".',
            gender_code
        ) as issue_detail
    from normalized
    where gender_code not in ('L', 'P')

    union all

    select
        source_row,
        legacy_student_id,
        full_name,
        'INVALID_GRADE'::text,
        format(
            'Kelas harus 7, 8, atau 9, tetapi bernilai %s.',
            grade_level
        )
    from normalized
    where grade_level not in (7, 8, 9)

    union all

    select
        source_row,
        legacy_student_id,
        full_name,
        'GROUP_GRADE_MISMATCH'::text,
        format(
            'Kelas %s tidak sesuai dengan kelompok "%s".',
            grade_level,
            tahfiz_group_name
        )
    from normalized
    where split_part(tahfiz_group_name, ' ', 1)
          <> grade_level::text

    union all

    select
        source_row,
        legacy_student_id,
        full_name,
        'GROUP_GENDER_MISMATCH'::text,
        format(
            'Gender %s tidak sesuai dengan kelompok "%s".',
            gender_code,
            tahfiz_group_name
        )
    from normalized
    where (
        tahfiz_group_name like '% PUTRA'
        and gender_code <> 'L'
    )
    or (
        tahfiz_group_name like '% PUTRI'
        and gender_code <> 'P'
    )

    union all

    select
        normalized.source_row,
        normalized.legacy_student_id,
        normalized.full_name,
        'UNKNOWN_CLASS'::text,
        format(
            'Kelas %s tidak ditemukan pada tahun ajaran aktif.',
            normalized.grade_level
        )
    from normalized
    where not exists (
        select 1
        from public.classes as class
        inner join public.academic_years as academic_year
            on academic_year.id = class.academic_year_id
        where academic_year.is_current = true
          and class.is_active = true
          and class.grade_level = normalized.grade_level
    )

    union all

    select
        normalized.source_row,
        normalized.legacy_student_id,
        normalized.full_name,
        'UNKNOWN_TAHFIZ_GROUP'::text,
        format(
            'Kelompok Tahfiz "%s" tidak ditemukan pada tahun ajaran aktif.',
            normalized.tahfiz_group_name
        )
    from normalized
    where not exists (
        select 1
        from public.tahfiz_groups as tahfiz_group
        inner join public.academic_years as academic_year
            on academic_year.id = tahfiz_group.academic_year_id
        where academic_year.is_current = true
          and tahfiz_group.is_active = true
          and upper(btrim(tahfiz_group.name))
              = normalized.tahfiz_group_name
    )

    union all

    select
        normalized.source_row,
        normalized.legacy_student_id,
        normalized.full_name,
        'UNKNOWN_CARE_GROUP'::text,
        format(
            'Kelompok pengasuhan untuk gender %s tidak ditemukan.',
            normalized.gender_code
        )
    from normalized
    where normalized.gender_code in ('L', 'P')
      and not exists (
          select 1
          from public.care_groups as care_group
          inner join public.academic_years as academic_year
              on academic_year.id = care_group.academic_year_id
          where academic_year.is_current = true
            and care_group.is_active = true
            and care_group.gender = case
                when normalized.gender_code = 'L'
                    then 'male'::public.gender_type
                when normalized.gender_code = 'P'
                    then 'female'::public.gender_type
            end
      )
)
select
    source_row,
    legacy_student_id,
    full_name,
    issue_code,
    issue_detail
from issues
order by source_row, issue_code;

-- Pada spreadsheet awal, query ini diperkirakan menampilkan
-- 4 masalah GROUP_GENDER_MISMATCH yang perlu dikonfirmasi.

-- =========================================================
-- 7. RINGKASAN JUMLAH MASALAH
-- =========================================================

with normalized as (
    select
        source_row,
        upper(btrim(gender_code)) as gender_code,
        grade_level,
        upper(
            regexp_replace(
                btrim(tahfiz_group_name),
                '\s+',
                ' ',
                'g'
            )
        ) as tahfiz_group_name
    from staging.student_import_rows
    where batch_code = '2026-2027-initial'
),
issue_flags as (
    select
        source_row,
        (
            gender_code not in ('L', 'P')
            or grade_level not in (7, 8, 9)
            or split_part(tahfiz_group_name, ' ', 1)
                <> grade_level::text
            or (
                tahfiz_group_name like '% PUTRA'
                and gender_code <> 'L'
            )
            or (
                tahfiz_group_name like '% PUTRI'
                and gender_code <> 'P'
            )
        ) as has_source_issue
    from normalized
)
select
    count(*) filter (
        where has_source_issue
    ) as invalid_row_count,
    count(*) filter (
        where not has_source_issue
    ) as valid_row_count
from issue_flags;

-- Hasil spreadsheet awal diperkirakan:
-- invalid_row_count = 4
-- valid_row_count = 122

-- =========================================================
-- 8. PEMBINA YANG TERDAPAT PADA DATA SUMBER
-- =========================================================

select
    upper(
        regexp_replace(
            btrim(tahfiz_group_name),
            '\s+',
            ' ',
            'g'
        )
    ) as tahfiz_group_name,
    btrim(supervisor_name) as supervisor_name,
    count(*) as student_count
from staging.student_import_rows
where batch_code = '2026-2027-initial'
group by 1, 2
order by 1, 2;