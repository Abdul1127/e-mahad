-- ============================================================
-- E-MA'HAD
-- STAGE 191B
--
-- SAFE PRE-EXTERNAL-TEST QA CLEANUP
--
-- TUJUAN:
-- Menghapus HANYA data operasional QA yang telah
-- diidentifikasi pada Stage 191A / 191A-2B.
--
-- MASTER DATA TIDAK DISENTUH:
-- - students
-- - staff
-- - profiles
-- - roles
-- - user_roles
-- - guardians
-- - guardian_students
-- - academic_years
-- - care_groups
-- - care_group_members
-- - caregiver_assignments
-- - tahfiz_groups
-- - tahfiz_group_members
-- - tahfiz_supervisor_assignments
--
-- CATATAN:
-- File Storage harus sudah dihapus melalui
-- Supabase Storage Dashboard / Storage API,
-- BUKAN DELETE langsung dari storage.objects.
-- ============================================================


begin;


-- ============================================================
-- 01. SAFETY PRECHECK
--
-- Script dihentikan kalau dataset target sudah berubah dari
-- hasil inventory terakhir.
-- ============================================================

do $$
declare
    v_care_journal_count integer;
    v_care_entry_count integer;

    v_head_journal_count integer;
    v_head_check_count integer;

    v_tahfiz_report_count integer;

    v_bill_count integer;

    v_payment_count integer;

    v_allocation_count integer;
begin

    -- --------------------------------------------------------
    -- CARE JOURNALS
    -- --------------------------------------------------------

    select count(*)
    into v_care_journal_count
    from public.care_journals
    where id in (
        '191ee155-f1c4-4f45-8906-7076552fa061'::uuid,
        'f65e3bd4-e56e-41e9-b1f8-dbd1f64df734'::uuid,
        '130faef5-dd3c-416d-9d68-cb72ea54b9fa'::uuid
    );

    if v_care_journal_count <> 3 then
        raise exception
            'SAFETY CHECK FAILED: expected 3 QA care journals, found %.',
            v_care_journal_count;
    end if;


    select count(*)
    into v_care_entry_count
    from public.care_journal_entries
    where journal_id in (
        '191ee155-f1c4-4f45-8906-7076552fa061'::uuid,
        'f65e3bd4-e56e-41e9-b1f8-dbd1f64df734'::uuid,
        '130faef5-dd3c-416d-9d68-cb72ea54b9fa'::uuid
    );

    if v_care_entry_count <> 188 then
        raise exception
            'SAFETY CHECK FAILED: expected 188 QA care journal entries, found %.',
            v_care_entry_count;
    end if;


    -- --------------------------------------------------------
    -- MAHAD HEAD JOURNAL
    -- --------------------------------------------------------

    select count(*)
    into v_head_journal_count
    from public.mahad_head_journals
    where id =
        'ea5aed58-6ed3-4dd5-bbeb-8c61961166ce'::uuid;

    if v_head_journal_count <> 1 then
        raise exception
            'SAFETY CHECK FAILED: expected 1 QA Mahad Head Journal, found %.',
            v_head_journal_count;
    end if;


    select count(*)
    into v_head_check_count
    from public.mahad_head_journal_checks
    where journal_id =
        'ea5aed58-6ed3-4dd5-bbeb-8c61961166ce'::uuid;

    if v_head_check_count <> 4 then
        raise exception
            'SAFETY CHECK FAILED: expected 4 QA Mahad Head Journal checks, found %.',
            v_head_check_count;
    end if;


    -- --------------------------------------------------------
    -- TAHFIZ REPORT
    -- --------------------------------------------------------

    select count(*)
    into v_tahfiz_report_count
    from public.tahfiz_weekly_reports
    where id =
        '6dd0af6c-ca50-41ac-9fe1-ba10ffc05933'::uuid;

    if v_tahfiz_report_count <> 1 then
        raise exception
            'SAFETY CHECK FAILED: expected 1 QA Tahfiz report, found %.',
            v_tahfiz_report_count;
    end if;


    -- --------------------------------------------------------
    -- STUDENT BILL
    -- --------------------------------------------------------

    select count(*)
    into v_bill_count
    from public.student_bills
    where id =
        '655f8a8c-8813-4f2c-8337-439b8d22600e'::uuid;

    if v_bill_count <> 1 then
        raise exception
            'SAFETY CHECK FAILED: expected 1 QA student bill, found %.',
            v_bill_count;
    end if;


    -- --------------------------------------------------------
    -- PAYMENTS
    -- --------------------------------------------------------

    select count(*)
    into v_payment_count
    from public.payments
    where id in (
        '50b97613-9a40-412b-8149-16a1dc25d165'::uuid,
        'faa552be-8bc1-4eef-9e3e-96d250dee08f'::uuid
    );

    if v_payment_count <> 2 then
        raise exception
            'SAFETY CHECK FAILED: expected 2 QA payments, found %.',
            v_payment_count;
    end if;


    -- --------------------------------------------------------
    -- PAYMENT ALLOCATIONS
    -- --------------------------------------------------------

    select count(*)
    into v_allocation_count
    from public.payment_allocations
    where id in (
        '5b243055-a82a-4bfc-8488-7fe243f5b4c6'::uuid,
        '7b505993-1ca2-4f31-8fe9-c69b379b18bd'::uuid
    );

    if v_allocation_count <> 2 then
        raise exception
            'SAFETY CHECK FAILED: expected 2 QA payment allocations, found %.',
            v_allocation_count;
    end if;

