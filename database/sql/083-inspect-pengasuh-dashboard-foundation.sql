-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 083-inspect-pengasuh-dashboard-foundation.sql
--
-- PURPOSE:
-- - Audit akun dengan role Pengasuh
-- - Audit hubungan profile -> staff
-- - Audit assignment Pengasuh
-- - Audit kelompok pengasuhan tahun ajaran aktif
-- - Audit jumlah santri per kelompok
-- - Menentukan fondasi RPC Dashboard Pengasuh
--
-- READ ONLY
-- TIDAK MENGUBAH DATA
-- =========================================================


with current_academic_year as (
    select
        academic_year.id,
        academic_year.name,
        academic_year.start_date,
        academic_year.end_date

    from public.academic_years
        as academic_year

    where academic_year.is_current = true

    order by
        academic_year.start_date desc

    limit 1
),


-- =========================================================
-- 1. ACCOUNT YANG MEMILIKI ROLE PENGASUH
-- =========================================================

pengasuh_accounts as (
    select distinct
        profile.id
            as profile_id,

        profile.login_id,

        profile.is_active
            as account_active,

        staff.id
            as staff_id,

        staff.legacy_staff_id,

        staff.full_name,

        staff.position,

        staff.is_active
            as staff_is_active

    from public.profiles
        as profile

    inner join public.user_roles
        as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles
        as role
        on role.id =
           user_role.role_id

    left join public.staff
        as staff
        on staff.profile_id =
           profile.id

    where role.code = 'pengasuh'
),


-- =========================================================
-- 2. ACTIVE CARE ASSIGNMENTS
-- =========================================================

active_care_assignments as (
    select
        assignment.id
            as assignment_id,

        assignment.staff_id,

        assignment.care_group_id,

        assignment.is_primary,

        assignment.assigned_at,

        care_group.code
            as group_code,

        care_group.name
            as group_name,

        care_group.gender::text
            as group_gender,

        care_group.is_active
            as group_is_active,

        academic_year.id
            as academic_year_id,

        academic_year.name
            as academic_year_name,

        academic_year.is_current
            as academic_year_is_current

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

    where assignment.is_active = true
),


-- =========================================================
-- 3. CURRENT GROUP MEMBER COUNTS
-- =========================================================

care_group_member_counts as (
    select
        membership.care_group_id,

        count(*)::integer
            as active_member_count

    from public.care_group_members
        as membership

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where membership.is_active = true

      and student.status = 'active'

      and student.deleted_at is null

    group by
        membership.care_group_id
),


-- =========================================================
-- 4. CURRENT PENGASUH DATA
-- =========================================================

pengasuh_data as (
    select
        account.profile_id,

        account.login_id,

        account.account_active,

        account.staff_id,

        account.legacy_staff_id,

        account.full_name,

        account.position,

        account.staff_is_active,

        coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'assignment_id',
                        assignment.assignment_id,

                        'care_group_id',
                        assignment.care_group_id,

                        'group_code',
                        assignment.group_code,

                        'group_name',
                        assignment.group_name,

                        'group_gender',
                        assignment.group_gender,

                        'academic_year_id',
                        assignment.academic_year_id,

                        'academic_year_name',
                        assignment.academic_year_name,

                        'is_current_academic_year',
                        assignment.academic_year_is_current,

                        'assigned_at',
                        assignment.assigned_at,

                        'active_member_count',
                        coalesce(
                            member_count.active_member_count,
                            0
                        )
                    )

                    order by
                        assignment.group_name
                )

                from active_care_assignments
                    as assignment

                left join care_group_member_counts
                    as member_count
                    on member_count.care_group_id =
                       assignment.care_group_id

                where assignment.staff_id =
                      account.staff_id
            ),
            '[]'::jsonb
        ) as active_assignments,

        (
            select count(*)::integer

            from active_care_assignments
                as assignment

            where assignment.staff_id =
                  account.staff_id
        ) as active_assignment_count,

        (
            select count(*)::integer

            from active_care_assignments
                as assignment

            where assignment.staff_id =
                  account.staff_id

              and assignment.academic_year_is_current =
                  true

              and assignment.group_is_active =
                  true
        ) as current_assignment_count

    from pengasuh_accounts
        as account
),


-- =========================================================
-- 5. ASSIGNMENT TANPA AKUN/ROLE PENGASUH
-- =========================================================

assignment_without_ready_account as (
    select
        assignment.assignment_id,

        assignment.staff_id,

        staff.legacy_staff_id,

        staff.full_name,

        assignment.care_group_id,

        assignment.group_name,

        staff.profile_id,

        profile.login_id,

        coalesce(
            profile.is_active,
            false
        ) as account_active,

        staff.is_active
            as staff_is_active,

        exists (
            select 1

            from public.user_roles
                as user_role

            inner join public.roles
                as role
                on role.id =
                   user_role.role_id

            where user_role.user_id =
                  staff.profile_id

              and role.code =
                  'pengasuh'
        ) as has_pengasuh_role

    from active_care_assignments
        as assignment

    inner join public.staff
        as staff
        on staff.id =
           assignment.staff_id

    left join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    where
        staff.is_active = false

        or staff.profile_id is null

        or coalesce(
            profile.is_active,
            false
        ) = false

        or not exists (
            select 1

            from public.user_roles
                as user_role

            inner join public.roles
                as role
                on role.id =
                   user_role.role_id

            where user_role.user_id =
                  staff.profile_id

              and role.code =
                  'pengasuh'
        )
),


-- =========================================================
-- 6. PENGASUH ROLE TANPA STAFF
-- =========================================================

