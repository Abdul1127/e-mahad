-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 023-verify-staff-and-assignments.sql
-- PURPOSE:
-- - Memverifikasi 12 pengurus
-- - Memverifikasi assignment Pengasuh
-- - Memverifikasi assignment Pembina Tahfiz
-- - Menampilkan hasil dalam satu JSON
-- - Tidak mengubah data
-- =========================================================

with expected_staff_ids as (
    select unnest(
        array[
            '22-P-001',
            '20-P-002',
            '20-P-003',
            '22-P-004',
            '22-P-005',
            '22-P-006',
            '24-P-007',
            '24-P-008',
            '25-P-009',
            '25-P-010',
            '25-P-011',
            '26-P-012'
        ]::text[]
    ) as legacy_staff_id
),

staff_data as (
    select
        staff.id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.position,
        staff.is_active,
        staff.profile_id,
        staff.profile_id is not null as account_linked

    from public.staff as staff

    inner join expected_staff_ids as expected
        on expected.legacy_staff_id =
           staff.legacy_staff_id
),

caregiver_data as (
    select
        staff.legacy_staff_id,
        staff.full_name,
        care_group.name as care_group_name,
        care_group.gender,
        assignment.is_primary,
        assignment.assigned_at,
        assignment.is_active

    from public.caregiver_assignments as assignment

    inner join public.staff as staff
        on staff.id = assignment.staff_id

    inner join public.care_groups as care_group
        on care_group.id = assignment.care_group_id

    inner join public.academic_years as academic_year
        on academic_year.id = care_group.academic_year_id
       and academic_year.name = '2026/2027'

    where assignment.is_active = true
      and staff.legacy_staff_id in (
          '24-P-007',
          '24-P-008',
          '25-P-010',
          '26-P-012'
      )
),

tahfiz_data as (
    select
        staff.legacy_staff_id,
        staff.full_name,
        tahfiz_group.name as tahfiz_group_name,
        tahfiz_group.grade_level,
        tahfiz_group.gender,
        assignment.is_primary,
        assignment.assigned_at,
        assignment.is_active

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.staff as staff
        on staff.id = assignment.staff_id

    inner join public.tahfiz_groups as tahfiz_group
        on tahfiz_group.id = assignment.tahfiz_group_id

    inner join public.academic_years as academic_year
        on academic_year.id = tahfiz_group.academic_year_id
       and academic_year.name = '2026/2027'

    where assignment.is_active = true
      and staff.legacy_staff_id in (
          '24-P-007',
          '24-P-008',
          '25-P-011',
          '22-P-004',
          '25-P-009',
          '22-P-005'
      )
),

care_distribution as (
    select
        care_group_name,
        count(*) as caregiver_count
    from caregiver_data
    group by care_group_name
),

tahfiz_distribution as (
    select
        tahfiz_group_name,
        count(*) as supervisor_count,
        count(*) filter (
            where is_primary = true
        ) as primary_supervisor_count
    from tahfiz_data
    group by tahfiz_group_name
),

verification as (
    select
        (
            select count(*)
            from staff_data
        ) as staff_count,

        (
            select count(*)
            from caregiver_data
        ) as caregiver_assignment_count,

        (
            select count(*)
            from tahfiz_data
        ) as tahfiz_assignment_count,

        (
            select count(*)
            from staff_data
            where account_linked = true
        ) as linked_account_count,

        (
            select count(*)
            from staff_data
            where account_linked = false
        ) as unlinked_account_count,

        (
            select count(*) = 2
                   and sum(caregiver_count) = 4
                   and bool_and(caregiver_count = 2)
            from care_distribution
        ) as care_distribution_valid,

        (
            select count(*) = 6
                   and sum(supervisor_count) = 6
                   and bool_and(supervisor_count = 1)
                   and bool_and(
                       primary_supervisor_count = 1
                   )
            from tahfiz_distribution
        ) as tahfiz_distribution_valid
)

select jsonb_pretty(
    jsonb_build_object(
        'all_checks_passed',
        (
            select
                verification.staff_count = 12
                and verification.caregiver_assignment_count = 4
                and verification.tahfiz_assignment_count = 6
                and verification.care_distribution_valid = true
                and verification.tahfiz_distribution_valid = true
            from verification
        ),

        'summary',
        (
            select jsonb_build_object(
                'staff_count',
                verification.staff_count,

                'caregiver_assignment_count',
                verification.caregiver_assignment_count,

                'tahfiz_assignment_count',
                verification.tahfiz_assignment_count,

                'linked_account_count',
                verification.linked_account_count,

                'unlinked_account_count',
                verification.unlinked_account_count,

                'care_distribution_valid',
                verification.care_distribution_valid,

                'tahfiz_distribution_valid',
                verification.tahfiz_distribution_valid
            )
            from verification
        ),

        'staff',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'legacy_staff_id',
                        legacy_staff_id,

                        'full_name',
                        full_name,

                        'position',
                        position,

                        'is_active',
                        is_active,

                        'account_linked',
                        account_linked
                    )
                    order by legacy_staff_id
                ),
                '[]'::jsonb
            )
            from staff_data
        ),

        'caregiver_assignments',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'legacy_staff_id',
                        legacy_staff_id,

                        'full_name',
                        full_name,

                        'care_group',
                        care_group_name,

                        'gender',
                        gender,

                        'is_primary',
                        is_primary
                    )
                    order by
                        care_group_name,
                        full_name
                ),
                '[]'::jsonb
            )
            from caregiver_data
        ),

        'care_distribution',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'care_group',
                        care_group_name,

                        'caregiver_count',
                        caregiver_count
                    )
                    order by care_group_name
                ),
                '[]'::jsonb
            )
            from care_distribution
        ),

        'tahfiz_assignments',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'legacy_staff_id',
                        legacy_staff_id,

                        'full_name',
                        full_name,

                        'tahfiz_group',
                        tahfiz_group_name,

                        'grade_level',
                        grade_level,

                        'gender',
                        gender,

                        'is_primary',
                        is_primary
                    )
                    order by
                        grade_level,
                        gender
                ),
                '[]'::jsonb
            )
            from tahfiz_data
        ),

        'tahfiz_distribution',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'tahfiz_group',
                        tahfiz_group_name,

                        'supervisor_count',
                        supervisor_count,

                        'primary_supervisor_count',
                        primary_supervisor_count
                    )
                    order by tahfiz_group_name
                ),
                '[]'::jsonb
            )
            from tahfiz_distribution
        )
    )
) as verification_result;