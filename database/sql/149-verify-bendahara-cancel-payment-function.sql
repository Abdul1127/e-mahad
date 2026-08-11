-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 149-verify-bendahara-cancel-payment-function.sql
--
-- PURPOSE:
-- Verification cancel_bendahara_payment()
--
-- SCENARIO:
--
-- Bill = Rp750.000
--
-- Payment A = Rp300.000
-- Payment B = Rp450.000
--
-- Sebelum cancel:
--
-- paid_amount  = Rp750.000
-- outstanding  = Rp0
-- status       = paid
--
-- Cancel Payment A:
--
-- paid_amount  = Rp450.000
-- outstanding  = Rp300.000
-- status       = partial
--
-- Payment A tetap tersimpan sebagai cancelled.
-- Allocation A tetap tersedia sebagai historical audit trail.
--
-- TEST:
-- - function exists
-- - privileges
-- - payment cancellation
-- - bill recalculation
-- - allocation preserved
-- - bill detail integration
-- - payment history integration
-- - duplicate cancellation rejected
-- - empty reason rejected
-- - unknown payment rejected
-- - non-Bendahara rejected
--
-- Semua data verification di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.cancel_bendahara_payment(uuid,text)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.cancel_bendahara_payment(uuid,text)',
        'execute'
    )
        as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.cancel_bendahara_payment(uuid,text)',
        'execute'
    )
        as anon_can_execute;


-- =========================================================
-- 2. TEST TRANSACTION
-- =========================================================

begin;


do $verification$
declare
    v_bendahara_profile_id uuid;
    v_bendahara_email text;
    v_bendahara_staff_id uuid;

    v_non_bendahara_profile_id uuid;
    v_non_bendahara_email text;

    v_academic_year_id uuid;

    v_student_id uuid;

    v_bill_id uuid;

    v_payment_1_id uuid;
    v_payment_2_id uuid;

    v_allocation_1_id uuid;

    v_result jsonb;
    v_detail jsonb;
    v_history jsonb;

    v_bill_status text;
    v_payment_status text;

    v_paid_amount numeric;
    v_outstanding_amount numeric;

    v_suffix text;

    v_found boolean;
    v_item jsonb;