end
$$;


-- ============================================================
-- 02. CARE JOURNAL REVIEWS
--
-- Review harus dihapus sebelum jurnal induknya.
-- Tidak perlu mengetahui UUID review satu per satu karena
-- hanya journal_id target QA yang digunakan.
-- ============================================================

delete from public.care_journal_reviews
where journal_id in (
    '191ee155-f1c4-4f45-8906-7076552fa061'::uuid,
    'f65e3bd4-e56e-41e9-b1f8-dbd1f64df734'::uuid,
    '130faef5-dd3c-416d-9d68-cb72ea54b9fa'::uuid
);


-- ============================================================
-- 03. CARE JOURNAL ENTRIES
-- ============================================================

delete from public.care_journal_entries
where journal_id in (
    '191ee155-f1c4-4f45-8906-7076552fa061'::uuid,
    'f65e3bd4-e56e-41e9-b1f8-dbd1f64df734'::uuid,
    '130faef5-dd3c-416d-9d68-cb72ea54b9fa'::uuid
);


-- ============================================================
-- 04. CARE JOURNALS
-- ============================================================

delete from public.care_journals
where id in (
    '191ee155-f1c4-4f45-8906-7076552fa061'::uuid,
    'f65e3bd4-e56e-41e9-b1f8-dbd1f64df734'::uuid,
    '130faef5-dd3c-416d-9d68-cb72ea54b9fa'::uuid
);


-- ============================================================
-- 05. MAHAD HEAD JOURNAL CHECKS
-- ============================================================

delete from public.mahad_head_journal_checks
where journal_id =
    'ea5aed58-6ed3-4dd5-bbeb-8c61961166ce'::uuid;


-- ============================================================
-- 06. MAHAD HEAD JOURNAL
-- ============================================================

delete from public.mahad_head_journals
where id =
    'ea5aed58-6ed3-4dd5-bbeb-8c61961166ce'::uuid;


-- ============================================================
-- 07. TAHFIZ WEEKLY REPORT
-- ============================================================

delete from public.tahfiz_weekly_reports
where id =
    '6dd0af6c-ca50-41ac-9fe1-ba10ffc05933'::uuid;


-- ============================================================
-- 08. PAYMENT ALLOCATIONS
--
-- Harus sebelum payment dan bill.
-- ============================================================

delete from public.payment_allocations
where id in (
    '5b243055-a82a-4bfc-8488-7fe243f5b4c6'::uuid,
    '7b505993-1ca2-4f31-8fe9-c69b379b18bd'::uuid
);


-- ============================================================
-- 09. PAYMENTS
-- ============================================================

delete from public.payments
where id in (
    '50b97613-9a40-412b-8149-16a1dc25d165'::uuid,
    'faa552be-8bc1-4eef-9e3e-96d250dee08f'::uuid
);


-- ============================================================
-- 10. STUDENT BILL
-- ============================================================

delete from public.student_bills
where id =
    '655f8a8c-8813-4f2c-8337-439b8d22600e'::uuid;


-- ============================================================
-- 11. COMMIT
-- ============================================================

commit;


-- ============================================================
-- 12. QUICK RESULT
--
-- Setelah cleanup, seluruh data operasional QA yang telah
-- diidentifikasi seharusnya bernilai 0.
-- ============================================================

select
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

            'care_journal_reviews',
            (
                select count(*)
                from public.care_journal_reviews
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
    ) as cleanup_result;