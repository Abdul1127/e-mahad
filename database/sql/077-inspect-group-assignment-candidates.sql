-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 077-inspect-group-assignment-candidates.sql
--
-- PURPOSE:
-- - Audit kandidat Pengasuh
-- - Audit kandidat Pembina Tahfiz
-- - Membandingkan role akun dengan assignment aktif
-- - Memeriksa status staf dan akun
-- - Menentukan aturan aman sebelum fitur write assignment
--
-- READ ONLY
-- TIDAK MENGUBAH DATA
-- =========================================================


with staff_role_data as (
    select
        staff.id
            as staff_id,

        staff.legacy_staff_id,

        staff.full_name,

        staff.position,

        staff.is_active
            as staff_is_active,

        staff.profile_id,

        profile.login_id,

        coalesce(
            profile.is_active,
            false
        ) as account_active,

        coalesce(
            jsonb_agg(
                distinct role.code
                order by role.code
            ) filter (
                where role.code is not null
            ),
            '[]'::jsonb
        ) as roles,

        bool_or(
            role.code = 'pengasuh'
        ) as has_pengasuh_role,

        bool_or(
            role.code = 'pembina_tahfiz'
        ) as has_pembina_tahfiz_role

    from public.staff
        as staff

    left join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    left join public.user_roles
        as user_role
        on user_role.user_id =
           profile.id

    left join public.roles
        as role
        on role.id =
           user_role.role_id

    group by
        staff.id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.position,
        staff.is_active,
        staff.profile_id,
        profile.login_id,
        profile.is_active
),


-- =========================================================
-- CARE ASSIGNMENTS
-- =========================================================

care_assignment_data as (
    select
        assignment.id
            as assignment_id,

        assignment.staff_id,

        assignment.care_group_id,

        care_group.name
            as group_name,

        care_group.gender::text
            as group_gender,

        assignment.is_primary,

        assignment.assigned_at,

        assignment.ended_at,

        assignment.is_active

    from public.caregiver_assignments
        as assignment

    inner join public.care_groups
        as care_group
        on care_group.id =
           assignment.care_group_id

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

    where academic_year.is_current = true
),


-- =========================================================
-- TAHFIZ ASSIGNMENTS
-- =========================================================

tahfiz_assignment_data as (
    select
        assignment.id
            as assignment_id,

        assignment.staff_id,

        assignment.tahfiz_group_id,

        tahfiz_group.name
            as group_name,

        tahfiz_group.grade_level,

        tahfiz_group.gender::text
            as group_gender,

        assignment.is_primary,

        assignment.assigned_at,

        assignment.ended_at,

        assignment.is_active

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           assignment.tahfiz_group_id

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           tahfiz_group.academic_year_id

    where academic_year.is_current = true
),


-- =========================================================
-- PENGASUH CANDIDATES
-- =========================================================

caregiver_candidates as (
    select
        staff_data.staff_id,

        staff_data.legacy_staff_id,

        staff_data.full_name,

        staff_data.position,

        staff_data.staff_is_active,

        staff_data.profile_id,

        staff_data.login_id,

        staff_data.account_active,

        staff_data.roles,

        (
            staff_data.staff_is_active
            and staff_data.has_pengasuh_role
        ) as role_eligible,

        (
            staff_data.staff_is_active
            and staff_data.has_pengasuh_role
            and staff_data.profile_id is not null
            and staff_data.account_active = true
        ) as operationally_ready,

        coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'assignment_id',
                        assignment.assignment_id,

                        'care_group_id',
                        assignment.care_group_id,

                        'group_name',
                        assignment.group_name,

                        'group_gender',
                        assignment.group_gender,

                        'is_primary',
                        assignment.is_primary,

                        'assigned_at',
                        assignment.assigned_at
                    )

                    order by
                        assignment.group_name
                )

                from care_assignment_data
                    as assignment

                where assignment.staff_id =
                      staff_data.staff_id

                  and assignment.is_active = true
            ),
            '[]'::jsonb
        ) as active_assignments

    from staff_role_data
        as staff_data

    where staff_data.staff_is_active = true

      and (
          staff_data.has_pengasuh_role = true

          or lower(
              coalesce(
                  staff_data.position,
                  ''
              )
          ) like '%pengasuh%'
      )
),


