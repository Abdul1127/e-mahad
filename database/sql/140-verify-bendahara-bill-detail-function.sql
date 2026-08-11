-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 140-verify-bendahara-bill-detail-function.sql
--
-- PURPOSE:
-- Verification get_bendahara_bill_detail()
--
-- TEST:
-- - function exists
-- - privilege
-- - unpaid detail
-- - partial payment detail
-- - payment history
-- - amount calculation
-- - can_record_payment
-- - can_cancel
-- - unknown bill protection
-- - non-Bendahara protection
--
-- Semua data verification di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FUNCTION
-- =========================================================

select
    to_regprocedure(
        'public.get_bendahara_bill_detail(uuid)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_bendahara_bill_detail(uuid)',
        'execute'
    )
        as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_bendahara_bill_detail(uuid)',
        'execute'
    )
        as anon_can_execute;


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
    v_payment_id uuid;

    v_result jsonb;

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
    -- B. CURRENT YEAR
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
    -- C. STUDENT
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
    -- D. CREATE BILL
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
        'VERIFY-DETAIL-' || v_suffix,
        'Verification Detail Tagihan',
        'verification',
        'Agustus 2026',
        1000000,
        current_date + 10,
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_id;


    -- =====================================================
    -- E. UNPAID DETAIL
    -- =====================================================

    v_result :=
        public.get_bendahara_bill_detail(
            v_bill_id
        );


    if (
        v_result
        #>> '{bill,id}'
    )::uuid <>
       v_bill_id
    then
        raise exception
            'Bill ID detail salah.';
    end if;


    if (
        v_result
        #>> '{bill,status}'
    ) <> 'unpaid'
    then
        raise exception
            'Bill baru seharusnya unpaid.';
    end if;


    if (
        v_result
        #>> '{summary,bill_amount}'
    )::numeric <>
       1000000
    then
        raise exception
            'Bill amount salah.';
    end if;


    if (
        v_result
        #>> '{summary,paid_amount}'
    )::numeric <>
       0
    then
        raise exception
            'Paid amount bill baru seharusnya 0.';
    end if;


    if (
        v_result
        #>> '{summary,outstanding_amount}'
    )::numeric <>
       1000000
    then
        raise exception
            'Outstanding bill baru salah.';
    end if;


    if (
        v_result
        #>> '{bill,can_record_payment}'
    )::boolean <>
       true
    then
        raise exception
            'Unpaid bill seharusnya dapat menerima pembayaran.';
    end if;


    if (
        v_result
        #>> '{bill,can_cancel}'
    )::boolean <>
       true
    then
        raise exception
            'Bill tanpa pembayaran seharusnya bisa dibatalkan.';
    end if;


    raise notice
        'UNPAID BILL DETAIL SUCCESS';


    -- =====================================================
    -- F. CREATE PAYMENT 400K
    -- =====================================================

    insert into public.payments (
        academic_year_id,
        student_id,
        payment_code,
        payment_date,
        amount,
        payment_method,
        reference_number,
        notes,
        recorded_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_id,
        'VERIFY-DETAIL-PAY-' ||
            v_suffix,
        current_date,
        400000,
        'transfer',
        'VERIFY-REF',
        'Verification payment detail',
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
        v_bill_id,
        400000,
        v_bendahara_staff_id
    );


    -- =====================================================
    -- G. PARTIAL DETAIL
    -- =====================================================

    v_result :=
        public.get_bendahara_bill_detail(
            v_bill_id
        );


    if (
        v_result
        #>> '{bill,status}'
    ) <> 'partial'
    then
        raise exception
            'Bill harus menjadi partial.';
    end if;


    if (
        v_result
        #>> '{summary,paid_amount}'
    )::numeric <>
       400000
    then
        raise exception
            'Paid amount harus Rp400.000.';
    end if;


    if (
        v_result
        #>> '{summary,outstanding_amount}'
    )::numeric <>
       600000
    then
        raise exception
            'Outstanding harus Rp600.000.';
    end if;


    if (
        v_result
        #>> '{summary,payment_count}'
    )::integer <>
       1
    then
        raise exception
            'Payment count harus 1.';
    end if;


    if (
        v_result
        #>> '{summary,recorded_payment_count}'
    )::integer <>
       1
    then
        raise exception
            'Recorded payment count harus 1.';
    end if;


    if jsonb_array_length(
        v_result -> 'payments'
    ) <> 1
    then
        raise exception
            'Payment history harus berisi 1 item.';
    end if;


    if (
        (
            v_result
            -> 'payments'
            -> 0
            ->> 'allocation_amount'
        )::numeric
    ) <> 400000
    then
        raise exception
            'Allocation amount salah.';
    end if;


    if (
        v_result
        #>> '{bill,can_record_payment}'
    )::boolean <>
       true
    then
        raise exception
            'Partial bill masih harus bisa menerima pembayaran.';
    end if;


    if (
        v_result
        #>> '{bill,can_cancel}'
    )::boolean <>
       false
    then
        raise exception
            'Bill yang sudah memiliki pembayaran aktif tidak boleh dibatalkan.';
    end if;


    raise notice
        'PARTIAL BILL DETAIL SUCCESS';


    raise notice
        'PAYMENT HISTORY DETAIL SUCCESS';


    -- =====================================================
    -- H. UNKNOWN BILL
    -- =====================================================

    begin

        perform
            public.get_bendahara_bill_detail(
                gen_random_uuid()
            );


        raise exception
            'EXPECTED_UNKNOWN_BILL_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_UNKNOWN_BILL_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Tagihan tidak ditemukan%'
            then
                raise;
            end if;

    end;


    raise notice
        'UNKNOWN BILL PROTECTION SUCCESS';


    -- =====================================================
    -- I. NON-BENDAHARA
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
            'Akun non-Bendahara tidak ditemukan.';
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
            public.get_bendahara_bill_detail(
                v_bill_id
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
               '%Akses Detail Tagihan Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA BILL DETAIL PROTECTION SUCCESS';


    raise notice
        'BENDAHARA BILL DETAIL VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Detail Tagihan Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;