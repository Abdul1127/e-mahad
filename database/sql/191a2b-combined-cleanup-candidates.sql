-- ============================================================
-- E-MA'HAD
-- STAGE 191A-2B
--
-- COMBINED PRE-EXTERNAL-TEST CLEANUP CANDIDATES
--
-- READ ONLY
--
-- TUJUAN:
-- Menggabungkan seluruh kandidat data operasional QA
-- ke dalam SATU result set agar mudah diperiksa
-- melalui Supabase SQL Editor.
--
-- TIDAK ADA DELETE / UPDATE / INSERT DATA APLIKASI.
-- ============================================================


with cleanup_candidates as (

    -- ========================================================
    -- 01. CARE JOURNALS
    -- ========================================================

    select
        1 as sort_order,

        'CARE_JOURNAL'
            as data_type,

        journal.id::text
            as record_id,

        journal.journal_date::text
            as record_date,

        care_group.name
            as subject,

        concat(
            'session=',
            journal.session,

            ' | status=',
            journal.status,

            ' | entries=',
            (
                select
                    count(*)

                from public.care_journal_entries
                    as entry

                where entry.journal_id =
                      journal.id
            ),

            ' | submission_version=',
            journal.submission_version,

            ' | created_at=',
            journal.created_at
        )
            as detail

    from public.care_journals
        as journal

    inner join public.care_groups
        as care_group

        on care_group.id =
           journal.care_group_id


    union all


    -- ========================================================
    -- 02. MAHAD HEAD JOURNALS
    -- ========================================================

    select
        2 as sort_order,

        'MAHAD_HEAD_JOURNAL'
            as data_type,

        journal.id::text
            as record_id,

        journal.journal_date::text
            as record_date,

        'Jurnal Kepala Ma''had'
            as subject,

        concat(
            'status=',
            journal.status,

            ' | checks=',
            (
                select
                    count(*)

                from public.mahad_head_journal_checks
                    as journal_check

                where journal_check.journal_id =
                      journal.id
            ),

            ' | evidence=',
            coalesce(
                journal.evidence_path,
                '-'
            ),

            ' | submitted_at=',
            coalesce(
                journal.submitted_at::text,
                '-'
            ),

            ' | created_at=',
            journal.created_at
        )
            as detail

    from public.mahad_head_journals
        as journal


    union all


    -- ========================================================
    -- 03. TAHFIZ WEEKLY REPORTS
    -- ========================================================

    select
        3 as sort_order,

        'TAHFIZ_REPORT'
            as data_type,

        report.id::text
            as record_id,

        report.week_start::text
            as record_date,

        student.full_name
            as subject,

        concat(
            'week=',
            report.week_start,

            ' s.d. ',
            report.week_end,

            ' | status=',
            report.status,

            ' | published_at=',
            coalesce(
                report.published_at::text,
                '-'
            ),

            ' | created_at=',
            report.created_at
        )
            as detail

    from public.tahfiz_weekly_reports
        as report

    inner join public.students
        as student

        on student.id =
           report.student_id


    union all


    -- ========================================================
    -- 04. STUDENT BILLS
    -- ========================================================

    select
        4 as sort_order,

        'STUDENT_BILL'
            as data_type,

        bill.id::text
            as record_id,

        coalesce(
            bill.period_start,
            bill.due_date,
            bill.created_at::date
        )::text
            as record_date,

        student.full_name
            as subject,

        concat(
            'code=',
            bill.bill_code,

            ' | title=',
            bill.title,

            ' | category=',
            bill.category,

            ' | amount=',
            bill.amount,

            ' | status=',
            bill.status,

            ' | active_paid=',
            coalesce(
                (
                    select
                        sum(
                            allocation.amount
                        )

                    from public.payment_allocations
                        as allocation

                    inner join public.payments
                        as payment

                        on payment.id =
                           allocation.payment_id

                    where allocation.bill_id =
                          bill.id

                      and payment.status =
                          'recorded'
                ),
                0
            ),

            ' | created_at=',
            bill.created_at
        )
            as detail

    from public.student_bills
        as bill

    inner join public.students
        as student

        on student.id =
           bill.student_id


    union all


    -- ========================================================
    -- 05. PAYMENTS
    -- ========================================================

    select
        5 as sort_order,

        'PAYMENT'
            as data_type,

        payment.id::text
            as record_id,

        payment.payment_date::text
            as record_date,

        student.full_name
            as subject,

        concat(
            'code=',
            payment.payment_code,

            ' | amount=',
            payment.amount,

            ' | status=',
            payment.status,

            ' | method=',
            payment.payment_method,

            ' | proof=',
            coalesce(
                payment.proof_path,
                '-'
            ),

            ' | cancelled_at=',
            coalesce(
                payment.cancelled_at::text,
                '-'
            ),

            ' | cancellation_reason=',
            coalesce(
                payment.cancellation_reason,
                '-'
            ),

            ' | created_at=',
            payment.created_at
        )
            as detail

    from public.payments
        as payment

    inner join public.students
        as student

        on student.id =
           payment.student_id


    union all


    -- ========================================================
    -- 06. PAYMENT ALLOCATIONS
    -- ========================================================

    select
        6 as sort_order,

        'PAYMENT_ALLOCATION'
            as data_type,

        allocation.id::text
            as record_id,

        allocation.created_at::date::text
            as record_date,

        student.full_name
            as subject,

        concat(
            'payment=',
            payment.payment_code,

            ' [',
            payment.status,
            ']',

            ' | bill=',
            bill.bill_code,

            ' [',
            bill.status,
            ']',

            ' | allocated=',
            allocation.amount,

            ' | created_at=',
            allocation.created_at
        )
            as detail

    from public.payment_allocations
        as allocation

    inner join public.payments
        as payment

        on payment.id =
           allocation.payment_id

    inner join public.student_bills
        as bill

        on bill.id =
           allocation.bill_id

    inner join public.students
        as student

        on student.id =
           bill.student_id


    union all


    -- ========================================================
    -- 07. PAYMENT PROOF STORAGE
    -- ========================================================

    select
        7 as sort_order,

        'PAYMENT_PROOF_FILE'
            as data_type,

        object.id::text
            as record_id,

        object.created_at::date::text
            as record_date,

        object.name
            as subject,

        concat(
            'bucket=',
            object.bucket_id,

            ' | created_at=',
            object.created_at,

            ' | updated_at=',
            object.updated_at
        )
            as detail

    from storage.objects
        as object

    where object.bucket_id =
          'payment-proofs'


    union all


    -- ========================================================
    -- 08. MAHAD HEAD JOURNAL EVIDENCE STORAGE
    -- ========================================================

    select
        8 as sort_order,

        'MAHAD_HEAD_EVIDENCE_FILE'
            as data_type,

        object.id::text
            as record_id,

        object.created_at::date::text
            as record_date,

        object.name
            as subject,

        concat(
            'bucket=',
            object.bucket_id,

            ' | created_at=',
            object.created_at,

            ' | updated_at=',
            object.updated_at
        )
            as detail

    from storage.objects
        as object

    where object.bucket_id =
          'mahad-head-journal-evidence'
)


-- ============================================================
-- FINAL RESULT
-- ============================================================

select
    data_type,
    record_id,
    record_date,
    subject,
    detail

from cleanup_candidates

order by
    sort_order,
    record_date,
    subject,
    record_id;