-- =========================================================
-- PEMBINA TAHFIZ CANDIDATES
-- =========================================================

tahfiz_candidates as (
    select
        staff_data.staff_id,

        staff_data.legacy_staff_id,

        staff_data.full_name,

        staff_data.position,

        staff_data.staff_is_active,

        staff_data.profile_id,

        staff_data.login_id,

        staff_data.account_active,

        staff_data.roles,

        (
            staff_data.staff_is_active
            and staff_data.has_pembina_tahfiz_role
        ) as role_eligible,

        (
            staff_data.staff_is_active
            and staff_data.has_pembina_tahfiz_role
            and staff_data.profile_id is not null
            and staff_data.account_active = true
        ) as operationally_ready,

        coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'assignment_id',
                        assignment.assignment_id,

                        'tahfiz_group_id',
                        assignment.tahfiz_group_id,

                        'group_name',
                        assignment.group_name,

                        'grade_level',
                        assignment.grade_level,

                        'group_gender',
                        assignment.group_gender,

                        'is_primary',
                        assignment.is_primary,

                        'assigned_at',
                        assignment.assigned_at
                    )

                    order by
                        assignment.grade_level,
                        assignment.group_gender,
                        assignment.group_name
                )

                from tahfiz_assignment_data
                    as assignment

                where assignment.staff_id =
                      staff_data.staff_id

                  and assignment.is_active = true
            ),
            '[]'::jsonb
        ) as active_assignments

    from staff_role_data
        as staff_data

    where staff_data.staff_is_active = true

      and (
          staff_data.has_pembina_tahfiz_role = true

          or lower(
              coalesce(
                  staff_data.position,
                  ''
              )
          ) like '%pembina tahfiz%'
      )
),


-- =========================================================
-- ACTIVE CARE ASSIGNMENT ANOMALIES
-- =========================================================

care_assignment_anomalies as (
    select
        jsonb_build_object(
            'assignment_id',
            assignment.assignment_id,

            'staff_id',
            staff_data.staff_id,

            'legacy_staff_id',
            staff_data.legacy_staff_id,

            'full_name',
            staff_data.full_name,

            'group_name',
            assignment.group_name,

            'staff_is_active',
            staff_data.staff_is_active,

            'profile_id',
            staff_data.profile_id,

            'login_id',
            staff_data.login_id,

            'account_active',
            staff_data.account_active,

            'has_pengasuh_role',
            staff_data.has_pengasuh_role,

            'issue',
            case
                when staff_data.staff_is_active = false
                    then 'staff_inactive'

                when staff_data.profile_id is null
                    then 'account_not_linked'

                when staff_data.account_active = false
                    then 'account_inactive'

                when staff_data.has_pengasuh_role = false
                    then 'missing_pengasuh_role'

                else 'unknown'
            end
        ) as item

    from care_assignment_data
        as assignment

    inner join staff_role_data
        as staff_data
        on staff_data.staff_id =
           assignment.staff_id

    where assignment.is_active = true

      and (
          staff_data.staff_is_active = false
          or staff_data.profile_id is null
          or staff_data.account_active = false
          or staff_data.has_pengasuh_role = false
      )
),


-- =========================================================
-- ACTIVE TAHFIZ ASSIGNMENT ANOMALIES
-- =========================================================

