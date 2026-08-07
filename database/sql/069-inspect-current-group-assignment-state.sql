-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 069-inspect-current-group-assignment-state.sql
--
-- PURPOSE:
-- - Memeriksa data kelompok aktual
-- - Memeriksa membership aktif
-- - Memeriksa assignment aktif
-- - Memeriksa index dan partial unique index
-- - Mendeteksi anomali sebelum membuat modul Admin
--
-- READ ONLY
-- TIDAK MENGUBAH DATA
-- =========================================================


with target_tables as (
    select unnest(
        array[
            'care_groups',
            'care_group_members',
            'caregiver_assignments',
            'tahfiz_groups',
            'tahfiz_group_members',
            'tahfiz_supervisor_assignments'
        ]::text[]
    ) as table_name
),

table_indexes as (
    select
        schemaname,
        tablename,
        indexname,
        indexdef

    from pg_indexes

    where schemaname = 'public'

      and tablename in (
          select table_name
          from target_tables
      )
),

care_group_data as (
    select
        care_group.id,
        care_group.academic_year_id,
        care_group.code,
        care_group.name,
        care_group.gender::text
            as gender,
        care_group.description,
        care_group.is_active,

        count(
            distinct member.student_id
        ) filter (
            where member.is_active = true
        )::integer
            as active_member_count,

        count(
            distinct assignment.staff_id
        ) filter (
            where assignment.is_active = true
        )::integer
            as active_caregiver_count,

        count(
            distinct assignment.staff_id
        ) filter (
            where assignment.is_active = true
              and assignment.is_primary = true
        )::integer
            as primary_caregiver_count,

        coalesce(
            jsonb_agg(
                distinct jsonb_build_object(
                    'assignment_id',
                    assignment.id,

                    'staff_id',
                    staff.id,

                    'legacy_staff_id',
                    staff.legacy_staff_id,

                    'full_name',
                    staff.full_name,

                    'is_primary',
                    assignment.is_primary,

                    'assigned_at',
                    assignment.assigned_at
                )
            ) filter (
                where assignment.id is not null
                  and assignment.is_active = true
            ),
            '[]'::jsonb
        ) as caregivers

    from public.care_groups
        as care_group

    left join public.care_group_members
        as member
        on member.care_group_id =
           care_group.id

    left join public.caregiver_assignments
        as assignment
        on assignment.care_group_id =
           care_group.id

    left join public.staff
        as staff
        on staff.id =
           assignment.staff_id

    group by
        care_group.id,
        care_group.academic_year_id,
        care_group.code,
        care_group.name,
        care_group.gender,
        care_group.description,
        care_group.is_active
),

tahfiz_group_data as (
    select
        tahfiz_group.id,
        tahfiz_group.academic_year_id,
        tahfiz_group.code,
        tahfiz_group.name,
        tahfiz_group.grade_level,
        tahfiz_group.gender::text
            as gender,
        tahfiz_group.description,
        tahfiz_group.is_active,

        count(
            distinct member.student_id
        ) filter (
            where member.is_active = true
        )::integer
            as active_member_count,

        count(
            distinct assignment.staff_id
        ) filter (
            where assignment.is_active = true
        )::integer
            as active_supervisor_count,

        count(
            distinct assignment.staff_id
        ) filter (
            where assignment.is_active = true
              and assignment.is_primary = true
        )::integer
            as primary_supervisor_count,

        coalesce(
            jsonb_agg(
                distinct jsonb_build_object(
                    'assignment_id',
                    assignment.id,

                    'staff_id',
                    staff.id,

                    'legacy_staff_id',
                    staff.legacy_staff_id,

                    'full_name',
                    staff.full_name,

                    'is_primary',
                    assignment.is_primary,

                    'assigned_at',
                    assignment.assigned_at
                )
            ) filter (
                where assignment.id is not null
                  and assignment.is_active = true
            ),
            '[]'::jsonb
        ) as supervisors

    from public.tahfiz_groups
        as tahfiz_group

    left join public.tahfiz_group_members
        as member
        on member.tahfiz_group_id =
           tahfiz_group.id

    left join public.tahfiz_supervisor_assignments
        as assignment
        on assignment.tahfiz_group_id =
           tahfiz_group.id

    left join public.staff
        as staff
        on staff.id =
           assignment.staff_id

    group by
        tahfiz_group.id,
        tahfiz_group.academic_year_id,
        tahfiz_group.code,
        tahfiz_group.name,
        tahfiz_group.grade_level,
        tahfiz_group.gender,
        tahfiz_group.description,
        tahfiz_group.is_active
),

