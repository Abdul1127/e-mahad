-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 074-inspect-student-placement-history-safety.sql
--
-- PURPOSE:
-- - Audit class_enrollments
-- - Audit care_group_members
-- - Audit tahfiz_group_members
-- - Memeriksa unique constraint/index
-- - Memeriksa riwayat placement
-- - Menentukan perubahan aman sebelum hardening
--
-- READ ONLY
-- TIDAK MENGUBAH DATA
-- =========================================================


-- =========================================================
-- 1. TARGET TABLES
-- =========================================================

with target_tables as (
    select unnest(
        array[
            'class_enrollments',
            'care_group_members',
            'tahfiz_group_members'
        ]::text[]
    ) as table_name
),


-- =========================================================
-- 2. TABLE COLUMNS
-- =========================================================

table_columns as (
    select
        column_data.table_name,
        column_data.ordinal_position,
        column_data.column_name,
        column_data.data_type,
        column_data.udt_name,
        column_data.is_nullable,
        column_data.column_default

    from information_schema.columns
        as column_data

    where column_data.table_schema = 'public'

      and column_data.table_name in (
          select table_name
          from target_tables
      )
),


-- =========================================================
-- 3. INDEXES
-- =========================================================

table_indexes as (
    select
        index_data.tablename
            as table_name,

        index_data.indexname
            as index_name,

        index_data.indexdef
            as definition

    from pg_indexes
        as index_data

    where index_data.schemaname = 'public'

      and index_data.tablename in (
          select table_name
          from target_tables
      )
),


-- =========================================================
-- 4. CONSTRAINTS
-- =========================================================

table_constraints as (
    select
        constraint_data.table_name,

        constraint_data.constraint_name,

        constraint_data.constraint_type,

        coalesce(
            jsonb_agg(
                key_data.column_name
                order by
                    key_data.ordinal_position
            ) filter (
                where key_data.column_name
                      is not null
            ),
            '[]'::jsonb
        ) as columns

    from information_schema.table_constraints
        as constraint_data

    left join information_schema.key_column_usage
        as key_data
        on key_data.constraint_schema =
           constraint_data.constraint_schema

       and key_data.constraint_name =
           constraint_data.constraint_name

       and key_data.table_name =
           constraint_data.table_name

    where constraint_data.table_schema =
          'public'

      and constraint_data.table_name in (
          select table_name
          from target_tables
      )

    group by
        constraint_data.table_name,
        constraint_data.constraint_name,
        constraint_data.constraint_type
),


-- =========================================================
-- 5. CLASS SUMMARY
-- =========================================================

class_summary as (
    select
        count(*)::integer
            as total_rows,

        count(*) filter (
            where enrollment.is_active = true
        )::integer
            as active_rows,

        count(*) filter (
            where enrollment.is_active = false
        )::integer
            as historical_rows,

        count(
            distinct enrollment.student_id
        ) filter (
            where enrollment.is_active = true
        )::integer
            as active_students

    from public.class_enrollments
        as enrollment
),


-- =========================================================
-- 6. CARE SUMMARY
-- =========================================================

care_summary as (
    select
        count(*)::integer
            as total_rows,

        count(*) filter (
            where membership.is_active = true
        )::integer
            as active_rows,

        count(*) filter (
            where membership.is_active = false
        )::integer
            as historical_rows,

        count(
            distinct membership.student_id
        ) filter (
            where membership.is_active = true
        )::integer
            as active_students

    from public.care_group_members
        as membership
),


-- =========================================================
-- 7. TAHFIZ SUMMARY
-- =========================================================

tahfiz_summary as (
    select
        count(*)::integer
            as total_rows,

        count(*) filter (
            where membership.is_active = true
        )::integer
            as active_rows,

        count(*) filter (
            where membership.is_active = false
        )::integer
            as historical_rows,

        count(
            distinct membership.student_id
        ) filter (
            where membership.is_active = true
        )::integer
            as active_students

    from public.tahfiz_group_members
        as membership
),


-- =========================================================
-- 8. REPEAT SAME CLASS
-- =========================================================

