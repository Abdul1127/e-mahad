-- ============================================================
-- E-MA'HAD
-- STAGE 185A
--
-- AUDIT PENANGGUNG JAWAB
-- DORMITORY MONITORING FOUNDATION
--
-- READ ONLY
-- TIDAK MENGUBAH DATA
-- ============================================================

with audit as (

    -- ========================================================
    -- 01. RELEVANT TABLES
    --
    -- Mencari tabel yang berkaitan dengan:
    -- - Pengasuhan
    -- - Jurnal Kepala Ma'had
    -- - Tahfiz
    -- ========================================================

    select
        1 as section_order,

        '01_relevant_tables'::text
            as section,

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'table_name',
                    table_data.table_name
                )
                order by
                    table_data.table_name
            ),
            '[]'::jsonb
        )
            as data

    from (
        select
            table_name

        from information_schema.tables

        where table_schema =
              'public'

          and table_type =
              'BASE TABLE'

          and (
              table_name ilike
                  '%journal%'

              or table_name ilike
                  '%pengasuh%'

              or table_name ilike
                  '%care%'

              or table_name ilike
                  '%mahad%'

              or table_name ilike
                  '%tahfiz%'
          )
    ) as table_data


    union all


    -- ========================================================
    -- 02. RELEVANT TABLE COLUMNS
    -- ========================================================

    select
        2,

        '02_relevant_table_columns',

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'table_name',
                    c.table_name,

                    'column_name',
                    c.column_name,

                    'data_type',
                    c.data_type,

                    'udt_name',
                    c.udt_name,

                    'is_nullable',
                    c.is_nullable,

                    'column_default',
                    c.column_default
                )
                order by
                    c.table_name,
                    c.ordinal_position
            ),
            '[]'::jsonb
        )

    from information_schema.columns
        as c

    where c.table_schema =
          'public'

      and (
          c.table_name ilike
              '%journal%'

          or c.table_name ilike
              '%pengasuh%'

          or c.table_name ilike
              '%care%'

          or c.table_name ilike
              '%mahad%'

          or c.table_name ilike
              '%tahfiz%'
      )


    union all


    -- ========================================================
    -- 03. RELEVANT FUNCTIONS
    --
    -- Kita fokus pada RPC yang sudah ada agar Stage 185
    -- sebisa mungkin memakai fondasi existing.
    -- ========================================================

    select
        3,

        '03_relevant_functions',

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'function_name',
                    function_data.function_name,

                    'arguments',
                    function_data.arguments,

                    'result_type',
                    function_data.result_type,

                    'security_definer',
                    function_data.security_definer,

                    'volatility',
                    function_data.volatility,

                    'acl',
                    function_data.acl,

                    'definition',
                    function_data.definition
                )
                order by
                    function_data.function_name,
                    function_data.arguments
            ),
            '[]'::jsonb
        )

    from (
        select
            procedure.proname
                as function_name,

            pg_get_function_identity_arguments(
                procedure.oid
            )
                as arguments,

            pg_get_function_result(
                procedure.oid
            )
                as result_type,

            procedure.prosecdef
                as security_definer,

            case procedure.provolatile
                when 'i'
                    then 'IMMUTABLE'

                when 's'
                    then 'STABLE'

                when 'v'
                    then 'VOLATILE'

                else
                    procedure.provolatile::text
            end
                as volatility,

            coalesce(
                procedure.proacl::text,
                'DEFAULT'
            )
                as acl,

            pg_get_functiondef(
                procedure.oid
            )
                as definition

        from pg_proc
            as procedure

        inner join pg_namespace
            as namespace

            on namespace.oid =
               procedure.pronamespace

        where namespace.nspname =
              'public'

          and (
              procedure.proname ilike
                  '%pengasuh%'

              or procedure.proname ilike
                  '%care%'

              or procedure.proname ilike
                  '%mahad%journal%'

              or procedure.proname ilike
                  '%head%journal%'

              or procedure.proname ilike
                  '%tahfiz%'

              or procedure.proname ilike
                  '%leadership%'
          )
    ) as function_data


    union all


    -- ========================================================
    -- 04. JOURNAL / TAHFIZ STATUS CONSTRAINTS
    --
    -- Berguna untuk mengetahui nilai status yang benar-benar
    -- diperbolehkan tanpa menebak.
    -- ========================================================

    select
        4,

        '04_status_constraints',

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'table_name',
                    constraint_data.table_name,

                    'constraint_name',
                    constraint_data.constraint_name,

                    'definition',
                    constraint_data.definition
                )
                order by
                    constraint_data.table_name,
                    constraint_data.constraint_name
            ),
            '[]'::jsonb
        )

    from (
        select
            class.relname
                as table_name,

            constraint_item.conname
                as constraint_name,

            pg_get_constraintdef(
                constraint_item.oid,
                true
            )
                as definition

        from pg_constraint
            as constraint_item

        inner join pg_class
            as class

            on class.oid =
               constraint_item.conrelid

        inner join pg_namespace
            as namespace

            on namespace.oid =
               class.relnamespace

        where namespace.nspname =
              'public'

          and constraint_item.contype =
              'c'

          and (
              class.relname ilike
                  '%journal%'

              or class.relname ilike
                  '%pengasuh%'

              or class.relname ilike
                  '%care%'

              or class.relname ilike
                  '%mahad%'

              or class.relname ilike
                  '%tahfiz%'
          )
    ) as constraint_data


    union all


    -- ========================================================
    -- 05. ROW COUNTS
    --
    -- Dynamic query tidak digunakan supaya audit tetap aman
    -- dan sederhana.
    --
    -- Tabel yang sudah diketahui pasti dari implementasi
    -- sebelumnya ditampilkan di sini.
    -- ========================================================

    select
        5,

        '05_known_table_counts',

        jsonb_build_object(

            'mahad_head_journals',
            (
                select count(*)
                from public.mahad_head_journals
            ),

            'mahad_head_journal_checks',
            (
                select count(*)
                from public.mahad_head_journal_checks
            ),

            'mahad_head_journal_checklist_items',
            (
                select count(*)
                from public.mahad_head_journal_checklist_items
            ),

            'tahfiz_weekly_reports',
            (
                select count(*)
                from public.tahfiz_weekly_reports
            )
        )


    union all


    -- ========================================================
    -- 06. HEAD JOURNAL SNAPSHOT
    -- ========================================================

    select
        6,

        '06_mahad_head_journal_snapshot',

        coalesce(
            (
                select
                    jsonb_agg(
                        to_jsonb(sample)
                    )

                from (
                    select *

                    from public.mahad_head_journals

                    order by
                        created_at desc

                    limit 5
                ) as sample
            ),
            '[]'::jsonb
        )


    union all


    -- ========================================================
    -- 07. TAHFIZ SNAPSHOT
    -- ========================================================

    select
        7,

        '07_tahfiz_snapshot',

        coalesce(
            (
                select
                    jsonb_agg(
                        to_jsonb(sample)
                    )

                from (
                    select *

                    from public.tahfiz_weekly_reports

                    order by
                        created_at desc

                    limit 5
                ) as sample
            ),
            '[]'::jsonb
        )


    union all


    -- ========================================================
    -- 08. CURRENT ACADEMIC YEAR
    -- ========================================================

    select
        8,

        '08_current_academic_year',

        coalesce(
            (
                select
                    jsonb_agg(
                        to_jsonb(academic_year)
                    )

                from public.academic_years
                    as academic_year

                where academic_year.is_current =
                      true
            ),
            '[]'::jsonb
        )


    union all


    -- ========================================================
    -- 09. PENANGGUNG JAWAB BASELINE
    -- ========================================================

    select
        9,

        '09_penanggung_jawab',

        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'profile_id',
                    profile.id,

                    'login_id',
                    profile.login_id,

                    'full_name',
                    profile.full_name,

                    'profile_active',
                    profile.is_active,

                    'role_id',
                    role.id,

                    'role_code',
                    role.code,

                    'role_name',
                    role.name
                )
            ),
            '[]'::jsonb
        )

    from public.profiles
        as profile

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    where role.code =
          'penanggung_jawab'
)

select
    section,
    data

from audit

order by
    section_order;