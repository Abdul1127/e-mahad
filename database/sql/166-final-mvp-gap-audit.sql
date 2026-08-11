-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 166-final-mvp-gap-audit.sql
--
-- PURPOSE:
-- Final MVP Gap Audit sebelum Feature Freeze.
--
-- READ ONLY.
--
-- Audit:
--
-- 01 Core tables
-- 02 Auth / role foundation
-- 03 Pengasuhan
-- 04 Tahfiz
-- 05 Finance
-- 06 Guardian
-- 07 Dormant Jadwal & Absensi
-- 08 Core RPC functions
-- 09 Current Academic Year
-- 10 Active Students
-- 11 Guardian Links
-- 12 Staff Accounts
-- 13 Data relationship summary
--
-- TIDAK ADA:
-- INSERT
-- UPDATE
-- DELETE
-- ALTER
-- DROP
-- =========================================================


-- =========================================================
-- 01. CORE TABLES
-- =========================================================

select
    '01_core_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                data.table_name
            )
            order by
                data.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        table_name

    from information_schema.tables

    where table_schema =
          'public'

      and table_type =
          'BASE TABLE'

      and table_name in (
          'academic_years',
          'classes',
          'class_enrollments',
          'students',
          'profiles',
          'roles',
          'user_roles',
          'staff',
          'guardians',
          'guardian_students'
      )
)
    as data


union all


-- =========================================================
-- 02. AUTH / ROLE FOUNDATION
-- =========================================================

select
    '02_roles'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'code',
                role.code,

                'name',
                role.name,

                'is_active',
                role.is_active
            )

            order by
                role.code
        ),
        '[]'::jsonb
    )
        as data

from public.roles
    as role


union all


-- =========================================================
-- 03. PENGASUHAN TABLES
-- =========================================================

select
    '03_pengasuhan_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                data.table_name
            )

            order by
                data.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        table_name

    from information_schema.tables

    where table_schema =
          'public'

      and table_type =
          'BASE TABLE'

      and table_name in (
          'care_groups',
          'care_group_members',
          'caregiver_assignments',
          'care_journals',
          'care_journal_entries',
          'care_journal_reviews'
      )
)
    as data


union all


-- =========================================================
-- 04. TAHFIZ TABLES
-- =========================================================

select
    '04_tahfiz_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                data.table_name
            )

            order by
                data.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        table_name

    from information_schema.tables

    where table_schema =
          'public'

      and table_type =
          'BASE TABLE'

      and table_name in (
          'tahfiz_groups',
          'tahfiz_group_members',
          'tahfiz_supervisor_assignments',
          'tahfiz_weekly_reports'
      )
)
    as data


union all


-- =========================================================
-- 05. FINANCE TABLES
-- =========================================================

select
    '05_finance_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                data.table_name
            )

            order by
                data.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        table_name

    from information_schema.tables

    where table_schema =
          'public'

      and table_type =
          'BASE TABLE'

      and table_name in (
          'student_bills',
          'payments',
          'payment_allocations'
      )
)
    as data


union all


-- =========================================================
-- 06. GUARDIAN FOUNDATION
-- =========================================================

select
    '06_guardian_tables'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'table_name',
                data.table_name
            )

            order by
                data.table_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select
        table_name

    from information_schema.tables

    where table_schema =
          'public'

      and table_type =
          'BASE TABLE'

      and table_name in (
          'guardians',
          'guardian_students'
      )
)
    as data


union all


-- =========================================================
-- 07. DORMANT JADWAL & ABSENSI
--
-- Status untuk MVP:
-- FOUNDATION DISIMPAN
-- FRONTEND TIDAK DIEKSPOSE DI SIDEBAR
-- =========================================================

select
    '07_deferred_activity_module'
        as section,

    jsonb_build_object(
        'activity_schedules_exists',
        to_regclass(
            'public.activity_schedules'
        ) is not null,

        'activity_attendances_exists',
        to_regclass(
            'public.activity_attendances'
        ) is not null,

        'mvp_status',
        'deferred_after_deploy'
    )
        as data


union all


-- =========================================================
-- 08. CORE RPC FUNCTIONS
--
-- Tidak memaksakan nama satu per satu.
-- Kita kelompokkan berdasarkan modul.
-- =========================================================

select
    '08_core_rpc_functions'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'function_name',
                data.function_name
            )

            order by
                data.function_name
        ),
        '[]'::jsonb
    )
        as data

from (
    select distinct
        routine_name
            as function_name

    from information_schema.routines

    where routine_schema =
          'public'

      and (
          routine_name ilike
              '%care%'

          or routine_name ilike
              '%journal%'

          or routine_name ilike
              '%pengasuh%'

          or routine_name ilike
              '%tahfiz%'

          or routine_name ilike
              '%bendahara%'

          or routine_name ilike
              '%guardian%'

          or routine_name ilike
              '%bill%'

          or routine_name ilike
              '%payment%'
      )
)
    as data


union all


-- =========================================================
-- 09. CURRENT ACADEMIC YEAR
-- =========================================================