class_repeat_pairs as (
    select
        enrollment.student_id,

        enrollment.class_id,

        count(*)::integer
            as period_count

    from public.class_enrollments
        as enrollment

    group by
        enrollment.student_id,
        enrollment.class_id

    having count(*) > 1
),


-- =========================================================
-- 9. REPEAT SAME CARE GROUP
-- =========================================================

care_repeat_pairs as (
    select
        membership.student_id,

        membership.care_group_id,

        count(*)::integer
            as period_count

    from public.care_group_members
        as membership

    group by
        membership.student_id,
        membership.care_group_id

    having count(*) > 1
),


-- =========================================================
-- 10. REPEAT SAME TAHFIZ GROUP
-- =========================================================

tahfiz_repeat_pairs as (
    select
        membership.student_id,

        membership.tahfiz_group_id,

        count(*)::integer
            as period_count

    from public.tahfiz_group_members
        as membership

    group by
        membership.student_id,
        membership.tahfiz_group_id

    having count(*) > 1
),


-- =========================================================
-- 11. STUDENTS WITH CLASS HISTORY
-- =========================================================

students_with_class_history as (
    select
        enrollment.student_id,

        count(*)::integer
            as history_count

    from public.class_enrollments
        as enrollment

    group by
        enrollment.student_id

    having count(*) > 1
),


-- =========================================================
-- 12. STUDENTS WITH CARE HISTORY
-- =========================================================

students_with_care_history as (
    select
        membership.student_id,

        count(*)::integer
            as history_count

    from public.care_group_members
        as membership

    group by
        membership.student_id

    having count(*) > 1
),


-- =========================================================
-- 13. STUDENTS WITH TAHFIZ HISTORY
-- =========================================================

students_with_tahfiz_history as (
    select
        membership.student_id,

        count(*)::integer
            as history_count

    from public.tahfiz_group_members
        as membership

    group by
        membership.student_id

    having count(*) > 1
),


-- =========================================================
-- 14. MULTIPLE ACTIVE CLASS
-- =========================================================

invalid_active_class as (
    select
        enrollment.student_id,

        count(*)::integer
            as active_count

    from public.class_enrollments
        as enrollment

    where enrollment.is_active = true

    group by
        enrollment.student_id

    having count(*) > 1
),


-- =========================================================
-- 15. MULTIPLE ACTIVE CARE GROUP
-- =========================================================

invalid_active_care as (
    select
        membership.student_id,

        count(*)::integer
            as active_count

    from public.care_group_members
        as membership

    where membership.is_active = true

    group by
        membership.student_id

    having count(*) > 1
),


-- =========================================================
-- 16. MULTIPLE ACTIVE TAHFIZ GROUP
-- =========================================================

invalid_active_tahfiz as (
    select
        membership.student_id,

        count(*)::integer
            as active_count

    from public.tahfiz_group_members
        as membership

    where membership.is_active = true

    group by
        membership.student_id

    having count(*) > 1
),


-- =========================================================
-- 17. INVALID DATE RANGE
-- =========================================================

invalid_date_ranges as (
    select
        jsonb_build_object(
            'type',
            'class',

            'id',
            enrollment.id,

            'student_id',
            enrollment.student_id,

            'started_at',
            enrollment.enrolled_at,

            'ended_at',
            enrollment.left_at
        ) as item

    from public.class_enrollments
        as enrollment

    where enrollment.left_at is not null

      and enrollment.left_at <
          enrollment.enrolled_at


    union all


    select
        jsonb_build_object(
            'type',
            'care',

            'id',
            membership.id,

            'student_id',
            membership.student_id,

            'started_at',
            membership.joined_at,

            'ended_at',
            membership.left_at
        ) as item

    from public.care_group_members
        as membership

    where membership.left_at is not null

      and membership.left_at <
          membership.joined_at


    union all


    select
        jsonb_build_object(
            'type',
            'tahfiz',

            'id',
            membership.id,

            'student_id',
            membership.student_id,

            'started_at',
            membership.joined_at,

            'ended_at',
            membership.left_at
        ) as item

    from public.tahfiz_group_members
        as membership

    where membership.left_at is not null

      and membership.left_at <
          membership.joined_at
)


-- =========================================================
-- 18. FINAL RESULT
-- =========================================================

