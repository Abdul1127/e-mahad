-- =========================================================
-- E-MA'HAD
-- 179-verify-leadership-tahfiz-monitoring.sql
--
-- VERIFICATION:
-- - function existence
-- - Kepala Ma'had access
-- - Penanggung Jawab access
-- - Guardian denied
-- - published only
-- - detail/history
-- =========================================================


-- =========================================================
-- 01. FOUNDATION
-- =========================================================

select
    to_regprocedure(
        'public.get_leadership_tahfiz_monitoring_overview(date,text,uuid)'
    ) is not null
        as overview_function_exists,

    to_regprocedure(
        'public.get_leadership_tahfiz_student_history(uuid,integer,integer)'
    ) is not null
        as history_function_exists;


-- =========================================================
-- 02. CURRENT STRUCTURE
-- =========================================================

select
    (
        select
            count(*)::integer

        from public.tahfiz_groups
            as tahfiz_group

        inner join public.academic_years
            as academic_year

            on academic_year.id =
               tahfiz_group.academic_year_id

        where academic_year.is_current =
              true

          and tahfiz_group.is_active =
              true
    )
        as active_group_count,

    (
        select
            count(
                distinct member.student_id
            )::integer

        from public.tahfiz_group_members
            as member

        inner join public.tahfiz_groups
            as tahfiz_group

            on tahfiz_group.id =
               member.tahfiz_group_id

        inner join public.academic_years
            as academic_year

            on academic_year.id =
               tahfiz_group.academic_year_id

        where academic_year.is_current =
              true

          and tahfiz_group.is_active =
              true

          and member.is_active =
              true
    )
        as active_student_count,

    (
        select
            count(*)::integer

        from public.tahfiz_weekly_reports
            as report

        inner join public.academic_years
            as academic_year

            on academic_year.id =
               report.academic_year_id

        where academic_year.is_current =
              true

          and report.status =
              'published'
    )
        as published_report_count;


-- =========================================================
-- 03. ROLE VERIFICATION
-- =========================================================

begin;


do $verification$
declare
    v_kepala_profile_id uuid;
    v_kepala_email text;

    v_penanggung_profile_id uuid;
    v_penanggung_email text;

    v_guardian_profile_id uuid;
    v_guardian_email text;

    v_student_id uuid;

    v_week_start date;

    v_result jsonb;
    v_history jsonb;

    v_item jsonb;
