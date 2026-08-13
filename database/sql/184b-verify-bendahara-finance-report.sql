-- ============================================================
-- E-MA'HAD
-- STAGE 184B
-- VERIFY BENDAHARA FINANCE REPORT
-- ============================================================

create temporary table if not exists
emahad_stage_184b_result (
    step_order integer,
    test_name text,
    status text,
    detail text
);


truncate table
emahad_stage_184b_result;


do $verify$

declare
    v_bendahara_profile_id uuid;
    v_head_profile_id uuid;

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
          'get_bendahara_finance_report'

      and pg_get_function_identity_arguments(
          procedure.oid
      ) = 'p_start_date date, p_end_date date'

    limit 1;


    v_authenticated_execute :=
        has_function_privilege(
            'authenticated',
            'public.get_bendahara_finance_report(date,date)',
            'EXECUTE'
        );


    v_anon_execute :=
        has_function_privilege(
            'anon',
            'public.get_bendahara_finance_report(date,date)',
            'EXECUTE'
        );


    if
        v_security_definer = true

        and v_volatility = 's'

        and v_authenticated_execute = true

        and v_anon_execute = false
    then
        insert into emahad_stage_184b_result
        values (
            1,
            'Function security',
            'PASS',
            'SECURITY DEFINER + STABLE + authenticated execute + anon denied.'
        );
    else
        insert into emahad_stage_184b_result
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
    -- 2. BENDAHARA ACCESS
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

        v_payload :=
            public.get_bendahara_finance_report(
                '2026-08-01'::date,
                '2026-08-31'::date
            );


        if
            v_payload
                ->> 'access_mode' =
                'bendahara_read_only_report'

            and v_payload
                -> 'period'
                ->> 'start_date' =
                '2026-08-01'

            and v_payload
                -> 'bill_summary'
                is not null

            and v_payload
                -> 'payment_summary'
                is not null
        then
            insert into emahad_stage_184b_result
            values (
                2,
                'Bendahara access',
                'PASS',
                concat(
                    'bill_summary=',
                    (
                        v_payload
                        -> 'bill_summary'
                    )::text,
                    ' payment_summary=',
                    (
                        v_payload
                        -> 'payment_summary'
                    )::text
                )
            );
        else
            insert into emahad_stage_184b_result
            values (
                2,
                'Bendahara access',
                'FAIL',
                v_payload::text
            );
        end if;

    exception
        when others then
            insert into emahad_stage_184b_result
            values (
                2,
                'Bendahara access',
                'FAIL',
                concat(
                    SQLSTATE,
                    ' - ',
                    SQLERRM
                )
            );
    end;


    -- ========================================================
    -- 3. KEPALA MA'HAD MUST BE DENIED
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


    perform set_config(
        'request.jwt.claim.sub',
        v_head_profile_id::text,
        true
    );


    begin

        perform
            public.get_bendahara_finance_report(
                '2026-08-01'::date,
                '2026-08-31'::date
            );


        insert into emahad_stage_184b_result
        values (
            3,
            'Kepala Mahad denied',
            'FAIL',
            'Kepala Mahad berhasil menjalankan RPC Bendahara.'
        );

    exception
        when others then

            if SQLSTATE =
               '42501'
            then
                insert into emahad_stage_184b_result
                values (
                    3,
                    'Kepala Mahad denied',
                    'PASS',
                    SQLERRM
                );
            else
                insert into emahad_stage_184b_result
                values (
                    3,
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
    -- 4. INVALID PERIOD
    -- ========================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_bendahara_profile_id::text,
        true
    );


    begin

        perform
            public.get_bendahara_finance_report(
                '2026-08-31'::date,
                '2026-08-01'::date
            );


        insert into emahad_stage_184b_result
        values (
            4,
            'Invalid period rejected',
            'FAIL',
            'Periode terbalik tidak ditolak.'
        );

    exception
        when others then
            insert into emahad_stage_184b_result
            values (
                4,
                'Invalid period rejected',
                'PASS',
                SQLERRM
            );
    end;

end;

$verify$;


select
    test_name,
    status,
    detail

from emahad_stage_184b_result

order by
    step_order;