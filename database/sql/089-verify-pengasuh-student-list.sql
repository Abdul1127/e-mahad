-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 089-verify-pengasuh-student-list.sql
--
-- PURPOSE:
-- - Verify daftar Santri Ampuan
-- - Test semua Pengasuh aktif
-- - Pastikan tidak ada santri dari group lain
-- - Test pencarian
-- - Pastikan non-Pengasuh ditolak
-- =========================================================


select
    to_regprocedure(
        'public.get_pengasuh_student_list(text)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_pengasuh_student_list(text)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_pengasuh_student_list(text)',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_pengasuh record;

    v_result jsonb;

    v_item jsonb;

    v_expected_count integer;

    v_actual_count integer;

    v_tested_count integer := 0;

    v_first_student_name text;

    v_search_result jsonb;

    v_non_pengasuh_profile_id uuid;

    v_non_pengasuh_email text;
begin

    -- =====================================================
    -- A. TEST ALL OPERATIONAL PENGASUH
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

        v_tested_count :=
            v_tested_count + 1;


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


        v_result :=
            public.get_pengasuh_student_list(
                null
            );


        -- =================================================
        -- EXPECTED COUNT
        -- =================================================

        select
            count(
                distinct student.id
            )::integer

        into
            v_expected_count

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


        v_actual_count :=
            (
                v_result
                #>> '{summary,student_count}'
            )::integer;


        if v_actual_count <>
           v_expected_count
        then
            raise exception
                'Jumlah Santri Ampuan % tidak sesuai. Expected %, actual %.',
                v_pengasuh.full_name,
                v_expected_count,
                v_actual_count;
        end if;


        -- =================================================
        -- ITEM ISOLATION
        -- =================================================

        for v_item in

            select value

            from jsonb_array_elements(
                v_result -> 'items'
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

                inner join public.care_group_members
                    as membership
                    on membership.care_group_id =
                       care_group.id

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

                  and membership.is_active =
                      true

                  and student.id =
                      (
                          v_item
                          ->> 'student_id'
                      )::uuid

                  and student.status =
                      'active'

                  and student.deleted_at
                      is null
            ) then
                raise exception
                    'DATA LEAK: Pengasuh % menerima santri di luar assignment.',
                    v_pengasuh.full_name;
            end if;

        end loop;


        -- =================================================
        -- SEARCH TEST
        -- =================================================

        select
            item ->> 'full_name'

        into
            v_first_student_name

        from jsonb_array_elements(
            v_result -> 'items'
        ) as list_item(item)

        limit 1;


        if v_first_student_name
           is not null
        then

            v_search_result :=
                public.get_pengasuh_student_list(
                    v_first_student_name
                );


            if (
                v_search_result
                #>> '{summary,student_count}'
            )::integer < 1
            then
                raise exception
                    'Pencarian Santri Ampuan gagal untuk Pengasuh %.',
                    v_pengasuh.full_name;
            end if;

        end if;


        raise notice
            'PENGASUH STUDENT LIST VERIFIED: % | students: %',
            v_pengasuh.full_name,
            v_expected_count;

    end loop;


    if v_tested_count = 0 then
        raise exception
            'Tidak ada akun Pengasuh aktif untuk pengujian.';
    end if;


    -- =====================================================
    -- B. NON-PENGASUH MUST FAIL
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

    where profile.is_active =
          true

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
            public.get_pengasuh_student_list(
                null
            );


        raise exception
            'Akun non-Pengasuh berhasil mengakses Santri Ampuan.';

    exception
        when others then

            if sqlerrm not ilike
               '%Akses Santri Ampuan ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PENGASUH STUDENT ACCESS PROTECTION SUCCESS';


    raise notice
        'TOTAL PENGASUH STUDENT LIST VERIFIED: %',
        v_tested_count;


    raise notice
        'PENGASUH STUDENT LIST VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Santri Ampuan Pengasuh berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;