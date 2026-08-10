begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 105-create-pembina-tahfiz-dashboard-function.sql
--
-- PURPOSE:
-- - Dashboard Pembina Tahfiz
-- - Menampilkan kelompok Tahfiz yang diampu
-- - Menampilkan jumlah santri ampuan
-- - Menampilkan preview santri
--
-- SECURITY:
-- - Berdasarkan auth.uid()
-- - Hanya role pembina_tahfiz
-- - Profile + staff harus aktif
-- - Hanya assignment tahun ajaran aktif
-- =========================================================


create or replace function
public.get_pembina_tahfiz_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_login_id text;

    v_staff_id uuid;

    v_legacy_staff_id text;

    v_full_name text;

    v_position text;

    v_academic_year_id uuid;

    v_academic_year_name text;

    v_start_date date;

    v_end_date date;

    v_group_count integer := 0;

    v_student_count integer := 0;

    v_male_count integer := 0;

    v_female_count integer := 0;

    v_groups jsonb := '[]'::jsonb;
begin

    -- =====================================================
    -- A. AUTHENTICATION
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pembina_tahfiz'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Dashboard Pembina Tahfiz ditolak.';
    end if;


    -- =====================================================
    -- B. ACTIVE PROFILE
    -- =====================================================

    select
        profile.login_id

    into
        v_login_id

    from public.profiles
        as profile

    where profile.id =
          v_profile_id

      and profile.is_active =
          true;


    if not found then
        raise exception using
            errcode = '42501',
            message = 'Profile Pembina Tahfiz tidak aktif.';
    end if;


    -- =====================================================
    -- C. ACTIVE STAFF
    -- =====================================================

    select
        staff.id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.position

    into
        v_staff_id,
        v_legacy_staff_id,
        v_full_name,
        v_position

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif Pembina Tahfiz tidak ditemukan.';
    end if;


    -- =====================================================
    -- D. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.name,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
        v_academic_year_name,
        v_start_date,
        v_end_date

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;


    -- =====================================================
    -- E. GROUP COUNT
    -- =====================================================

    select
        count(
            distinct assignment.tahfiz_group_id
        )::integer

    into
        v_group_count

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           assignment.tahfiz_group_id

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active =
          true

      and assignment.ended_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_academic_year_id;


    -- =====================================================
    -- F. UNIQUE STUDENT SUMMARY
    -- =====================================================

    select
        count(
            distinct student.id
        )::integer,

        count(
            distinct student.id
        ) filter (
            where student.gender =
                  'male'
        )::integer,

        count(
            distinct student.id
        ) filter (
            where student.gender =
                  'female'
        )::integer

    into
        v_student_count,
        v_male_count,
        v_female_count

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.tahfiz_groups
        as tahfiz_group
        on tahfiz_group.id =
           assignment.tahfiz_group_id

    inner join public.tahfiz_group_members
        as membership
        on membership.tahfiz_group_id =
           tahfiz_group.id

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active =
          true

      and assignment.ended_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_academic_year_id

      and membership.is_active =
          true

      and membership.left_at
          is null

      and student.status =
          'active'

      and student.deleted_at
          is null;


    -- =====================================================
    -- G. GROUPS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                group_data.payload

                order by
                    group_data.grade_level,
                    group_data.group_name
            ),
            '[]'::jsonb
        )

    into
        v_groups

    from (
        select
            tahfiz_group.grade_level,

            tahfiz_group.name
                as group_name,

            jsonb_build_object(
                'id',
                tahfiz_group.id,

                'code',
                tahfiz_group.code,

                'name',
                tahfiz_group.name,

                'gender',
                tahfiz_group.gender::text,

                'grade_level',
                tahfiz_group.grade_level,

                'assignment',
                jsonb_build_object(
                    'id',
                    assignment.id,

                    'is_primary',
                    assignment.is_primary,

                    'assigned_at',
                    assignment.assigned_at
                ),

                'summary',
                jsonb_build_object(
                    'member_count',
                    (
                        select
                            count(
                                distinct membership.student_id
                            )::integer

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
                    ),

                    'male_count',
                    (
                        select
                            count(
                                distinct membership.student_id
                            )::integer

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

                          and student.gender =
                              'male'
                    ),

                    'female_count',
                    (
                        select
                            count(
                                distinct membership.student_id
                            )::integer

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

                          and student.gender =
                              'female'
                    )
                ),

                'member_preview',
                (
                    select
                        coalesce(
                            jsonb_agg(
                                preview.payload

                                order by
                                    preview.full_name,
                                    preview.student_id
                            ),
                            '[]'::jsonb
                        )

                    from (
                        select
                            student.id
                                as student_id,

                            student.full_name,

                            jsonb_build_object(
                                'id',
                                student.id,

                                'legacy_student_id',
                                student.legacy_student_id,

                                'nis',
                                student.nis,

                                'full_name',
                                student.full_name,

                                'gender',
                                student.gender::text,

                                'class',
                                case
                                    when current_class.class_id
                                         is null
                                    then null

                                    else jsonb_build_object(
                                        'id',
                                        current_class.class_id,

                                        'name',
                                        current_class.class_name,

                                        'grade_level',
                                        current_class.grade_level
                                    )
                                end
                            ) as payload

                        from public.tahfiz_group_members
                            as membership

                        inner join public.students
                            as student
                            on student.id =
                               membership.student_id

                        left join lateral (
                            select
                                class.id
                                    as class_id,

                                class.name
                                    as class_name,

                                class.grade_level

                            from public.class_enrollments
                                as enrollment

                            inner join public.classes
                                as class
                                on class.id =
                                   enrollment.class_id

                            where enrollment.student_id =
                                  student.id

                              and enrollment.is_active =
                                  true

                              and class.is_active =
                                  true

                              and class.academic_year_id =
                                  v_academic_year_id

                            order by
                                enrollment.enrolled_at desc,
                                enrollment.created_at desc

                            limit 1
                        ) as current_class
                            on true

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

                        order by
                            student.full_name,
                            student.id

                        limit 8
                    ) as preview
                )
            ) as payload

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               assignment.tahfiz_group_id

        where assignment.staff_id =
              v_staff_id

          and assignment.is_active =
              true

          and assignment.ended_at
              is null

          and tahfiz_group.is_active =
              true

          and tahfiz_group.academic_year_id =
              v_academic_year_id
    ) as group_data;


    -- =====================================================
    -- H. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'profile',
        jsonb_build_object(
            'id',
            v_profile_id,

            'login_id',
            v_login_id
        ),

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'legacy_staff_id',
            v_legacy_staff_id,

            'full_name',
            v_full_name,

            'position',
            v_position
        ),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name,

            'start_date',
            v_start_date,

            'end_date',
            v_end_date
        ),

        'summary',
        jsonb_build_object(
            'group_count',
            coalesce(
                v_group_count,
                0
            ),

            'student_count',
            coalesce(
                v_student_count,
                0
            ),

            'male_count',
            coalesce(
                v_male_count,
                0
            ),

            'female_count',
            coalesce(
                v_female_count,
                0
            )
        ),

        'groups',
        coalesce(
            v_groups,
            '[]'::jsonb
        )
    );

end;
$function$;


comment on function
public.get_pembina_tahfiz_dashboard()
is
'Dashboard Pembina Tahfiz berdasarkan assignment kelompok Tahfiz pada tahun ajaran aktif. Scope ditentukan dari auth.uid().';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.get_pembina_tahfiz_dashboard()
from public;


revoke all on function
public.get_pembina_tahfiz_dashboard()
from anon;


grant execute on function
public.get_pembina_tahfiz_dashboard()
to authenticated;


commit;