-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 030-verify-muh-lubis-test-account.sql
-- PURPOSE:
-- - Memastikan akun Auth Muh Lubis terhubung dengan staff
-- - Memastikan dua role tersedia
-- - Memastikan assignment Pengasuhan Putra tersedia
-- - Memastikan assignment Tahfiz 7 Putra tersedia
-- - Tidak mengubah data
-- =========================================================

with target_account as (
    select
        auth_user.id as user_id,
        auth_user.email,
        profile.full_name as profile_name,
        profile.is_active as profile_is_active,

        staff.id as staff_id,
        staff.legacy_staff_id,
        staff.full_name as staff_name,
        staff.position,
        staff.is_active as staff_is_active

    from auth.users as auth_user

    inner join public.profiles as profile
        on profile.id = auth_user.id

    inner join public.staff as staff
        on staff.profile_id = profile.id

    where lower(auth_user.email) =
          lower('muh.lubis.test@emahad.test')
),

role_data as (
    select
        role.code,
        role.name

    from target_account as account

    inner join public.user_roles as user_role
        on user_role.user_id = account.user_id

    inner join public.roles as role
        on role.id = user_role.role_id

    where role.is_active = true
),

care_assignment_data as (
    select
        care_group.name as care_group_name,
        care_group.gender,
        assignment.is_primary,
        assignment.is_active

    from target_account as account

    inner join public.caregiver_assignments as assignment
        on assignment.staff_id = account.staff_id

    inner join public.care_groups as care_group
        on care_group.id = assignment.care_group_id

    inner join public.academic_years as academic_year
        on academic_year.id = care_group.academic_year_id

    where assignment.is_active = true
      and academic_year.name = '2026/2027'
      and academic_year.is_current = true
),

tahfiz_assignment_data as (
    select
        tahfiz_group.name as tahfiz_group_name,
        tahfiz_group.grade_level,
        tahfiz_group.gender,
        assignment.is_primary,
        assignment.is_active

    from target_account as account

    inner join public.tahfiz_supervisor_assignments as assignment
        on assignment.staff_id = account.staff_id

    inner join public.tahfiz_groups as tahfiz_group
        on tahfiz_group.id = assignment.tahfiz_group_id

    inner join public.academic_years as academic_year
        on academic_year.id = tahfiz_group.academic_year_id

    where assignment.is_active = true
      and academic_year.name = '2026/2027'
      and academic_year.is_current = true
),

verification as (
    select
        (
            select count(*)
            from target_account
        ) as account_count,

        (
            select count(*)
            from role_data
        ) as role_count,

        (
            select count(*)
            from role_data
            where code = 'pengasuh'
        ) as caregiver_role_count,

        (
            select count(*)
            from role_data
            where code = 'pembina_tahfiz'
        ) as tahfiz_role_count,

        (
            select count(*)
            from care_assignment_data
            where care_group_name = 'Pengasuhan Putra'
              and gender = 'male'::public.gender_type
        ) as care_assignment_count,

        (
            select count(*)
            from tahfiz_assignment_data
            where tahfiz_group_name = '7 Putra'
              and grade_level = 7
              and gender = 'male'::public.gender_type
        ) as tahfiz_assignment_count
)

select jsonb_pretty(
    jsonb_build_object(
        'all_checks_passed',
        (
            select
                verification.account_count = 1
                and verification.role_count = 2
                and verification.caregiver_role_count = 1
                and verification.tahfiz_role_count = 1
                and verification.care_assignment_count = 1
                and verification.tahfiz_assignment_count = 1
            from verification
        ),

        'account',
        (
            select jsonb_build_object(
                'email',
                email,

                'profile_name',
                profile_name,

                'profile_is_active',
                profile_is_active,

                'legacy_staff_id',
                legacy_staff_id,

                'staff_name',
                staff_name,

                'position',
                position,

                'staff_is_active',
                staff_is_active
            )
            from target_account
        ),

        'roles',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'code',
                        code,

                        'name',
                        name
                    )
                    order by code
                ),
                '[]'::jsonb
            )
            from role_data
        ),

        'care_assignments',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'care_group',
                        care_group_name,

                        'gender',
                        gender,

                        'is_primary',
                        is_primary,

                        'is_active',
                        is_active
                    )
                    order by care_group_name
                ),
                '[]'::jsonb
            )
            from care_assignment_data
        ),

        'tahfiz_assignments',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'tahfiz_group',
                        tahfiz_group_name,

                        'grade_level',
                        grade_level,

                        'gender',
                        gender,

                        'is_primary',
                        is_primary,

                        'is_active',
                        is_active
                    )
                    order by tahfiz_group_name
                ),
                '[]'::jsonb
            )
            from tahfiz_assignment_data
        )
    )
) as verification_result;