-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 129-verify-finance-foundation.sql
--
-- PURPOSE:
-- Verify Finance Foundation.
--
-- TEST:
-- - Tables
-- - Constraints
-- - RLS
-- - Direct authenticated access revoked
-- - Bill lifecycle
-- - Partial payment
-- - Full payment
-- - Payment cancellation
-- - Overpayment protection
-- - Cross-student protection
-- - Bill cancellation protection
--
-- TEST DATA:
-- Transaction + ROLLBACK.
-- Tidak meninggalkan data.
-- =========================================================


-- =========================================================
-- 1. STRUCTURE
-- =========================================================

select
    to_regclass(
        'public.student_bills'
    ) is not null
        as student_bills_exists,

    to_regclass(
        'public.payments'
    ) is not null
        as payments_exists,

    to_regclass(
        'public.payment_allocations'
    ) is not null
        as payment_allocations_exists,

    to_regprocedure(
        'public.validate_payment_allocation()'
    ) is not null
        as allocation_validator_exists,

    to_regprocedure(
        'public.recalculate_student_bill_status(uuid)'
    ) is not null
        as bill_recalculator_exists;


-- =========================================================
-- 2. RLS + PRIVILEGES
-- =========================================================

select
    table_data.relname
        as table_name,

    table_data.relrowsecurity
        as rls_enabled,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_data.relname
        ),
        'SELECT'
    ) as authenticated_select,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_data.relname
        ),
        'INSERT'
    ) as authenticated_insert,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_data.relname
        ),
        'UPDATE'
    ) as authenticated_update,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_data.relname
        ),
        'DELETE'
    ) as authenticated_delete

from pg_class
    as table_data

inner join pg_namespace
    as namespace
    on namespace.oid =
       table_data.relnamespace

where namespace.nspname =
      'public'

  and table_data.relname in (
      'student_bills',
      'payments',
      'payment_allocations'
  )

order by
    table_data.relname;


-- =========================================================
-- 3. LIFECYCLE TEST
-- =========================================================

begin;


do $verification$
declare
    v_academic_year_id uuid;

    v_staff_id uuid;

    v_student_1_id uuid;
    v_student_2_id uuid;

    v_bill_id uuid;
    v_bill_2_id uuid;

    v_payment_1_id uuid;
    v_payment_2_id uuid;

    v_cross_payment_id uuid;

    v_bill_status text;

    v_test_suffix text;
