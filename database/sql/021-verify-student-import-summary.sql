-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 021-verify-student-import-summary.sql
-- PURPOSE:
-- - Menampilkan seluruh hasil verifikasi import dalam satu hasil
-- - Memudahkan pemeriksaan melalui Supabase SQL Editor
-- - Tidak mengubah data
-- =========================================================

with batch_student_ids as (
    select
        btrim(import_row.legacy_student_id) as legacy_student_id
    from staging.student_import_rows as import_row
    where import_row.batch_code = '2026-2027-initial'
),

imported_students as (
    select
        student.id,
        student.legacy_student_id,
        student.full_name,
        student.gender
    from public.students as student
    inner join batch_student_ids as batch
        on batch.legacy_student_id = student.legacy_student_id
),

student_summary as (
    select
        count(*) as total_students,

        count(*) filter (
            where gender = 'male'::public.gender_type
        ) as male_students,

        count(*) filter (
            where gender = 'female'::public.gender_type
        ) as female_students

    from imported_students
),

class_distribution as (
    select
        class.grade_level,
        class.name as class_name,
        count(*) as student_count

    from imported_students as student

    inner join public.class_enrollments as enrollment
        on enrollment.student_id = student.id
       and enrollment.is_active = true

    inner join public.classes as class
        on class.id = enrollment.class_id

    inner join public.academic_years as academic_year
        on academic_year.id = class.academic_year_id
       and academic_year.name = '2026/2027'

    group by
        class.grade_level,
        class.name
),

care_distribution as (
    select
        care_group.name as care_group_name,
        care_group.gender,
        count(*) as student_count

    from imported_students as student

    inner join public.care_group_members as membership
        on membership.student_id = student.id
       and membership.is_active = true

    inner join public.care_groups as care_group
        on care_group.id = membership.care_group_id

    inner join public.academic_years as academic_year
        on academic_year.id = care_group.academic_year_id
       and academic_year.name = '2026/2027'

    group by
        care_group.name,
        care_group.gender
),

tahfiz_distribution as (
    select
        tahfiz_group.name as tahfiz_group_name,
        count(*) as student_count

    from imported_students as student

    inner join public.tahfiz_group_members as membership
        on membership.student_id = student.id
       and membership.is_active = true

    inner join public.tahfiz_groups as tahfiz_group
        on tahfiz_group.id = membership.tahfiz_group_id

    inner join public.academic_years as academic_year
        on academic_year.id = tahfiz_group.academic_year_id
       and academic_year.name = '2026/2027'

    group by tahfiz_group.name
),

integrity_checks as (
    select
        (
            select count(*)
            from imported_students as student
            where not exists (
                select 1
                from public.class_enrollments as enrollment
                where enrollment.student_id = student.id
                  and enrollment.is_active = true
            )
        ) as without_active_class,

        (
            select count(*)
            from imported_students as student
            where not exists (
                select 1
                from public.care_group_members as membership
                where membership.student_id = student.id
                  and membership.is_active = true
            )
        ) as without_active_care_group,

        (
            select count(*)
            from imported_students as student
            where not exists (
                select 1
                from public.tahfiz_group_members as membership
                where membership.student_id = student.id
                  and membership.is_active = true
            )
        ) as without_active_tahfiz_group,

        (
            select count(*)
            from (
                select enrollment.student_id
                from public.class_enrollments as enrollment
                inner join imported_students as student
                    on student.id = enrollment.student_id
                where enrollment.is_active = true
                group by enrollment.student_id
                having count(*) > 1
            ) as duplicated
        ) as multiple_active_classes,

        (
            select count(*)
            from (
                select membership.student_id
                from public.care_group_members as membership
                inner join imported_students as student
                    on student.id = membership.student_id
                where membership.is_active = true
                group by membership.student_id
                having count(*) > 1
            ) as duplicated
        ) as multiple_active_care_groups,

        (
            select count(*)
            from (
                select membership.student_id
                from public.tahfiz_group_members as membership
                inner join imported_students as student
                    on student.id = membership.student_id
                where membership.is_active = true
                group by membership.student_id
                having count(*) > 1
            ) as duplicated
        ) as multiple_active_tahfiz_groups,

        (
            select count(*)
            from imported_students as student
            inner join public.care_group_members as membership
                on membership.student_id = student.id
               and membership.is_active = true
            inner join public.care_groups as care_group
                on care_group.id = membership.care_group_id
            where student.gender <> care_group.gender
        ) as care_gender_mismatches,

        (
            select count(*)
            from imported_students as student
            inner join public.tahfiz_group_members as membership
                on membership.student_id = student.id
               and membership.is_active = true
            inner join public.tahfiz_groups as tahfiz_group
                on tahfiz_group.id = membership.tahfiz_group_id
            where student.gender <> tahfiz_group.gender
        ) as tahfiz_gender_mismatches
),

