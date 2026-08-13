-- ============================================================
-- E-MA'HAD
-- STAGE 183C
--
-- VERIFY KEPALA MA'HAD FINANCE SUMMARY
--
-- Tidak mengubah data aplikasi.
-- Temporary table hanya hidup pada session SQL ini.
-- ============================================================


create temporary table if not exists
emahad_stage_183c_result (

    step_order integer,

    test_name text,

    status text,

    detail text
);


truncate table
emahad_stage_183c_result;


do $verify$

declare

    v_head_profile_id uuid;

    v_pj_profile_id uuid;

    v_bendahara_profile_id uuid;


    v_payload jsonb;


    v_security_definer boolean;

    v_volatility "char";

    v_authenticated_execute boolean;

    v_anon_execute boolean;

begin

    -- ========================================================
    -- 1. FUNCTION METADATA
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
          'get_kepala_mahad_finance_summary'

      and pg_get_function_identity_arguments(
          procedure.oid
      ) = ''

    limit 1;


    v_authenticated_execute :=
        has_function_privilege(
            'authenticated',
            'public.get_kepala_mahad_finance_summary()',
            'EXECUTE'
        );


    v_anon_execute :=
        has_function_privilege(
            'anon',
            'public.get_kepala_mahad_finance_summary()',
            'EXECUTE'
        );


    if
        v_security_definer = true

        and v_volatility = 's'

        and v_authenticated_execute = true

        and v_anon_execute = false
    then

        insert into emahad_stage_183c_result
        values (
            1,
            'Function security',
            'PASS',
            'SECURITY DEFINER + STABLE + authenticated execute + anon denied.'
        );

    else

        insert into emahad_stage_183c_result
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
    -- 2. FIND ACTIVE KEPALA MA'HAD
    -- ========================================================

    select
        user_role.user_id

    into
        v_head_profile_id

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


    if v_head_profile_id is null then

        insert into emahad_stage_183c_result
        values (
            2,
            'Kepala Mahad access',
            'FAIL',
            'Profile Kepala Mahad aktif tidak ditemukan.'
        );

    else

        perform set_config(
            'request.jwt.claim.sub',
            v_head_profile_id::text,
            true
        );


        begin

            v_payload :=
                public.get_kepala_mahad_finance_summary();


            if
                v_payload ->> 'access_mode' =
                    'read_only'

                and v_payload
                    -> 'viewer'
                    ->> 'role' =
                    'kepala_mahad'

                and v_payload
                    -> 'academic_year'
                    ->> 'id'
                    is not null

                and v_payload
                    -> 'summary'
                    is not null
            then

                insert into emahad_stage_183c_result
                values (
                    2,
                    'Kepala Mahad access',
                    'PASS',
                    concat(
                        'RPC berhasil. Summary = ',
                        (
                            v_payload
                            -> 'summary'
                        )::text
                    )
                );

            else

                insert into emahad_stage_183c_result
                values (
                    2,
                    'Kepala Mahad access',
                    'FAIL',
                    concat(
                        'Payload tidak sesuai kontrak. Payload = ',
                        v_payload::text
                    )
                );

            end if;


        exception

            when others then

                insert into emahad_stage_183c_result
                values (
                    2,
                    'Kepala Mahad access',
                    'FAIL',
                    concat(
                        SQLSTATE,
                        ' - ',
                        SQLERRM
                    )
                );

        end;

    end if;


    -- ========================================================
    -- 3. PENANGGUNG JAWAB MUST BE DENIED
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

        insert into emahad_stage_183c_result
        values (
            3,
            'Penanggung Jawab denied',
            'FAIL',
            'Profile Penanggung Jawab aktif tidak ditemukan.'
        );

    else

        perform set_config(
            'request.jwt.claim.sub',
            v_pj_profile_id::text,
            true
        );


        begin

            perform
                public.get_kepala_mahad_finance_summary();


            insert into emahad_stage_183c_result
            values (
                3,
                'Penanggung Jawab denied',
                'FAIL',
                'Penanggung Jawab berhasil menjalankan RPC, padahal seharusnya ditolak.'
            );


        exception

            when others then

                if SQLSTATE = '42501' then

                    insert into emahad_stage_183c_result
                    values (
                        3,
                        'Penanggung Jawab denied',
                        'PASS',
                        SQLERRM
                    );

                else

                    insert into emahad_stage_183c_result
                    values (
                        3,
                        'Penanggung Jawab denied',
                        'FAIL',
                        concat(
                            SQLSTATE,
                            ' - ',
                            SQLERRM
                        )
                    );

                end if;

        end;

    end if;


    -- ========================================================
    -- 4. BENDAHARA MUST ALSO BE DENIED
    --
    -- Bendahara memiliki RPC sendiri.
    -- RPC ini khusus monitoring Kepala Ma'had.
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


    if v_bendahara_profile_id is null then

        insert into emahad_stage_183c_result
        values (
            4,
            'Bendahara denied',
            'FAIL',
            'Profile Bendahara aktif tidak ditemukan.'
        );

    else

        perform set_config(
            'request.jwt.claim.sub',
            v_bendahara_profile_id::text,
            true
        );


        begin

            perform
                public.get_kepala_mahad_finance_summary();


            insert into emahad_stage_183c_result
            values (
                4,
                'Bendahara denied',
                'FAIL',
                'Bendahara berhasil menjalankan RPC khusus Kepala Mahad.'
            );


        exception

            when others then

                if SQLSTATE = '42501' then

                    insert into emahad_stage_183c_result
                    values (
                        4,
                        'Bendahara denied',
                        'PASS',
                        SQLERRM
                    );

                else

                    insert into emahad_stage_183c_result
                    values (
                        4,
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

    end if;

end;

$verify$;


-- ============================================================
-- RESULT
-- ============================================================

select
    test_name,
    status,
    detail

from emahad_stage_183c_result

order by
    step_order;