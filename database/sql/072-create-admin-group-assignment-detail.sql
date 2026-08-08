begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 072-create-admin-group-assignment-detail.sql
--
-- PURPOSE:
-- - Detail kelompok pengasuhan / tahfiz
-- - Daftar anggota aktif
-- - Assignment aktif
-- - Riwayat assignment
-- - Hanya Admin aktif
-- =========================================================

create or replace function
public.get_admin_group_assignment_detail(
    p_group_type text,
    p_group_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_group_type text;
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

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses detail kelompok ditolak.';
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
    -- 2. VALIDASI PARAMETER
    -- =====================================================

    if p_group_id is null then
        raise exception
            'Group ID wajib diisi.';
    end if;

    v_group_type :=
        lower(
            btrim(
                coalesce(
                    p_group_type,
                    ''
                )
            )
        );

    if v_group_type not in (
        'care',
        'tahfiz'
    ) then
        raise exception
            'Tipe kelompok tidak valid.';
    end if;

    -- =====================================================
    -- 3. KELOMPOK PENGASUHAN
    -- =====================================================

    if v_group_type = 'care' then

        if not exists (
            select 1

            from public.care_groups
                as care_group

            where care_group.id =
                  p_group_id
        ) then
            return null;
        end if;

        with target_group as (
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

                academic_year.id
                    as academic_year_id,

                academic_year.name
                    as academic_year_name,

                academic_year.start_date
                    as academic_year_start_date,

                academic_year.end_date
                    as academic_year_end_date,

                academic_year.is_current
                    as academic_year_is_current

            from public.care_groups
                as care_group

            inner join public.academic_years
                as academic_year
                on academic_year.id =
                   care_group.academic_year_id

            where care_group.id =
                  p_group_id
        ),

        active_members as (
            select
                membership.id
                    as membership_id,

                membership.joined_at,

                student.id
                    as student_id,

                student.legacy_student_id,

                student.nis,

                student.full_name,

                student.gender::text
                    as gender,

                student.status::text
                    as status,

                class.id
                    as class_id,

                class.name
                    as class_name,

                class.grade_level

            from public.care_group_members
                as membership

            inner join public.students
                as student
                on student.id =
                   membership.student_id

            left join public.class_enrollments
                as enrollment
                on enrollment.student_id =
                   student.id

               and enrollment.is_active =
                   true

            left join public.classes
                as class
                on class.id =
                   enrollment.class_id

            where membership.care_group_id =
                  p_group_id

              and membership.is_active = true

              and student.deleted_at is null
        ),

        active_assignments as (
            select
                assignment.id
                    as assignment_id,

                assignment.is_primary,

                assignment.assigned_at,

                staff.id
                    as staff_id,

                staff.profile_id,

                staff.legacy_staff_id,

                staff.full_name,

                staff.phone,

                staff.position,

                staff.is_active
                    as staff_is_active,

                profile.login_id,

                coalesce(
                    profile.is_active,
                    false
                ) as account_active

            from public.caregiver_assignments
                as assignment

            inner join public.staff
                as staff
                on staff.id =
                   assignment.staff_id

            left join public.profiles
                as profile
                on profile.id =
                   staff.profile_id

            where assignment.care_group_id =
                  p_group_id

              and assignment.is_active = true
        ),

        assignment_history as (
            select
                assignment.id
                    as assignment_id,

                assignment.is_primary,

                assignment.assigned_at,

                assignment.ended_at,

                assignment.is_active,

                staff.id
                    as staff_id,

                staff.legacy_staff_id,

                staff.full_name,

                staff.position

            from public.caregiver_assignments
                as assignment

            inner join public.staff
                as staff
                on staff.id =
                   assignment.staff_id

            where assignment.care_group_id =
                  p_group_id
        )

        select jsonb_build_object(
            'generated_at',
            now(),

            'group_type',
            'care',

            'group',
            (
                select jsonb_build_object(
                    'id',
                    target.id,

                    'code',
                    target.code,

                    'name',
                    target.name,

                    'gender',
                    target.gender,

                    'grade_level',
                    null,

                    'description',
                    target.description,

                    'is_active',
                    target.is_active,

                    'created_at',
                    target.created_at,

                    'updated_at',
                    target.updated_at
                )

                from target_group
                    as target
            ),

            'academic_year',
            (
                select jsonb_build_object(
                    'id',
                    target.academic_year_id,

                    'name',
                    target.academic_year_name,

                    'start_date',
                    target.academic_year_start_date,

                    'end_date',
                    target.academic_year_end_date,

                    'is_current',
                    target.academic_year_is_current
                )

                from target_group
                    as target
            ),

            'summary',
            jsonb_build_object(
                'active_member_count',
                (
                    select count(*)::integer
                    from active_members
                ),

                'active_assignment_count',
                (
                    select count(*)::integer
                    from active_assignments
                ),

                'primary_assignment_count',
                (
                    select count(*)::integer

                    from active_assignments

                    where is_primary = true
                ),

                'assignment_history_count',
                (
                    select count(*)::integer
                    from assignment_history
                )
            ),

            'members',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'membership_id',
                            member.membership_id,

                            'joined_at',
                            member.joined_at,

                            'student_id',
                            member.student_id,

                            'legacy_student_id',
                            member.legacy_student_id,

                            'nis',
                            member.nis,

                            'full_name',
                            member.full_name,

                            'gender',
                            member.gender,

                            'status',
                            member.status,

                            'class_id',
                            member.class_id,

                            'class_name',
                            member.class_name,

                            'grade_level',
                            member.grade_level
                        )

                        order by
                            member.grade_level
                                nulls last,

                            member.class_name
                                nulls last,

                            member.full_name
                    ),
                    '[]'::jsonb
                )

                from active_members
                    as member
            ),

            'active_assignments',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'assignment_id',
                            assignment.assignment_id,

                            'staff_id',
                            assignment.staff_id,

                            'profile_id',
                            assignment.profile_id,

                            'legacy_staff_id',
                            assignment.legacy_staff_id,

                            'full_name',
                            assignment.full_name,

                            'phone',
                            assignment.phone,

                            'position',
                            assignment.position,

                            'staff_is_active',
                            assignment.staff_is_active,

                            'login_id',
                            assignment.login_id,

                            'account_active',
                            assignment.account_active,

                            'is_primary',
                            assignment.is_primary,

                            'assigned_at',
                            assignment.assigned_at
                        )

                        order by
                            assignment.is_primary desc,

                            assignment.full_name
                    ),
                    '[]'::jsonb
                )

                from active_assignments
                    as assignment
            ),

            'assignment_history',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'assignment_id',
                            history.assignment_id,

                            'staff_id',
                            history.staff_id,

                            'legacy_staff_id',
                            history.legacy_staff_id,

                            'full_name',
                            history.full_name,

                            'position',
                            history.position,

                            'is_primary',
                            history.is_primary,

                            'assigned_at',
                            history.assigned_at,

                            'ended_at',
                            history.ended_at,

                            'is_active',
                            history.is_active
                        )

                        order by
                            history.assigned_at desc,

                            history.full_name
                    ),
                    '[]'::jsonb
                )

                from assignment_history
                    as history
            )
        )

        into v_result;

        return v_result;
    end if;


    -- =====================================================
    -- 4. KELOMPOK TAHFIZ
    -- =====================================================

    if not exists (
        select 1

        from public.tahfiz_groups
            as tahfiz_group

        where tahfiz_group.id =
              p_group_id
    ) then
        return null;
    end if;

    with target_group as (
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

            academic_year.id
                as academic_year_id,

            academic_year.name
                as academic_year_name,

            academic_year.start_date
                as academic_year_start_date,

            academic_year.end_date
                as academic_year_end_date,

            academic_year.is_current
                as academic_year_is_current

        from public.tahfiz_groups
            as tahfiz_group

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               tahfiz_group.academic_year_id

        where tahfiz_group.id =
              p_group_id
    ),

    active_members as (
        select
            membership.id
                as membership_id,

            membership.joined_at,

            student.id
                as student_id,

            student.legacy_student_id,

            student.nis,

            student.full_name,

            student.gender::text
                as gender,

            student.status::text
                as status,

            class.id
                as class_id,

            class.name
                as class_name,

            class.grade_level

        from public.tahfiz_group_members
            as membership

        inner join public.students
            as student
            on student.id =
               membership.student_id

        left join public.class_enrollments
            as enrollment
            on enrollment.student_id =
               student.id

           and enrollment.is_active =
               true

        left join public.classes
            as class
            on class.id =
               enrollment.class_id

        where membership.tahfiz_group_id =
              p_group_id

          and membership.is_active = true

          and student.deleted_at is null
    ),

    active_assignments as (
        select
            assignment.id
                as assignment_id,

            assignment.is_primary,

            assignment.assigned_at,

            staff.id
                as staff_id,

            staff.profile_id,

            staff.legacy_staff_id,

            staff.full_name,

            staff.phone,

            staff.position,

            staff.is_active
                as staff_is_active,

            profile.login_id,

            coalesce(
                profile.is_active,
                false
            ) as account_active

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.staff
            as staff
            on staff.id =
               assignment.staff_id

        left join public.profiles
            as profile
            on profile.id =
               staff.profile_id

        where assignment.tahfiz_group_id =
              p_group_id

          and assignment.is_active = true
    ),

    assignment_history as (
        select
            assignment.id
                as assignment_id,

            assignment.is_primary,

            assignment.assigned_at,

            assignment.ended_at,

            assignment.is_active,

            staff.id
                as staff_id,

            staff.legacy_staff_id,

            staff.full_name,

            staff.position

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.staff
            as staff
            on staff.id =
               assignment.staff_id

        where assignment.tahfiz_group_id =
              p_group_id
    )

    select jsonb_build_object(
        'generated_at',
        now(),

        'group_type',
        'tahfiz',

        'group',
        (
            select jsonb_build_object(
                'id',
                target.id,

                'code',
                target.code,

                'name',
                target.name,

                'gender',
                target.gender,

                'grade_level',
                target.grade_level,

                'description',
                target.description,

                'is_active',
                target.is_active,

                'created_at',
                target.created_at,

                'updated_at',
                target.updated_at
            )

            from target_group
                as target
        ),

        'academic_year',
        (
            select jsonb_build_object(
                'id',
                target.academic_year_id,

                'name',
                target.academic_year_name,

                'start_date',
                target.academic_year_start_date,

                'end_date',
                target.academic_year_end_date,

                'is_current',
                target.academic_year_is_current
            )

            from target_group
                as target
        ),

        'summary',
        jsonb_build_object(
            'active_member_count',
            (
                select count(*)::integer
                from active_members
            ),

            'active_assignment_count',
            (
                select count(*)::integer
                from active_assignments
            ),

            'primary_assignment_count',
            (
                select count(*)::integer

                from active_assignments

                where is_primary = true
            ),

            'assignment_history_count',
            (
                select count(*)::integer
                from assignment_history
            )
        ),

        'members',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'membership_id',
                        member.membership_id,

                        'joined_at',
                        member.joined_at,

                        'student_id',
                        member.student_id,

                        'legacy_student_id',
                        member.legacy_student_id,

                        'nis',
                        member.nis,

                        'full_name',
                        member.full_name,

                        'gender',
                        member.gender,

                        'status',
                        member.status,

                        'class_id',
                        member.class_id,

                        'class_name',
                        member.class_name,

                        'grade_level',
                        member.grade_level
                    )

                    order by
                        member.class_name
                            nulls last,

                        member.full_name
                ),
                '[]'::jsonb
            )

            from active_members
                as member
        ),

        'active_assignments',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'assignment_id',
                        assignment.assignment_id,

                        'staff_id',
                        assignment.staff_id,

                        'profile_id',
                        assignment.profile_id,

                        'legacy_staff_id',
                        assignment.legacy_staff_id,

                        'full_name',
                        assignment.full_name,

                        'phone',
                        assignment.phone,

                        'position',
                        assignment.position,

                        'staff_is_active',
                        assignment.staff_is_active,

                        'login_id',
                        assignment.login_id,

                        'account_active',
                        assignment.account_active,

                        'is_primary',
                        assignment.is_primary,

                        'assigned_at',
                        assignment.assigned_at
                    )

                    order by
                        assignment.is_primary desc,

                        assignment.full_name
                ),
                '[]'::jsonb
            )

            from active_assignments
                as assignment
        ),

        'assignment_history',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'assignment_id',
                        history.assignment_id,

                        'staff_id',
                        history.staff_id,

                        'legacy_staff_id',
                        history.legacy_staff_id,

                        'full_name',
                        history.full_name,

                        'position',
                        history.position,

                        'is_primary',
                        history.is_primary,

                        'assigned_at',
                        history.assigned_at,

                        'ended_at',
                        history.ended_at,

                        'is_active',
                        history.is_active
                    )

                    order by
                        history.assigned_at desc,

                        history.full_name
                ),
                '[]'::jsonb
            )

            from assignment_history
                as history
        )
    )

    into v_result;

    return v_result;
end;
$function$;


comment on function
public.get_admin_group_assignment_detail(
    text,
    uuid
)
is
'Detail kelompok, anggota, assignment aktif, dan riwayat assignment untuk Admin.';


revoke all on function
public.get_admin_group_assignment_detail(
    text,
    uuid
)
from public;

revoke all on function
public.get_admin_group_assignment_detail(
    text,
    uuid
)
from anon;

grant execute on function
public.get_admin_group_assignment_detail(
    text,
    uuid
)
to authenticated;

commit;