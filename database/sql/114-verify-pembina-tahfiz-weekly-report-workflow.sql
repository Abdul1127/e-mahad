-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 114-verify-pembina-tahfiz-weekly-report-workflow.sql
--
-- TEST:
-- - Overview isolation
-- - Detail isolation
-- - Save draft
-- - Incomplete publish blocked
-- - Complete report publish
-- - Edit published report
-- - Published status preserved
-- - Outside assignment blocked
-- - Non-Pembina blocked
--
-- ALL TEST DATA ROLLBACK
-- =========================================================


select
    to_regprocedure(
        'public.get_pembina_tahfiz_weekly_report_overview(date,text)'
    ) is not null
        as overview_exists,

    to_regprocedure(
        'public.get_pembina_tahfiz_weekly_report_detail(uuid,date)'
    ) is not null
        as detail_exists,

    to_regprocedure(
        'public.save_pembina_tahfiz_weekly_report(uuid,date,text,text,text,text,text,text,text)'
    ) is not null
        as save_exists,

    to_regprocedure(
        'public.publish_pembina_tahfiz_weekly_report(uuid,date)'
    ) is not null
        as publish_exists;


begin;


do $verification$
declare
    v_current_year_id uuid;
    v_start_date date;
    v_end_date date;

    v_week_start date;

    v_profile_id uuid;
    v_email text;
    v_staff_id uuid;
    v_staff_name text;

    v_group_id uuid;
    v_student_id uuid;

    v_other_student_id uuid;

    v_non_pembina_profile_id uuid;
    v_non_pembina_email text;

    v_result jsonb;

    v_report_id uuid;

    v_published_at_before timestamptz;
    v_published_at_after timestamptz;

    v_item jsonb;

    v_tested_item_count integer := 0;
