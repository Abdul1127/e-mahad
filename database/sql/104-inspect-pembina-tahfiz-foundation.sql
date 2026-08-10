-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 104-inspect-pembina-tahfiz-foundation.sql
--
-- PURPOSE:
-- - Audit fondasi modul Pembina Tahfiz
-- - READ ONLY
-- - Tidak membuat / mengubah / menghapus data
--
-- CHECK:
-- 1. Tahun ajaran aktif
-- 2. Kelompok Tahfiz aktif
-- 3. Membership santri aktif
-- 4. Akun role Pembina Tahfiz
-- 5. Assignment Pembina Tahfiz
-- 6. Group tanpa pembina
-- 7. Pembina tanpa assignment
-- 8. Assignment tanpa akun/profile
-- 9. Membership ganda
-- 10. Membership santri nonaktif
-- 11. Gender mismatch
-- 12. Ringkasan per kelompok
-- =========================================================


-- =========================================================
-- 1. CURRENT ACADEMIC YEAR
-- =========================================================

select
    academic_year.id
        as academic_year_id,

    academic_year.name
        as academic_year_name,

    academic_year.is_current,

    academic_year.start_date,

    academic_year.end_date

from public.academic_years
    as academic_year

where academic_year.is_current =
      true

order by
    academic_year.start_date desc;


-- =========================================================
-- 2. MAIN FOUNDATION SUMMARY
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
),

active_groups as (
    select
        tahfiz_group.id

    from public.tahfiz_groups
        as tahfiz_group

    inner join current_year
        on current_year.id =
           tahfiz_group.academic_year_id

    where tahfiz_group.is_active =
          true
),

active_memberships as (
    select
        membership.id

    from public.tahfiz_group_members
        as membership

    inner join active_groups
        on active_groups.id =
           membership.tahfiz_group_id

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where membership.is_active =
          true

      and membership.left_at
          is null

      and student.status =
          'active'

      and student.deleted_at
          is null
),

pembina_role_accounts as (
    select distinct
        profile.id
            as profile_id

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

    where role.code =
          'pembina_tahfiz'

      and role.is_active =
          true
),

operational_pembina as (
    select distinct
        staff.id
            as staff_id

    from public.staff
        as staff

    inner join pembina_role_accounts
        on pembina_role_accounts.profile_id =
           staff.profile_id

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    where staff.is_active =
          true

      and profile.is_active =
          true
),

active_assignments as (
    select
        assignment.id

    from public.tahfiz_supervisor_assignments
        as assignment

    where assignment.is_active =
          true

      and assignment.ended_at
          is null
),

current_assignments as (
    select
        assignment.id

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join active_groups
        on active_groups.id =
           assignment.tahfiz_group_id

    where assignment.is_active =
          true

      and assignment.ended_at
          is null
)

select
    (
        select
            count(*)

        from current_year
    )::integer
        as current_academic_year_count,

    (
        select
            count(*)

        from active_groups
    )::integer
        as active_tahfiz_groups,

    (
        select
            count(*)

        from active_memberships
    )::integer
        as active_tahfiz_memberships,

    (
        select
            count(*)

        from pembina_role_accounts
    )::integer
        as pembina_role_accounts,

    (
        select
            count(*)

        from operational_pembina
    )::integer
        as operational_pembina_accounts,

    (
        select
            count(*)

        from active_assignments
    )::integer
        as active_supervisor_assignments,

    (
        select
            count(*)

        from current_assignments
    )::integer
        as current_supervisor_assignments;


-- =========================================================
-- 3. GROUP SUMMARY
--
-- Expected:
-- - 6 active groups
-- - member distribution
-- - supervisor assignment
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    tahfiz_group.id
        as tahfiz_group_id,

    tahfiz_group.code,

    tahfiz_group.name,

    tahfiz_group.grade_level,

    tahfiz_group.gender,

    count(
        distinct membership.student_id
    ) filter (
        where membership.is_active =
              true

          and membership.left_at
              is null

          and student.status =
              'active'

          and student.deleted_at
              is null
    )::integer
        as active_member_count,

    count(
        distinct assignment.staff_id
    ) filter (
        where assignment.is_active =
              true

          and assignment.ended_at
              is null
    )::integer
        as active_supervisor_count,

    count(
        distinct assignment.staff_id
    ) filter (
        where assignment.is_active =
              true

          and assignment.ended_at
              is null

          and assignment.is_primary =
              true
    )::integer
        as primary_supervisor_count

