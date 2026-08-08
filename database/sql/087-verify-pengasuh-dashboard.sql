-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 087-verify-pengasuh-dashboard.sql
--
-- PURPOSE:
-- - Verify get_pengasuh_dashboard()
-- - Test semua akun Pengasuh operasional
-- - Pastikan group tidak bocor antar-Pengasuh
-- - Pastikan jumlah santri sesuai assignment
-- - Pastikan preview santri berasal dari group assignment
-- - Pastikan non-Pengasuh ditolak
--
-- READ ONLY / TEST SESSION
-- =========================================================


-- =========================================================
-- 1. FUNCTION + PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.get_pengasuh_dashboard()'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_pengasuh_dashboard()',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_pengasuh_dashboard()',
        'execute'
    ) as anon_can_execute;


begin;


-- =========================================================
-- 2. VERIFY ALL OPERATIONAL PENGASUH
-- =========================================================

do $verification$
declare
    v_pengasuh record;

    v_result jsonb;

    v_group_item jsonb;

    v_member_item jsonb;

    v_expected_group_count integer;

    v_expected_student_count integer;

    v_expected_male_count integer;

    v_expected_female_count integer;

    v_tested_pengasuh_count integer :=
        0;

    v_non_pengasuh_profile_id uuid;

    v_non_pengasuh_email text;
