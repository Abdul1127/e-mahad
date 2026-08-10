begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 121-create-guardian-tahfiz-dashboard-function.sql
--
-- PURPOSE:
-- Dashboard Orang Tua / Wali untuk data Tahfiz.
--
-- RULES:
-- - Hanya role guardian.
-- - Guardian harus aktif.
-- - Guardian harus terhubung dengan profile auth.uid().
-- - Hanya anak yang terhubung melalui guardian_students.
-- - Hanya data Tahfiz.
-- - Hanya Laporan Tahfiz status PUBLISHED.
-- - Draft tidak pernah dikembalikan.
--
-- SECURITY:
-- SECURITY DEFINER + explicit authorization.
-- =========================================================


create or replace function
public.get_guardian_tahfiz_dashboard()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_guardian_id uuid;
    v_guardian_name text;
    v_guardian_phone text;
    v_guardian_email text;
    v_legacy_guardian_id text;

    v_login_id text;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_child_count integer := 0;
    v_published_report_count integer := 0;

    v_children jsonb := '[]'::jsonb;
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
        'guardian'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Dashboard Orang Tua/Wali ditolak.';
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
            message = 'Profile Orang Tua/Wali tidak aktif.';
    end if;


    -- =====================================================
    -- C. ACTIVE GUARDIAN
    --
    -- profile_id adalah penghubung akun login dengan
    -- identitas wali.
    -- =====================================================

    select
        guardian.id,
        guardian.legacy_guardian_id,
        guardian.full_name,
        guardian.phone,
        guardian.email

    into
        v_guardian_id,
        v_legacy_guardian_id,
        v_guardian_name,
        v_guardian_phone,
        v_guardian_email

    from public.guardians
        as guardian

    where guardian.profile_id =
          v_profile_id

      and guardian.is_active =
          true

    limit 1;


    if v_guardian_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data Orang Tua/Wali aktif tidak ditemukan.';
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
        v_academic_year_start,
        v_academic_year_end

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
    -- E. CHILD COUNT
    -- =====================================================

    select
        count(
            distinct guardian_student.student_id
        )::integer

    into
        v_child_count

    from public.guardian_students
        as guardian_student

    inner join public.students
        as student
        on student.id =
           guardian_student.student_id

    where guardian_student.guardian_id =
          v_guardian_id

      and student.status =
          'active'

      and student.deleted_at
          is null;


    -- =====================================================
    -- F. TOTAL PUBLISHED REPORTS
    --
    -- IMPORTANT:
    -- status = published is enforced here.
    -- Draft is never included.
    -- =====================================================

    select
        count(
            distinct report.id
        )::integer

    into
        v_published_report_count

    from public.guardian_students
        as guardian_student

    inner join public.students
        as student
        on student.id =
           guardian_student.student_id

    inner join public.tahfiz_weekly_reports
        as report
        on report.student_id =
           student.id

    where guardian_student.guardian_id =
          v_guardian_id

      and student.status =
          'active'

      and student.deleted_at
          is null

      and report.academic_year_id =
          v_academic_year_id

      and report.status =
          'published'

      and report.published_at
          is not null;


    -- =====================================================
    -- G. CHILDREN
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                child_data.payload

                order by
                    child_data.full_name,
                    child_data.student_id
            ),
            '[]'::jsonb
        )

    into
        v_children

    from (
        select
            student.id
                as student_id,

            student.full_name,

            jsonb_build_object(
                'relationship',
                jsonb_build_object(
                    'id',
                    guardian_student.id,

                    'type',
                    guardian_student.relationship_type,

                    'is_primary_contact',
                    guardian_student.is_primary_contact
                ),

                'student',
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
                    student.gender::text
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
                end,

                'tahfiz_group',
                case
                    when current_tahfiz.tahfiz_group_id
                         is null
                    then null

                    else jsonb_build_object(
                        'id',
                        current_tahfiz.tahfiz_group_id,

                        'code',
                        current_tahfiz.tahfiz_group_code,

                        'name',
                        current_tahfiz.tahfiz_group_name,

                        'gender',
                        current_tahfiz.tahfiz_group_gender,

                        'grade_level',
                        current_tahfiz.tahfiz_group_grade_level
                    )
                end,

                'summary',
                jsonb_build_object(
                    'published_report_count',
                    (
                        select
                            count(*)::integer

                        from public.tahfiz_weekly_reports
                            as child_report

                        where child_report.student_id =
                              student.id

                          and child_report.academic_year_id =
                              v_academic_year_id

                          and child_report.status =
                              'published'

                          and child_report.published_at
                              is not null
                    )
                ),

                'latest_report',
                (
                    select
                        jsonb_build_object(
                            'id',
                            latest_report.id,

                            'week_start',
                            latest_report.week_start,

                            'week_end',
                            latest_report.week_end,

                            'memorization_achievement',
                            latest_report.memorization_achievement,

                            'murajaah_achievement',
                            latest_report.murajaah_achievement,

                            'fluency_rating',
                            latest_report.fluency_rating,

                            'tajwid_rating',
                            latest_report.tajwid_rating,

                            'consistency_rating',
                            latest_report.consistency_rating,

                            'supervisor_notes',
                            latest_report.supervisor_notes,

                            'next_week_target',
                            latest_report.next_week_target,

                            'status',
                            latest_report.status,

                            'published_at',
                            latest_report.published_at,

                            'updated_at',
                            latest_report.updated_at
                        )

                    from public.tahfiz_weekly_reports
                        as latest_report

                    where latest_report.student_id =
                          student.id

                      and latest_report.academic_year_id =
                          v_academic_year_id

                      and latest_report.status =
                          'published'

                      and latest_report.published_at
                          is not null

                    order by
                        latest_report.week_start desc,
                        latest_report.published_at desc,
                        latest_report.id desc

                    limit 1
                )
            ) as payload

        from public.guardian_students
            as guardian_student

        inner join public.students
            as student
            on student.id =
               guardian_student.student_id


        -- =================================================
        -- CURRENT CLASS
        -- =================================================

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


        -- =================================================
        -- CURRENT TAHFIZ GROUP
        -- =================================================

        left join lateral (
            select
                tahfiz_group.id
                    as tahfiz_group_id,

                tahfiz_group.code
                    as tahfiz_group_code,

                tahfiz_group.name
                    as tahfiz_group_name,

                tahfiz_group.gender::text
                    as tahfiz_group_gender,

                tahfiz_group.grade_level
                    as tahfiz_group_grade_level

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
                  v_academic_year_id

            order by
                membership.joined_at desc,
                membership.created_at desc

            limit 1
        ) as current_tahfiz
            on true


        where guardian_student.guardian_id =
              v_guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null
    ) as child_data;


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

        'guardian',
        jsonb_build_object(
            'id',
            v_guardian_id,

            'legacy_guardian_id',
            v_legacy_guardian_id,

            'full_name',
            v_guardian_name,

            'phone',
            v_guardian_phone,

            'email',
            v_guardian_email
        ),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name,

            'start_date',
            v_academic_year_start,

            'end_date',
            v_academic_year_end
        ),

        'summary',
        jsonb_build_object(
            'child_count',
            coalesce(
                v_child_count,
                0
            ),

            'published_report_count',
            coalesce(
                v_published_report_count,
                0
            )
        ),

        'children',
        coalesce(
            v_children,
            '[]'::jsonb
        )
    );

end;
$function$;


-- =========================================================
-- COMMENT
-- =========================================================

comment on function
public.get_guardian_tahfiz_dashboard()
is
'Dashboard Tahfiz Orang Tua/Wali. Hanya menampilkan anak yang terhubung dengan akun wali dan hanya laporan Tahfiz berstatus published.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.get_guardian_tahfiz_dashboard()
from public;


revoke all on function
public.get_guardian_tahfiz_dashboard()
from anon;


grant execute on function
public.get_guardian_tahfiz_dashboard()
to authenticated;


commit;