multiple_active_care_membership as (
    select
        student.id,
        student.legacy_student_id,
        student.nis,
        student.full_name,

        count(*)::integer
            as active_group_count,

        jsonb_agg(
            jsonb_build_object(
                'group_id',
                care_group.id,

                'group_name',
                care_group.name
            )
            order by care_group.name
        ) as groups

    from public.students
        as student

    inner join public.care_group_members
        as member
        on member.student_id =
           student.id

       and member.is_active =
           true

    inner join public.care_groups
        as care_group
        on care_group.id =
           member.care_group_id

    where student.deleted_at is null

    group by
        student.id,
        student.legacy_student_id,
        student.nis,
        student.full_name

    having count(*) > 1
),

multiple_active_tahfiz_membership as (
    select
        student.id,
        student.legacy_student_id,
        student.nis,
        student.full_name,

        count(*)::integer
            as active_group_count,

        jsonb_agg(
            jsonb_build_object(
                'group_id',
                tahfiz_group.id,

                'group_name',
                tahfiz_group.name
            )
            order by tahfiz_group.name
        ) as groups

    from public.students
        as student

    inner join public.tahfiz_group_members
        as member
        on member.student_id =
           student.id

       and member.is_active =
           true

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           member.tahfiz_group_id

    where student.deleted_at is null

    group by
        student.id,
        student.legacy_student_id,
        student.nis,
        student.full_name

    having count(*) > 1
),

care_gender_mismatch as (
    select
        student.id
            as student_id,

        student.full_name,

        student.gender::text
            as student_gender,

        care_group.id
            as group_id,

        care_group.name
            as group_name,

        care_group.gender::text
            as group_gender

    from public.care_group_members
        as member

    inner join public.students
        as student
        on student.id =
           member.student_id

    inner join public.care_groups
        as care_group
        on care_group.id =
           member.care_group_id

    where member.is_active = true

      and student.deleted_at is null

      and student.gender <>
          care_group.gender
),

tahfiz_gender_mismatch as (
    select
        student.id
            as student_id,

        student.full_name,

        student.gender::text
            as student_gender,

        tahfiz_group.id
            as group_id,

        tahfiz_group.name
            as group_name,

        tahfiz_group.gender::text
            as group_gender

    from public.tahfiz_group_members
        as member

    inner join public.students
        as student
        on student.id =
           member.student_id

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           member.tahfiz_group_id

    where member.is_active = true

      and student.deleted_at is null

      and student.gender <>
          tahfiz_group.gender
),

care_multiple_primary as (
    select
        care_group.id,
        care_group.name,

        count(*)::integer
            as primary_count

    from public.care_groups
        as care_group

    inner join public.caregiver_assignments
        as assignment
        on assignment.care_group_id =
           care_group.id

       and assignment.is_active =
           true

       and assignment.is_primary =
           true

    group by
        care_group.id,
        care_group.name

    having count(*) > 1
),

tahfiz_multiple_primary as (
    select
        tahfiz_group.id,
        tahfiz_group.name,

        count(*)::integer
            as primary_count

    from public.tahfiz_groups
        as tahfiz_group

    inner join public.tahfiz_supervisor_assignments
        as assignment
        on assignment.tahfiz_group_id =
           tahfiz_group.id

       and assignment.is_active =
           true

       and assignment.is_primary =
           true

    group by
        tahfiz_group.id,
        tahfiz_group.name

    having count(*) > 1
),

