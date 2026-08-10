-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 125-verify-guardian-tahfiz-report-history-function.sql
--
-- PURPOSE:
-- Verify Guardian Tahfiz Report History RPC.
--
-- SECURITY TEST:
-- - Own child allowed
-- - Outside child denied
-- - Draft never returned
-- - Pagination
-- - Non-Guardian denied
--
-- READ ONLY
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.get_guardian_tahfiz_report_history(uuid,integer,integer)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_guardian_tahfiz_report_history(uuid,integer,integer)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_guardian_tahfiz_report_history(uuid,integer,integer)',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_guardian record;

    v_result jsonb;
    v_item jsonb;

    v_own_student_id uuid;
    v_outside_student_id uuid;

    v_expected_count integer;
    v_returned_count integer;

    v_non_guardian_profile_id uuid;
    v_non_guardian_email text;

    v_tested_guardian_count integer := 0;
begin

    -- =====================================================
    -- A. TEST OPERATIONAL GUARDIANS WITH CHILDREN
    -- =====================================================

    for v_guardian in

        select distinct
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

        inner join public.guardian_students
            as guardian_student
            on guardian_student.guardian_id =
               guardian.id

        where guardian.is_active =
              true

          and profile.is_active =
              true

          and role.code =
              'guardian'

          and role.is_active =
              true

        order by
            guardian.full_name

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
        -- OWN CHILD
        -- =================================================

        select
            guardian_student.student_id

        into
            v_own_student_id

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
              is null

        order by
            guardian_student.created_at,
            guardian_student.id

        limit 1;


        if v_own_student_id is null then
            raise exception
                'Guardian % tidak memiliki santri aktif.',
                v_guardian.guardian_name;
        end if;


        -- =================================================
        -- CALL HISTORY
        -- =================================================

        v_result :=
            public.get_guardian_tahfiz_report_history(
                v_own_student_id,
                100,
                0
            );


        -- =================================================
        -- STUDENT RESPONSE MUST MATCH
        -- =================================================

        if (
            v_result
            #>> '{student,id}'
        )::uuid <>
           v_own_student_id
        then
            raise exception
                'Student response mismatch untuk Guardian %.',
                v_guardian.guardian_name;
        end if;


        -- =================================================
        -- EXPECTED PUBLISHED COUNT
        -- =================================================

        select
            count(*)::integer

        into
            v_expected_count

        from public.tahfiz_weekly_reports
            as report

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               report.academic_year_id

        where report.student_id =
              v_own_student_id

          and academic_year.is_current =
              true

          and report.status =
              'published'

          and report.published_at
              is not null;


        v_returned_count :=
            (
                v_result
                #>> '{summary,published_report_count}'
            )::integer;


        if v_returned_count <>
           v_expected_count
        then
            raise exception
                'Published count mismatch untuk Guardian %. Expected %, returned %.',
                v_guardian.guardian_name,
                v_expected_count,
                v_returned_count;
        end if;


        -- =================================================
        -- EVERY ITEM MUST BE PUBLISHED
        -- =================================================

        for v_item in

            select
                value

            from jsonb_array_elements(
                v_result -> 'items'
            )

        loop

            if (
                v_item
                ->> 'status'
            ) <> 'published'
            then
                raise exception
                    'Guardian % menerima laporan non-published.',
                    v_guardian.guardian_name;
            end if;


            if (
                v_item
                ->> 'published_at'
            ) is null
            then
                raise exception
                    'Guardian % menerima published report tanpa published_at.',
                    v_guardian.guardian_name;
            end if;

        end loop;


        raise notice
            'OWN CHILD HISTORY SUCCESS: % | published=%',
            v_guardian.guardian_name,
            v_returned_count;


        -- =================================================
        -- PAGINATION
        -- =================================================

        v_result :=
            public.get_guardian_tahfiz_report_history(
                v_own_student_id,
                1,
                0
            );


        if jsonb_array_length(
            v_result -> 'items'
        ) > 1
        then
            raise exception
                'Pagination limit gagal untuk Guardian %.',
                v_guardian.guardian_name;
        end if;


        if (
            v_result
            #>> '{pagination,limit}'
        )::integer <> 1
        then
            raise exception
                'Pagination response salah untuk Guardian %.',
                v_guardian.guardian_name;
        end if;


        raise notice
            'GUARDIAN HISTORY PAGINATION SUCCESS: %',
            v_guardian.guardian_name;


        -- =================================================
        -- OUTSIDE CHILD
        -- =================================================

        select
            student.id

        into
            v_outside_student_id

        from public.students
            as student

        where student.status =
              'active'

          and student.deleted_at
              is null

          and not exists (
              select 1

              from public.guardian_students
                  as guardian_student

              where guardian_student.guardian_id =
                    v_guardian.guardian_id

                and guardian_student.student_id =
                    student.id
          )

        order by
            student.full_name,
            student.id

        limit 1;


        if v_outside_student_id is not null then

            begin

                perform
                    public.get_guardian_tahfiz_report_history(
                        v_outside_student_id,
                        20,
                        0
                    );


                raise exception
                    'EXPECTED_OUTSIDE_STUDENT_FAILURE';

            exception
                when others then

                    if sqlerrm =
                       'EXPECTED_OUTSIDE_STUDENT_FAILURE'
                    then
                        raise;
                    end if;


                    if sqlerrm not ilike
                       '%Santri tidak terhubung dengan akun Orang Tua/Wali ini%'
                    then
                        raise;
                    end if;

            end;


            raise notice
                'OUTSIDE CHILD ACCESS PROTECTION SUCCESS: %',
                v_guardian.guardian_name;

        end if;

    end loop;


    -- =====================================================
    -- B. AT LEAST ONE GUARDIAN
    -- =====================================================

    if v_tested_guardian_count = 0 then
        raise exception
            'Tidak ada Guardian aktif dengan santri terhubung untuk diuji.';
    end if;


    raise notice
        'GUARDIAN HISTORY ISOLATION SUCCESS: % account(s)',
        v_tested_guardian_count;


    -- =====================================================
    -- C. NON-GUARDIAN ACCOUNT
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


    -- Gunakan student aktif apa pun.
    select
        student.id

    into
        v_own_student_id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null

    order by
        student.full_name

    limit 1;


    begin

        perform
            public.get_guardian_tahfiz_report_history(
                v_own_student_id,
                20,
                0
            );


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
               '%Akses Riwayat Tahfiz Orang Tua/Wali ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-GUARDIAN HISTORY ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'GUARDIAN TAHFIZ REPORT HISTORY VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Riwayat Tahfiz Orang Tua/Wali berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;