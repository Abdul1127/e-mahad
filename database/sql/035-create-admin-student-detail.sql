begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 035-create-admin-student-detail.sql
-- PURPOSE:
-- - Menyediakan detail satu santri untuk Admin
-- - Menampilkan penempatan aktif
-- - Menampilkan wali terhubung
-- - Menampilkan riwayat kelas, pengasuhan, dan tahfiz
-- - Read-only
-- =========================================================

create or replace function public.get_admin_student_detail(
    p_student_id uuid
)
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
    -- 1. VALIDASI INPUT
    -- =====================================================

    if p_student_id is null then
        raise exception
            'Student ID wajib diisi.';
    end if;

    -- =====================================================
    -- 2. VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses detail santri ditolak.';
    end if;

    -- =====================================================
    -- 3. SUSUN DATA DETAIL
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

    target_student as (
        select
            student.id,
            student.legacy_student_id,
            student.nis,
            student.full_name,
            student.gender,
            student.photo_url,
            student.status,
            student.created_at,
            student.updated_at

        from public.students as student

        where student.id = p_student_id
          and student.deleted_at is null

        limit 1
    ),

    current_class as (
        select
            class.id,
            class.name,
            class.grade_level,
            class.gender,
            academic_year.id as academic_year_id,
            academic_year.name as academic_year_name,
            enrollment.enrolled_at,
            enrollment.left_at

        from target_student as student

        inner join public.class_enrollments
            as enrollment
            on enrollment.student_id = student.id
           and enrollment.is_active = true

        inner join public.classes as class
            on class.id = enrollment.class_id
           and class.is_active = true

        inner join current_year as academic_year
            on academic_year.id =
               class.academic_year_id

        limit 1
    ),

    current_care_group as (
        select
            care_group.id,
            care_group.name,
            care_group.gender,
            academic_year.id as academic_year_id,
            academic_year.name as academic_year_name,
            membership.joined_at,
            membership.left_at,

            coalesce(
                (
                    select jsonb_agg(
                        jsonb_build_object(
                            'id',
                            staff.id,

                            'legacy_staff_id',
                            staff.legacy_staff_id,

                            'full_name',
                            staff.full_name,

                            'is_primary',
                            assignment.is_primary
                        )
                        order by
                            assignment.is_primary desc,
                            staff.full_name
                    )

                    from public.caregiver_assignments
                        as assignment

                    inner join public.staff as staff
                        on staff.id =
                           assignment.staff_id
                       and staff.is_active = true

                    where assignment.care_group_id =
                          care_group.id
                      and assignment.is_active = true
                ),
                '[]'::jsonb
            ) as caregivers

        from target_student as student

        inner join public.care_group_members
            as membership
            on membership.student_id = student.id
           and membership.is_active = true

        inner join public.care_groups as care_group
            on care_group.id =
               membership.care_group_id
           and care_group.is_active = true

        inner join current_year as academic_year
            on academic_year.id =
               care_group.academic_year_id

        limit 1
    ),

    current_tahfiz_group as (
        select
            tahfiz_group.id,
            tahfiz_group.name,
            tahfiz_group.grade_level,
            tahfiz_group.gender,
            academic_year.id as academic_year_id,
            academic_year.name as academic_year_name,
            membership.joined_at,
            membership.left_at,

            coalesce(
                (
                    select jsonb_agg(
                        jsonb_build_object(
                            'id',
                            staff.id,

                            'legacy_staff_id',
                            staff.legacy_staff_id,

                            'full_name',
                            staff.full_name,

                            'is_primary',
                            assignment.is_primary
                        )
                        order by
                            assignment.is_primary desc,
                            staff.full_name
                    )

                    from public.tahfiz_supervisor_assignments
                        as assignment

                    inner join public.staff as staff
                        on staff.id =
                           assignment.staff_id
                       and staff.is_active = true

                    where assignment.tahfiz_group_id =
                          tahfiz_group.id
                      and assignment.is_active = true
                ),
                '[]'::jsonb
            ) as supervisors

        from target_student as student

        inner join public.tahfiz_group_members
            as membership
            on membership.student_id = student.id
           and membership.is_active = true

        inner join public.tahfiz_groups as tahfiz_group
            on tahfiz_group.id =
               membership.tahfiz_group_id
           and tahfiz_group.is_active = true

        inner join current_year as academic_year
            on academic_year.id =
               tahfiz_group.academic_year_id

        limit 1
    ),

    guardian_data as (
        select
            guardian.id,
            guardian.legacy_guardian_id,
            guardian.full_name,
            guardian.phone,
            guardian.email,
            guardian.is_active,
            guardian.profile_id,
            auth_user.email as account_email,

            exists (
                select 1
                from public.profiles as profile
                where profile.id = guardian.profile_id
                  and profile.is_active = true
            ) as account_active

        from target_student as student

        inner join public.guardian_students
            as guardian_student
            on guardian_student.student_id =
               student.id

        inner join public.guardians as guardian
            on guardian.id =
               guardian_student.guardian_id

        left join auth.users as auth_user
            on auth_user.id = guardian.profile_id
    ),

    class_history as (
        select
            enrollment.id,
            class.id as class_id,
            class.name as class_name,
            class.grade_level,
            academic_year.id as academic_year_id,
            academic_year.name as academic_year_name,
            enrollment.enrolled_at,
            enrollment.left_at,
            enrollment.is_active

        from target_student as student

        inner join public.class_enrollments
            as enrollment
            on enrollment.student_id = student.id

        inner join public.classes as class
            on class.id = enrollment.class_id

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               class.academic_year_id
    ),

    care_history as (
        select
            membership.id,
            care_group.id as care_group_id,
            care_group.name as care_group_name,
            care_group.gender,
            academic_year.id as academic_year_id,
            academic_year.name as academic_year_name,
            membership.joined_at,
            membership.left_at,
            membership.is_active

        from target_student as student

        inner join public.care_group_members
            as membership
            on membership.student_id = student.id

        inner join public.care_groups as care_group
            on care_group.id =
               membership.care_group_id

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               care_group.academic_year_id
    ),

    tahfiz_history as (
        select
            membership.id,
            tahfiz_group.id as tahfiz_group_id,
            tahfiz_group.name as tahfiz_group_name,
            tahfiz_group.grade_level,
            tahfiz_group.gender,
            academic_year.id as academic_year_id,
            academic_year.name as academic_year_name,
            membership.joined_at,
            membership.left_at,
            membership.is_active

        from target_student as student

        inner join public.tahfiz_group_members
            as membership
            on membership.student_id = student.id

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               membership.tahfiz_group_id

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               tahfiz_group.academic_year_id
    )

    select
        case
            when not exists (
                select 1
                from target_student
            ) then null

            else jsonb_build_object(
                'generated_at',
                now(),

                'student',
                (
                    select jsonb_build_object(
                        'id',
                        student.id,

                        'legacy_student_id',
                        student.legacy_student_id,

                        'nis',
                        student.nis,

                        'full_name',
                        student.full_name,

                        'gender',
                        student.gender,

                        'photo_url',
                        student.photo_url,

                        'status',
                        student.status,

                        'created_at',
                        student.created_at,

                        'updated_at',
                        student.updated_at
                    )
                    from target_student as student
                ),

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

                'current_placement',
                jsonb_build_object(
                    'class',
                    (
                        select jsonb_build_object(
                            'id',
                            current_class.id,

                            'name',
                            current_class.name,

                            'grade_level',
                            current_class.grade_level,

                            'gender',
                            current_class.gender,

                            'academic_year_id',
                            current_class.academic_year_id,

                            'academic_year_name',
                            current_class.academic_year_name,

                            'enrolled_at',
                            current_class.enrolled_at,

                            'left_at',
                            current_class.left_at
                        )
                        from current_class
                    ),

                    'care_group',
                    (
                        select jsonb_build_object(
                            'id',
                            care_group.id,

                            'name',
                            care_group.name,

                            'gender',
                            care_group.gender,

                            'academic_year_id',
                            care_group.academic_year_id,

                            'academic_year_name',
                            care_group.academic_year_name,

                            'joined_at',
                            care_group.joined_at,

                            'left_at',
                            care_group.left_at,

                            'caregivers',
                            care_group.caregivers
                        )
                        from current_care_group
                            as care_group
                    ),

                    'tahfiz_group',
                    (
                        select jsonb_build_object(
                            'id',
                            tahfiz_group.id,

                            'name',
                            tahfiz_group.name,

                            'grade_level',
                            tahfiz_group.grade_level,

                            'gender',
                            tahfiz_group.gender,

                            'academic_year_id',
                            tahfiz_group.academic_year_id,

                            'academic_year_name',
                            tahfiz_group.academic_year_name,

                            'joined_at',
                            tahfiz_group.joined_at,

                            'left_at',
                            tahfiz_group.left_at,

                            'supervisors',
                            tahfiz_group.supervisors
                        )
                        from current_tahfiz_group
                            as tahfiz_group
                    )
                ),

                'guardians',
                (
                    select coalesce(
                        jsonb_agg(
                            jsonb_build_object(
                                'id',
                                guardian.id,

                                'legacy_guardian_id',
                                guardian.legacy_guardian_id,

                                'full_name',
                                guardian.full_name,

                                'phone',
                                guardian.phone,

                                'email',
                                guardian.email,

                                'is_active',
                                guardian.is_active,

                                'profile_id',
                                guardian.profile_id,

                                'account_email',
                                guardian.account_email,

                                'account_active',
                                guardian.account_active
                            )
                            order by guardian.full_name
                        ),
                        '[]'::jsonb
                    )
                    from guardian_data as guardian
                ),

                'history',
                jsonb_build_object(
                    'classes',
                    (
                        select coalesce(
                            jsonb_agg(
                                jsonb_build_object(
                                    'id',
                                    history.id,

                                    'class_id',
                                    history.class_id,

                                    'class_name',
                                    history.class_name,

                                    'grade_level',
                                    history.grade_level,

                                    'academic_year_id',
                                    history.academic_year_id,

                                    'academic_year_name',
                                    history.academic_year_name,

                                    'enrolled_at',
                                    history.enrolled_at,

                                    'left_at',
                                    history.left_at,

                                    'is_active',
                                    history.is_active
                                )
                                order by
                                    history.is_active desc,
                                    history.enrolled_at desc,
                                    history.class_name
                            ),
                            '[]'::jsonb
                        )
                        from class_history as history
                    ),

                    'care_groups',
                    (
                        select coalesce(
                            jsonb_agg(
                                jsonb_build_object(
                                    'id',
                                    history.id,

                                    'care_group_id',
                                    history.care_group_id,

                                    'care_group_name',
                                    history.care_group_name,

                                    'gender',
                                    history.gender,

                                    'academic_year_id',
                                    history.academic_year_id,

                                    'academic_year_name',
                                    history.academic_year_name,

                                    'joined_at',
                                    history.joined_at,

                                    'left_at',
                                    history.left_at,

                                    'is_active',
                                    history.is_active
                                )
                                order by
                                    history.is_active desc,
                                    history.joined_at desc,
                                    history.care_group_name
                            ),
                            '[]'::jsonb
                        )
                        from care_history as history
                    ),

                    'tahfiz_groups',
                    (
                        select coalesce(
                            jsonb_agg(
                                jsonb_build_object(
                                    'id',
                                    history.id,

                                    'tahfiz_group_id',
                                    history.tahfiz_group_id,

                                    'tahfiz_group_name',
                                    history.tahfiz_group_name,

                                    'grade_level',
                                    history.grade_level,

                                    'gender',
                                    history.gender,

                                    'academic_year_id',
                                    history.academic_year_id,

                                    'academic_year_name',
                                    history.academic_year_name,

                                    'joined_at',
                                    history.joined_at,

                                    'left_at',
                                    history.left_at,

                                    'is_active',
                                    history.is_active
                                )
                                order by
                                    history.is_active desc,
                                    history.joined_at desc,
                                    history.tahfiz_group_name
                            ),
                            '[]'::jsonb
                        )
                        from tahfiz_history as history
                    )
                )
            )
        end
    into v_result;

    return v_result;
end;
$$;

comment on function public.get_admin_student_detail(uuid) is
'Detail santri Admin beserta penempatan, wali, dan riwayat.';

revoke all on function public.get_admin_student_detail(uuid)
from public;

revoke all on function public.get_admin_student_detail(uuid)
from anon;

grant execute on function public.get_admin_student_detail(uuid)
to authenticated;

commit;