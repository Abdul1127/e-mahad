-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 106-verify-pembina-tahfiz-dashboard-function.sql
--
-- PURPOSE:
-- - Verify Dashboard Pembina Tahfiz
-- - Test seluruh Pembina Tahfiz aktif
-- - Verify assignment isolation
-- - Verify jumlah kelompok
-- - Verify jumlah santri
-- - Verify preview santri
-- - Verify non-Pembina ditolak
--
-- NO PERMANENT DATA CHANGES
-- =========================================================


-- =========================================================
-- 1. FUNCTION + PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.get_pembina_tahfiz_dashboard()'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_pembina_tahfiz_dashboard()',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_pembina_tahfiz_dashboard()',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_current_year_id uuid;

    v_pembina record;

    v_result jsonb;

    v_group_item jsonb;

    v_preview_item jsonb;

    v_returned_group_id uuid;

    v_returned_student_id uuid;

    v_expected_group_count integer;

    v_expected_student_count integer;

    v_returned_group_count integer;

    v_returned_student_count integer;

    v_non_pembina_profile_id uuid;

    v_non_pembina_email text;

    v_tested_pembina_count integer := 0;
begin

    -- =====================================================
    -- A. CURRENT ACADEMIC YEAR
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
    -- B. LOOP ALL OPERATIONAL PEMBINA
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


        -- =================================================
        -- LOGIN EMULATION
        -- =================================================

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
        -- CALL DASHBOARD
        -- =================================================

        v_result :=
            public.get_pembina_tahfiz_dashboard();


        -- =================================================
        -- STAFF ID MUST MATCH
        -- =================================================

        if (
            v_result
            #>> '{staff,id}'
        )::uuid <>
           v_pembina.staff_id
        then
            raise exception
                'Dashboard staff mismatch untuk %.',
                v_pembina.full_name;
        end if;


        -- =================================================
        -- EXPECTED GROUP COUNT
        -- =================================================

        select
            count(
                distinct assignment.tahfiz_group_id
            )::integer

        into
            v_expected_group_count

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               assignment.tahfiz_group_id

        where assignment.staff_id =
              v_pembina.staff_id

          and assignment.is_active =
              true

          and assignment.ended_at
              is null

          and tahfiz_group.is_active =
              true

          and tahfiz_group.academic_year_id =
              v_current_year_id;


        v_returned_group_count :=
            (
                v_result
                #>> '{summary,group_count}'
            )::integer;


        if v_returned_group_count <>
           v_expected_group_count
        then
            raise exception
                'Group count mismatch untuk %. Expected %, returned %.',
                v_pembina.full_name,
                v_expected_group_count,
                v_returned_group_count;
        end if;


        -- =================================================
        -- EXPECTED STUDENT COUNT
        -- =================================================

        select
            count(
                distinct student.id
            )::integer

        into
            v_expected_student_count

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
              v_pembina.staff_id

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
              is null;


        v_returned_student_count :=
            (
                v_result
                #>> '{summary,student_count}'
            )::integer;


        if v_returned_student_count <>
           v_expected_student_count
        then
            raise exception
                'Student count mismatch untuk %. Expected %, returned %.',
                v_pembina.full_name,
                v_expected_student_count,
                v_returned_student_count;
        end if;


        -- =================================================
        -- GROUP ISOLATION
        -- =================================================

        for v_group_item in

            select
                value

            from jsonb_array_elements(
                v_result -> 'groups'
            )

        loop

            v_returned_group_id :=
                (
                    v_group_item
                    ->> 'id'
                )::uuid;


            if not exists (
                select 1

                from public.tahfiz_supervisor_assignments
                    as assignment

                inner join public.tahfiz_groups
                    as tahfiz_group
                    on tahfiz_group.id =
                       assignment.tahfiz_group_id

                where assignment.staff_id =
                      v_pembina.staff_id

                  and assignment.tahfiz_group_id =
                      v_returned_group_id

                  and assignment.is_active =
                      true

                  and assignment.ended_at
                      is null

                  and tahfiz_group.is_active =
                      true

                  and tahfiz_group.academic_year_id =
                      v_current_year_id
            ) then
                raise exception
                    'Pembina % dapat melihat kelompok di luar assignment.',
                    v_pembina.full_name;
            end if;


            -- =============================================
            -- MEMBER PREVIEW ISOLATION
            -- =============================================

            for v_preview_item in

                select
                    value

                from jsonb_array_elements(
                    v_group_item
                    -> 'member_preview'
                )

            loop

                v_returned_student_id :=
                    (
                        v_preview_item
                        ->> 'id'
                    )::uuid;


                if not exists (
                    select 1

                    from public.tahfiz_group_members
                        as membership

                    inner join public.students
                        as student
                        on student.id =
                           membership.student_id

                    where membership.tahfiz_group_id =
                          v_returned_group_id

                      and membership.student_id =
                          v_returned_student_id

                      and membership.is_active =
                          true

                      and membership.left_at
                          is null

                      and student.status =
                          'active'

                      and student.deleted_at
                          is null
                ) then
                    raise exception
                        'Preview santri di luar kelompok untuk Pembina %.',
                        v_pembina.full_name;
                end if;

            end loop;

        end loop;


        raise notice
            'PEMBINA OK: % | groups=% | students=%',
            v_pembina.full_name,
            v_returned_group_count,
            v_returned_student_count;

    end loop;


    -- =====================================================
    -- C. MUST TEST PEMBINA
    -- =====================================================

    if v_tested_pembina_count = 0 then
        raise exception
            'Tidak ada akun Pembina Tahfiz aktif yang dapat diuji.';
    end if;


    raise notice
        'ALL PEMBINA DASHBOARD ISOLATION SUCCESS: % accounts',
        v_tested_pembina_count;


    -- =====================================================
    -- D. FIND NON-PEMBINA
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


    -- =====================================================
    -- E. LOGIN AS NON-PEMBINA
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


    -- =====================================================
    -- F. NON-PEMBINA MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_pembina_tahfiz_dashboard();


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
               '%Akses Dashboard Pembina Tahfiz ditolak%'
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
        'PEMBINA TAHFIZ DASHBOARD VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Dashboard Pembina Tahfiz berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;