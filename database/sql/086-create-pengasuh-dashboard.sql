begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 086-create-pengasuh-dashboard.sql
--
-- PURPOSE:
-- - Dashboard Pengasuh berdasarkan auth.uid()
-- - Hanya role Pengasuh
-- - Hanya kelompok yang di-assignment ke staf login
-- - Hanya tahun ajaran aktif
-- - Ringkasan santri ampuan
-- - Preview santri per kelompok
--
-- SECURITY:
-- Pengasuh tidak dapat meminta staff/group milik orang lain.
-- Identitas selalu ditentukan dari auth.uid().
-- =========================================================


create or replace function
public.get_pengasuh_dashboard()
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

    v_phone text;

    v_position text;

    v_academic_year_id uuid;

    v_academic_year_name text;

    v_academic_year_start_date date;

    v_academic_year_end_date date;

    v_assigned_group_count integer;

    v_active_student_count integer;

    v_male_student_count integer;

    v_female_student_count integer;

    v_groups jsonb;
begin

    -- =====================================================
    -- 1. AUTHENTICATION
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- 2. ROLE
    -- =====================================================

    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Dashboard Pengasuh ditolak.';
    end if;


    -- =====================================================
    -- 3. PROFILE
    -- =====================================================

    select
        profile.login_id

    into
        v_login_id

    from public.profiles
        as profile

    where profile.id =
          v_profile_id

      and profile.is_active = true;


    if not found then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    -- =====================================================
    -- 4. STAFF
    -- =====================================================

    select
        staff.id,

        staff.legacy_staff_id,

        staff.full_name,

        staff.phone,

        staff.position

    into
        v_staff_id,

        v_legacy_staff_id,

        v_full_name,

        v_phone,

        v_position

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active = true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- 5. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,

        academic_year.name,

        academic_year.start_date,

        academic_year.end_date

    into
        v_academic_year_id,

        v_academic_year_name,

        v_academic_year_start_date,

        v_academic_year_end_date

    from public.academic_years
        as academic_year

    where academic_year.is_current = true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;


    -- =====================================================
    -- 6. JUMLAH KELOMPOK ASSIGNMENT
    -- =====================================================

    select
        count(*)::integer

    into
        v_assigned_group_count

    from public.caregiver_assignments
        as assignment

    inner join public.care_groups
        as care_group
        on care_group.id =
           assignment.care_group_id

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active = true

      and care_group.is_active = true

      and care_group.academic_year_id =
          v_academic_year_id;


    -- =====================================================
    -- 7. JUMLAH SANTRI AMPUAN
    --
    -- DISTINCT digunakan agar aman apabila suatu saat
    -- Pengasuh memiliki lebih dari satu kelompok.
    -- =====================================================

    select
        count(
            distinct student.id
        )::integer,

        count(
            distinct student.id
        ) filter (
            where student.gender::text =
                  'male'
        )::integer,

        count(
            distinct student.id
        ) filter (
            where student.gender::text =
                  'female'
        )::integer

    into
        v_active_student_count,

        v_male_student_count,

        v_female_student_count

    from public.caregiver_assignments
        as assignment

    inner join public.care_groups
        as care_group
        on care_group.id =
           assignment.care_group_id

    inner join public.care_group_members
        as membership
        on membership.care_group_id =
           care_group.id

       and membership.is_active = true

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active = true

      and care_group.is_active = true

      and care_group.academic_year_id =
          v_academic_year_id

      and student.status = 'active'

      and student.deleted_at is null;


    -- =====================================================
    -- 8. GROUP DATA
    -- =====================================================

    select coalesce(
        jsonb_agg(
            group_data.payload

            order by
                group_data.group_name,
                group_data.group_id
        ),
        '[]'::jsonb
    )

    into
        v_groups

    from (
        select
            care_group.id
                as group_id,

            care_group.name
                as group_name,

            jsonb_build_object(
                'assignment_id',
                assignment.id,

                'assigned_at',
                assignment.assigned_at,

                'id',
                care_group.id,

                'code',
                care_group.code,

                'name',
                care_group.name,

                'gender',
                care_group.gender::text,

                'description',
                care_group.description,

                'active_member_count',
                (
                    select
                        count(*)::integer

                    from public.care_group_members
                        as membership

                    inner join public.students
                        as student
                        on student.id =
                           membership.student_id

                    where membership.care_group_id =
                          care_group.id

                      and membership.is_active =
                          true

                      and student.status =
                          'active'

                      and student.deleted_at
                          is null
                ),

                'member_preview',
                coalesce(
                    (
                        select
                            jsonb_agg(
                                preview_data.payload

                                order by
                                    preview_data.full_name,
                                    preview_data.student_id
                            )

                        from (
                            select
                                student.id
                                    as student_id,

                                student.full_name,

                                jsonb_build_object(
                                    'membership_id',
                                    membership.id,

                                    'joined_at',
                                    membership.joined_at,

                                    'student_id',
                                    student.id,

                                    'legacy_student_id',
                                    student.legacy_student_id,

                                    'nis',
                                    student.nis,

                                    'full_name',
                                    student.full_name,

                                    'gender',
                                    student.gender::text,

                                    'class_id',
                                    current_class.class_id,

                                    'class_name',
                                    current_class.class_name,

                                    'grade_level',
                                    current_class.grade_level
                                ) as payload

                            from public.care_group_members
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

                            where membership.care_group_id =
                                  care_group.id

                              and membership.is_active =
                                  true

                              and student.status =
                                  'active'

                              and student.deleted_at
                                  is null

                            order by
                                student.full_name,
                                student.id

                            limit 6
                        ) as preview_data
                    ),
                    '[]'::jsonb
                )
            ) as payload

        from public.caregiver_assignments
            as assignment

        inner join public.care_groups
            as care_group
            on care_group.id =
               assignment.care_group_id

        where assignment.staff_id =
              v_staff_id

          and assignment.is_active =
              true

          and care_group.is_active =
              true

          and care_group.academic_year_id =
              v_academic_year_id
    ) as group_data;


    -- =====================================================
    -- 9. RESPONSE
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

            'phone',
            v_phone,

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
            v_academic_year_start_date,

            'end_date',
            v_academic_year_end_date,

            'is_current',
            true
        ),

        'summary',
        jsonb_build_object(
            'assigned_group_count',
            coalesce(
                v_assigned_group_count,
                0
            ),

            'active_student_count',
            coalesce(
                v_active_student_count,
                0
            ),

            'male_student_count',
            coalesce(
                v_male_student_count,
                0
            ),

            'female_student_count',
            coalesce(
                v_female_student_count,
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


-- =========================================================
-- DOCUMENTATION
-- =========================================================

comment on function
public.get_pengasuh_dashboard()
is
'Dashboard Pengasuh berdasarkan auth.uid(). Hanya mengembalikan kelompok pengasuhan dan santri aktif yang berada dalam assignment Pengasuh pada tahun ajaran aktif.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.get_pengasuh_dashboard()
from public;


revoke all on function
public.get_pengasuh_dashboard()
from anon;


grant execute on function
public.get_pengasuh_dashboard()
to authenticated;


commit;