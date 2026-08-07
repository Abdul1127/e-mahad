begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 070-create-admin-group-assignment-overview.sql
--
-- PURPOSE:
-- - Ringkasan kelompok pengasuhan
-- - Ringkasan kelompok tahfiz
-- - Menampilkan jumlah anggota
-- - Menampilkan assignment aktif
-- - Menampilkan readiness kelompok
-- - Hanya dapat dibaca Admin aktif
-- =========================================================


create or replace function
public.get_admin_group_assignment_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_result jsonb;
begin
    -- =====================================================
    -- 1. VALIDASI SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    -- =====================================================
    -- 2. VALIDASI ADMIN
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses kelompok dan assignment ditolak.';
    end if;

    if not exists (
        select 1

        from public.profiles as profile

        where profile.id = auth.uid()
          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;

    -- =====================================================
    -- 3. SUSUN RESPONSE
    -- =====================================================

    with current_year as (
        select
            academic_year.id,
            academic_year.name,
            academic_year.start_date,
            academic_year.end_date

        from public.academic_years
            as academic_year

        where academic_year.is_current = true

        order by
            academic_year.start_date desc,
            academic_year.id

        limit 1
    ),

    active_students as (
        select
            student.id

        from public.students as student

        where student.status = 'active'
          and student.deleted_at is null
    ),

    care_group_data as (
        select
            care_group.id,
            care_group.code,
            care_group.name,
            care_group.gender::text
                as gender,
            care_group.description,
            care_group.is_active,
            care_group.created_at,
            care_group.updated_at,

            count(
                distinct membership.student_id
            ) filter (
                where membership.is_active = true
            )::integer
                as member_count,

            count(
                distinct assignment.id
            ) filter (
                where assignment.is_active = true
            )::integer
                as caregiver_count,

            count(
                distinct assignment.id
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

                        'position',
                        staff.position,

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

        inner join current_year
            as academic_year
            on academic_year.id =
               care_group.academic_year_id

        left join public.care_group_members
            as membership
            on membership.care_group_id =
               care_group.id

        left join public.caregiver_assignments
            as assignment
            on assignment.care_group_id =
               care_group.id

        left join public.staff
            as staff
            on staff.id =
               assignment.staff_id

        where care_group.is_active = true

        group by
            care_group.id,
            care_group.code,
            care_group.name,
            care_group.gender,
            care_group.description,
            care_group.is_active,
            care_group.created_at,
            care_group.updated_at
    ),

    tahfiz_group_data as (
        select
            tahfiz_group.id,
            tahfiz_group.code,
            tahfiz_group.name,
            tahfiz_group.grade_level,
            tahfiz_group.gender::text
                as gender,
            tahfiz_group.description,
            tahfiz_group.is_active,
            tahfiz_group.created_at,
            tahfiz_group.updated_at,

            count(
                distinct membership.student_id
            ) filter (
                where membership.is_active = true
            )::integer
                as member_count,

            count(
                distinct assignment.id
            ) filter (
                where assignment.is_active = true
            )::integer
                as supervisor_count,

            count(
                distinct assignment.id
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

                        'position',
                        staff.position,

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

        inner join current_year
            as academic_year
            on academic_year.id =
               tahfiz_group.academic_year_id

        left join public.tahfiz_group_members
            as membership
            on membership.tahfiz_group_id =
               tahfiz_group.id

        left join public.tahfiz_supervisor_assignments
            as assignment
            on assignment.tahfiz_group_id =
               tahfiz_group.id

        left join public.staff
            as staff
            on staff.id =
               assignment.staff_id

        where tahfiz_group.is_active = true

        group by
            tahfiz_group.id,
            tahfiz_group.code,
            tahfiz_group.name,
            tahfiz_group.grade_level,
            tahfiz_group.gender,
            tahfiz_group.description,
            tahfiz_group.is_active,
            tahfiz_group.created_at,
            tahfiz_group.updated_at
    ),

    students_without_care_group as (
        select
            count(*)::integer
                as total

        from active_students as student

        where not exists (
            select 1

            from public.care_group_members
                as membership

            inner join public.care_groups
                as care_group
                on care_group.id =
                   membership.care_group_id

            inner join current_year
                as academic_year
                on academic_year.id =
                   care_group.academic_year_id

            where membership.student_id =
                  student.id

              and membership.is_active = true

              and care_group.is_active = true
        )
    ),

    students_without_tahfiz_group as (
        select
            count(*)::integer
                as total

        from active_students as student

        where not exists (
            select 1

            from public.tahfiz_group_members
                as membership

            inner join public.tahfiz_groups
                as tahfiz_group
                on tahfiz_group.id =
                   membership.tahfiz_group_id

            inner join current_year
                as academic_year
                on academic_year.id =
                   tahfiz_group.academic_year_id

            where membership.student_id =
                  student.id

              and membership.is_active = true

              and tahfiz_group.is_active = true
        )
    ),

    care_groups_without_caregiver as (
        select
            count(*)::integer
                as total

        from care_group_data as care_group

        where care_group.caregiver_count = 0
    ),

    tahfiz_groups_without_primary as (
        select
            count(*)::integer
                as total

        from tahfiz_group_data
            as tahfiz_group

        where tahfiz_group.primary_supervisor_count = 0
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

            from current_year
                as academic_year
        ),

        'summary',
        jsonb_build_object(
            'active_students',
            (
                select count(*)::integer
                from active_students
            ),

            'active_care_groups',
            (
                select count(*)::integer
                from care_group_data
            ),

            'active_tahfiz_groups',
            (
                select count(*)::integer
                from tahfiz_group_data
            ),

            'active_care_memberships',
            (
                select
                    coalesce(
                        sum(member_count),
                        0
                    )::integer

                from care_group_data
            ),

            'active_tahfiz_memberships',
            (
                select
                    coalesce(
                        sum(member_count),
                        0
                    )::integer

                from tahfiz_group_data
            ),

            'active_caregiver_assignments',
            (
                select
                    coalesce(
                        sum(caregiver_count),
                        0
                    )::integer

                from care_group_data
            ),

            'active_tahfiz_assignments',
            (
                select
                    coalesce(
                        sum(supervisor_count),
                        0
                    )::integer

                from tahfiz_group_data
            ),

            'students_without_care_group',
            (
                select total
                from students_without_care_group
            ),

            'students_without_tahfiz_group',
            (
                select total
                from students_without_tahfiz_group
            ),

            'care_groups_without_caregiver',
            (
                select total
                from care_groups_without_caregiver
            ),

            'tahfiz_groups_without_primary_supervisor',
            (
                select total
                from tahfiz_groups_without_primary
            )
        ),

        'care_groups',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'id',
                        care_group.id,

                        'code',
                        care_group.code,

                        'name',
                        care_group.name,

                        'gender',
                        care_group.gender,

                        'description',
                        care_group.description,

                        'is_active',
                        care_group.is_active,

                        'member_count',
                        care_group.member_count,

                        'caregiver_count',
                        care_group.caregiver_count,

                        'primary_caregiver_count',
                        care_group.primary_caregiver_count,

                        'caregivers',
                        care_group.caregivers
                    )

                    order by
                        care_group.gender,
                        care_group.name
                ),
                '[]'::jsonb
            )

            from care_group_data
                as care_group
        ),

        'tahfiz_groups',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'id',
                        tahfiz_group.id,

                        'code',
                        tahfiz_group.code,

                        'name',
                        tahfiz_group.name,

                        'grade_level',
                        tahfiz_group.grade_level,

                        'gender',
                        tahfiz_group.gender,

                        'description',
                        tahfiz_group.description,

                        'is_active',
                        tahfiz_group.is_active,

                        'member_count',
                        tahfiz_group.member_count,

                        'supervisor_count',
                        tahfiz_group.supervisor_count,

                        'primary_supervisor_count',
                        tahfiz_group.primary_supervisor_count,

                        'supervisors',
                        tahfiz_group.supervisors
                    )

                    order by
                        tahfiz_group.grade_level,
                        tahfiz_group.gender,
                        tahfiz_group.name
                ),
                '[]'::jsonb
            )

            from tahfiz_group_data
                as tahfiz_group
        )
    )

    into v_result;

    return v_result;
end;
$function$;


comment on function
public.get_admin_group_assignment_overview()
is
'Ringkasan kelompok pengasuhan, kelompok tahfiz, anggota, dan assignment untuk Admin.';


-- =========================================================
-- PRIVILEGE
-- =========================================================

revoke all on function
public.get_admin_group_assignment_overview()
from public;

revoke all on function
public.get_admin_group_assignment_overview()
from anon;

grant execute on function
public.get_admin_group_assignment_overview()
to authenticated;


commit;