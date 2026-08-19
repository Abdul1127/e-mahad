-- ============================================================
-- E-MA'HAD
-- STAGE 191A
--
-- PRE-EXTERNAL-TEST DATA INVENTORY
--
-- READ ONLY
--
-- TUJUAN:
-- Menentukan data mana yang merupakan master data dan mana
-- yang merupakan data operasional / QA sebelum external test.
--
-- TIDAK ADA DELETE / UPDATE / INSERT KE DATA APLIKASI.
-- ============================================================


-- ============================================================
-- 01. CURRENT ACADEMIC YEAR
-- ============================================================

select
    '01_CURRENT_ACADEMIC_YEAR'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                to_jsonb(
                    academic_year
                )
            ),
            '[]'::jsonb
        )
    )
        as data

from public.academic_years
    as academic_year

where academic_year.is_current =
      true;


-- ============================================================
-- 02. MASTER DATA COUNTS
-- ============================================================

select
    '02_MASTER_DATA_COUNTS'
        as section,

    jsonb_pretty(
        jsonb_build_object(

            'active_students',
            (
                select
                    count(*)

                from public.students

                where status =
                      'active'

                  and deleted_at
                      is null
            ),

            'active_staff',
            (
                select
                    count(*)

                from public.staff

                where is_active =
                      true
            ),

            'active_profiles',
            (
                select
                    count(*)

                from public.profiles

                where is_active =
                      true
            ),

            'user_roles',
            (
                select
                    count(*)

                from public.user_roles
            ),

            'active_care_groups',
            (
                select
                    count(*)

                from public.care_groups

                where is_active =
                      true
            ),

            'active_tahfiz_groups',
            (
                select
                    count(*)

                from public.tahfiz_groups

                where is_active =
                      true
            ),

            'tahfiz_group_members',
            (
                select
                    count(*)

                from public.tahfiz_group_members
            )
        )
    )
        as data;


-- ============================================================
-- 03. ACTIVE LOGIN ACCOUNTS
--
-- Hanya inventory.
-- Akun TIDAK akan dihapus pada cleanup transaksi.
-- ============================================================

select
    '03_ACTIVE_LOGIN_ACCOUNTS'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'profile_id',
                    profile.id,

                    'login_id',
                    profile.login_id,

                    'full_name',
                    profile.full_name,

                    'is_active',
                    profile.is_active,

                    'roles',
                    coalesce(
                        (
                            select
                                jsonb_agg(
                                    jsonb_build_object(
                                        'code',
                                        role.code,

                                        'name',
                                        role.name
                                    )
                                    order by
                                        role.id
                                )

                            from public.user_roles
                                as user_role

                            inner join public.roles
                                as role

                                on role.id =
                                   user_role.role_id

                            where user_role.user_id =
                                  profile.id
                        ),
                        '[]'::jsonb
                    )
                )
                order by
                    profile.login_id
            ),
            '[]'::jsonb
        )
    )
        as data

from public.profiles
    as profile

where profile.login_id
      is not null;


-- ============================================================
-- 04. OPERATIONAL DATA COUNTS
--
-- Ini kandidat utama untuk dibersihkan sebelum external test.
-- ============================================================

select
    '04_OPERATIONAL_DATA_COUNTS'
        as section,

    jsonb_pretty(
        jsonb_build_object(

            'care_journals',
            (
                select
                    count(*)

                from public.care_journals
            ),

            'care_journal_entries',
            (
                select
                    count(*)

                from public.care_journal_entries
            ),

            'mahad_head_journals',
            (
                select
                    count(*)

                from public.mahad_head_journals
            ),

            'mahad_head_journal_checks',
            (
                select
                    count(*)

                from public.mahad_head_journal_checks
            ),

            'tahfiz_weekly_reports',
            (
                select
                    count(*)

                from public.tahfiz_weekly_reports
            ),

            'student_bills',
            (
                select
                    count(*)

                from public.student_bills
            ),

            'payments',
            (
                select
                    count(*)

                from public.payments
            ),

            'payment_allocations',
            (
                select
                    count(*)

                from public.payment_allocations
            )
        )
    )
        as data;


