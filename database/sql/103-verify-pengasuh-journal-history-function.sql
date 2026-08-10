-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 103-verify-pengasuh-journal-history-function.sql
--
-- PURPOSE:
-- - Verify RPC Riwayat Pengasuhan
-- - Verify assignment isolation
-- - Verify filters
-- - Verify pagination
-- - Verify non-Pengasuh cannot access
--
-- NO PERMANENT DATA CHANGES
-- =========================================================


-- =========================================================
-- 1. FUNCTION + PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.get_pengasuh_journal_history(text,text,date,integer,integer)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_pengasuh_journal_history(text,text,date,integer,integer)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_pengasuh_journal_history(text,text,date,integer,integer)',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_pengasuh_profile_id uuid;

    v_pengasuh_email text;

    v_pengasuh_staff_id uuid;

    v_pengasuh_name text;

    v_current_year_id uuid;

    v_start_date date;

    v_end_date date;

    v_result jsonb;

    v_item jsonb;

    v_item_group_id uuid;

    v_item_status text;

    v_item_session text;

    v_non_pengasuh_profile_id uuid;

    v_non_pengasuh_email text;

    v_returned_count integer;

    v_filtered_count integer;
begin

    -- =====================================================
    -- A. CURRENT ACADEMIC YEAR
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
    -- B. PICK OPERATIONAL PENGASUH
    -- =====================================================

    select
        profile.id,
        auth_user.email,
        staff.id,
        staff.full_name

    into
        v_pengasuh_profile_id,
        v_pengasuh_email,
        v_pengasuh_staff_id,
        v_pengasuh_name

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

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true

      and exists (
          select 1

          from public.caregiver_assignments
              as assignment

          inner join public.care_groups
              as care_group
              on care_group.id =
                 assignment.care_group_id

          where assignment.staff_id =
                staff.id

            and assignment.is_active =
                true

            and care_group.is_active =
                true

            and care_group.academic_year_id =
                v_current_year_id
      )

    order by
        staff.full_name

    limit 1;


    if v_pengasuh_profile_id is null then
        raise exception
            'Pengasuh operational tidak ditemukan.';
    end if;


    raise notice
        'TEST PENGASUH: %',
        v_pengasuh_name;


    -- =====================================================
    -- C. LOGIN AS PENGASUH
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_pengasuh_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_pengasuh_profile_id,

            'role',
            'authenticated',

            'email',
            v_pengasuh_email
        )::text,
        true
    );


    -- =====================================================
    -- D. GET ALL HISTORY
    -- =====================================================

    v_result :=
        public.get_pengasuh_journal_history(
            null,
            null,
            null,
            50,
            0
        );


    if (
        v_result
        #>> '{academic_year,id}'
    )::uuid <>
       v_current_year_id
    then
        raise exception
            'RPC tidak menggunakan tahun ajaran aktif.';
    end if;


    raise notice
        'CURRENT ACADEMIC YEAR SUCCESS';


    -- =====================================================
    -- E. ASSIGNMENT ISOLATION
    -- =====================================================

    for v_item in

        select
            value

        from jsonb_array_elements(
            v_result -> 'items'
        )

    loop

        v_item_group_id :=
            (
                v_item
                #>> '{care_group,id}'
            )::uuid;


        if not exists (
            select 1

            from public.caregiver_assignments
                as assignment

            inner join public.care_groups
                as care_group
                on care_group.id =
                   assignment.care_group_id

            where assignment.staff_id =
                  v_pengasuh_staff_id

              and assignment.care_group_id =
                  v_item_group_id

              and assignment.is_active =
                  true

              and care_group.is_active =
                  true

              and care_group.academic_year_id =
                  v_current_year_id
        ) then
            raise exception
                'Pengasuh dapat melihat jurnal kelompok di luar assignment.';
        end if;

    end loop;


    raise notice
        'ASSIGNMENT ISOLATION SUCCESS';


    -- =====================================================
    -- F. PAGINATION LIMIT
    -- =====================================================

    v_result :=
        public.get_pengasuh_journal_history(
            null,
            null,
            null,
            1,
            0
        );


    v_returned_count :=
        (
            v_result
            #>> '{pagination,returned_count}'
        )::integer;


    if v_returned_count > 1 then
        raise exception
            'Pagination limit tidak bekerja.';
    end if;


    raise notice
        'PAGINATION LIMIT SUCCESS';


    -- =====================================================
    -- G. STATUS FILTER
    -- =====================================================

    v_result :=
        public.get_pengasuh_journal_history(
            'reviewed',
            null,
            null,
            100,
            0
        );


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_result -> 'items'
        )

    loop

        v_item_status :=
            v_item
            ->> 'status';


        if v_item_status <>
           'reviewed'
        then
            raise exception
                'Filter status reviewed gagal.';
        end if;

    end loop;


    raise notice
        'STATUS FILTER SUCCESS';


    -- =====================================================
    -- H. SESSION FILTER
    -- =====================================================

    v_result :=
        public.get_pengasuh_journal_history(
            null,
            'morning',
            null,
            100,
            0
        );


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_result -> 'items'
        )

    loop

        v_item_session :=
            v_item
            ->> 'session';


        if v_item_session <>
           'morning'
        then
            raise exception
                'Filter sesi morning gagal.';
        end if;

    end loop;


    raise notice
        'SESSION FILTER SUCCESS';


    -- =====================================================
    -- I. INVALID STATUS MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_pengasuh_journal_history(
                'invalid_status',
                null,
                null,
                50,
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
               '%Filter status jurnal tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID STATUS PROTECTION SUCCESS';


    -- =====================================================
    -- J. INVALID SESSION MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_pengasuh_journal_history(
                null,
                'night',
                null,
                50,
                0
            );


        raise exception
            'EXPECTED_INVALID_SESSION_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INVALID_SESSION_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Filter sesi jurnal tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID SESSION PROTECTION SUCCESS';


    -- =====================================================
    -- K. OUTSIDE ACADEMIC YEAR DATE MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_pengasuh_journal_history(
                null,
                null,
                v_start_date - 1,
                50,
                0
            );


        raise exception
            'EXPECTED_OUTSIDE_DATE_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_OUTSIDE_DATE_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Tanggal berada di luar tahun ajaran aktif%'
            then
                raise;
            end if;

    end;


    raise notice
        'ACADEMIC YEAR DATE PROTECTION SUCCESS';


    -- =====================================================
    -- L. INVALID PAGINATION MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_pengasuh_journal_history(
                null,
                null,
                null,
                101,
                0
            );


        raise exception
            'EXPECTED_LIMIT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_LIMIT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Limit harus berada antara 1 sampai 100%'
            then
                raise;
            end if;

    end;


    raise notice
        'PAGINATION VALIDATION SUCCESS';


    -- =====================================================
    -- M. FILTERED COUNT CONSISTENCY
    -- =====================================================

    v_result :=
        public.get_pengasuh_journal_history(
            null,
            null,
            null,
            100,
            0
        );


    v_filtered_count :=
        (
            v_result
            #>> '{pagination,filtered_count}'
        )::integer;


    v_returned_count :=
        (
            v_result
            #>> '{pagination,returned_count}'
        )::integer;


    if v_filtered_count <= 100
       and v_filtered_count <>
           v_returned_count
    then
        raise exception
            'Filtered count dan returned count tidak konsisten.';
    end if;


    raise notice
        'PAGINATION COUNT CONSISTENCY SUCCESS';


    -- =====================================================
    -- N. FIND NON-PENGASUH
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


    if v_non_pengasuh_profile_id is null then
        raise exception
            'Akun non-Pengasuh untuk security test tidak ditemukan.';
    end if;


    -- =====================================================
    -- O. LOGIN AS NON-PENGASUH
    -- =====================================================

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


    -- =====================================================
    -- P. ACCESS MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_pengasuh_journal_history(
                null,
                null,
                null,
                50,
                0
            );


        raise exception
            'EXPECTED_NON_PENGASUH_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_PENGASUH_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses Riwayat Pengasuhan ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PENGASUH ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'PENGASUH JOURNAL HISTORY VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Riwayat Jurnal Pengasuhan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;