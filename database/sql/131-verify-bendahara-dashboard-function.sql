-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 131-verify-bendahara-dashboard-function.sql
--
-- PURPOSE:
-- Verification get_bendahara_dashboard()
--
-- TEST:
-- - Function exists
-- - Privileges
-- - Bendahara access
-- - Financial summary
-- - Partial bill
-- - Overdue bill
-- - Recent payment
-- - Non-Bendahara rejected
--
-- Semua test data di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_bendahara_dashboard()'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_bendahara_dashboard()',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_bendahara_dashboard()',
        'execute'
    ) as anon_can_execute;


-- =========================================================
-- 2. TRANSACTION
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

    v_bill_partial_id uuid;
    v_bill_overdue_id uuid;

    v_payment_id uuid;

    v_suffix text;

    v_before jsonb;
    v_after jsonb;

    v_before_active integer;
    v_before_unpaid integer;
    v_before_partial integer;
    v_before_paid integer;
    v_before_overdue integer;

    v_before_billed numeric;
    v_before_paid_amount numeric;
    v_before_outstanding numeric;

    v_before_payment_count integer;
    v_before_payment_amount numeric;

    v_after_active integer;
    v_after_unpaid integer;
    v_after_partial integer;
    v_after_paid integer;
    v_after_overdue integer;

    v_after_billed numeric;
    v_after_paid_amount numeric;
    v_after_outstanding numeric;

    v_after_payment_count integer;
    v_after_payment_amount numeric;
