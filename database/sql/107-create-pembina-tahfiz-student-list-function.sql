begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 107-create-pembina-tahfiz-student-list-function.sql
--
-- PURPOSE:
-- - Daftar seluruh santri Tahfiz yang diampu Pembina
-- - Search santri
-- - Menampilkan kelompok Tahfiz + kelas aktif
--
-- SECURITY:
-- - Scope berdasarkan auth.uid()
-- - Hanya role pembina_tahfiz
-- - Profile + staff harus aktif
-- - Hanya kelompok assignment aktif Pembina
-- - Hanya tahun ajaran aktif
-- =========================================================


create or replace function
public.get_pembina_tahfiz_student_list(
    p_search text default null
)
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

    v_search text;

    v_group_count integer := 0;

    v_student_count integer := 0;

    v_filtered_count integer := 0;

    v_items jsonb := '[]'::jsonb;
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
            message = 'Akses Santri Tahfiz Ampuan ditolak.';
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
    -- E. NORMALIZE SEARCH
    -- =====================================================

    v_search :=
        nullif(
            btrim(
                coalesce(
                    p_search,
                    ''
                )
            ),
            ''
        );


    -- =====================================================
    -- F. GROUP COUNT
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
    -- G. TOTAL UNIQUE STUDENTS
    -- =====================================================

    select
        count(
            distinct student.id
        )::integer

    into
        v_student_count

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
    -- H. FILTERED COUNT
    -- =====================================================

    select
        count(
            distinct student.id
        )::integer

    into
        v_filtered_count

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
          is null

      and (
          v_search is null

          or student.full_name
             ilike
             '%' || v_search || '%'

          or coalesce(
              student.nis,
              ''
          ) ilike
             '%' || v_search || '%'

          or coalesce(
              student.legacy_student_id,
              ''
          ) ilike
             '%' || v_search || '%'

          or tahfiz_group.name
             ilike
             '%' || v_search || '%'

          or tahfiz_group.code
             ilike
             '%' || v_search || '%'
      );


    -- =====================================================
    -- I. STUDENT ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                student_data.payload

                order by
                    student_data.group_name,
                    student_data.full_name,
                    student_data.student_id
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select distinct on (
            student.id
        )
            student.id
                as student_id,

            student.full_name,

            tahfiz_group.name
                as group_name,

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

                'tahfiz_group',
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
                    tahfiz_group.grade_level
                ),

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
              is null

          and (
              v_search is null

              or student.full_name
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.nis,
                  ''
              ) ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.legacy_student_id,
                  ''
              ) ilike
                 '%' || v_search || '%'

              or tahfiz_group.name
                 ilike
                 '%' || v_search || '%'

              or tahfiz_group.code
                 ilike
                 '%' || v_search || '%'
          )

        order by
            student.id,
            tahfiz_group.name
    ) as student_data;


    -- =====================================================
    -- J. RESPONSE
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

        'filters',
        jsonb_build_object(
            'search',
            v_search
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

            'filtered_count',
            coalesce(
                v_filtered_count,
                0
            )
        ),

        'items',
        coalesce(
            v_items,
            '[]'::jsonb
        )
    );

end;
$function$;


comment on function
public.get_pembina_tahfiz_student_list(text)
is
'Daftar santri Tahfiz yang berada pada kelompok assignment aktif Pembina Tahfiz yang sedang login.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.get_pembina_tahfiz_student_list(text)
from public;


revoke all on function
public.get_pembina_tahfiz_student_list(text)
from anon;


grant execute on function
public.get_pembina_tahfiz_student_list(text)
to authenticated;


commit;