inactive_group_active_members as (
    select jsonb_build_object(
        'type',
        'care',

        'membership_id',
        member.id,

        'student_id',
        member.student_id,

        'group_id',
        care_group.id,

        'group_name',
        care_group.name
    ) as item

    from public.care_group_members
        as member

    inner join public.care_groups
        as care_group
        on care_group.id =
           member.care_group_id

    where member.is_active = true
      and care_group.is_active = false

    union all

    select jsonb_build_object(
        'type',
        'tahfiz',

        'membership_id',
        member.id,

        'student_id',
        member.student_id,

        'group_id',
        tahfiz_group.id,

        'group_name',
        tahfiz_group.name
    )

    from public.tahfiz_group_members
        as member

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           member.tahfiz_group_id

    where member.is_active = true
      and tahfiz_group.is_active = false
),

summary_data as (
    select
        (
            select count(*)::integer

            from public.students
                as student

            where student.status = 'active'
              and student.deleted_at is null
        ) as active_students,

        (
            select count(*)::integer
            from public.care_groups
            where is_active = true
        ) as active_care_groups,

        (
            select count(*)::integer
            from public.tahfiz_groups
            where is_active = true
        ) as active_tahfiz_groups,

        (
            select count(*)::integer
            from public.care_group_members
            where is_active = true
        ) as active_care_memberships,

        (
            select count(*)::integer
            from public.tahfiz_group_members
            where is_active = true
        ) as active_tahfiz_memberships,

        (
            select count(*)::integer
            from public.caregiver_assignments
            where is_active = true
        ) as active_caregiver_assignments,

        (
            select count(*)::integer
            from public.tahfiz_supervisor_assignments
            where is_active = true
        ) as active_tahfiz_assignments
)

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Kondisi kelompok dan assignment berhasil diperiksa',

        'inspected_at',
        now(),

        'summary',
        (
            select to_jsonb(summary)
            from summary_data as summary
        ),

        'indexes',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        tablename,

                        'index_name',
                        indexname,

                        'definition',
                        indexdef
                    )
                    order by
                        tablename,
                        indexname
                ),
                '[]'::jsonb
            )

            from table_indexes
        ),

        'care_groups',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(group_data)
                    order by
                        group_data.name
                ),
                '[]'::jsonb
            )

            from care_group_data
                as group_data
        ),

        'tahfiz_groups',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(group_data)
                    order by
                        group_data.grade_level
                            nulls last,

                        group_data.gender,

                        group_data.name
                ),
                '[]'::jsonb
            )

            from tahfiz_group_data
                as group_data
        ),

        'anomalies',
        jsonb_build_object(
            'students_multiple_active_care_groups',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(item)
                        order by item.full_name
                    ),
                    '[]'::jsonb
                )

                from multiple_active_care_membership
                    as item
            ),

            'students_multiple_active_tahfiz_groups',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(item)
                        order by item.full_name
                    ),
                    '[]'::jsonb
                )

                from multiple_active_tahfiz_membership
                    as item
            ),

            'care_gender_mismatch',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(item)
                        order by item.full_name
                    ),
                    '[]'::jsonb
                )

                from care_gender_mismatch
                    as item
            ),

            'tahfiz_gender_mismatch',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(item)
                        order by item.full_name
                    ),
                    '[]'::jsonb
                )

                from tahfiz_gender_mismatch
                    as item
            ),

            'care_groups_multiple_primary_caregivers',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(item)
                        order by item.name
                    ),
                    '[]'::jsonb
                )

                from care_multiple_primary
                    as item
            ),

            'tahfiz_groups_multiple_primary_supervisors',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(item)
                        order by item.name
                    ),
                    '[]'::jsonb
                )

                from tahfiz_multiple_primary
                    as item
            ),

            'active_memberships_in_inactive_groups',
            (
                select coalesce(
                    jsonb_agg(item),
                    '[]'::jsonb
                )

                from inactive_group_active_members
            )
        )
    )
) as current_group_assignment_state;