begin

    v_suffix :=
        replace(
            gen_random_uuid()::text,
            '-',
            ''
        );


    -- =====================================================
    -- A. OPERATIONAL BENDAHARA
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
    -- E. BASELINE DASHBOARD
    -- =====================================================

    v_before :=
        public.get_bendahara_dashboard();


    v_before_active :=
        (
            v_before
            #>> '{summary,active_bill_count}'
        )::integer;


    v_before_unpaid :=
        (
            v_before
            #>> '{summary,unpaid_count}'
        )::integer;


    v_before_partial :=
        (
            v_before
            #>> '{summary,partial_count}'
        )::integer;


    v_before_paid :=
        (
            v_before
            #>> '{summary,paid_count}'
        )::integer;


    v_before_overdue :=
        (
            v_before
            #>> '{summary,overdue_count}'
        )::integer;


    v_before_billed :=
        (
            v_before
            #>> '{summary,billed_amount}'
        )::numeric;


    v_before_paid_amount :=
        (
            v_before
            #>> '{summary,paid_amount}'
        )::numeric;


    v_before_outstanding :=
        (
            v_before
            #>> '{summary,outstanding_amount}'
        )::numeric;


    v_before_payment_count :=
        (
            v_before
            #>> '{summary,payment_count_this_month}'
        )::integer;


    v_before_payment_amount :=
        (
            v_before
            #>> '{summary,payment_amount_this_month}'
        )::numeric;


    raise notice
        'BENDAHARA BASELINE SUCCESS';


    -- =====================================================
    -- F. CREATE BILL A = 1,000,000
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
        'VERIFY-DASH-BILL-A-' || v_suffix,
        'Verification Dashboard A',
        'verification',
        'Verification A',
        1000000,
        current_date + 10,
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_partial_id;


    -- =====================================================
    -- G. PAYMENT = 400,000
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
        v_student_id,
        'VERIFY-DASH-PAY-' || v_suffix,
        current_date,
        400000,
        'transfer',
        'VERIFY-DASHBOARD',
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_payment_id;


    insert into public.payment_allocations (
        payment_id,
        bill_id,
        amount,
        created_by_staff_id
    )
    values (
        v_payment_id,
        v_bill_partial_id,
        400000,
        v_bendahara_staff_id
    );


    -- =====================================================
    -- H. CREATE OVERDUE BILL = 500,000
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
        'VERIFY-DASH-BILL-B-' || v_suffix,
        'Verification Dashboard Overdue',
        'verification',
        'Verification B',
        500000,
        current_date - 1,
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_overdue_id;


    -- =====================================================
    -- I. AFTER DASHBOARD
    -- =====================================================

    v_after :=
        public.get_bendahara_dashboard();


    v_after_active :=
        (
            v_after
            #>> '{summary,active_bill_count}'
        )::integer;


    v_after_unpaid :=
        (
            v_after
            #>> '{summary,unpaid_count}'
        )::integer;


    v_after_partial :=
        (
            v_after
            #>> '{summary,partial_count}'
        )::integer;


    v_after_paid :=
        (
            v_after
            #>> '{summary,paid_count}'
        )::integer;


    v_after_overdue :=
        (
            v_after
            #>> '{summary,overdue_count}'
        )::integer;


    v_after_billed :=
        (
            v_after
            #>> '{summary,billed_amount}'
        )::numeric;


    v_after_paid_amount :=
        (
            v_after
            #>> '{summary,paid_amount}'
        )::numeric;


    v_after_outstanding :=
        (
            v_after
            #>> '{summary,outstanding_amount}'
        )::numeric;


    v_after_payment_count :=
        (
            v_after
            #>> '{summary,payment_count_this_month}'
        )::integer;


    v_after_payment_amount :=
        (
            v_after
            #>> '{summary,payment_amount_this_month}'
        )::numeric;


    -- =====================================================
    -- J. COUNTS
    -- =====================================================

    if v_after_active <>
       v_before_active + 2
    then
        raise exception
            'Active bill count gagal. Before %, After %.',
            v_before_active,
            v_after_active;
    end if;


    if v_after_unpaid <>
       v_before_unpaid + 1
    then
        raise exception
            'Unpaid count gagal.';
    end if;


    if v_after_partial <>
       v_before_partial + 1
    then
        raise exception
            'Partial count gagal.';
    end if;


    if v_after_paid <>
       v_before_paid
    then
        raise exception
            'Paid count berubah tidak semestinya.';
    end if;


    if v_after_overdue <>
       v_before_overdue + 1
    then
        raise exception
            'Overdue count gagal.';
    end if;


    raise notice
        'BILL SUMMARY COUNTS SUCCESS';


    -- =====================================================
    -- K. AMOUNTS
    -- =====================================================

    if v_after_billed <>
       v_before_billed +
       1500000
    then
        raise exception
            'Billed amount gagal. Before %, After %.',
            v_before_billed,
            v_after_billed;
    end if;


    if v_after_paid_amount <>
       v_before_paid_amount +
       400000
    then
        raise exception
            'Paid amount gagal. Before %, After %.',
            v_before_paid_amount,
            v_after_paid_amount;
    end if;


    if v_after_outstanding <>
       v_before_outstanding +
       1100000
    then
        raise exception
            'Outstanding amount gagal. Before %, After %.',
            v_before_outstanding,
            v_after_outstanding;
    end if;


    raise notice
        'BILL SUMMARY AMOUNTS SUCCESS';


    -- =====================================================
    -- L. MONTHLY PAYMENT
    -- =====================================================

    if v_after_payment_count <>
       v_before_payment_count + 1
    then
        raise exception
            'Payment count bulan berjalan gagal.';
    end if;


    if v_after_payment_amount <>
       v_before_payment_amount +
       400000
    then
        raise exception
            'Payment amount bulan berjalan gagal.';
    end if;


    raise notice
        'MONTHLY PAYMENT SUMMARY SUCCESS';


    -- =====================================================
    -- M. OVERDUE ITEM MUST EXIST
    -- =====================================================

    if not exists (
        select 1

        from jsonb_array_elements(
            v_after -> 'overdue_bills'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_bill_overdue_id
    ) then
        raise exception
            'Tagihan overdue verification tidak muncul di dashboard.';
    end if;


    raise notice
        'OVERDUE BILL LIST SUCCESS';


    -- =====================================================
    -- N. RECENT PAYMENT MUST EXIST
    -- =====================================================

    if not exists (
        select 1

        from jsonb_array_elements(
            v_after -> 'recent_payments'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_payment_id
    ) then
        raise exception
            'Pembayaran verification tidak muncul di recent payments.';
    end if;


    raise notice
        'RECENT PAYMENT LIST SUCCESS';


    -- =====================================================
    -- O. NON-BENDAHARA
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
            'Akun non-Bendahara untuk security test tidak ditemukan.';
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
            public.get_bendahara_dashboard();


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
               '%Akses Dashboard Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'BENDAHARA DASHBOARD VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Dashboard Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;