corrected_students as (
    select
        student.legacy_student_id,
        student.full_name,
        student.gender,
        class.name as class_name,
        care_group.name as care_group_name,
        tahfiz_group.name as tahfiz_group_name

    from imported_students as student

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
        '247112',
        '247211',
        '257134',
        '267203'
    )
),

corrected_students_check as (
    select
        count(*) as corrected_student_count,

        bool_and(
            case
                when legacy_student_id in ('247112', '257134')
                    then gender = 'male'::public.gender_type
                     and care_group_name = 'Pengasuhan Putra'
                     and tahfiz_group_name like '%Putra'

                when legacy_student_id in ('247211', '267203')
                    then gender = 'female'::public.gender_type
                     and care_group_name = 'Pengasuhan Putri'
                     and tahfiz_group_name like '%Putri'

                else false
            end
        ) as corrected_students_valid

    from corrected_students
)

select
    jsonb_pretty(
        jsonb_build_object(
            'all_checks_passed',
            (
                select
                    summary.total_students = 126
                    and summary.male_students = 65
                    and summary.female_students = 61

                    and (
                        select count(*) = 3
                               and sum(student_count) = 126
                        from class_distribution
                    )

                    and (
                        select count(*) = 2
                               and sum(student_count) = 126
                        from care_distribution
                    )

                    and (
                        select count(*) = 6
                               and sum(student_count) = 126
                        from tahfiz_distribution
                    )

                    and integrity.without_active_class = 0
                    and integrity.without_active_care_group = 0
                    and integrity.without_active_tahfiz_group = 0
                    and integrity.multiple_active_classes = 0
                    and integrity.multiple_active_care_groups = 0
                    and integrity.multiple_active_tahfiz_groups = 0
                    and integrity.care_gender_mismatches = 0
                    and integrity.tahfiz_gender_mismatches = 0

                    and corrected.corrected_student_count = 4
                    and corrected.corrected_students_valid = true

                from student_summary as summary
                cross join integrity_checks as integrity
                cross join corrected_students_check as corrected
            ),

            'student_summary',
            (
                select jsonb_build_object(
                    'total', total_students,
                    'male', male_students,
                    'female', female_students
                )
                from student_summary
            ),

            'class_distribution',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'grade_level', grade_level,
                            'class_name', class_name,
                            'student_count', student_count
                        )
                        order by grade_level
                    ),
                    '[]'::jsonb
                )
                from class_distribution
            ),

            'care_distribution',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'care_group', care_group_name,
                            'gender', gender,
                            'student_count', student_count
                        )
                        order by care_group_name
                    ),
                    '[]'::jsonb
                )
                from care_distribution
            ),

            'tahfiz_distribution',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'tahfiz_group', tahfiz_group_name,
                            'student_count', student_count
                        )
                        order by tahfiz_group_name
                    ),
                    '[]'::jsonb
                )
                from tahfiz_distribution
            ),

            'integrity',
            (
                select to_jsonb(integrity)
                from integrity_checks as integrity
            ),

            'corrected_students',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'legacy_student_id', legacy_student_id,
                            'full_name', full_name,
                            'gender', gender,
                            'class_name', class_name,
                            'care_group_name', care_group_name,
                            'tahfiz_group_name', tahfiz_group_name
                        )
                        order by legacy_student_id
                    ),
                    '[]'::jsonb
                )
                from corrected_students
            )
        )
    ) as verification_result;