begin

    v_suffix :=
        upper(
            substr(
                replace(
                    gen_random_uuid()::text,
                    '-',
                    ''
                ),
                1,
                10
            )
        );


    -- =====================================================
    -- A. BENDAHARA
    -- =====================================================

    select
        profile.id,
        auth_user.email,
        staff.id

    into
        v_bendahara_profile_id,
        v_bendahara_email,
        v_bendahara_staff_id

    from public.profiles
        as profile

    inner join auth.users
        as auth_user
        on auth_user.id =
           profile.id

    inner join public.staff
        as staff
        on staff.profile_id =
           profile.id

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

      and profile.is_active =
          true

      and staff.is_active =
          true

    order by
        staff.created_at,
        staff.id

    limit 1;


    if v_bendahara_profile_id is null then
        raise exception
            'Akun Bendahara aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. LOGIN AS BENDAHARA
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_bendahara_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_bendahara_profile_id,

            'role',
            'authenticated',

            'email',
            v_bendahara_email
        )::text,
        true
    );


    -- =====================================================
    -- C. CURRENT ACADEMIC YEAR
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
    -- D. ACTIVE STUDENT
    -- =====================================================

    select
        student.id

    into
        v_student_id

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


    if v_student_id is null then
        raise exception
            'Santri aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- E. CREATE BILL = 750K
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
        v_student_id,

        'VERIFY-CANCEL-PAY-' ||
            v_suffix,

        'Verification Cancel Payment',

        'verification',

        750000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_id;


    -- =====================================================
    -- F. PAYMENT A = 300K
    -- =====================================================

    v_result :=
        public.record_bendahara_bill_payment(
            p_bill_id =>
                v_bill_id,

            p_payment_date =>
                current_date,

            p_amount =>
                300000,

            p_payment_method =>
                'transfer',

            p_reference_number =>
                'VERIFY-CANCEL-A-' ||
                v_suffix,

            p_notes =>
                'Payment A verification cancellation.'
        );


    v_payment_1_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    v_allocation_1_id :=
        (
            v_result
            #>> '{allocation,id}'
        )::uuid;


    if v_payment_1_id is null
       or v_allocation_1_id is null
    then
        raise exception
            'Payment A gagal dibuat.';
    end if;


    -- =====================================================
    -- G. PAYMENT B = 450K
    -- =====================================================

    v_result :=
        public.record_bendahara_bill_payment(
            p_bill_id =>
                v_bill_id,

            p_payment_date =>
                current_date,

            p_amount =>
                450000,

            p_payment_method =>
                'cash',

            p_reference_number =>
                'VERIFY-CANCEL-B-' ||
                v_suffix,

            p_notes =>
                'Payment B verification cancellation.'
        );


    v_payment_2_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    if v_payment_2_id is null then
        raise exception
            'Payment B gagal dibuat.';
    end if;


    -- =====================================================
    -- H. BILL MUST BE PAID BEFORE CANCELLATION
    -- =====================================================

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
            'Bill seharusnya paid sebelum pembatalan.';
    end if;


    select
        coalesce(
            sum(
                allocation.amount
            ),
            0
        )

    into
        v_paid_amount

    from public.payment_allocations
        as allocation

    inner join public.payments
        as payment
        on payment.id =
           allocation.payment_id

    where allocation.bill_id =
          v_bill_id

      and payment.status =
          'recorded';


    if v_paid_amount <>
       750000
    then
        raise exception
            'Paid amount sebelum cancel harus Rp750.000.';
    end if;


    raise notice
        'PRE-CANCELLATION PAID BILL SUCCESS';


    -- =====================================================
    -- I. CANCEL PAYMENT A
    -- =====================================================

    v_result :=
        public.cancel_bendahara_payment(
            p_payment_id =>
                v_payment_1_id,

            p_cancellation_reason =>
                'Salah input pembayaran verification'
        );


    if (
        v_result
        ->> 'success'
    )::boolean <>
       true
    then
        raise exception
            'Response cancellation success bukan true.';
    end if;


    if (
        v_result
        #>> '{payment,status}'
    ) <> 'cancelled'
    then
        raise exception
            'Response status payment bukan cancelled.';
    end if;


    if (
        v_result
        #>> '{payment,historical_allocated_amount}'
    )::numeric <>
       300000
    then
        raise exception
            'Historical allocated amount harus Rp300.000.';
    end if;


    if (
        v_result
        ->> 'affected_bill_count'
    )::integer <>
       1
    then
        raise exception
            'Affected bill count seharusnya 1.';
    end if;


    if jsonb_array_length(
        v_result -> 'affected_bills'
    ) <> 1
    then
        raise exception
            'Affected bills harus berisi 1 tagihan.';
    end if;


    if (
        v_result
        #>> '{affected_bills,0,id}'
    )::uuid <>
       v_bill_id
    then
        raise exception
            'Affected bill ID salah.';
    end if;


    if (
        v_result
        #>> '{affected_bills,0,status}'
    ) <> 'partial'
    then
        raise exception
            'Affected bill seharusnya menjadi partial.';
    end if;


    if (
        v_result
        #>> '{affected_bills,0,paid_amount}'
    )::numeric <>
       450000
    then
        raise exception
            'Affected bill paid amount seharusnya Rp450.000.';
    end if;


    if (
        v_result
        #>> '{affected_bills,0,outstanding_amount}'
    )::numeric <>
       300000
    then
        raise exception
            'Affected bill outstanding seharusnya Rp300.000.';
    end if;


    raise notice
        'PAYMENT CANCELLATION RESPONSE SUCCESS';


    -- =====================================================
    -- J. PAYMENT DATABASE
    -- =====================================================

    select
        payment.status

    into
        v_payment_status

    from public.payments
        as payment

    where payment.id =
          v_payment_1_id;


    if v_payment_status <>
       'cancelled'
    then
        raise exception
            'Payment A database bukan cancelled.';
    end if;


    if not exists (
        select 1

        from public.payments
            as payment

        where payment.id =
              v_payment_1_id

          and payment.cancelled_at
              is not null

          and payment.cancelled_by_staff_id =
              v_bendahara_staff_id

          and payment.cancellation_reason =
              'Salah input pembayaran verification'
    ) then
        raise exception
            'Audit cancellation payment tidak lengkap.';
    end if;


    raise notice
        'PAYMENT CANCELLATION DATABASE SUCCESS';


    -- =====================================================
    -- K. ALLOCATION MUST REMAIN
    -- =====================================================

    if not exists (
        select 1

        from public.payment_allocations
            as allocation

        where allocation.id =
              v_allocation_1_id

          and allocation.payment_id =
              v_payment_1_id

          and allocation.bill_id =
              v_bill_id

          and allocation.amount =
              300000
    ) then
        raise exception
            'Allocation payment yang dibatalkan hilang.';
    end if;


    raise notice
        'CANCELLED PAYMENT ALLOCATION PRESERVED SUCCESS';


    -- =====================================================
    -- L. BILL DATABASE MUST RECALCULATE
    -- =====================================================

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
            'Bill setelah cancellation harus partial.';
    end if;


    select
        coalesce(
            sum(
                allocation.amount
            ),
            0
        )

    into
        v_paid_amount

    from public.payment_allocations
        as allocation

    inner join public.payments
        as payment
        on payment.id =
           allocation.payment_id

    where allocation.bill_id =
          v_bill_id

      and payment.status =
          'recorded';


    v_outstanding_amount :=
        750000 -
        v_paid_amount;


    if v_paid_amount <>
       450000
    then
        raise exception
            'Paid amount setelah cancellation harus Rp450.000.';
    end if;


    if v_outstanding_amount <>
       300000
    then
        raise exception
            'Outstanding setelah cancellation harus Rp300.000.';
    end if;


    raise notice
        'BILL RECALCULATION AFTER CANCELLATION SUCCESS';


    -- =====================================================
    -- M. BILL DETAIL INTEGRATION
    -- =====================================================

    v_detail :=
        public.get_bendahara_bill_detail(
            v_bill_id
        );


    if (
        v_detail
        #>> '{bill,status}'
    ) <> 'partial'
    then
        raise exception
            'Detail RPC status bill tidak partial.';
    end if;


    if (
        v_detail
        #>> '{summary,paid_amount}'
    )::numeric <>
       450000
    then
        raise exception
            'Detail RPC paid amount salah.';
    end if;


    if (
        v_detail
        #>> '{summary,outstanding_amount}'
    )::numeric <>
       300000
    then
        raise exception
            'Detail RPC outstanding amount salah.';
    end if;


    if (
        v_detail
        #>> '{summary,payment_count}'
    )::integer <>
       2
    then
        raise exception
            'Detail RPC payment_count harus tetap 2.';
    end if;


    if (
        v_detail
        #>> '{summary,recorded_payment_count}'
    )::integer <>
       1
    then
        raise exception
            'Detail RPC recorded payment count harus 1.';
    end if;


    if (
        v_detail
        #>> '{summary,cancelled_payment_count}'
    )::integer <>
       1
    then
        raise exception
            'Detail RPC cancelled payment count harus 1.';
    end if;


    raise notice
        'CANCELLED PAYMENT BILL DETAIL INTEGRATION SUCCESS';


    -- =====================================================
    -- N. PAYMENT HISTORY INTEGRATION
    -- =====================================================

    v_history :=
        public.get_bendahara_payment_history(
            'VERIFY-CANCEL-A-' ||
            v_suffix,

            null,
            null,
            1,
            20
        );


    if (
        v_history
        #>> '{summary,filtered_count}'
    )::integer <>
       1
    then
        raise exception
            'Cancelled payment tidak ditemukan di payment history.';
    end if;


    v_item :=
        v_history
        -> 'items'
        -> 0;


    if (
        v_item
        ->> 'id'
    )::uuid <>
       v_payment_1_id
    then
        raise exception
            'Payment history mengembalikan payment yang salah.';
    end if;


    if (
        v_item
        ->> 'status'
    ) <> 'cancelled'
    then
        raise exception
            'Payment history status bukan cancelled.';
    end if;


    if (
        v_item
        ->> 'historical_allocated_amount'
    )::numeric <>
       300000
    then
        raise exception
            'Payment history historical allocation salah.';
    end if;


    if (
        v_item
        ->> 'allocated_amount'
    )::numeric <>
       0
    then
        raise exception
            'Cancelled payment active allocated amount harus 0.';
    end if;


    if jsonb_array_length(
        v_item -> 'allocations'
    ) <> 1
    then
        raise exception
            'Historical allocation tidak tersedia di payment history.';
    end if;


    raise notice
        'CANCELLED PAYMENT HISTORY INTEGRATION SUCCESS';


    -- =====================================================
    -- O. DUPLICATE CANCELLATION MUST FAIL
    -- =====================================================

    begin

        perform
            public.cancel_bendahara_payment(
                p_payment_id =>
                    v_payment_1_id,

                p_cancellation_reason =>
                    'Cancel kedua'
            );


        raise exception
            'EXPECTED_DUPLICATE_CANCEL_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_DUPLICATE_CANCEL_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%sudah dibatalkan sebelumnya%'
            then
                raise;
            end if;

    end;


    raise notice
        'DUPLICATE PAYMENT CANCELLATION PROTECTION SUCCESS';


    -- =====================================================
    -- P. EMPTY REASON MUST FAIL
    -- =====================================================

    begin

        perform
            public.cancel_bendahara_payment(
                p_payment_id =>
                    v_payment_2_id,

                p_cancellation_reason =>
                    '   '
            );


        raise exception
            'EXPECTED_EMPTY_REASON_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_EMPTY_REASON_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Alasan pembatalan pembayaran wajib diisi%'
            then
                raise;
            end if;

    end;


    raise notice
        'EMPTY CANCELLATION REASON PROTECTION SUCCESS';


    -- =====================================================
    -- Q. UNKNOWN PAYMENT MUST FAIL
    -- =====================================================

    begin

        perform
            public.cancel_bendahara_payment(
                p_payment_id =>
                    gen_random_uuid(),

                p_cancellation_reason =>
                    'Unknown payment verification'
            );


        raise exception
            'EXPECTED_UNKNOWN_PAYMENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_UNKNOWN_PAYMENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Pembayaran tidak ditemukan%'
            then
                raise;
            end if;

    end;


    raise notice
        'UNKNOWN PAYMENT CANCELLATION PROTECTION SUCCESS';


    -- =====================================================
    -- R. NON-BENDAHARA
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_non_bendahara_profile_id,
        v_non_bendahara_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user
        on auth_user.id =
           profile.id

    where profile.is_active =
          true

      and not exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'bendahara'

            and role.is_active =
                true
      )

    order by
        profile.created_at,
        profile.id

    limit 1;


    if v_non_bendahara_profile_id is null then
        raise exception
            'Akun non-Bendahara untuk verification tidak ditemukan.';
    end if;


    perform set_config(
        'request.jwt.claim.sub',
        v_non_bendahara_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_non_bendahara_profile_id,

            'role',
            'authenticated',

            'email',
            v_non_bendahara_email
        )::text,
        true
    );


    begin

        perform
            public.cancel_bendahara_payment(
                p_payment_id =>
                    v_payment_2_id,

                p_cancellation_reason =>
                    'Unauthorized cancellation'
            );


        raise exception
            'EXPECTED_NON_BENDAHARA_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_BENDAHARA_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses pembatalan pembayaran Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA PAYMENT CANCELLATION PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'BENDAHARA PAYMENT CANCELLATION VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Pembatalan Pembayaran Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;