begin

    -- =====================================================
    -- A. CURRENT YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.start_date,
        academic_year.end_date

    into
        v_current_year_id,
        v_start_date,
        v_end_date

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_current_year_id is null then
        raise exception
            'Tahun ajaran aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. MONDAY TEST WEEK
    -- =====================================================

    select
        generated.day_value::date

    into
        v_week_start

    from generate_series(
        v_start_date::timestamp,
        (v_end_date - 6)::timestamp,
        interval '1 day'
    ) as generated(day_value)

    where extract(
        isodow
        from generated.day_value
    ) = 1

      and not exists (
          select 1

          from public.tahfiz_weekly_reports
              as report

          where report.week_start =
                generated.day_value::date
      )

    order by
        generated.day_value desc

    limit 1;


    if v_week_start is null then
        raise exception
            'Pekan kosong untuk verification tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. PICK PEMBINA + OWN STUDENT
    -- =====================================================

    select
        profile.id,
        auth_user.email,

        staff.id,
        staff.full_name,

        tahfiz_group.id,
        student.id

    into
        v_profile_id,
        v_email,

        v_staff_id,
        v_staff_name,

        v_group_id,
        v_student_id

    from public.profiles
        as profile

    inner join auth.users
        as auth_user
        on auth_user.id =
           profile.id

    inner join public.staff
        as staff
        on staff.profile_id =
           profile.id

    inner join public.user_roles
        as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles
        as role
        on role.id =
           user_role.role_id

    inner join public.tahfiz_supervisor_assignments
        as assignment
        on assignment.staff_id =
           staff.id

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

    where role.code =
          'pembina_tahfiz'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true

      and assignment.is_active =
          true

      and assignment.ended_at
          is null

      and tahfiz_group.is_active =
          true

      and tahfiz_group.academic_year_id =
          v_current_year_id

      and membership.is_active =
          true

      and membership.left_at
          is null

      and student.status =
          'active'

      and student.deleted_at
          is null

    order by
        staff.full_name,
        student.full_name

    limit 1;


    if v_profile_id is null
       or v_student_id is null
    then
        raise exception
            'Pembina / santri test tidak ditemukan.';
    end if;


    raise notice
        'TEST PEMBINA: %',
        v_staff_name;


    -- =====================================================
    -- D. LOGIN AS PEMBINA
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_profile_id,

            'role',
            'authenticated',

            'email',
            v_email
        )::text,
        true
    );


    -- =====================================================
    -- E. OVERVIEW
    -- =====================================================

    v_result :=
        public.get_pembina_tahfiz_weekly_report_overview(
            v_week_start,
            null
        );


    if (
        v_result
        #>> '{week,start}'
    )::date <>
       v_week_start
    then
        raise exception
            'Overview menggunakan pekan yang salah.';
    end if;


    for v_item in
        select value
        from jsonb_array_elements(
            v_result -> 'items'
        )
    loop

        v_tested_item_count :=
            v_tested_item_count + 1;


        if not exists (
            select 1

            from public.tahfiz_group_members
                as membership

            inner join public.tahfiz_supervisor_assignments
                as assignment
                on assignment.tahfiz_group_id =
                   membership.tahfiz_group_id

            where membership.student_id =
                  (
                      v_item
                      #>> '{student,id}'
                  )::uuid

              and assignment.staff_id =
                  v_staff_id

              and membership.is_active =
                  true

              and membership.left_at
                  is null

              and assignment.is_active =
                  true

              and assignment.ended_at
                  is null
        ) then
            raise exception
                'Overview mengandung santri di luar assignment.';
        end if;

    end loop;


    if v_tested_item_count = 0 then
        raise exception
            'Overview tidak mempunyai santri.';
    end if;


    raise notice
        'OVERVIEW ISOLATION SUCCESS';


    -- =====================================================
    -- F. DETAIL BEFORE REPORT
    -- =====================================================

    v_result :=
        public.get_pembina_tahfiz_weekly_report_detail(
            v_student_id,
            v_week_start
        );


    if v_result -> 'report'
       <> 'null'::jsonb
    then
        raise exception
            'Report seharusnya belum tersedia.';
    end if;


    raise notice
        'EMPTY REPORT DETAIL SUCCESS';


    -- =====================================================
    -- G. SAVE INCOMPLETE DRAFT
    -- =====================================================

    v_result :=
        public.save_pembina_tahfiz_weekly_report(
            v_student_id,
            v_week_start,

            'QS. Test ayat 1-10',
            null,

            'good',
            null,
            null,

            null,
            null
        );


    v_report_id :=
        (
            v_result
            ->> 'report_id'
        )::uuid;


    if v_report_id is null then
        raise exception
            'Draft report gagal dibuat.';
    end if;


    if (
        v_result
        ->> 'status'
    ) <> 'draft'
    then
        raise exception
            'Report pertama tidak berstatus draft.';
    end if;


    raise notice
        'SAVE INCOMPLETE DRAFT SUCCESS';


    -- =====================================================
    -- H. INCOMPLETE PUBLISH MUST FAIL
    -- =====================================================

    begin

        perform
            public.publish_pembina_tahfiz_weekly_report(
                v_student_id,
                v_week_start
            );


        raise exception
            'EXPECTED_INCOMPLETE_PUBLISH_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INCOMPLETE_PUBLISH_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Laporan belum lengkap%'
            then
                raise;
            end if;

    end;


    raise notice
        'INCOMPLETE PUBLISH PROTECTION SUCCESS';


    -- =====================================================
    -- I. SAVE COMPLETE REPORT
    -- =====================================================

    perform
        public.save_pembina_tahfiz_weekly_report(
            v_student_id,
            v_week_start,

            'QS. Al-Baqarah ayat 1-20',
            'Murajaah Juz 30',

            'good',
            'excellent',
            'good',

            'Perkembangan hafalan baik.',
            'Melanjutkan QS. Al-Baqarah ayat 21-30'
        );


    if not exists (
        select 1

        from public.tahfiz_weekly_reports
            as report

        where report.id =
              v_report_id

          and report.status =
              'draft'

          and report.memorization_achievement =
              'QS. Al-Baqarah ayat 1-20'

          and report.murajaah_achievement =
              'Murajaah Juz 30'

          and report.fluency_rating =
              'good'

          and report.tajwid_rating =
              'excellent'

          and report.consistency_rating =
              'good'

          and report.next_week_target =
              'Melanjutkan QS. Al-Baqarah ayat 21-30'
    ) then
        raise exception
            'Complete draft tidak tersimpan dengan benar.';
    end if;


    raise notice
        'SAVE COMPLETE DRAFT SUCCESS';


    -- =====================================================
    -- J. PUBLISH
    -- =====================================================

    v_result :=
        public.publish_pembina_tahfiz_weekly_report(
            v_student_id,
            v_week_start
        );


    if (
        v_result
        ->> 'status'
    ) <> 'published'
    then
        raise exception
            'Publish tidak menghasilkan status published.';
    end if;


    select
        report.published_at

    into
        v_published_at_before

    from public.tahfiz_weekly_reports
        as report

    where report.id =
          v_report_id;


    if v_published_at_before is null then
        raise exception
            'published_at tidak terisi.';
    end if;


    raise notice
        'PUBLISH REPORT SUCCESS';


    -- =====================================================
    -- K. EDIT PUBLISHED REPORT
    -- =====================================================

    v_result :=
        public.save_pembina_tahfiz_weekly_report(
            v_student_id,
            v_week_start,

            'QS. Al-Baqarah ayat 1-25',
            'Murajaah Juz 30',

            'excellent',
            'excellent',
            'good',

            'Laporan diperbaiki setelah publikasi.',
            'Melanjutkan QS. Al-Baqarah ayat 26-35'
        );


    if (
        v_result
        ->> 'status'
    ) <> 'published'
    then
        raise exception
            'Edit published report mengubah status.';
    end if;


    select
        report.published_at

    into
        v_published_at_after

    from public.tahfiz_weekly_reports
        as report

    where report.id =
          v_report_id;


    if v_published_at_after
       is distinct from
       v_published_at_before
    then
        raise exception
            'Edit published report mengubah published_at.';
    end if;


    raise notice
        'EDIT PUBLISHED REPORT PRESERVES PUBLICATION SUCCESS';


    -- =====================================================
    -- L. UNIQUE REPORT COUNT
    -- =====================================================

    if (
        select count(*)

        from public.tahfiz_weekly_reports
            as report

        where report.student_id =
              v_student_id

          and report.academic_year_id =
              v_current_year_id

          and report.week_start =
              v_week_start
    ) <> 1
    then
        raise exception
            'Terdapat duplikasi weekly report.';
    end if;


    raise notice
        'UNIQUE WEEKLY REPORT SUCCESS';


    -- =====================================================
    -- M. FIND STUDENT OUTSIDE ASSIGNMENT
    -- =====================================================

    select
        student.id

    into
        v_other_student_id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null

      and not exists (
          select 1

          from public.tahfiz_group_members
              as membership

          inner join public.tahfiz_supervisor_assignments
              as assignment
              on assignment.tahfiz_group_id =
                 membership.tahfiz_group_id

          inner join public.tahfiz_groups
              as tahfiz_group
              on tahfiz_group.id =
                 membership.tahfiz_group_id

          where membership.student_id =
                student.id

            and assignment.staff_id =
                v_staff_id

            and membership.is_active =
                true

            and membership.left_at
                is null

            and assignment.is_active =
                true

            and assignment.ended_at
                is null

            and tahfiz_group.academic_year_id =
                v_current_year_id
      )

    order by
        student.full_name

    limit 1;


    if v_other_student_id is null then
        raise exception
            'Santri di luar assignment untuk security test tidak ditemukan.';
    end if;


    begin

        perform
            public.get_pembina_tahfiz_weekly_report_detail(
                v_other_student_id,
                v_week_start
            );


        raise exception
            'EXPECTED_OUTSIDE_ASSIGNMENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_OUTSIDE_ASSIGNMENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%di luar assignment%'
            then
                raise;
            end if;

    end;


    raise notice
        'OUTSIDE ASSIGNMENT PROTECTION SUCCESS';


    -- =====================================================
    -- N. FIND NON PEMBINA
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_non_pembina_profile_id,
        v_non_pembina_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user
        on auth_user.id =
           profile.id

    where profile.is_active =
          true

      and not exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'pembina_tahfiz'

            and role.is_active =
                true
      )

    order by
        profile.created_at,
        profile.id

    limit 1;


    if v_non_pembina_profile_id is null then
        raise exception
            'Akun non-Pembina tidak ditemukan.';
    end if;


    -- =====================================================
    -- O. LOGIN NON PEMBINA
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_non_pembina_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_non_pembina_profile_id,

            'role',
            'authenticated',

            'email',
            v_non_pembina_email
        )::text,
        true
    );


    begin

        perform
            public.get_pembina_tahfiz_weekly_report_overview(
                v_week_start,
                null
            );


        raise exception
            'EXPECTED_NON_PEMBINA_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_PEMBINA_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses Laporan Tahfiz ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PEMBINA ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'PEMBINA TAHFIZ WEEKLY REPORT WORKFLOW VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Workflow Laporan Tahfiz Mingguan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;