tahfiz_assignment_anomalies as (
    select
        jsonb_build_object(
            'assignment_id',
            assignment.assignment_id,

            'staff_id',
            staff_data.staff_id,

            'legacy_staff_id',
            staff_data.legacy_staff_id,

            'full_name',
            staff_data.full_name,

            'group_name',
            assignment.group_name,

            'staff_is_active',
            staff_data.staff_is_active,

            'profile_id',
            staff_data.profile_id,

            'login_id',
            staff_data.login_id,

            'account_active',
            staff_data.account_active,

            'has_pembina_tahfiz_role',
            staff_data.has_pembina_tahfiz_role,

            'issue',
            case
                when staff_data.staff_is_active = false
                    then 'staff_inactive'

                when staff_data.profile_id is null
                    then 'account_not_linked'

                when staff_data.account_active = false
                    then 'account_inactive'

                when staff_data.has_pembina_tahfiz_role = false
                    then 'missing_pembina_tahfiz_role'

                else 'unknown'
            end
        ) as item

    from tahfiz_assignment_data
        as assignment

    inner join staff_role_data
        as staff_data
        on staff_data.staff_id =
           assignment.staff_id

    where assignment.is_active = true

      and (
          staff_data.staff_is_active = false
          or staff_data.profile_id is null
          or staff_data.account_active = false
          or staff_data.has_pembina_tahfiz_role = false
      )
),


-- =========================================================
-- SUMMARY
-- =========================================================

summary_data as (
    select
        (
            select count(*)::integer

            from staff_role_data

            where staff_is_active = true
        ) as active_staff,

        (
            select count(*)::integer

            from caregiver_candidates
        ) as caregiver_candidate_count,

        (
            select count(*)::integer

            from caregiver_candidates

            where role_eligible = true
        ) as caregiver_role_eligible_count,

        (
            select count(*)::integer

            from caregiver_candidates

            where operationally_ready = true
        ) as caregiver_operationally_ready_count,

        (
            select count(*)::integer

            from tahfiz_candidates
        ) as tahfiz_candidate_count,

        (
            select count(*)::integer

            from tahfiz_candidates

            where role_eligible = true
        ) as tahfiz_role_eligible_count,

        (
            select count(*)::integer

            from tahfiz_candidates

            where operationally_ready = true
        ) as tahfiz_operationally_ready_count,

        (
            select count(*)::integer

            from care_assignment_data

            where is_active = true
        ) as active_caregiver_assignments,

        (
            select count(*)::integer

            from tahfiz_assignment_data

            where is_active = true
        ) as active_tahfiz_assignments,

        (
            select count(*)::integer

            from care_assignment_anomalies
        ) as care_assignment_anomaly_count,

        (
            select count(*)::integer

            from tahfiz_assignment_anomalies
        ) as tahfiz_assignment_anomaly_count
)


-- =========================================================
-- FINAL RESULT
-- =========================================================

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Kandidat assignment staf berhasil diperiksa',

        'inspected_at',
        now(),

        'summary',
        (
            select to_jsonb(summary_data)

            from summary_data
        ),

        'caregiver_candidates',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(candidate)
                    order by
                        candidate.full_name
                ),
                '[]'::jsonb
            )

            from caregiver_candidates
                as candidate
        ),

        'tahfiz_candidates',
        (
            select coalesce(
                jsonb_agg(
                    to_jsonb(candidate)
                    order by
                        candidate.full_name
                ),
                '[]'::jsonb
            )

            from tahfiz_candidates
                as candidate
        ),

        'anomalies',
        jsonb_build_object(
            'care_assignments',
            (
                select coalesce(
                    jsonb_agg(
                        anomaly.item
                    ),
                    '[]'::jsonb
                )

                from care_assignment_anomalies
                    as anomaly
            ),

            'tahfiz_assignments',
            (
                select coalesce(
                    jsonb_agg(
                        anomaly.item
                    ),
                    '[]'::jsonb
                )

                from tahfiz_assignment_anomalies
                    as anomaly
            )
        )
    )
) as group_assignment_candidate_inspection;