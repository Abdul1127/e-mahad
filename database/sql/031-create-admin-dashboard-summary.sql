begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 031-create-admin-dashboard-summary.sql
-- PURPOSE:
-- - Menyediakan data aktual untuk Dashboard Admin
-- - Mengembalikan satu response JSON
-- - Membatasi akses hanya untuk role Admin aktif
-- =========================================================

create or replace function public.get_admin_dashboard_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_result jsonb;
begin
    -- =====================================================
    -- VALIDASI SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    -- =====================================================
    -- VALIDASI ROLE ADMIN
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses Dashboard Admin ditolak.';
    end if;

    -- =====================================================
    -- SUSUN DATA DASHBOARD
    -- =====================================================

    with current_year as (
        select
            academic_year.id,
            academic_year.name,
            academic_year.start_date,
            academic_year.end_date

        from public.academic_years as academic_year

        where academic_year.is_current = true

        order by academic_year.start_date desc
        limit 1
    ),

    active_students as (
        select
            student.id,
            student.gender

        from public.students as student

        where student.status =
              'active'::public.student_status
          and student.deleted_at is null
    ),

    active_staff as (
        select
            staff.id,
            staff.legacy_staff_id,
            staff.full_name,
            staff.position,
            staff.profile_id

        from public.staff as staff

        where staff.is_active = true
    ),

    class_distribution as (
        select
            class.grade_level,
            class.name as class_name,
            count(student.id)::integer as student_count

        from current_year as academic_year

        inner join public.classes as class
            on class.academic_year_id =
               academic_year.id
           and class.is_active = true

        left join public.class_enrollments
            as enrollment
            on enrollment.class_id = class.id
           and enrollment.is_active = true

        left join active_students as student
            on student.id = enrollment.student_id

        group by
            class.grade_level,
            class.name
    ),

    care_distribution as (
        select
            care_group.id,
            care_group.name as care_group_name,
            care_group.gender,

            count(
                distinct student.id
            )::integer as student_count,

            count(
                distinct assignment.staff_id
            )::integer as caregiver_count

        from current_year as academic_year

        inner join public.care_groups as care_group
            on care_group.academic_year_id =
               academic_year.id
           and care_group.is_active = true

        left join public.care_group_members
            as membership
            on membership.care_group_id =
               care_group.id
           and membership.is_active = true

        left join active_students as student
            on student.id = membership.student_id

        left join public.caregiver_assignments
            as assignment
            on assignment.care_group_id =
               care_group.id
           and assignment.is_active = true

        group by
            care_group.id,
            care_group.name,
            care_group.gender
    ),

    tahfiz_distribution as (
        select
            tahfiz_group.id,
            tahfiz_group.name as tahfiz_group_name,
            tahfiz_group.grade_level,
            tahfiz_group.gender,

            count(
                distinct student.id
            )::integer as student_count,

            count(
                distinct assignment.staff_id
            )::integer as supervisor_count,

            count(
                distinct assignment.staff_id
            ) filter (
                where assignment.is_primary = true
            )::integer as primary_supervisor_count

        from current_year as academic_year

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.academic_year_id =
               academic_year.id
           and tahfiz_group.is_active = true

        left join public.tahfiz_group_members
            as membership
            on membership.tahfiz_group_id =
               tahfiz_group.id
           and membership.is_active = true

        left join active_students as student
            on student.id = membership.student_id

        left join public.tahfiz_supervisor_assignments
            as assignment
            on assignment.tahfiz_group_id =
               tahfiz_group.id
           and assignment.is_active = true

        group by
            tahfiz_group.id,
            tahfiz_group.name,
            tahfiz_group.grade_level,
            tahfiz_group.gender
    ),

    attention_counts as (
        select
            (
                select count(*)::integer
                from active_staff
                where profile_id is null
            ) as staff_without_accounts,

            (
                select count(*)::integer
                from active_students as student
                where not exists (
                    select 1
                    from public.guardian_students
                        as guardian_student
                    inner join public.guardians
                        as guardian
                        on guardian.id =
                           guardian_student.guardian_id
                       and guardian.is_active = true
                    where guardian_student.student_id =
                          student.id
                )
            ) as students_without_guardians,

            (
                select count(*)::integer
                from active_students as student
                where not exists (
                    select 1
                    from public.class_enrollments
                        as enrollment
                    inner join public.classes as class
                        on class.id =
                           enrollment.class_id
                       and class.is_active = true
                    inner join current_year
                        as academic_year
                        on academic_year.id =
                           class.academic_year_id
                    where enrollment.student_id =
                          student.id
                      and enrollment.is_active = true
                )
            ) as students_without_active_class,

            (
                select count(*)::integer
                from active_students as student
                where not exists (
                    select 1
                    from public.care_group_members
                        as membership
                    inner join public.care_groups
                        as care_group
                        on care_group.id =
                           membership.care_group_id
                       and care_group.is_active = true
                    inner join current_year
                        as academic_year
                        on academic_year.id =
                           care_group.academic_year_id
                    where membership.student_id =
                          student.id
                      and membership.is_active = true
                )
            ) as students_without_active_care_group,

            (
                select count(*)::integer
                from active_students as student
                where not exists (
                    select 1
                    from public.tahfiz_group_members
                        as membership
                    inner join public.tahfiz_groups
                        as tahfiz_group
                        on tahfiz_group.id =
                           membership.tahfiz_group_id
                       and tahfiz_group.is_active = true
                    inner join current_year
                        as academic_year
                        on academic_year.id =
                           tahfiz_group.academic_year_id
                    where membership.student_id =
                          student.id
                      and membership.is_active = true
                )
            ) as students_without_active_tahfiz_group,

            (
                select count(*)::integer
                from care_distribution
                where caregiver_count = 0
            ) as care_groups_without_caregiver,

            (
                select count(*)::integer
                from tahfiz_distribution
                where primary_supervisor_count = 0
            ) as tahfiz_groups_without_primary_supervisor
    )

    select jsonb_build_object(
        'generated_at',
        now(),

        'academic_year',
        (
            select jsonb_build_object(
                'id',
                academic_year.id,

                'name',
                academic_year.name,

                'start_date',
                academic_year.start_date,

                'end_date',
                academic_year.end_date
            )
            from current_year as academic_year
        ),

        'summary',
        jsonb_build_object(
            'active_students',
            (
                select count(*)::integer
                from active_students
            ),

            'active_staff',
            (
                select count(*)::integer
                from active_staff
            ),

            'linked_staff_accounts',
            (
                select count(*)::integer
                from active_staff
                where profile_id is not null
            ),

            'unlinked_staff_accounts',
            (
                select count(*)::integer
                from active_staff
                where profile_id is null
            ),

            'active_guardians',
            (
                select count(*)::integer
                from public.guardians
                where is_active = true
            ),

            'active_classes',
            (
                select count(*)::integer
                from public.classes as class
                inner join current_year as academic_year
                    on academic_year.id =
                       class.academic_year_id
                where class.is_active = true
            ),

            'active_care_groups',
            (
                select count(*)::integer
                from care_distribution
            ),

            'active_tahfiz_groups',
            (
                select count(*)::integer
                from tahfiz_distribution
            )
        ),

        'class_distribution',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'grade_level',
                        distribution.grade_level,

                        'class_name',
                        distribution.class_name,

                        'student_count',
                        distribution.student_count
                    )
                    order by distribution.grade_level
                ),
                '[]'::jsonb
            )
            from class_distribution as distribution
        ),

        'care_distribution',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'care_group_name',
                        distribution.care_group_name,

                        'gender',
                        distribution.gender,

                        'student_count',
                        distribution.student_count,

                        'caregiver_count',
                        distribution.caregiver_count
                    )
                    order by distribution.gender
                ),
                '[]'::jsonb
            )
            from care_distribution as distribution
        ),

        'tahfiz_distribution',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'tahfiz_group_name',
                        distribution.tahfiz_group_name,

                        'grade_level',
                        distribution.grade_level,

                        'gender',
                        distribution.gender,

                        'student_count',
                        distribution.student_count,

                        'supervisor_count',
                        distribution.supervisor_count,

                        'primary_supervisor_count',
                        distribution.primary_supervisor_count
                    )
                    order by
                        distribution.grade_level,
                        distribution.gender
                ),
                '[]'::jsonb
            )
            from tahfiz_distribution as distribution
        ),

        'attention',
        (
            select jsonb_build_object(
                'staff_without_accounts',
                attention.staff_without_accounts,

                'students_without_guardians',
                attention.students_without_guardians,

                'students_without_active_class',
                attention.students_without_active_class,

                'students_without_active_care_group',
                attention.students_without_active_care_group,

                'students_without_active_tahfiz_group',
                attention.students_without_active_tahfiz_group,

                'care_groups_without_caregiver',
                attention.care_groups_without_caregiver,

                'tahfiz_groups_without_primary_supervisor',
                attention.tahfiz_groups_without_primary_supervisor
            )
            from attention_counts as attention
        ),

        'readiness',
        (
            select jsonb_build_object(
                'class_memberships_complete',
                attention.students_without_active_class = 0,

                'care_memberships_complete',
                attention.students_without_active_care_group = 0,

                'tahfiz_memberships_complete',
                attention.students_without_active_tahfiz_group = 0,

                'care_assignments_complete',
                attention.care_groups_without_caregiver = 0,

                'tahfiz_assignments_complete',
                attention.tahfiz_groups_without_primary_supervisor = 0
            )
            from attention_counts as attention
        ),

        'unlinked_staff',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'legacy_staff_id',
                        staff.legacy_staff_id,

                        'full_name',
                        staff.full_name,

                        'position',
                        staff.position
                    )
                    order by staff.full_name
                ),
                '[]'::jsonb
            )
            from active_staff as staff
            where staff.profile_id is null
        )
    )
    into v_result;

    return v_result;
end;
$$;

comment on function public.get_admin_dashboard_summary() is
'Mengambil ringkasan aktual Dashboard Admin E-Ma''had.';

revoke all on function public.get_admin_dashboard_summary()
from public;

revoke all on function public.get_admin_dashboard_summary()
from anon;

grant execute on function public.get_admin_dashboard_summary()
to authenticated;

commit;