-- ============================================================
-- 05. CARE JOURNALS
--
-- Seluruh jurnal ditampilkan karena volume QA seharusnya kecil.
-- ============================================================

select
    '05_CARE_JOURNALS'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    journal.id,

                    'journal_date',
                    journal.journal_date,

                    'session',
                    journal.session,

                    'status',
                    journal.status,

                    'submission_version',
                    journal.submission_version,

                    'submitted_at',
                    journal.submitted_at,

                    'last_reviewed_at',
                    journal.last_reviewed_at,

                    'created_at',
                    journal.created_at,

                    'care_group',
                    jsonb_build_object(
                        'id',
                        care_group.id,

                        'code',
                        care_group.code,

                        'name',
                        care_group.name
                    ),

                    'entry_count',
                    (
                        select
                            count(*)

                        from public.care_journal_entries
                            as entry

                        where entry.journal_id =
                              journal.id
                    )
                )
                order by
                    journal.journal_date,
                    journal.created_at
            ),
            '[]'::jsonb
        )
    )
        as data

from public.care_journals
    as journal

inner join public.care_groups
    as care_group

    on care_group.id =
       journal.care_group_id;


-- ============================================================
-- 06. MAHAD HEAD JOURNALS
-- ============================================================

select
    '06_MAHAD_HEAD_JOURNALS'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    journal.id,

                    'journal_date',
                    journal.journal_date,

                    'status',
                    journal.status,

                    'submitted_at',
                    journal.submitted_at,

                    'created_at',
                    journal.created_at,

                    'evidence_path',
                    journal.evidence_path,

                    'checked_count',
                    (
                        select
                            count(*)

                        from public.mahad_head_journal_checks
                            as journal_check

                        where journal_check.journal_id =
                              journal.id
                    )
                )
                order by
                    journal.journal_date,
                    journal.created_at
            ),
            '[]'::jsonb
        )
    )
        as data

from public.mahad_head_journals
    as journal;


-- ============================================================
-- 07. TAHFIZ REPORTS
-- ============================================================

select
    '07_TAHFIZ_WEEKLY_REPORTS'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    report.id,

                    'student_id',
                    student.id,

                    'student_name',
                    student.full_name,

                    'week_start',
                    report.week_start,

                    'week_end',
                    report.week_end,

                    'status',
                    report.status,

                    'published_at',
                    report.published_at,

                    'created_at',
                    report.created_at,

                    'group_id',
                    report.tahfiz_group_id
                )
                order by
                    report.week_start,
                    student.full_name
            ),
            '[]'::jsonb
        )
    )
        as data

from public.tahfiz_weekly_reports
    as report

inner join public.students
    as student

    on student.id =
       report.student_id;


-- ============================================================
-- 08. STUDENT BILLS
-- ============================================================

select
    '08_STUDENT_BILLS'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    bill.id,

                    'student_id',
                    student.id,

                    'student_name',
                    student.full_name,

                    'bill_code',
                    bill.bill_code,

                    'title',
                    bill.title,

                    'category',
                    bill.category,

                    'period_label',
                    bill.period_label,

                    'amount',
                    bill.amount,

                    'due_date',
                    bill.due_date,

                    'status',
                    bill.status,

                    'cancelled_at',
                    bill.cancelled_at,

                    'created_at',
                    bill.created_at,

                    'active_paid_amount',
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
                    )
                )
                order by
                    bill.created_at,
                    student.full_name
            ),
            '[]'::jsonb
        )
    )
        as data

from public.student_bills
    as bill

inner join public.students
    as student

    on student.id =
       bill.student_id;


-- ============================================================
-- 09. PAYMENTS
-- ============================================================

