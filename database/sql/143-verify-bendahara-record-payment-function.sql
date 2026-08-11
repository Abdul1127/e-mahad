-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 143-verify-bendahara-record-payment-function.sql
--
-- PURPOSE:
-- Verification record_bendahara_bill_payment()
--
-- TEST:
--
-- - Function exists
-- - Authenticated execute
-- - Anon denied
-- - Partial payment
-- - Bill auto becomes partial
-- - Second payment
-- - Bill auto becomes paid
-- - Payment stored
-- - Allocation stored
-- - Detail RPC integration
-- - Dashboard foundation integration
-- - Overpayment protection
-- - Paid bill protection
-- - Future payment date protection
-- - Invalid payment method
-- - Cancelled bill protection
-- - Non-Bendahara protection
--
-- TEST DATA:
-- transaction + rollback
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.record_bendahara_bill_payment(uuid,date,numeric,text,text,text)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.record_bendahara_bill_payment(uuid,date,numeric,text,text,text)',
        'execute'
    )
        as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.record_bendahara_bill_payment(uuid,date,numeric,text,text,text)',
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
    v_cancelled_bill_id uuid;

    v_payment_1_id uuid;
    v_payment_2_id uuid;

    v_result jsonb;
    v_detail jsonb;

    v_bill_status text;

    v_paid_amount numeric;
    v_outstanding_amount numeric;

    v_payment_count integer;
    v_allocation_count integer;

    v_suffix text;