from public.tahfiz_groups
    as tahfiz_group

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

left join public.tahfiz_group_members
    as membership
    on membership.tahfiz_group_id =
       tahfiz_group.id

left join public.students
    as student
    on student.id =
       membership.student_id

left join public.tahfiz_supervisor_assignments
    as assignment
    on assignment.tahfiz_group_id =
       tahfiz_group.id

where tahfiz_group.is_active =
      true

group by
    tahfiz_group.id,
    tahfiz_group.code,
    tahfiz_group.name,
    tahfiz_group.grade_level,
    tahfiz_group.gender

order by
    tahfiz_group.grade_level,
    tahfiz_group.gender,
    tahfiz_group.name;


-- =========================================================
-- 4. ACTIVE PEMBINA + CURRENT ASSIGNMENT
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    staff.id
        as staff_id,

    staff.legacy_staff_id,

    staff.full_name,

    staff.position,

    profile.id
        as profile_id,

    profile.login_id,

    profile.is_active
        as profile_is_active,

    staff.is_active
        as staff_is_active,

    assignment.id
        as assignment_id,

    tahfiz_group.id
        as tahfiz_group_id,

    tahfiz_group.code
        as tahfiz_group_code,

    tahfiz_group.name
        as tahfiz_group_name,

    tahfiz_group.gender
        as tahfiz_group_gender,

    tahfiz_group.grade_level,

    assignment.is_primary,

    assignment.assigned_at,

    assignment.ended_at,

    assignment.is_active
        as assignment_is_active,

    (
        select
            count(*)::integer

        from public.tahfiz_group_members
            as membership

        inner join public.students
            as student
            on student.id =
               membership.student_id

        where membership.tahfiz_group_id =
              tahfiz_group.id

          and membership.is_active =
              true

          and membership.left_at
              is null

          and student.status =
              'active'

          and student.deleted_at
              is null
    ) as active_member_count

from public.staff
    as staff

inner join public.profiles
    as profile
    on profile.id =
       staff.profile_id

inner join public.user_roles
    as user_role
    on user_role.user_id =
       profile.id

inner join public.roles
    as role
    on role.id =
       user_role.role_id

left join public.tahfiz_supervisor_assignments
    as assignment
    on assignment.staff_id =
       staff.id

   and assignment.is_active =
       true

   and assignment.ended_at
       is null

left join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       assignment.tahfiz_group_id

   and tahfiz_group.academic_year_id =
       (
           select id
           from current_year
       )

where role.code =
      'pembina_tahfiz'

  and role.is_active =
      true

order by
    staff.full_name,
    tahfiz_group.name;


-- =========================================================
-- 5. ANOMALY SUMMARY
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
),

active_groups as (
    select
        tahfiz_group.id

    from public.tahfiz_groups
        as tahfiz_group

    inner join current_year
        on current_year.id =
           tahfiz_group.academic_year_id

    where tahfiz_group.is_active =
          true
),

pembina_staff as (
    select distinct
        staff.id
            as staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    inner join public.user_roles
        as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles
        as role
        on role.id =
           user_role.role_id

    where role.code =
          'pembina_tahfiz'

      and role.is_active =
          true

      and staff.is_active =
          true

      and profile.is_active =
          true
)

