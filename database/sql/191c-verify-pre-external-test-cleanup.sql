-- ============================================================
-- E-MA'HAD
-- STAGE 191C
--
-- VERIFY PRE-EXTERNAL-TEST CLEANUP
--
-- READ ONLY
--
-- Tujuan:
-- - memastikan data QA operasional sudah bersih;
-- - memastikan master data utama tetap utuh;
-- - memastikan Storage QA sudah kosong;
-- ============================================================


with verification as (

    -- ========================================================
    -- 01. ACTIVE STUDENTS
    -- ========================================================

    select
        1 as sort_order,

        'Active students'
            as test_name,

        case
            when count(*) = 127
                then 'PASS'
            else 'FAIL'
        end
            as status,

        format(
            'actual=%s expected=127',
            count(*)
        )
            as detail

    from public.students

    where status =
          'active'

      and deleted_at
          is null


    union all


    -- ========================================================
    -- 02. CURRENT ACADEMIC YEAR
    -- ========================================================

    select
        2,

        'Current academic year',

        case
            when count(*) = 1
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'current_year_count=%s',
            count(*)
        )

    from public.academic_years

    where is_current =
          true


    union all


    -- ========================================================
    -- 03. MAHAD HEAD MASTER CHECKLIST
    -- ========================================================

    select
        3,

        'Mahad Head checklist master',

        case
            when count(*) = 19
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'checklist_items=%s expected=19',
            count(*)
        )

    from public.mahad_head_journal_checklist_items


    union all


    -- ========================================================
    -- 04. CARE JOURNALS CLEAN
    -- ========================================================

    select
        4,

        'Care journals cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.care_journals


    union all


    -- ========================================================
    -- 05. CARE JOURNAL ENTRIES CLEAN
    -- ========================================================

    select
        5,

        'Care journal entries cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.care_journal_entries


    union all


    -- ========================================================
    -- 06. CARE REVIEWS CLEAN
    -- ========================================================

    select
        6,

        'Care journal reviews cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.care_journal_reviews


    union all


    -- ========================================================
    -- 07. MAHAD HEAD JOURNALS CLEAN
    -- ========================================================

    select
        7,

        'Mahad Head journals cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.mahad_head_journals


    union all


    -- ========================================================
    -- 08. MAHAD HEAD CHECKS CLEAN
    -- ========================================================

    select
        8,

        'Mahad Head journal checks cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.mahad_head_journal_checks


    union all


    -- ========================================================
    -- 09. TAHFIZ REPORTS CLEAN
    -- ========================================================

    select
        9,

        'Tahfiz reports cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.tahfiz_weekly_reports


    union all


    -- ========================================================
    -- 10. STUDENT BILLS CLEAN
    -- ========================================================

    select
        10,

        'Student bills cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.student_bills


    union all


    -- ========================================================
    -- 11. PAYMENTS CLEAN
    -- ========================================================

    select
        11,

        'Payments cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.payments


    union all


    -- ========================================================
    -- 12. PAYMENT ALLOCATIONS CLEAN
    -- ========================================================

    select
        12,

        'Payment allocations cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining=%s',
            count(*)
        )

    from public.payment_allocations


    union all


    -- ========================================================
    -- 13. PAYMENT PROOF STORAGE CLEAN
    -- ========================================================

    select
        13,

        'Payment proof Storage cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining_files=%s',
            count(*)
        )

    from storage.objects

    where bucket_id =
          'payment-proofs'


    union all


    -- ========================================================
    -- 14. HEAD JOURNAL EVIDENCE STORAGE CLEAN
    -- ========================================================

    select
        14,

        'Mahad Head evidence Storage cleaned',

        case
            when count(*) = 0
                then 'PASS'
            else 'FAIL'
        end,

        format(
            'remaining_files=%s',
            count(*)
        )

    from storage.objects

    where bucket_id =
          'mahad-head-journal-evidence'
),

final_result as (

    select
        99 as sort_order,

        'FINAL PRE-EXTERNAL DATA READINESS'
            as test_name,

        case
            when count(*) filter (
                where status = 'FAIL'
            ) = 0
            then 'PASS'

            else 'FAIL'
        end
            as status,

        format(
            'PASS=%s FAIL=%s',
            count(*) filter (
                where status = 'PASS'
            ),
            count(*) filter (
                where status = 'FAIL'
            )
        )
            as detail

    from verification
)

select
    test_name,
    status,
    detail

from (
    select *
    from verification

    union all

    select *
    from final_result
) as result

order by
    sort_order;