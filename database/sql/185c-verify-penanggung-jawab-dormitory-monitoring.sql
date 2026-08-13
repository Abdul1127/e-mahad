-- ============================================================
-- E-MA'HAD
-- STAGE 185C
--
-- VERIFY PENANGGUNG JAWAB
-- MONITORING ASRAMA
-- ============================================================


create temporary table if not exists
emahad_stage_185c_result (
    step_order integer,
    test_name text,
    status text,
    detail text
);


truncate table
emahad_stage_185c_result;


do $verify$

declare

    v_pj_profile_id uuid;

    v_kepala_profile_id uuid;

    v_bendahara_profile_id uuid;


    v_payload jsonb;


    v_security_definer boolean;

    v_volatility "char";


    v_authenticated_execute boolean;

    v_anon_execute boolean;

begin

    -- ========================================================
    -- 1. FUNCTION SECURITY
    -- ========================================================

    select
        procedure.prosecdef,
        procedure.provolatile

    into
        v_security_definer,
        v_volatility

    from pg_proc
        as procedure

    inner join pg_namespace
        as namespace

        on namespace.oid =
           procedure.pronamespace

    where namespace.nspname =
          'public'

      and procedure.proname =
          'get_penanggung_jawab_dormitory_monitoring'

      and pg_get_function_identity_arguments(
          procedure.oid
      ) = ''

    limit 1;


    v_authenticated_execute :=
        has_function_privilege(
            'authenticated',
            'public.get_penanggung_jawab_dormitory_monitoring()',
            'EXECUTE'
        );


    v_anon_execute :=
        has_function_privilege(
            'anon',
            'public.get_penanggung_jawab_dormitory_monitoring()',
            'EXECUTE'
        );


    if
        v_security_definer =
            true

        and v_volatility =
            's'

        and v_authenticated_execute =
            true

        and v_anon_execute =
            false
    then

        insert into emahad_stage_185c_result
        values (
            1,
            'Function security',
            'PASS',
            'SECURITY DEFINER + STABLE + authenticated execute + anon denied.'
        );

    else

        insert into emahad_stage_185c_result
        values (
            1,
            'Function security',
            'FAIL',
            format(
                'security_definer=%s, volatility=%s, authenticated_execute=%s, anon_execute=%s',
                v_security_definer,
                v_volatility,
                v_authenticated_execute,
                v_anon_execute
            )
        );

    end if;


    -- ========================================================
    -- 2. GET PENANGGUNG JAWAB PROFILE
    -- ========================================================

    select
        user_role.user_id

    into
        v_pj_profile_id

    from public.user_roles
        as user_role

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    inner join public.profiles
        as profile

        on profile.id =
           user_role.user_id

    where role.code =
          'penanggung_jawab'

      and role.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_pj_profile_id is null then
        raise exception
            'Profile Penanggung Jawab aktif tidak ditemukan.';
    end if;


    -- ========================================================
    -- 3. PENANGGUNG JAWAB ACCESS
    -- ========================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_pj_profile_id::text,
        true
    );


    begin

        v_payload :=
            public.get_penanggung_jawab_dormitory_monitoring();


        if
            v_payload
                ->> 'access_mode' =
                'penanggung_jawab_read_only_monitoring'

            and v_payload
                -> 'academic_year'
                ->> 'name' =
                '2026/2027'

            and v_payload
                -> 'care'
                -> 'summary'
                is not null

            and v_payload
                -> 'mahad_head_journal'
                -> 'summary'
                is not null

            and v_payload
                -> 'tahfiz'
                -> 'summary'
                is not null

            and not (
                v_payload ?
                'finance'
            )

            and not (
                v_payload ?
                'keuangan'
            )
        then

            insert into emahad_stage_185c_result
            values (
                2,
                'Penanggung Jawab access',
                'PASS',
                concat(
                    'care=',
                    (
                        v_payload
                        -> 'care'
                        -> 'summary'
                    )::text,

                    ' head_journal=',
                    (
                        v_payload
                        -> 'mahad_head_journal'
                        -> 'summary'
                    )::text,

                    ' tahfiz=',
                    (
                        v_payload
                        -> 'tahfiz'
                        -> 'summary'
                    )::text
                )
            );

        else

            insert into emahad_stage_185c_result
            values (
                2,
                'Penanggung Jawab access',
                'FAIL',
                v_payload::text
            );

        end if;

    exception
        when others then

            insert into emahad_stage_185c_result
            values (
                2,
                'Penanggung Jawab access',
                'FAIL',
                concat(
                    SQLSTATE,
                    ' - ',
                    SQLERRM
                )
            );

    end;


    -- ========================================================
    -- 4. HEAD JOURNAL VISIBILITY
    --
    -- Response hanya boleh menghitung submitted journal.
    -- ========================================================

    if
        (
            v_payload
            -> 'mahad_head_journal'
            -> 'summary'
            ->> 'submitted_count'
        )::integer
        =
        (
            select
                count(*)::integer

            from public.mahad_head_journals
                as journal

            inner join public.academic_years
                as academic_year

                on academic_year.id =
                   journal.academic_year_id

            where academic_year.is_current =
                  true

              and journal.status =
                  'submitted'

              and journal.journal_date
                  between
                  date_trunc(
                      'week',
                      current_date
                  )::date
                  and
                  (
                      date_trunc(
                          'week',
                          current_date
                      )::date
                      + 6
                  )
        )
    then

        insert into emahad_stage_185c_result
        values (
            3,
            'Submitted Head Journal only',
            'PASS',
            'Ringkasan Jurnal Kepala Ma''had hanya menggunakan jurnal submitted.'
        );

    else

        insert into emahad_stage_185c_result
        values (
            3,
            'Submitted Head Journal only',
            'FAIL',
            'Jumlah jurnal submitted pada response berbeda dengan database.'
        );

    end if;


    -- ========================================================
    -- 5. PUBLISHED TAHFIZ ONLY
    -- ========================================================

    if
        (
            v_payload
            -> 'tahfiz'
            -> 'summary'
            ->> 'published_count'
        )::integer
        =
        (
            select
                count(
                    distinct report.student_id
                )::integer

            from public.tahfiz_weekly_reports
                as report

            inner join public.academic_years
                as academic_year

                on academic_year.id =
                   report.academic_year_id

            inner join public.students
                as student

                on student.id =
                   report.student_id

            where academic_year.is_current =
                  true

              and report.status =
                  'published'

              and report.published_at
                  is not null

              and report.week_start =
                  date_trunc(
                      'week',
                      current_date
                  )::date

              and student.status =
                  'active'

              and student.deleted_at
                  is null
        )
    then

        insert into emahad_stage_185c_result
        values (
            4,
            'Published Tahfiz only',
            'PASS',
            'Ringkasan Tahfiz hanya menghitung laporan published.'
        );

    else

        insert into emahad_stage_185c_result
        values (
            4,
            'Published Tahfiz only',
            'FAIL',
            'Jumlah laporan Tahfiz published pada response berbeda dengan database.'
        );

    end if;


    -- ========================================================
    -- 6. KEPALA MAHAD MUST BE DENIED
    -- ========================================================

    select
        user_role.user_id

    into
        v_kepala_profile_id

    from public.user_roles
        as user_role

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    inner join public.profiles
        as profile

        on profile.id =
           user_role.user_id

    where role.code =
          'kepala_mahad'

      and role.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    perform set_config(
        'request.jwt.claim.sub',
        v_kepala_profile_id::text,
        true
    );


    begin

        perform
            public.get_penanggung_jawab_dormitory_monitoring();


        insert into emahad_stage_185c_result
        values (
            5,
            'Kepala Mahad denied',
            'FAIL',
            'Kepala Ma''had berhasil mengakses RPC khusus Penanggung Jawab.'
        );

    exception
        when others then

            if SQLSTATE =
               '42501'
            then

                insert into emahad_stage_185c_result
                values (
                    5,
                    'Kepala Mahad denied',
                    'PASS',
                    SQLERRM
                );

            else

                insert into emahad_stage_185c_result
                values (
                    5,
                    'Kepala Mahad denied',
                    'FAIL',
                    concat(
                        SQLSTATE,
                        ' - ',
                        SQLERRM
                    )
                );

            end if;

    end;


    -- ========================================================
    -- 7. BENDAHARA MUST BE DENIED
    -- ========================================================

    select
        user_role.user_id

    into
        v_bendahara_profile_id

    from public.user_roles
        as user_role

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    inner join public.profiles
        as profile

        on profile.id =
           user_role.user_id

    where role.code =
          'bendahara'

      and role.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    perform set_config(
        'request.jwt.claim.sub',
        v_bendahara_profile_id::text,
        true
    );


    begin

        perform
            public.get_penanggung_jawab_dormitory_monitoring();


        insert into emahad_stage_185c_result
        values (
            6,
            'Bendahara denied',
            'FAIL',
            'Bendahara berhasil mengakses RPC khusus Penanggung Jawab.'
        );

    exception
        when others then

            if SQLSTATE =
               '42501'
            then

                insert into emahad_stage_185c_result
                values (
                    6,
                    'Bendahara denied',
                    'PASS',
                    SQLERRM
                );

            else

                insert into emahad_stage_185c_result
                values (
                    6,
                    'Bendahara denied',
                    'FAIL',
                    concat(
                        SQLSTATE,
                        ' - ',
                        SQLERRM
                    )
                );

            end if;

    end;

end;

$verify$;


select
    test_name,
    status,
    detail

from emahad_stage_185c_result

order by
    step_order;