begin

    -- =====================================================
    -- CURRENT WEEK
    -- =====================================================

    v_week_start :=
        date_trunc(
            'week',
            current_date
        )::date;


    -- =====================================================
    -- KEPALA MA'HAD
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_kepala_profile_id,
        v_kepala_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    where role.code =
          'kepala_mahad'

      and role.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_kepala_profile_id is null then
        raise exception
            'Akun Kepala Ma''had tidak ditemukan.';
    end if;


    perform set_config(
        'request.jwt.claim.sub',
        v_kepala_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_kepala_profile_id,

            'role',
            'authenticated',

            'email',
            v_kepala_email
        )::text,
        true
    );


    v_result :=
        public.get_leadership_tahfiz_monitoring_overview(
            v_week_start,
            null,
            null
        );


    if (
        v_result
        #>> '{academic_year,name}'
    ) is null then
        raise exception
            'Academic year tidak ditemukan pada overview.';
    end if;


    if (
        v_result
        #>> '{summary,group_count}'
    )::integer <= 0 then
        raise exception
            'Kelompok Tahfiz tidak ditemukan.';
    end if;


    if (
        v_result
        #>> '{summary,student_count}'
    )::integer <= 0 then
        raise exception
            'Santri Tahfiz tidak ditemukan.';
    end if;


    -- Draft must never appear.
    for v_item in
        select
            value

        from jsonb_array_elements(
            v_result -> 'items'
        )
    loop

        if v_item -> 'report'
           is not null

           and (
               v_item
               #>> '{report,status}'
           ) <>
           'published'
        then
            raise exception
                'Overview mengekspos report selain published.';
        end if;

    end loop;


    raise notice
        'KEPALA MAHAD OVERVIEW SUCCESS';


    -- =====================================================
    -- STUDENT HISTORY
    -- Gunakan santri yang mempunyai published report.
    -- =====================================================

    select
        report.student_id

    into
        v_student_id

    from public.tahfiz_weekly_reports
        as report

    inner join public.academic_years
        as academic_year

        on academic_year.id =
           report.academic_year_id

    where academic_year.is_current =
          true

      and report.status =
          'published'

    order by
        report.week_start desc

    limit 1;


    if v_student_id is not null then

        v_history :=
            public.get_leadership_tahfiz_student_history(
                v_student_id,
                10,
                0
            );


        if (
            v_history
            #>> '{student,id}'
        )::uuid <>
           v_student_id
        then
            raise exception
                'History santri tidak sesuai.';
        end if;


        for v_item in
            select
                value

            from jsonb_array_elements(
                v_history -> 'items'
            )
        loop

            if (
                v_item
                ->> 'status'
            ) <>
               'published'
            then
                raise exception
                    'History mengekspos report selain published.';
            end if;

        end loop;


        raise notice
            'KEPALA MAHAD STUDENT HISTORY SUCCESS';

    else

        raise notice
            'Tidak ada published report untuk pengujian history.';

    end if;


    -- =====================================================
    -- PENANGGUNG JAWAB
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_penanggung_profile_id,
        v_penanggung_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    where role.code =
          'penanggung_jawab'

      and role.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_penanggung_profile_id is null then
        raise exception
            'Akun Penanggung Jawab tidak ditemukan.';
    end if;


    perform set_config(
        'request.jwt.claim.sub',
        v_penanggung_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_penanggung_profile_id,

            'role',
            'authenticated',

            'email',
            v_penanggung_email
        )::text,
        true
    );


    v_result :=
        public.get_leadership_tahfiz_monitoring_overview(
            v_week_start,
            null,
            null
        );


    if (
        v_result
        #>> '{summary,student_count}'
    )::integer <= 0 then
        raise exception
            'Penanggung Jawab tidak menerima data monitoring.';
    end if;


    if v_student_id is not null then

        v_history :=
            public.get_leadership_tahfiz_student_history(
                v_student_id,
                10,
                0
            );


        if (
            v_history
            #>> '{student,id}'
        )::uuid <>
           v_student_id
        then
            raise exception
                'History Penanggung Jawab tidak sesuai.';
        end if;

    end if;


    raise notice
        'PENANGGUNG JAWAB MONITORING SUCCESS';


    -- =====================================================
    -- GUARDIAN MUST BE DENIED
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_guardian_profile_id,
        v_guardian_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    where role.code =
          'guardian'

      and role.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_guardian_profile_id is not null then

        perform set_config(
            'request.jwt.claim.sub',
            v_guardian_profile_id::text,
            true
        );


        perform set_config(
            'request.jwt.claims',
            jsonb_build_object(
                'sub',
                v_guardian_profile_id,

                'role',
                'authenticated',

                'email',
                v_guardian_email
            )::text,
            true
        );


        begin

            perform
                public.get_leadership_tahfiz_monitoring_overview(
                    v_week_start,
                    null,
                    null
                );


            raise exception
                'EXPECTED_GUARDIAN_FAILURE';

        exception
            when others then

                if sqlerrm =
                   'EXPECTED_GUARDIAN_FAILURE'
                then
                    raise;
                end if;


                if sqlerrm not ilike
                   '%Akses monitoring Tahfiz pimpinan ditolak%'
                then
                    raise;
                end if;

        end;


        raise notice
            'GUARDIAN ACCESS PROTECTION SUCCESS';

    end if;


    raise notice
        'LEADERSHIP TAHFIZ MONITORING VERIFICATION SUCCESS';

end;
$verification$;


rollback;


-- =========================================================
-- 04. FINAL
-- =========================================================

select
    'Monitoring Tahfiz pimpinan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;