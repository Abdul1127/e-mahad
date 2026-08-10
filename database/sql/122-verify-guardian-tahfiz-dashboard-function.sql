-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 122-verify-guardian-tahfiz-dashboard-function.sql
--
-- PURPOSE:
-- - Verify Guardian Dashboard RPC
-- - Verify guardian ↔ student isolation
-- - Verify only published reports
-- - Verify draft never returned
-- - Verify multiple children
-- - Verify non-Guardian denied
--
-- READ ONLY
-- Tidak membuat atau mengubah laporan.
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_guardian_tahfiz_dashboard()'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_guardian_tahfiz_dashboard()',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_guardian_tahfiz_dashboard()',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_guardian record;

    v_result jsonb;
    v_child jsonb;

    v_student_id uuid;

    v_expected_child_count integer;
    v_returned_child_count integer;

    v_expected_published_count integer;
    v_returned_published_count integer;

    v_latest_report_status text;

    v_non_guardian_profile_id uuid;
    v_non_guardian_email text;

    v_tested_guardian_count integer := 0;
begin

    -- =====================================================
    -- A. TEST ALL OPERATIONAL GUARDIAN ACCOUNTS
    -- =====================================================

    for v_guardian in

        select
            guardian.id
                as guardian_id,

            guardian.full_name
                as guardian_name,

            guardian.profile_id,

            auth_user.email

        from public.guardians
            as guardian

        inner join public.profiles
            as profile
            on profile.id =
               guardian.profile_id

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

        where guardian.is_active =
              true

          and guardian.profile_id
              is not null

          and profile.is_active =
              true

          and role.code =
              'guardian'

          and role.is_active =
              true

        order by
            guardian.full_name,
            guardian.id

    loop

        v_tested_guardian_count :=
            v_tested_guardian_count +
            1;


        -- =================================================
        -- LOGIN AS GUARDIAN
        -- =================================================

        perform set_config(
            'request.jwt.claim.sub',
            v_guardian.profile_id::text,
            true
        );


        perform set_config(
            'request.jwt.claims',
            jsonb_build_object(
                'sub',
                v_guardian.profile_id,

                'role',
                'authenticated',

                'email',
                v_guardian.email
            )::text,
            true
        );


        -- =================================================
        -- CALL RPC
        -- =================================================

        v_result :=
            public.get_guardian_tahfiz_dashboard();


        -- =================================================
        -- GUARDIAN ID MUST MATCH
        -- =================================================

        if (
            v_result
            #>> '{guardian,id}'
        )::uuid <>
           v_guardian.guardian_id
        then
            raise exception
                'Guardian identity mismatch untuk %.',
                v_guardian.guardian_name;
        end if;


        -- =================================================
        -- EXPECTED CHILD COUNT
        -- =================================================

        select
            count(
                distinct guardian_student.student_id
            )::integer

        into
            v_expected_child_count

        from public.guardian_students
            as guardian_student

        inner join public.students
            as student
            on student.id =
               guardian_student.student_id

        where guardian_student.guardian_id =
              v_guardian.guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null;


        v_returned_child_count :=
            (
                v_result
                #>> '{summary,child_count}'
            )::integer;


        if v_returned_child_count <>
           v_expected_child_count
        then
            raise exception
                'Child count mismatch untuk %. Expected %, returned %.',
                v_guardian.guardian_name,
                v_expected_child_count,
                v_returned_child_count;
        end if;


        if jsonb_array_length(
            v_result -> 'children'
        ) <>
           v_expected_child_count
        then
            raise exception
                'Jumlah children response salah untuk %.',
                v_guardian.guardian_name;
        end if;


        -- =================================================
        -- EXPECTED PUBLISHED REPORT COUNT
        -- =================================================

        select
            count(
                distinct report.id
            )::integer

        into
            v_expected_published_count

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

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               report.academic_year_id

        where guardian_student.guardian_id =
              v_guardian.guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null

          and academic_year.is_current =
              true

          and report.status =
              'published'

          and report.published_at
              is not null;


        v_returned_published_count :=
            (
                v_result
                #>> '{summary,published_report_count}'
            )::integer;


        if v_returned_published_count <>
           v_expected_published_count
        then
            raise exception
                'Published report count mismatch untuk %. Expected %, returned %.',
                v_guardian.guardian_name,
                v_expected_published_count,
                v_returned_published_count;
        end if;


        -- =================================================
        -- VERIFY EVERY CHILD
        -- =================================================

        for v_child in

            select
                value

            from jsonb_array_elements(
                v_result -> 'children'
            )

        loop

            v_student_id :=
                (
                    v_child
                    #>> '{student,id}'
                )::uuid;


            -- Guardian ↔ student relation wajib ada
            if not exists (
                select 1

                from public.guardian_students
                    as guardian_student

                where guardian_student.guardian_id =
                      v_guardian.guardian_id

                  and guardian_student.student_id =
                      v_student_id
            ) then
                raise exception
                    'Guardian % menerima data santri yang bukan anak terhubung.',
                    v_guardian.guardian_name;
            end if;


            -- =================================================
            -- LATEST REPORT MUST BE PUBLISHED
            -- =================================================

            if (
                v_child -> 'latest_report'
            ) <>
            'null'::jsonb
            then

                v_latest_report_status :=
                    v_child
                    #>> '{latest_report,status}';


                if v_latest_report_status <>
                   'published'
                then
                    raise exception
                        'Guardian % menerima report non-published.',
                        v_guardian.guardian_name;
                end if;

            end if;

        end loop;


        raise notice
            'GUARDIAN DASHBOARD OK: % | children=% | published=%',
            v_guardian.guardian_name,
            v_returned_child_count,
            v_returned_published_count;

    end loop;


    -- =====================================================
    -- B. MUST HAVE AT LEAST ONE OPERATIONAL GUARDIAN
    -- =====================================================

    if v_tested_guardian_count = 0 then
        raise exception
            'Tidak ada akun Guardian aktif yang dapat diuji.';
    end if;


    raise notice
        'GUARDIAN-STUDENT ISOLATION SUCCESS: % account(s)',
        v_tested_guardian_count;


    -- =====================================================
    -- C. EXPLICIT DRAFT LEAK CHECK
    --
    -- RPC response must contain zero "draft" report objects.
    -- =====================================================

    for v_guardian in

        select
            guardian.id
                as guardian_id,

            guardian.profile_id,

            auth_user.email

        from public.guardians
            as guardian

        inner join public.profiles
            as profile
            on profile.id =
               guardian.profile_id

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

        where guardian.is_active =
              true

          and profile.is_active =
              true

          and role.code =
              'guardian'

          and role.is_active =
              true

    loop

        perform set_config(
            'request.jwt.claim.sub',
            v_guardian.profile_id::text,
            true
        );


        perform set_config(
            'request.jwt.claims',
            jsonb_build_object(
                'sub',
                v_guardian.profile_id,

                'role',
                'authenticated',

                'email',
                v_guardian.email
            )::text,
            true
        );


        v_result :=
            public.get_guardian_tahfiz_dashboard();


        if exists (
            select 1

            from jsonb_array_elements(
                v_result -> 'children'
            ) as child(value)

            where (
                child.value
                #>> '{latest_report,status}'
            ) = 'draft'
        ) then
            raise exception
                'DRAFT REPORT LEAKED TO GUARDIAN.';
        end if;

    end loop;


    raise notice
        'DRAFT REPORT PROTECTION SUCCESS';


    -- =====================================================
    -- D. FIND NON-GUARDIAN
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_non_guardian_profile_id,
        v_non_guardian_email

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
                'guardian'

            and role.is_active =
                true
      )

    order by
        profile.created_at,
        profile.id

    limit 1;


    if v_non_guardian_profile_id is null then
        raise exception
            'Akun non-Guardian untuk security test tidak ditemukan.';
    end if;


    -- =====================================================
    -- E. LOGIN AS NON-GUARDIAN
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_non_guardian_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_non_guardian_profile_id,

            'role',
            'authenticated',

            'email',
            v_non_guardian_email
        )::text,
        true
    );


    begin

        perform
            public.get_guardian_tahfiz_dashboard();


        raise exception
            'EXPECTED_NON_GUARDIAN_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_GUARDIAN_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses Dashboard Orang Tua/Wali ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-GUARDIAN ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'GUARDIAN TAHFIZ DASHBOARD VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Dashboard Tahfiz Orang Tua/Wali berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;