begin

    -- =====================================================
    -- LOOP SEMUA PENGASUH AKTIF
    -- =====================================================

    for v_pengasuh in

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
              'pengasuh'

          and profile.is_active =
              true

          and staff.is_active =
              true

        order by
            staff.full_name,
            staff.id

    loop

        v_tested_pengasuh_count :=
            v_tested_pengasuh_count + 1;


        -- =================================================
        -- EMULATE LOGIN
        -- =================================================

        perform set_config(
            'request.jwt.claim.sub',
            v_pengasuh.profile_id::text,
            true
        );


        perform set_config(
            'request.jwt.claims',
            jsonb_build_object(
                'sub',
                v_pengasuh.profile_id,

                'role',
                'authenticated',

                'email',
                v_pengasuh.email
            )::text,
            true
        );


        -- =================================================
        -- CALL RPC
        -- =================================================

        v_result :=
            public.get_pengasuh_dashboard();


        if v_result is null then
            raise exception
                'Dashboard NULL untuk Pengasuh %.',
                v_pengasuh.full_name;
        end if;


        -- =================================================
        -- IDENTITY MUST MATCH AUTH USER
        -- =================================================

        if (
            v_result
            #>> '{profile,id}'
        )::uuid <>
           v_pengasuh.profile_id
        then
            raise exception
                'Profile dashboard tidak sesuai untuk Pengasuh %.',
                v_pengasuh.full_name;
        end if;


        if (
            v_result
            #>> '{staff,id}'
        )::uuid <>
           v_pengasuh.staff_id
        then
            raise exception
                'Staff dashboard tidak sesuai untuk Pengasuh %.',
                v_pengasuh.full_name;
        end if;


        -- =================================================
        -- EXPECTED COUNTS
        -- =================================================

        select
            count(*)::integer

        into
            v_expected_group_count

        from public.caregiver_assignments
            as assignment

        inner join public.care_groups
            as care_group
            on care_group.id =
               assignment.care_group_id

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               care_group.academic_year_id

        where assignment.staff_id =
              v_pengasuh.staff_id

          and assignment.is_active =
              true

          and care_group.is_active =
              true

          and academic_year.is_current =
              true;


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
            v_expected_student_count,

            v_expected_male_count,

            v_expected_female_count

        from public.caregiver_assignments
            as assignment

        inner join public.care_groups
            as care_group
            on care_group.id =
               assignment.care_group_id

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               care_group.academic_year_id

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

        where assignment.staff_id =
              v_pengasuh.staff_id

          and assignment.is_active =
              true

          and care_group.is_active =
              true

          and academic_year.is_current =
              true

          and student.status =
              'active'

          and student.deleted_at
              is null;


        -- =================================================
        -- COMPARE COUNTS
        -- =================================================

        if (
            v_result
            #>> '{summary,assigned_group_count}'
        )::integer <>
           v_expected_group_count
        then
            raise exception
                'Jumlah group dashboard % tidak sesuai. Expected %, actual %.',
                v_pengasuh.full_name,
                v_expected_group_count,
                v_result
                #>> '{summary,assigned_group_count}';
        end if;


        if (
            v_result
            #>> '{summary,active_student_count}'
        )::integer <>
           v_expected_student_count
        then
            raise exception
                'Jumlah santri dashboard % tidak sesuai.',
                v_pengasuh.full_name;
        end if;


        if (
            v_result
            #>> '{summary,male_student_count}'
        )::integer <>
           v_expected_male_count
        then
            raise exception
                'Jumlah santri Putra dashboard % tidak sesuai.',
                v_pengasuh.full_name;
        end if;


        if (
            v_result
            #>> '{summary,female_student_count}'
        )::integer <>
           v_expected_female_count
        then
            raise exception
                'Jumlah santri Putri dashboard % tidak sesuai.',
                v_pengasuh.full_name;
        end if;


        -- =================================================
        -- GROUP ISOLATION
        -- =================================================

        for v_group_item in

            select value

            from jsonb_array_elements(
                v_result -> 'groups'
            )

        loop

            if not exists (
                select 1

                from public.caregiver_assignments
                    as assignment

                inner join public.care_groups
                    as care_group
                    on care_group.id =
                       assignment.care_group_id

                inner join public.academic_years
                    as academic_year
                    on academic_year.id =
                       care_group.academic_year_id

                where assignment.staff_id =
                      v_pengasuh.staff_id

                  and assignment.care_group_id =
                      (
                          v_group_item
                          ->> 'id'
                      )::uuid

                  and assignment.is_active =
                      true

                  and care_group.is_active =
                      true

                  and academic_year.is_current =
                      true
            ) then
                raise exception
                    'DATA LEAK: Pengasuh % menerima group yang bukan assignment miliknya.',
                    v_pengasuh.full_name;
            end if;


            -- =============================================
            -- MEMBER PREVIEW ISOLATION
            -- =============================================

            for v_member_item in

                select value

                from jsonb_array_elements(
                    v_group_item
                    -> 'member_preview'
                )

            loop

                if not exists (
                    select 1

                    from public.care_group_members
                        as membership

                    inner join public.students
                        as student
                        on student.id =
                           membership.student_id

                    where membership.care_group_id =
                          (
                              v_group_item
                              ->> 'id'
                          )::uuid

                      and membership.student_id =
                          (
                              v_member_item
                              ->> 'student_id'
                          )::uuid

                      and membership.is_active =
                          true

                      and student.status =
                          'active'

                      and student.deleted_at
                          is null
                ) then
                    raise exception
                        'DATA LEAK: Preview santri tidak berasal dari kelompok Pengasuh %.',
                        v_pengasuh.full_name;
                end if;

            end loop;

        end loop;


        raise notice
            'PENGASUH VERIFIED: % | groups: % | students: %',
            v_pengasuh.full_name,
            v_expected_group_count,
            v_expected_student_count;

    end loop;


    -- =====================================================
    -- MINIMUM TESTED ACCOUNT
    -- =====================================================

    if v_tested_pengasuh_count = 0 then
        raise exception
            'Tidak ada akun Pengasuh yang dapat diverifikasi.';
    end if;


    -- =====================================================
    -- NON-PENGASUH MUST BE DENIED
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_non_pengasuh_profile_id,
        v_non_pengasuh_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user
        on auth_user.id =
           profile.id

    where profile.is_active = true

      and exists (
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
                'admin'
      )

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
                'pengasuh'
      )

    order by
        profile.created_at,
        profile.id

    limit 1;


    if v_non_pengasuh_profile_id
       is null
    then
        raise exception
            'Akun non-Pengasuh untuk security test tidak ditemukan.';
    end if;


    perform set_config(
        'request.jwt.claim.sub',
        v_non_pengasuh_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_non_pengasuh_profile_id,

            'role',
            'authenticated',

            'email',
            v_non_pengasuh_email
        )::text,
        true
    );


    begin

        perform
            public.get_pengasuh_dashboard();


        raise exception
            'Akun non-Pengasuh berhasil mengakses Dashboard Pengasuh.';

    exception
        when others then

            if sqlerrm not ilike
               '%Akses Dashboard Pengasuh ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PENGASUH ACCESS PROTECTION SUCCESS';


    raise notice
        'TOTAL PENGASUH VERIFIED: %',
        v_tested_pengasuh_count;


    raise notice
        'PENGASUH DASHBOARD VERIFICATION SUCCESS';

end;
$verification$;


rollback;


-- =========================================================
-- FINAL OUTPUT
-- =========================================================

select
    'Dashboard Pengasuh berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;