begin

    v_suffix :=
        replace(
            gen_random_uuid()::text,
            '-',
            ''
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
    -- B. LOGIN BENDAHARA
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
    -- C. CURRENT YEAR
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

        period_label,

        amount,
        due_date,

        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_id,

        'VERIFY-PAY-BILL-' ||
            v_suffix,

        'Verification Payment Bill',

        'verification',

        'Agustus 2026',

        750000,

        current_date + 10,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_id;


    -- =====================================================
    -- F. FIRST PAYMENT = 300K
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
                'TRANSFER',

            p_reference_number =>
                'VERIFY-PAY-001',

            p_notes =>
                'Pembayaran pertama verification.'
        );


    if (
        v_result
        ->> 'success'
    )::boolean <>
       true
    then
        raise exception
            'Response pembayaran pertama gagal.';
    end if;


    if (
        v_result
        #>> '{payment,payment_method}'
    ) <> 'transfer'
    then
        raise exception
            'Normalisasi metode pembayaran gagal.';
    end if;


    if (
        v_result
        #>> '{bill,status}'
    ) <> 'partial'
    then
        raise exception
            'Tagihan setelah pembayaran pertama seharusnya partial.';
    end if;


    if (
        v_result
        #>> '{bill,paid_amount}'
    )::numeric <>
       300000
    then
        raise exception
            'Paid amount setelah pembayaran pertama salah.';
    end if;


    if (
        v_result
        #>> '{bill,outstanding_amount}'
    )::numeric <>
       450000
    then
        raise exception
            'Outstanding setelah pembayaran pertama harus Rp450.000.';
    end if;


    v_payment_1_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    if v_payment_1_id is null then
        raise exception
            'Payment ID pertama tidak tersedia.';
    end if;


    raise notice
        'FIRST PAYMENT RESPONSE SUCCESS';


    -- =====================================================
    -- G. DATABASE FIRST PAYMENT
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
            'Status database bill tidak menjadi partial.';
    end if;


    if not exists (
        select 1

        from public.payments
            as payment

        where payment.id =
              v_payment_1_id

          and payment.student_id =
              v_student_id

          and payment.amount =
              300000

          and payment.status =
              'recorded'
    ) then
        raise exception
            'Payment pertama tidak tersimpan dengan benar.';
    end if;


    if not exists (
        select 1

        from public.payment_allocations
            as allocation

        where allocation.payment_id =
              v_payment_1_id

          and allocation.bill_id =
              v_bill_id

          and allocation.amount =
              300000
    ) then
        raise exception
            'Allocation pembayaran pertama tidak tersimpan.';
    end if;


    raise notice
        'FIRST PAYMENT DATABASE SUCCESS';


    -- =====================================================
    -- H. DETAIL RPC INTEGRATION
    -- =====================================================

    v_detail :=
        public.get_bendahara_bill_detail(
            v_bill_id
        );


    if (
        v_detail
        #>> '{summary,paid_amount}'
    )::numeric <>
       300000
    then
        raise exception
            'Detail RPC paid amount tidak sinkron.';
    end if;


    if (
        v_detail
        #>> '{summary,outstanding_amount}'
    )::numeric <>
       450000
    then
        raise exception
            'Detail RPC outstanding tidak sinkron.';
    end if;


    if (
        v_detail
        #>> '{summary,payment_count}'
    )::integer <>
       1
    then
        raise exception
            'Detail RPC payment count seharusnya 1.';
    end if;


    raise notice
        'PAYMENT DETAIL INTEGRATION SUCCESS';


    -- =====================================================
    -- I. OVERPAYMENT MUST FAIL
    --
    -- Outstanding tinggal Rp450.000.
    -- Coba bayar Rp500.000.
    -- =====================================================

    begin

        perform
            public.record_bendahara_bill_payment(
                p_bill_id =>
                    v_bill_id,

                p_payment_date =>
                    current_date,

                p_amount =>
                    500000,

                p_payment_method =>
                    'cash'
            );


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
               '%melebihi sisa tagihan%'
            then
                raise;
            end if;

    end;


    raise notice
        'OVERPAYMENT PROTECTION SUCCESS';


    -- =====================================================
    -- J. SECOND PAYMENT = 450K
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
                null,

            p_notes =>
                'Pelunasan verification.'
        );


    v_payment_2_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    if (
        v_result
        #>> '{bill,status}'
    ) <> 'paid'
    then
        raise exception
            'Tagihan setelah pembayaran kedua harus paid.';
    end if;


    if (
        v_result
        #>> '{bill,paid_amount}'
    )::numeric <>
       750000
    then
        raise exception
            'Total paid amount setelah pelunasan salah.';
    end if;


    if (
        v_result
        #>> '{bill,outstanding_amount}'
    )::numeric <>
       0
    then
        raise exception
            'Outstanding setelah pelunasan harus 0.';
    end if;


    raise notice
        'SECOND PAYMENT RESPONSE SUCCESS';


    -- =====================================================
    -- K. FINAL BILL DATABASE
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
            'Bill database harus paid.';
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
            'Total allocation aktif harus Rp750.000.';
    end if;


    v_outstanding_amount :=
        750000 -
        v_paid_amount;


    if v_outstanding_amount <>
       0
    then
        raise exception
            'Outstanding final bukan 0.';
    end if;


    raise notice
        'PAID BILL DATABASE SUCCESS';


    -- =====================================================
    -- L. PAYMENT COUNT
    -- =====================================================

    select
        count(*)::integer

    into
        v_payment_count

    from public.payments
        as payment

    where payment.id in (
        v_payment_1_id,
        v_payment_2_id
    );


    if v_payment_count <>
       2
    then
        raise exception
            'Harus terdapat 2 payment verification.';
    end if;


    select
        count(*)::integer

    into
        v_allocation_count

    from public.payment_allocations
        as allocation

    where allocation.bill_id =
          v_bill_id;


    if v_allocation_count <>
       2
    then
        raise exception
            'Harus terdapat 2 allocation verification.';
    end if;


    raise notice
        'MULTIPLE PAYMENT HISTORY SUCCESS';


    -- =====================================================
    -- M. PAID BILL MUST REJECT MORE PAYMENT
    -- =====================================================

    begin

        perform
            public.record_bendahara_bill_payment(
                p_bill_id =>
                    v_bill_id,

                p_payment_date =>
                    current_date,

                p_amount =>
                    1000,

                p_payment_method =>
                    'cash'
            );


        raise exception
            'EXPECTED_PAID_BILL_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_PAID_BILL_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Tagihan sudah lunas%'
            then
                raise;
            end if;

    end;


    raise notice
        'PAID BILL PAYMENT PROTECTION SUCCESS';


    -- =====================================================
    -- N. FUTURE DATE
    -- =====================================================

    -- Buat bill baru supaya bukan status paid.

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

        'VERIFY-FUTURE-' ||
            v_suffix,

        'Verification Future Date',

        'verification',

        100000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_cancelled_bill_id;


    begin

        perform
            public.record_bendahara_bill_payment(
                p_bill_id =>
                    v_cancelled_bill_id,

                p_payment_date =>
                    current_date + 1,

                p_amount =>
                    100000,

                p_payment_method =>
                    'transfer'
            );


        raise exception
            'EXPECTED_FUTURE_DATE_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_FUTURE_DATE_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%tidak boleh melebihi hari ini%'
            then
                raise;
            end if;

    end;


    raise notice
        'FUTURE PAYMENT DATE PROTECTION SUCCESS';


    -- =====================================================
    -- O. INVALID METHOD
    -- =====================================================

    begin

        perform
            public.record_bendahara_bill_payment(
                p_bill_id =>
                    v_cancelled_bill_id,

                p_payment_date =>
                    current_date,

                p_amount =>
                    100000,

                p_payment_method =>
                    'bitcoin'
            );


        raise exception
            'EXPECTED_INVALID_METHOD_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INVALID_METHOD_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Metode pembayaran tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID PAYMENT METHOD PROTECTION SUCCESS';


    -- =====================================================
    -- P. CANCEL BILL
    -- =====================================================

    update public.student_bills
    set
        status =
            'cancelled',

        cancelled_at =
            now(),

        cancelled_by_staff_id =
            v_bendahara_staff_id,

        cancellation_reason =
            'Verification cancelled bill',

        updated_by_staff_id =
            v_bendahara_staff_id

    where id =
          v_cancelled_bill_id;


    begin

        perform
            public.record_bendahara_bill_payment(
                p_bill_id =>
                    v_cancelled_bill_id,

                p_payment_date =>
                    current_date,

                p_amount =>
                    100000,

                p_payment_method =>
                    'cash'
            );


        raise exception
            'EXPECTED_CANCELLED_BILL_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_CANCELLED_BILL_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%dibatalkan tidak dapat menerima pembayaran%'
            then
                raise;
            end if;

    end;


    raise notice
        'CANCELLED BILL PAYMENT PROTECTION SUCCESS';


    -- =====================================================
    -- Q. NON-BENDAHARA
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
            public.record_bendahara_bill_payment(
                p_bill_id =>
                    v_bill_id,

                p_payment_date =>
                    current_date,

                p_amount =>
                    1000,

                p_payment_method =>
                    'cash'
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
               '%Akses pencatatan pembayaran Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA PAYMENT PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'BENDAHARA PAYMENT VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Pencatatan Pembayaran Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;