pengasuh_role_without_staff as (
    select
        account.profile_id,

        account.login_id,

        account.account_active

    from pengasuh_accounts
        as account

    where account.staff_id is null
),


-- =========================================================
-- 7. PENGASUH TANPA CURRENT ASSIGNMENT
-- =========================================================

pengasuh_without_current_assignment as (
    select
        data.profile_id,

        data.login_id,

        data.staff_id,

        data.legacy_staff_id,

        data.full_name

    from pengasuh_data
        as data

    where data.account_active = true

      and data.staff_is_active = true

      and data.current_assignment_count = 0
),


-- =========================================================
-- 8. ASSIGNMENT DI LUAR TAHUN AJARAN AKTIF
-- =========================================================

assignment_outside_current_year as (
    select
        assignment.*

    from active_care_assignments
        as assignment

    where assignment.academic_year_is_current = false

       or assignment.group_is_active = false
),


-- =========================================================
-- 9. GROUP CURRENT YEAR TANPA PENGASUH
-- =========================================================

current_group_without_caregiver as (
    select
        care_group.id
            as care_group_id,

        care_group.code,

        care_group.name,

        care_group.gender::text
            as gender,

        coalesce(
            member_count.active_member_count,
            0
        ) as active_member_count

    from public.care_groups
        as care_group

    inner join current_academic_year
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

    left join care_group_member_counts
        as member_count
        on member_count.care_group_id =
           care_group.id

    where care_group.is_active = true

      and not exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.care_group_id =
                care_group.id

            and assignment.is_active = true
      )
),


-- =========================================================
-- 10. SUMMARY
-- =========================================================

summary_data as (
    select
        (
            select count(*)::integer

            from pengasuh_accounts
        ) as pengasuh_role_accounts,

        (
            select count(*)::integer

            from pengasuh_data

            where account_active = true
              and staff_is_active = true
        ) as operational_pengasuh_accounts,

        (
            select count(*)::integer

            from active_care_assignments
        ) as active_caregiver_assignments,

        (
            select count(*)::integer

            from active_care_assignments

            where academic_year_is_current = true
              and group_is_active = true
        ) as current_caregiver_assignments,

        (
            select count(*)::integer

            from public.care_groups
                as care_group

            inner join current_academic_year
                as academic_year
                on academic_year.id =
                   care_group.academic_year_id

            where care_group.is_active = true
        ) as current_care_groups,

        (
            select coalesce(
                sum(
                    member_count.active_member_count
                ),
                0
            )::integer

            from care_group_member_counts
                as member_count

            inner join public.care_groups
                as care_group
                on care_group.id =
                   member_count.care_group_id

            inner join current_academic_year
                as academic_year
                on academic_year.id =
                   care_group.academic_year_id

            where care_group.is_active = true
        ) as current_active_members,

        (
            select count(*)::integer

            from assignment_without_ready_account
        ) as assignment_account_anomaly_count,

        (
            select count(*)::integer

            from pengasuh_role_without_staff
        ) as pengasuh_without_staff_count,

        (
            select count(*)::integer

            from pengasuh_without_current_assignment
        ) as pengasuh_without_current_assignment_count,

        (
            select count(*)::integer

            from assignment_outside_current_year
        ) as assignment_outside_current_year_count,

        (
            select count(*)::integer

            from current_group_without_caregiver
        ) as group_without_caregiver_count
)


-- =========================================================
-- 11. FINAL RESULT
-- =========================================================

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Fondasi Dashboard Pengasuh berhasil diperiksa',

        'inspected_at',
        now(),

        'current_academic_year',
        (
            select
                case
                    when academic_year.id is null
                        then null

                    else jsonb_build_object(
                        'id',
                        academic_year.id,

                        'name',
                        academic_year.name,

                        'start_date',
                        academic_year.start_date,

                        'end_date',
                        academic_year.end_date
                    )
                end

            from current_academic_year
                as academic_year
        ),

        'summary',
        (
            select to_jsonb(
                summary_row
            )

            from summary_data
                as summary_row
        ),

        'pengasuh',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'profile_id',
                        data.profile_id,

                        'login_id',
                        data.login_id,

                        'account_active',
                        data.account_active,

                        'staff_id',
                        data.staff_id,

                        'legacy_staff_id',
                        data.legacy_staff_id,

                        'full_name',
                        data.full_name,

                        'position',
                        data.position,

                        'staff_is_active',
                        data.staff_is_active,

                        'active_assignment_count',
                        data.active_assignment_count,

                        'current_assignment_count',
                        data.current_assignment_count,

                        'active_assignments',
                        data.active_assignments
                    )

                    order by
                        data.full_name
                ),
                '[]'::jsonb
            )

            from pengasuh_data
                as data
        ),

        'anomalies',
        jsonb_build_object(
            'assignment_without_ready_account',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly
                        )
                    ),
                    '[]'::jsonb
                )

                from assignment_without_ready_account
                    as anomaly
            ),

            'pengasuh_role_without_staff',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly
                        )
                    ),
                    '[]'::jsonb
                )

                from pengasuh_role_without_staff
                    as anomaly
            ),

            'pengasuh_without_current_assignment',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly
                        )
                    ),
                    '[]'::jsonb
                )

                from pengasuh_without_current_assignment
                    as anomaly
            ),

            'assignment_outside_current_year',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly
                        )
                    ),
                    '[]'::jsonb
                )

                from assignment_outside_current_year
                    as anomaly
            ),

            'current_group_without_caregiver',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly
                        )
                    ),
                    '[]'::jsonb
                )

                from current_group_without_caregiver
                    as anomaly
            )
        )
    )
) as pengasuh_dashboard_foundation_inspection;