select

    -- =====================================================
    -- Pembina role tapi staff/profile bermasalah
    -- =====================================================

    (
        select
            count(*)::integer

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

        where role.code =
              'pembina_tahfiz'

          and role.is_active =
              true

          and (
              staff.id is null

              or staff.is_active =
                 false

              or profile.is_active =
                 false
          )
    ) as pembina_without_operational_staff_count,


    -- =====================================================
    -- Current group without supervisor
    -- =====================================================

    (
        select
            count(*)::integer

        from active_groups
            as active_group

        where not exists (
            select 1

            from public.tahfiz_supervisor_assignments
                as assignment

            where assignment.tahfiz_group_id =
                  active_group.id

              and assignment.is_active =
                  true

              and assignment.ended_at
                  is null
        )
    ) as group_without_supervisor_count,


    -- =====================================================
    -- Active Pembina without current assignment
    -- =====================================================

    (
        select
            count(*)::integer

        from pembina_staff
            as pembina

        where not exists (
            select 1

            from public.tahfiz_supervisor_assignments
                as assignment

            inner join active_groups
                on active_groups.id =
                   assignment.tahfiz_group_id

            where assignment.staff_id =
                  pembina.staff_id

              and assignment.is_active =
                  true

              and assignment.ended_at
                  is null
        )
    ) as pembina_without_current_assignment_count,


    -- =====================================================
    -- Assignment staff account anomaly
    -- =====================================================

    (
        select
            count(*)::integer

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join active_groups
            on active_groups.id =
               assignment.tahfiz_group_id

        left join public.staff
            as staff
            on staff.id =
               assignment.staff_id

        left join public.profiles
            as profile
            on profile.id =
               staff.profile_id

        where assignment.is_active =
              true

          and assignment.ended_at
              is null

          and (
              staff.id is null

              or staff.is_active =
                 false

              or profile.id is null

              or profile.is_active =
                 false

              or not exists (
                  select 1

                  from public.user_roles
                      as user_role

                  inner join public.roles
                      as role
                      on role.id =
                         user_role.role_id

                  where user_role.user_id =
                        profile.id

                    and role.code =
                        'pembina_tahfiz'

                    and role.is_active =
                        true
              )
          )
    ) as assignment_account_anomaly_count,


    -- =====================================================
    -- Active assignment outside current year
    -- =====================================================

    (
        select
            count(*)::integer

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               assignment.tahfiz_group_id

        where assignment.is_active =
              true

          and assignment.ended_at
              is null

          and tahfiz_group.academic_year_id <>
              (
                  select
                      id

                  from current_year
              )
    ) as assignment_outside_current_year_count,


    -- =====================================================
    -- Active membership outside current year
    -- =====================================================

    (
        select
            count(*)::integer

        from public.tahfiz_group_members
            as membership

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               membership.tahfiz_group_id

        where membership.is_active =
              true

          and membership.left_at
              is null

          and tahfiz_group.academic_year_id <>
              (
                  select
                      id

                  from current_year
              )
    ) as membership_outside_current_year_count;


-- =========================================================
-- 6. GROUP WITHOUT ACTIVE SUPERVISOR DETAIL
--
-- Expected: 0 rows
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    tahfiz_group.id,

    tahfiz_group.code,

    tahfiz_group.name,

    tahfiz_group.grade_level,

    tahfiz_group.gender

from public.tahfiz_groups
    as tahfiz_group

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

where tahfiz_group.is_active =
      true

  and not exists (
      select 1

      from public.tahfiz_supervisor_assignments
          as assignment

      where assignment.tahfiz_group_id =
            tahfiz_group.id

        and assignment.is_active =
            true

        and assignment.ended_at
            is null
  )

order by
    tahfiz_group.name;


-- =========================================================
-- 7. PEMBINA WITHOUT CURRENT ASSIGNMENT DETAIL
--
-- Expected: 0 rows
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select distinct
    staff.id
        as staff_id,

    staff.legacy_staff_id,

    staff.full_name,

    staff.position,

    profile.login_id

from public.staff
    as staff

inner join public.profiles
    as profile
    on profile.id =
       staff.profile_id

inner join public.user_roles
    as user_role
    on user_role.user_id =
       profile.id

inner join public.roles
    as role
    on role.id =
       user_role.role_id

where role.code =
      'pembina_tahfiz'

  and role.is_active =
      true

  and staff.is_active =
      true

  and profile.is_active =
      true

  and not exists (
      select 1

      from public.tahfiz_supervisor_assignments
          as assignment

      inner join public.tahfiz_groups
          as tahfiz_group
          on tahfiz_group.id =
             assignment.tahfiz_group_id

      where assignment.staff_id =
            staff.id

        and assignment.is_active =
            true

        and assignment.ended_at
            is null

        and tahfiz_group.is_active =
            true

        and tahfiz_group.academic_year_id =
            (
                select id
                from current_year
            )
  )