select
    '09_PAYMENTS'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    payment.id,

                    'student_id',
                    student.id,

                    'student_name',
                    student.full_name,

                    'payment_code',
                    payment.payment_code,

                    'payment_date',
                    payment.payment_date,

                    'amount',
                    payment.amount,

                    'payment_method',
                    payment.payment_method,

                    'reference_number',
                    payment.reference_number,

                    'status',
                    payment.status,

                    'proof_path',
                    payment.proof_path,

                    'cancelled_at',
                    payment.cancelled_at,

                    'cancellation_reason',
                    payment.cancellation_reason,

                    'created_at',
                    payment.created_at,

                    'allocation_count',
                    (
                        select
                            count(*)

                        from public.payment_allocations
                            as allocation

                        where allocation.payment_id =
                              payment.id
                    ),

                    'allocated_amount',
                    coalesce(
                        (
                            select
                                sum(
                                    allocation.amount
                                )

                            from public.payment_allocations
                                as allocation

                            where allocation.payment_id =
                                  payment.id
                        ),
                        0
                    )
                )
                order by
                    payment.payment_date,
                    payment.created_at
            ),
            '[]'::jsonb
        )
    )
        as data

from public.payments
    as payment

inner join public.students
    as student

    on student.id =
       payment.student_id;


-- ============================================================
-- 10. PAYMENT ALLOCATIONS
-- ============================================================

select
    '10_PAYMENT_ALLOCATIONS'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'allocation_id',
                    allocation.id,

                    'amount',
                    allocation.amount,

                    'created_at',
                    allocation.created_at,

                    'payment_id',
                    payment.id,

                    'payment_code',
                    payment.payment_code,

                    'payment_status',
                    payment.status,

                    'bill_id',
                    bill.id,

                    'bill_code',
                    bill.bill_code,

                    'bill_status',
                    bill.status,

                    'student_id',
                    bill.student_id
                )
                order by
                    allocation.created_at
            ),
            '[]'::jsonb
        )
    )
        as data

from public.payment_allocations
    as allocation

inner join public.payments
    as payment

    on payment.id =
       allocation.payment_id

inner join public.student_bills
    as bill

    on bill.id =
       allocation.bill_id;


-- ============================================================
-- 11. STORAGE OBJECTS - PAYMENT PROOFS
--
-- Hanya inventory metadata.
-- ============================================================

select
    '11_PAYMENT_PROOF_STORAGE'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    object.id,

                    'name',
                    object.name,

                    'bucket_id',
                    object.bucket_id,

                    'created_at',
                    object.created_at,

                    'updated_at',
                    object.updated_at
                )
                order by
                    object.created_at
            ),
            '[]'::jsonb
        )
    )
        as data

from storage.objects
    as object

where object.bucket_id =
      'payment-proofs';


-- ============================================================
-- 12. STORAGE OBJECTS - MAHAD HEAD JOURNAL EVIDENCE
-- ============================================================

select
    '12_MAHAD_HEAD_JOURNAL_EVIDENCE_STORAGE'
        as section,

    jsonb_pretty(
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    object.id,

                    'name',
                    object.name,

                    'bucket_id',
                    object.bucket_id,

                    'created_at',
                    object.created_at,

                    'updated_at',
                    object.updated_at
                )
                order by
                    object.created_at
            ),
            '[]'::jsonb
        )
    )
        as data

from storage.objects
    as object

where object.bucket_id =
      'mahad-head-journal-evidence';


-- ============================================================
-- 13. CLEANUP SUMMARY
--
-- Belum melakukan cleanup.
-- Hanya menunjukkan volume data kandidat.
-- ============================================================

select
    '13_CLEANUP_CANDIDATE_SUMMARY'
        as section,

    jsonb_pretty(
        jsonb_build_object(

            'care_journals',
            (
                select count(*)
                from public.care_journals
            ),

            'care_journal_entries',
            (
                select count(*)
                from public.care_journal_entries
            ),

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

            'tahfiz_weekly_reports',
            (
                select count(*)
                from public.tahfiz_weekly_reports
            ),

            'student_bills',
            (
                select count(*)
                from public.student_bills
            ),

            'payments',
            (
                select count(*)
                from public.payments
            ),

            'payment_allocations',
            (
                select count(*)
                from public.payment_allocations
            ),

            'payment_proof_files',
            (
                select count(*)
                from storage.objects
                where bucket_id =
                      'payment-proofs'
            ),

            'mahad_head_evidence_files',
            (
                select count(*)
                from storage.objects
                where bucket_id =
                      'mahad-head-journal-evidence'
            )
        )
    )
        as data;