select jsonb_pretty(
    jsonb_build_object(
        'inspection_status',
        'Riwayat placement santri berhasil diperiksa',

        'inspected_at',
        now(),


        -- =================================================
        -- COLUMNS
        -- =================================================

        'columns',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        column_data.table_name,

                        'column_name',
                        column_data.column_name,

                        'data_type',
                        column_data.data_type,

                        'udt_name',
                        column_data.udt_name,

                        'is_nullable',
                        column_data.is_nullable,

                        'column_default',
                        column_data.column_default
                    )

                    order by
                        column_data.table_name,
                        column_data.ordinal_position
                ),
                '[]'::jsonb
            )

            from table_columns
                as column_data
        ),


        -- =================================================
        -- INDEXES
        -- =================================================

        'indexes',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        index_data.table_name,

                        'index_name',
                        index_data.index_name,

                        'definition',
                        index_data.definition
                    )

                    order by
                        index_data.table_name,
                        index_data.index_name
                ),
                '[]'::jsonb
            )

            from table_indexes
                as index_data
        ),


        -- =================================================
        -- CONSTRAINTS
        -- =================================================

        'constraints',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'table_name',
                        constraint_data.table_name,

                        'constraint_name',
                        constraint_data.constraint_name,

                        'constraint_type',
                        constraint_data.constraint_type,

                        'columns',
                        constraint_data.columns
                    )

                    order by
                        constraint_data.table_name,
                        constraint_data.constraint_name
                ),
                '[]'::jsonb
            )

            from table_constraints
                as constraint_data
        ),


        -- =================================================
        -- SUMMARY
        -- =================================================

        'summary',
        jsonb_build_object(
            'class',
            (
                select to_jsonb(
                    summary_data
                )

                from class_summary
                    as summary_data
            ),

            'care',
            (
                select to_jsonb(
                    summary_data
                )

                from care_summary
                    as summary_data
            ),

            'tahfiz',
            (
                select to_jsonb(
                    summary_data
                )

                from tahfiz_summary
                    as summary_data
            )
        ),


        -- =================================================
        -- EXISTING HISTORY
        -- =================================================

        'existing_history',
        jsonb_build_object(
            'students_with_class_history',
            (
                select count(*)::integer

                from students_with_class_history
            ),

            'students_with_care_history',
            (
                select count(*)::integer

                from students_with_care_history
            ),

            'students_with_tahfiz_history',
            (
                select count(*)::integer

                from students_with_tahfiz_history
            )
        ),


        -- =================================================
        -- REPEAT SAME DESTINATION
        -- =================================================

        'repeat_same_destination',
        jsonb_build_object(
            'class_pairs',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            repeat_data
                        )
                    ),
                    '[]'::jsonb
                )

                from class_repeat_pairs
                    as repeat_data
            ),

            'care_pairs',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            repeat_data
                        )
                    ),
                    '[]'::jsonb
                )

                from care_repeat_pairs
                    as repeat_data
            ),

            'tahfiz_pairs',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            repeat_data
                        )
                    ),
                    '[]'::jsonb
                )

                from tahfiz_repeat_pairs
                    as repeat_data
            )
        ),


        -- =================================================
        -- ANOMALIES
        -- =================================================

        'anomalies',
        jsonb_build_object(
            'students_multiple_active_classes',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly_data
                        )
                    ),
                    '[]'::jsonb
                )

                from invalid_active_class
                    as anomaly_data
            ),

            'students_multiple_active_care_groups',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly_data
                        )
                    ),
                    '[]'::jsonb
                )

                from invalid_active_care
                    as anomaly_data
            ),

            'students_multiple_active_tahfiz_groups',
            (
                select coalesce(
                    jsonb_agg(
                        to_jsonb(
                            anomaly_data
                        )
                    ),
                    '[]'::jsonb
                )

                from invalid_active_tahfiz
                    as anomaly_data
            ),

            'invalid_date_ranges',
            (
                select coalesce(
                    jsonb_agg(
                        date_anomaly.item
                    ),
                    '[]'::jsonb
                )

                from invalid_date_ranges
                    as date_anomaly
            )
        )
    )
) as student_placement_history_inspection;