select
    '09_current_academic_year'
        as section,

    coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                academic_year.id,

                'name',
                academic_year.name,

                'start_date',
                academic_year.start_date,

                'end_date',
                academic_year.end_date,

                'is_current',
                academic_year.is_current
            )
        ),
        '[]'::jsonb
    )
        as data

from public.academic_years
    as academic_year

where academic_year.is_current =
      true


union all


-- =========================================================
-- 10. ACTIVE STUDENTS
-- =========================================================

select
    '10_active_students'
        as section,

    jsonb_build_object(
        'active_count',
        count(*)
    )
        as data

from public.students
    as student

where student.status =
      'active'

  and student.deleted_at
      is null


union all


-- =========================================================
-- 11. GUARDIAN LINKS
-- =========================================================

select
    '11_guardian_links'
        as section,

    jsonb_build_object(
        'guardian_count',
        (
            select
                count(*)

            from public.guardians
                as guardian

            where guardian.is_active =
                  true
        ),

        'guardian_student_link_count',
        (
            select
                count(*)

            from public.guardian_students
        ),

        'linked_student_count',
        (
            select
                count(
                    distinct
                    relation.student_id
                )

            from public.guardian_students
                as relation
        )
    )
        as data


union all


-- =========================================================
-- 12. STAFF ACCOUNT SUMMARY
-- =========================================================

select
    '12_staff_accounts'
        as section,

    jsonb_build_object(
        'active_staff_count',
        (
            select
                count(*)

            from public.staff
                as staff

            where staff.is_active =
                  true
        ),

        'linked_profile_count',
        (
            select
                count(*)

            from public.staff
                as staff

            where staff.is_active =
                  true

              and staff.profile_id
                  is not null
        ),

        'unlinked_profile_count',
        (
            select
                count(*)

            from public.staff
                as staff

            where staff.is_active =
                  true

              and staff.profile_id
                  is null
        )
    )
        as data


union all


-- =========================================================
-- 13. CARE GROUP SUMMARY
-- =========================================================

select
    '13_care_group_summary'
        as section,

    jsonb_build_object(
        'active_group_count',
        (
            select
                count(*)

            from public.care_groups
                as care_group

            inner join public.academic_years
                as academic_year

                on academic_year.id =
                   care_group.academic_year_id

            where care_group.is_active =
                  true

              and academic_year.is_current =
                  true
        ),

        'active_membership_count',
        (
            select
                count(*)

            from public.care_group_members
                as membership

            inner join public.care_groups
                as care_group

                on care_group.id =
                   membership.care_group_id

            inner join public.academic_years
                as academic_year

                on academic_year.id =
                   care_group.academic_year_id

            where membership.is_active =
                  true

              and care_group.is_active =
                  true

              and academic_year.is_current =
                  true
        ),

        'active_caregiver_assignment_count',
        (
            select
                count(*)

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

            where assignment.is_active =
                  true

              and care_group.is_active =
                  true

              and academic_year.is_current =
                  true
        )
    )
        as data


union all


-- =========================================================
-- 14. TAHFIZ SUMMARY
-- =========================================================

select
    '14_tahfiz_summary'
        as section,

    jsonb_build_object(
        'active_group_count',
        (
            select
                count(*)

            from public.tahfiz_groups
                as tahfiz_group

            inner join public.academic_years
                as academic_year

                on academic_year.id =
                   tahfiz_group.academic_year_id

            where tahfiz_group.is_active =
                  true

              and academic_year.is_current =
                  true
        ),

        'active_member_count',
        (
            select
                count(*)

            from public.tahfiz_group_members
                as membership

            inner join public.tahfiz_groups
                as tahfiz_group

                on tahfiz_group.id =
                   membership.tahfiz_group_id

            inner join public.academic_years
                as academic_year

                on academic_year.id =
                   tahfiz_group.academic_year_id

            where membership.is_active =
                  true

              and tahfiz_group.is_active =
                  true

              and academic_year.is_current =
                  true
        ),

        'weekly_report_count',
        (
            select
                count(*)

            from public.tahfiz_weekly_reports
                as report

            where report.academic_year_id =
                  (
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
        )
    )
        as data


union all


-- =========================================================
-- 15. FINANCE SUMMARY
-- =========================================================

select
    '15_finance_summary'
        as section,

    jsonb_build_object(
        'bill_count',
        (
            select
                count(*)

            from public.student_bills
                as bill

            where bill.academic_year_id =
                  (
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
        ),

        'payment_count',
        (
            select
                count(*)

            from public.payments
                as payment

            where payment.academic_year_id =
                  (
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
        ),

        'recorded_payment_count',
        (
            select
                count(*)

            from public.payments
                as payment

            where payment.academic_year_id =
                  (
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

              and payment.status =
                  'recorded'
        ),

        'payment_with_proof_count',
        (
            select
                count(*)

            from public.payments
                as payment

            where payment.academic_year_id =
                  (
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

              and payment.proof_path
                  is not null
        )
    )
        as data


union all


-- =========================================================
-- 16. FINAL STATUS
-- =========================================================

select
    '16_audit_status'
        as section,

    jsonb_build_object(
        'status',
        'Final MVP database audit completed',

        'audited_at',
        now()
    )
        as data


order by
    section;