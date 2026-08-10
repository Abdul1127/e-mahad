-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 108-verify-pembina-tahfiz-student-list-function.sql
--
-- PURPOSE:
-- - Verify daftar Santri Tahfiz Ampuan
-- - Test seluruh Pembina Tahfiz aktif
-- - Verify jumlah santri
-- - Verify group isolation
-- - Verify student isolation
-- - Verify search
-- - Verify non-Pembina ditolak
--
-- NO PERMANENT DATA CHANGES
-- =========================================================


-- =========================================================
-- 1. FUNCTION + PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.get_pembina_tahfiz_student_list(text)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_pembina_tahfiz_student_list(text)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_pembina_tahfiz_student_list(text)',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_current_year_id uuid;

    v_pembina record;

    v_result jsonb;

    v_item jsonb;

    v_returned_student_id uuid;

    v_returned_group_id uuid;

    v_expected_student_count integer;

    v_returned_student_count integer;

    v_returned_filtered_count integer;

    v_search_student_id uuid;

    v_search_value text;

    v_search_found boolean;

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
        -- LOGIN AS PEMBINA
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
        -- CALL FULL LIST
        -- =================================================

        v_result :=
            public.get_pembina_tahfiz_student_list(
                null
            );


        -- =================================================
        -- STAFF MUST MATCH
        -- =================================================

        if (
            v_result
            #>> '{staff,id}'
        )::uuid <>
           v_pembina.staff_id
        then
            raise exception
                'Staff mismatch untuk Pembina %.',
                v_pembina.full_name;
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


        if jsonb_array_length(
            v_result -> 'items'
        ) <>
           v_expected_student_count
        then
            raise exception
                'Jumlah items tidak sama dengan jumlah santri untuk %.',
                v_pembina.full_name;
        end if;


        -- =================================================
        -- GROUP + STUDENT ISOLATION
        -- =================================================

        for v_item in

            select
                value

            from jsonb_array_elements(
                v_result -> 'items'
            )

        loop

            v_returned_student_id :=
                (
                    v_item
                    ->> 'id'
                )::uuid;


            v_returned_group_id :=
                (
                    v_item
                    #>> '{tahfiz_group,id}'
                )::uuid;


            -- Pembina wajib memiliki assignment ke group
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


            -- Student wajib member aktif group tersebut
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
                    'Pembina % dapat melihat santri di luar kelompok.',
                    v_pembina.full_name;
            end if;

        end loop;


        raise notice
            'PEMBINA STUDENT LIST OK: % | students=%',
            v_pembina.full_name,
            v_returned_student_count;


        -- =================================================
        -- SEARCH TEST
        --
        -- Gunakan legacy_student_id apabila tersedia.
        -- Jika tidak, fallback ke NIS atau nama.
        -- =================================================

        select
            student.id,

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
            v_search_student_id,
            v_search_value

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
              is null

        order by
            student.full_name,
            student.id

        limit 1;


        if v_search_student_id is not null
           and v_search_value is not null
        then

            v_result :=
                public.get_pembina_tahfiz_student_list(
                    v_search_value
                );


            v_returned_filtered_count :=
                (
                    v_result
                    #>> '{summary,filtered_count}'
                )::integer;


            if v_returned_filtered_count < 1 then
                raise exception
                    'Search tidak menemukan santri untuk Pembina %.',
                    v_pembina.full_name;
            end if;


            select
                exists (
                    select 1

                    from jsonb_array_elements(
                        v_result -> 'items'
                    ) as search_item(item)

                    where (
                        search_item.item
                        ->> 'id'
                    )::uuid =
                    v_search_student_id
                )

            into
                v_search_found;


            if not v_search_found then
                raise exception
                    'Search tidak mengembalikan target santri untuk Pembina %.',
                    v_pembina.full_name;
            end if;


            raise notice
                'SEARCH SUCCESS: % | query=%',
                v_pembina.full_name,
                v_search_value;

        end if;

    end loop;


    -- =====================================================
    -- C. MUST TEST AT LEAST ONE PEMBINA
    -- =====================================================

    if v_tested_pembina_count = 0 then
        raise exception
            'Tidak ada Pembina Tahfiz aktif yang dapat diuji.';
    end if;


    raise notice
        'ALL PEMBINA STUDENT LIST ISOLATION SUCCESS: % accounts',
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
    -- F. ACCESS MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_pembina_tahfiz_student_list(
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
               '%Akses Santri Tahfiz Ampuan ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PEMBINA STUDENT LIST ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'PEMBINA TAHFIZ STUDENT LIST VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Daftar Santri Tahfiz Ampuan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;