order by
    staff.full_name;


-- =========================================================
-- 8. ASSIGNMENT ACCOUNT ANOMALY DETAIL
--
-- Expected: 0 rows
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    assignment.id
        as assignment_id,

    assignment.staff_id,

    staff.legacy_staff_id,

    staff.full_name,

    profile.id
        as profile_id,

    profile.login_id,

    staff.is_active
        as staff_is_active,

    profile.is_active
        as profile_is_active,

    tahfiz_group.id
        as tahfiz_group_id,

    tahfiz_group.name
        as tahfiz_group_name,

    assignment.is_primary,

    assignment.assigned_at

from public.tahfiz_supervisor_assignments
    as assignment

inner join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       assignment.tahfiz_group_id

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

left join public.staff
    as staff
    on staff.id =
       assignment.staff_id

left join public.profiles
    as profile
    on profile.id =
       staff.profile_id

where assignment.is_active =
      true

  and assignment.ended_at
      is null

  and (
      staff.id is null

      or staff.is_active =
         false

      or profile.id is null

      or profile.is_active =
         false

      or not exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'pembina_tahfiz'

            and role.is_active =
                true
      )
  )

order by
    tahfiz_group.name;


-- =========================================================
-- 9. DUPLICATE ACTIVE MEMBERSHIP PER STUDENT
--
-- A student should only have one active Tahfiz group
-- in the current academic year.
--
-- Expected: 0 rows
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    student.id
        as student_id,

    student.legacy_student_id,

    student.nis,

    student.full_name,

    count(
        distinct membership.tahfiz_group_id
    )::integer
        as active_group_count,

    string_agg(
        distinct tahfiz_group.name,
        ' | '
        order by tahfiz_group.name
    ) as active_groups

from public.students
    as student

inner join public.tahfiz_group_members
    as membership
    on membership.student_id =
       student.id

inner join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       membership.tahfiz_group_id

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

where membership.is_active =
      true

  and membership.left_at
      is null

group by
    student.id,
    student.legacy_student_id,
    student.nis,
    student.full_name

having count(
    distinct membership.tahfiz_group_id
) > 1

order by
    student.full_name;


-- =========================================================
-- 10. ACTIVE STUDENT WITHOUT ACTIVE TAHFIZ MEMBERSHIP
--
-- Expected: 0 rows
-- Expected total coverage = 127
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    student.id
        as student_id,

    student.legacy_student_id,

    student.nis,

    student.full_name,

    student.gender,

    student.status

from public.students
    as student

where student.status =
      'active'

  and student.deleted_at
      is null

  and not exists (
      select 1

      from public.tahfiz_group_members
          as membership

      inner join public.tahfiz_groups
          as tahfiz_group
          on tahfiz_group.id =
             membership.tahfiz_group_id

      where membership.student_id =
            student.id

        and membership.is_active =
            true

        and membership.left_at
            is null

        and tahfiz_group.is_active =
            true

        and tahfiz_group.academic_year_id =
            (
                select
                    id

                from current_year
            )
  )

order by
    student.full_name;


-- =========================================================
-- 11. ACTIVE MEMBERSHIP WITH NON-ACTIVE STUDENT
--
-- Expected: 0 rows
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    membership.id
        as membership_id,

    student.id
        as student_id,

    student.legacy_student_id,

    student.full_name,

    student.status,

    student.deleted_at,

    tahfiz_group.id
        as tahfiz_group_id,

    tahfiz_group.name
        as tahfiz_group_name

from public.tahfiz_group_members
    as membership

inner join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       membership.tahfiz_group_id

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

inner join public.students
    as student
    on student.id =
       membership.student_id

where membership.is_active =
      true

  and membership.left_at
      is null

  and (
      student.status <>
      'active'

      or student.deleted_at
         is not null
  )

order by
    tahfiz_group.name,
    student.full_name;


