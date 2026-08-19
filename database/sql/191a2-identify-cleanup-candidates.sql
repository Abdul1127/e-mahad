-- ============================================================
-- E-MA'HAD
-- STAGE 191A-2
--
-- IDENTIFY PRE-EXTERNAL-TEST CLEANUP CANDIDATES
--
-- READ ONLY
--
-- Tidak ada DELETE / UPDATE.
-- Hanya menampilkan record operasional yang saat ini ada.
-- ============================================================


-- ============================================================
-- 01. CARE JOURNALS
-- ============================================================

select
    'CARE_JOURNAL' as data_type,

    journal.id::text as record_id,

    journal.journal_date::text as record_date,

    care_group.name as subject,

    concat(
        'session=',
        journal.session,
        ' | status=',
        journal.status,
        ' | entries=',
        (
            select count(*)
            from public.care_journal_entries as entry
            where entry.journal_id = journal.id
        )
    ) as detail

from public.care_journals as journal

inner join public.care_groups as care_group
    on care_group.id = journal.care_group_id

order by
    journal.journal_date,
    journal.created_at;


-- ============================================================
-- 02. MAHAD HEAD JOURNALS
-- ============================================================

select
    'MAHAD_HEAD_JOURNAL' as data_type,

    journal.id::text as record_id,

    journal.journal_date::text as record_date,

    'Jurnal Kepala Ma''had' as subject,

    concat(
        'status=',
        journal.status,
        ' | checks=',
        (
            select count(*)
            from public.mahad_head_journal_checks as journal_check
            where journal_check.journal_id = journal.id
        ),
        ' | evidence=',
        coalesce(
            journal.evidence_path,
            '-'
        )
    ) as detail

from public.mahad_head_journals as journal

order by
    journal.journal_date,
    journal.created_at;


-- ============================================================
-- 03. TAHFIZ WEEKLY REPORTS
-- ============================================================

select
    'TAHFIZ_REPORT' as data_type,

    report.id::text as record_id,

    report.week_start::text as record_date,

    student.full_name as subject,

    concat(
        'week=',
        report.week_start,
        ' s.d. ',
        report.week_end,
        ' | status=',
        report.status
    ) as detail

from public.tahfiz_weekly_reports as report

inner join public.students as student
    on student.id = report.student_id

order by
    report.week_start,
    student.full_name;


-- ============================================================
-- 04. STUDENT BILLS
-- ============================================================

select
    'STUDENT_BILL' as data_type,

    bill.id::text as record_id,

    coalesce(
        bill.period_start,
        bill.due_date,
        bill.created_at::date
    )::text as record_date,

    student.full_name as subject,

    concat(
        'code=',
        bill.bill_code,
        ' | title=',
        bill.title,
        ' | amount=',
        bill.amount,
        ' | status=',
        bill.status
    ) as detail

from public.student_bills as bill

inner join public.students as student
    on student.id = bill.student_id

order by
    bill.created_at;


-- ============================================================
-- 05. PAYMENTS
-- ============================================================

select
    'PAYMENT' as data_type,

    payment.id::text as record_id,

    payment.payment_date::text as record_date,

    student.full_name as subject,

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
        )
    ) as detail

from public.payments as payment

inner join public.students as student
    on student.id = payment.student_id

order by
    payment.payment_date,
    payment.created_at;


-- ============================================================
-- 06. PAYMENT ALLOCATIONS
-- ============================================================

select
    'PAYMENT_ALLOCATION' as data_type,

    allocation.id::text as record_id,

    allocation.created_at::date::text as record_date,

    student.full_name as subject,

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
        allocation.amount
    ) as detail

from public.payment_allocations as allocation

inner join public.payments as payment
    on payment.id = allocation.payment_id

inner join public.student_bills as bill
    on bill.id = allocation.bill_id

inner join public.students as student
    on student.id = bill.student_id

order by
    allocation.created_at;


-- ============================================================
-- 07. PAYMENT PROOF STORAGE OBJECTS
-- ============================================================

select
    'PAYMENT_PROOF_FILE' as data_type,

    object.id::text as record_id,

    object.created_at::date::text as record_date,

    object.name as subject,

    concat(
        'bucket=',
        object.bucket_id,
        ' | updated=',
        object.updated_at
    ) as detail

from storage.objects as object

where object.bucket_id =
      'payment-proofs'

order by
    object.created_at;


-- ============================================================
-- 08. MAHAD HEAD JOURNAL EVIDENCE STORAGE
-- ============================================================

select
    'MAHAD_HEAD_EVIDENCE_FILE' as data_type,

    object.id::text as record_id,

    object.created_at::date::text as record_date,

    object.name as subject,

    concat(
        'bucket=',
        object.bucket_id,
        ' | updated=',
        object.updated_at
    ) as detail

from storage.objects as object

where object.bucket_id =
      'mahad-head-journal-evidence'

order by
    object.created_at;