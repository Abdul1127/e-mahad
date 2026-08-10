-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 118-verify-pembina-tahfiz-weekly-report-history.sql
--
-- PURPOSE:
-- - Verify function exists
-- - Verify Pembina isolation
-- - Verify status filter
-- - Verify search
-- - Verify pagination
-- - Verify invalid status
-- - Verify non-Pembina denied
--
-- READ TEST ONLY
-- Tidak membuat report baru.
-- =========================================================


select
    to_regprocedure(
        'public.get_pembina_tahfiz_weekly_report_history(text,text,integer,integer)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_pembina_tahfiz_weekly_report_history(text,text,integer,integer)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_pembina_tahfiz_weekly_report_history(text,text,integer,integer)',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_current_year_id uuid;

    v_pembina record;

    v_result jsonb;
    v_search_result jsonb;
    v_status_result jsonb;
    v_pagination_result jsonb;

    v_item jsonb;

    v_student_id uuid;
    v_group_id uuid;

    v_search_value text;

    v_non_pembina_profile_id uuid;
    v_non_pembina_email text;

    v_tested_pembina_count integer := 0;
begin

    -- =====================================================
    -- A. CURRENT YEAR
    -- =====================================================

    select
        academic_year.id

    into
        v_current_year_id

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
    -- B. TEST ALL OPERATIONAL PEMBINA
    -- =====================================================

    for v_pembina in

        select distinct
            profile.id
                as profile_id,

            auth_user.email,

            staff.id
                as staff_id,

            staff.full_name

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

        where role.code =
              'pembina_tahfiz'

          and role.is_active =
              true

          and profile.is_active =
              true

          and staff.is_active =
              true

        order by
            staff.full_name

    loop

        v_tested_pembina_count :=
            v_tested_pembina_count +
            1;


        perform set_config(
            'request.jwt.claim.sub',
            v_pembina.profile_id::text,
            true
        );


        perform set_config(
            'request.jwt.claims',
            jsonb_build_object(
                'sub',
                v_pembina.profile_id,

                'role',
                'authenticated',

                'email',
                v_pembina.email
            )::text,
            true
        );


        -- =================================================
        -- FULL HISTORY
        -- =================================================

        v_result :=
            public.get_pembina_tahfiz_weekly_report_history(
                null,
                null,
                100,
                0
            );


        -- =================================================
        -- VERIFY EVERY RETURNED ITEM
        -- =================================================

        for v_item in

            select value

            from jsonb_array_elements(
                v_result -> 'items'
            )

        loop

            v_student_id :=
                (
                    v_item
                    #>> '{student,id}'
                )::uuid;


            v_group_id :=
                (
                    v_item
                    #>> '{tahfiz_group,id}'
                )::uuid;


            if not exists (
                select 1

                from public.tahfiz_supervisor_assignments
                    as assignment

                where assignment.staff_id =
                      v_pembina.staff_id

                  and assignment.tahfiz_group_id =
                      v_group_id

                  and assignment.is_active =
                      true

                  and assignment.ended_at
                      is null
            ) then
                raise exception
                    'History Pembina % mengandung group di luar assignment.',
                    v_pembina.full_name;
            end if;


            if not exists (
                select 1

                from public.tahfiz_group_members
                    as membership

                where membership.student_id =
                      v_student_id

                  and membership.tahfiz_group_id =
                      v_group_id

                  and membership.is_active =
                      true

                  and membership.left_at
                      is null
            ) then
                raise exception
                    'History Pembina % mengandung santri di luar assignment.',
                    v_pembina.full_name;
            end if;

        end loop;


        raise notice
            'HISTORY ISOLATION OK: % | reports=%',
            v_pembina.full_name,
            (
                v_result
                #>> '{summary,total_count}'
            )::integer;


        -- =================================================
        -- STATUS FILTER
        -- =================================================

        v_status_result :=
            public.get_pembina_tahfiz_weekly_report_history(
                'published',
                null,
                100,
                0
            );


        for v_item in

            select value

            from jsonb_array_elements(
                v_status_result -> 'items'
            )

        loop

            if (
                v_item
                #>> '{report,status}'
            ) <> 'published'
            then
                raise exception
                    'Status filter published gagal untuk %.',
                    v_pembina.full_name;
            end if;

        end loop;


        raise notice
            'STATUS FILTER OK: %',
            v_pembina.full_name;


        -- =================================================
        -- SEARCH TEST
        -- =================================================

        select
            coalesce(
                nullif(
                    student.legacy_student_id,
                    ''
                ),

                nullif(
                    student.nis,
                    ''
                ),

                student.full_name
            )

        into
            v_search_value

        from public.tahfiz_weekly_reports
            as report

        inner join public.students
            as student
            on student.id =
               report.student_id

        where report.academic_year_id =
              v_current_year_id

          and exists (
              select 1

              from public.tahfiz_supervisor_assignments
                  as assignment

              where assignment.staff_id =
                    v_pembina.staff_id

                and assignment.tahfiz_group_id =
                    report.tahfiz_group_id

                and assignment.is_active =
                    true

                and assignment.ended_at
                    is null
          )

          and exists (
              select 1

              from public.tahfiz_group_members
                  as membership

              where membership.student_id =
                    report.student_id

                and membership.tahfiz_group_id =
                    report.tahfiz_group_id

                and membership.is_active =
                    true

                and membership.left_at
                    is null
          )

        order by
            report.updated_at desc

        limit 1;


        if v_search_value is not null then

            v_search_result :=
                public.get_pembina_tahfiz_weekly_report_history(
                    null,
                    v_search_value,
                    100,
                    0
                );


            if (
                v_search_result
                #>> '{summary,filtered_count}'
            )::integer < 1
            then
                raise exception
                    'Search history gagal untuk %.',
                    v_pembina.full_name;
            end if;


            raise notice
                'SEARCH FILTER OK: % | query=%',
                v_pembina.full_name,
                v_search_value;

        end if;


        -- =================================================
        -- PAGINATION TEST
        -- =================================================

        v_pagination_result :=
            public.get_pembina_tahfiz_weekly_report_history(
                null,
                null,
                1,
                0
            );


        if jsonb_array_length(
            v_pagination_result -> 'items'
        ) > 1
        then
            raise exception
                'Pagination limit gagal untuk %.',
                v_pembina.full_name;
        end if;


        if (
            v_pagination_result
            #>> '{pagination,limit}'
        )::integer <> 1
        then
            raise exception
                'Pagination response limit salah.';
        end if;


        raise notice
            'PAGINATION OK: %',
            v_pembina.full_name;

    end loop;


    if v_tested_pembina_count = 0 then
        raise exception
            'Tidak ada Pembina Tahfiz aktif untuk diuji.';
    end if;


    -- =====================================================
    -- C. INVALID STATUS MUST FAIL
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        (
            select
                profile.id::text

            from public.profiles
                as profile

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

            where role.code =
                  'pembina_tahfiz'

              and profile.is_active =
                  true

              and staff.is_active =
                  true

            limit 1
        ),
        true
    );


    begin

        perform
            public.get_pembina_tahfiz_weekly_report_history(
                'invalid',
                null,
                20,
                0
            );


        raise exception
            'EXPECTED_INVALID_STATUS_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INVALID_STATUS_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%status%tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID STATUS PROTECTION SUCCESS';


    -- =====================================================
    -- D. NON-PEMBINA
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
            'Akun non-Pembina untuk security test tidak ditemukan.';
    end if;


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
            public.get_pembina_tahfiz_weekly_report_history(
                null,
                null,
                20,
                0
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
               '%Akses Riwayat Laporan Tahfiz ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PEMBINA HISTORY ACCESS PROTECTION SUCCESS';


    raise notice
        'PEMBINA TAHFIZ WEEKLY REPORT HISTORY VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Riwayat Laporan Tahfiz berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;