-- =========================================================
-- 12. GENDER MISMATCH
--
-- Only checked when group.gender has a value.
--
-- Expected: 0 rows
-- =========================================================

with current_year as (
    select
        academic_year.id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
)

select
    membership.id
        as membership_id,

    student.id
        as student_id,

    student.legacy_student_id,

    student.full_name,

    student.gender
        as student_gender,

    tahfiz_group.id
        as tahfiz_group_id,

    tahfiz_group.code
        as tahfiz_group_code,

    tahfiz_group.name
        as tahfiz_group_name,

    tahfiz_group.gender
        as group_gender

from public.tahfiz_group_members
    as membership

inner join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       membership.tahfiz_group_id

inner join current_year
    on current_year.id =
       tahfiz_group.academic_year_id

inner join public.students
    as student
    on student.id =
       membership.student_id

where membership.is_active =
      true

  and membership.left_at
      is null

  and student.status =
      'active'

  and student.deleted_at
      is null

  and tahfiz_group.gender
      is not null

  and tahfiz_group.gender <>
      student.gender

order by
    tahfiz_group.name,
    student.full_name;


-- =========================================================
-- 13. DUPLICATE ACTIVE SUPERVISOR ASSIGNMENT PAIR
--
-- Expected: 0 rows
-- =========================================================

select
    assignment.staff_id,

    staff.legacy_staff_id,

    staff.full_name,

    assignment.tahfiz_group_id,

    tahfiz_group.name
        as tahfiz_group_name,

    count(*)::integer
        as active_assignment_count

from public.tahfiz_supervisor_assignments
    as assignment

inner join public.staff
    as staff
    on staff.id =
       assignment.staff_id

inner join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       assignment.tahfiz_group_id

where assignment.is_active =
      true

  and assignment.ended_at
      is null

group by
    assignment.staff_id,
    staff.legacy_staff_id,
    staff.full_name,
    assignment.tahfiz_group_id,
    tahfiz_group.name

having count(*) > 1

order by
    staff.full_name,
    tahfiz_group.name;


-- =========================================================
-- 14. MULTIPLE ACTIVE PRIMARY SUPERVISORS
--
-- Database has a unique index for this,
-- but we verify the existing data too.
--
-- Expected: 0 rows
-- =========================================================

select
    assignment.tahfiz_group_id,

    tahfiz_group.code,

    tahfiz_group.name,

    count(*)::integer
        as active_primary_count,

    string_agg(
        staff.full_name,
        ' | '
        order by staff.full_name
    ) as primary_supervisors

from public.tahfiz_supervisor_assignments
    as assignment

inner join public.tahfiz_groups
    as tahfiz_group
    on tahfiz_group.id =
       assignment.tahfiz_group_id

inner join public.staff
    as staff
    on staff.id =
       assignment.staff_id

where assignment.is_active =
      true

  and assignment.ended_at
      is null

  and assignment.is_primary =
      true

group by
    assignment.tahfiz_group_id,
    tahfiz_group.code,
    tahfiz_group.name

having count(*) > 1

order by
    tahfiz_group.name;


-- =========================================================
-- 15. FINAL COVERAGE SUMMARY
-- =========================================================

with current_year as (
    select
        academic_year.id,
        academic_year.name

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1
),

active_students as (
    select
        student.id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null
),

covered_students as (
    select distinct
        membership.student_id

    from public.tahfiz_group_members
        as membership

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           membership.tahfiz_group_id

    inner join current_year
        on current_year.id =
           tahfiz_group.academic_year_id

    inner join active_students
        on active_students.id =
           membership.student_id

    where membership.is_active =
          true

      and membership.left_at
          is null

      and tahfiz_group.is_active =
          true
)

select
    current_year.name
        as academic_year,

    (
        select
            count(*)::integer

        from active_students
    ) as active_student_count,

    (
        select
            count(*)::integer

        from covered_students
    ) as tahfiz_covered_student_count,

    (
        (
            select
                count(*)::integer

            from active_students
        )

        -

        (
            select
                count(*)::integer

            from covered_students
        )
    ) as uncovered_student_count

from current_year;