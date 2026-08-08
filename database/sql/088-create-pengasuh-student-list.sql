begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 088-create-pengasuh-student-list.sql
--
-- PURPOSE:
-- - Daftar Santri Ampuan Pengasuh
-- - Berdasarkan auth.uid()
-- - Hanya santri dari care group yang di-assignment
-- - Hanya tahun ajaran aktif
-- - Mendukung pencarian nama / NIS / legacy ID
--
-- SECURITY:
-- Pengasuh tidak dapat menentukan staff_id atau group_id
-- sendiri. Scope selalu berasal dari akun login.
-- =========================================================


create or replace function
public.get_pengasuh_student_list(
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

    v_staff_name text;

    v_staff_position text;

    v_academic_year_id uuid;

    v_academic_year_name text;

    v_search text;

    v_items jsonb;

    v_total_count integer;

    v_group_count integer;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Santri Ampuan ditolak.';
    end if;


    -- =====================================================
    -- B. PROFILE
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
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    -- =====================================================
    -- C. STAFF
    -- =====================================================

    select
        staff.id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.position

    into
        v_staff_id,
        v_legacy_staff_id,
        v_staff_name,
        v_staff_position

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- D. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.name

    into
        v_academic_year_id,
        v_academic_year_name

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
    -- F. JUMLAH GROUP YANG DIAMPU
    -- =====================================================

    select
        count(
            distinct care_group.id
        )::integer

    into
        v_group_count

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
          v_academic_year_id;


    -- =====================================================
    -- G. STUDENT LIST
    -- =====================================================

    with scoped_students as (
        select distinct
            student.id
                as student_id,

            student.legacy_student_id,

            student.nis,

            student.full_name,

            student.gender::text
                as gender,

            membership.id
                as membership_id,

            membership.joined_at,

            care_group.id
                as care_group_id,

            care_group.code
                as care_group_code,

            care_group.name
                as care_group_name,

            care_group.gender::text
                as care_group_gender,

            current_class.class_id,

            current_class.class_name,

            current_class.grade_level

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

           and membership.is_active =
               true

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

          and care_group.is_active =
              true

          and care_group.academic_year_id =
              v_academic_year_id

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
          )
    )

    select
        count(*)::integer,

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'student_id',
                    scoped.student_id,

                    'legacy_student_id',
                    scoped.legacy_student_id,

                    'nis',
                    scoped.nis,

                    'full_name',
                    scoped.full_name,

                    'gender',
                    scoped.gender,

                    'membership_id',
                    scoped.membership_id,

                    'joined_at',
                    scoped.joined_at,

                    'care_group',
                    jsonb_build_object(
                        'id',
                        scoped.care_group_id,

                        'code',
                        scoped.care_group_code,

                        'name',
                        scoped.care_group_name,

                        'gender',
                        scoped.care_group_gender
                    ),

                    'class',
                    case
                        when scoped.class_id
                             is null
                        then null

                        else jsonb_build_object(
                            'id',
                            scoped.class_id,

                            'name',
                            scoped.class_name,

                            'grade_level',
                            scoped.grade_level
                        )
                    end
                )

                order by
                    scoped.full_name,
                    scoped.student_id
            ),
            '[]'::jsonb
        )

    into
        v_total_count,
        v_items

    from scoped_students
        as scoped;


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
            v_staff_name,

            'position',
            v_staff_position
        ),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name
        ),

        'query',
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
                v_total_count,
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
public.get_pengasuh_student_list(text)
is
'Daftar Santri Ampuan berdasarkan auth.uid() Pengasuh. Hanya santri aktif dari care group yang menjadi assignment aktif Pengasuh pada tahun ajaran aktif.';


revoke all on function
public.get_pengasuh_student_list(text)
from public;

revoke all on function
public.get_pengasuh_student_list(text)
from anon;

grant execute on function
public.get_pengasuh_student_list(text)
to authenticated;


commit;