begin

    v_test_suffix :=
        replace(
            gen_random_uuid()::text,
            '-',
            ''
        );


    -- =====================================================
    -- A. ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. BENDAHARA STAFF
    -- =====================================================

    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    inner join public.user_roles
        as user_role
        on user_role.user_id =
           profile.id

    inner join public.roles
        as role
        on role.id =
           user_role.role_id

    where role.code =
          'bendahara'

      and role.is_active =
          true

      and staff.is_active =
          true

      and profile.is_active =
          true

    order by
        staff.created_at,
        staff.id

    limit 1;


    if v_staff_id is null then
        raise exception
            'Bendahara aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. TWO STUDENTS
    -- =====================================================

    select
        student.id

    into
        v_student_1_id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null

    order by
        student.full_name,
        student.id

    limit 1;


    select
        student.id

    into
        v_student_2_id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null

      and student.id <>
          v_student_1_id

    order by
        student.full_name,
        student.id

    limit 1;


    if v_student_1_id is null
       or v_student_2_id is null
    then
        raise exception
            'Minimal dua santri aktif diperlukan untuk verification.';
    end if;


    -- =====================================================
    -- D. CREATE BILL = 1,000,000
    -- =====================================================

    insert into public.student_bills (
        academic_year_id,
        student_id,
        bill_code,
        title,
        category,
        period_label,
        amount,
        due_date,
        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_1_id,
        'TEST-BILL-' || v_test_suffix,
        'Verification Tagihan',
        'verification',
        'Verification',
        1000000,
        current_date + 10,
        v_staff_id,
        v_staff_id
    )
    returning id
    into v_bill_id;


    select
        bill.status

    into
        v_bill_status

    from public.student_bills
        as bill

    where bill.id =
          v_bill_id;


    if v_bill_status <>
       'unpaid'
    then
        raise exception
            'Tagihan baru seharusnya UNPAID.';
    end if;


    raise notice
        'NEW BILL STATUS SUCCESS: unpaid';


    -- =====================================================
    -- E. FIRST PAYMENT = 400,000
    -- =====================================================

    insert into public.payments (
        academic_year_id,
        student_id,
        payment_code,
        payment_date,
        amount,
        payment_method,
        reference_number,
        recorded_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_1_id,
        'TEST-PAY-1-' || v_test_suffix,
        current_date,
        400000,
        'transfer',
        'VERIFY-1',
        v_staff_id,
        v_staff_id
    )
    returning id
    into v_payment_1_id;


    insert into public.payment_allocations (
        payment_id,
        bill_id,
        amount,
        created_by_staff_id
    )
    values (
        v_payment_1_id,
        v_bill_id,
        400000,
        v_staff_id
    );


    select
        bill.status

    into
        v_bill_status

    from public.student_bills
        as bill

    where bill.id =
          v_bill_id;


    if v_bill_status <>
       'partial'
    then
        raise exception
            'Tagihan setelah pembayaran Rp400.000 seharusnya PARTIAL, tetapi %.',
            v_bill_status;
    end if;


    raise notice
        'PARTIAL PAYMENT SUCCESS';


    -- =====================================================
    -- F. SECOND PAYMENT = 600,000
    -- =====================================================

    insert into public.payments (
        academic_year_id,
        student_id,
        payment_code,
        payment_date,
        amount,
        payment_method,
        reference_number,
        recorded_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_1_id,
        'TEST-PAY-2-' || v_test_suffix,
        current_date,
        600000,
        'cash',
        'VERIFY-2',
        v_staff_id,
        v_staff_id
    )
    returning id
    into v_payment_2_id;


    insert into public.payment_allocations (
        payment_id,
        bill_id,
        amount,
        created_by_staff_id
    )
    values (
        v_payment_2_id,
        v_bill_id,
        600000,
        v_staff_id
    );


    select
        bill.status

    into
        v_bill_status

    from public.student_bills
        as bill

    where bill.id =
          v_bill_id;


    if v_bill_status <>
       'paid'
    then
        raise exception
            'Tagihan seharusnya PAID setelah total pembayaran penuh, tetapi %.',
            v_bill_status;
    end if;


    raise notice
        'FULL PAYMENT SUCCESS';


    -- =====================================================
    -- G. OVERPAYMENT MUST FAIL
    -- =====================================================

    begin

        update public.payment_allocations
        set
            amount =
                700000

        where payment_id =
              v_payment_2_id

          and bill_id =
              v_bill_id;


        raise exception
            'EXPECTED_OVERPAYMENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_OVERPAYMENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%melebihi nominal tagihan%'
               and sqlerrm not ilike
                   '%melebihi nominal pembayaran%'
            then
                raise;
            end if;

    end;


    raise notice
        'OVERPAYMENT PROTECTION SUCCESS';


    -- =====================================================
    -- H. BILL WITH ACTIVE PAYMENT CANNOT CANCEL
    -- =====================================================

    begin

        update public.student_bills
        set
            status =
                'cancelled',

            cancelled_at =
                now(),

            cancelled_by_staff_id =
                v_staff_id,

            cancellation_reason =
                'Verification cancellation'

        where id =
              v_bill_id;


        raise exception
            'EXPECTED_PAID_BILL_CANCEL_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_PAID_BILL_CANCEL_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%pembayaran aktif%'
            then
                raise;
            end if;

    end;


    raise notice
        'PAID BILL CANCELLATION PROTECTION SUCCESS';


    -- =====================================================
    -- I. CANCEL SECOND PAYMENT
    --
    -- Bill harus kembali menjadi PARTIAL.
    -- =====================================================

    update public.payments
    set
        status =
            'cancelled',

        cancelled_at =
            now(),

        cancelled_by_staff_id =
            v_staff_id,

        cancellation_reason =
            'Verification payment cancellation',

        updated_by_staff_id =
            v_staff_id

    where id =
          v_payment_2_id;


    select
        bill.status

    into
        v_bill_status

    from public.student_bills
        as bill

    where bill.id =
          v_bill_id;


    if v_bill_status <>
       'partial'
    then
        raise exception
            'Tagihan harus kembali PARTIAL setelah pembayaran kedua dibatalkan, tetapi %.',
            v_bill_status;
    end if;


    raise notice
        'PAYMENT CANCELLATION RECALCULATION SUCCESS';


    -- =====================================================
    -- J. CROSS-STUDENT PROTECTION
    -- =====================================================

    insert into public.student_bills (
        academic_year_id,
        student_id,
        bill_code,
        title,
        category,
        amount,
        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_2_id,
        'TEST-BILL-2-' || v_test_suffix,
        'Verification Tagihan Student 2',
        'verification',
        500000,
        v_staff_id,
        v_staff_id
    )
    returning id
    into v_bill_2_id;


    insert into public.payments (
        academic_year_id,
        student_id,
        payment_code,
        payment_date,
        amount,
        payment_method,
        recorded_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_1_id,
        'TEST-CROSS-' || v_test_suffix,
        current_date,
        100000,
        'transfer',
        v_staff_id,
        v_staff_id
    )
    returning id
    into v_cross_payment_id;


    begin

        insert into public.payment_allocations (
            payment_id,
            bill_id,
            amount,
            created_by_staff_id
        )
        values (
            v_cross_payment_id,
            v_bill_2_id,
            100000,
            v_staff_id
        );


        raise exception
            'EXPECTED_CROSS_STUDENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_CROSS_STUDENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%santri yang sama%'
            then
                raise;
            end if;

    end;


    raise notice
        'CROSS-STUDENT PAYMENT PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'FINANCE FOUNDATION VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Fondasi Keuangan E-Ma''had berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;