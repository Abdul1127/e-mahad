-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 146-verify-bendahara-payment-history-function.sql
--
-- PURPOSE:
-- Verification get_bendahara_payment_history()
--
-- TEST:
-- - Function exists
-- - Privileges
-- - Recorded payment appears
-- - Cancelled payment appears
-- - Cancelled payment excluded from active amount
-- - Search reference
-- - Status filter
-- - Method filter
-- - Allocation information
-- - Pagination
-- - Invalid filters rejected
-- - Non-Bendahara rejected
--
-- Semua data verification di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_bendahara_payment_history(text,text,text,integer,integer)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_bendahara_payment_history(text,text,text,integer,integer)',
        'execute'
    )
        as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_bendahara_payment_history(text,text,text,integer,integer)',
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

    v_bill_1_id uuid;
    v_bill_2_id uuid;

    v_payment_1_id uuid;
    v_payment_2_id uuid;

    v_suffix text;

    v_before jsonb;
    v_after jsonb;

    v_search_result jsonb;
    v_recorded_result jsonb;
    v_cancelled_result jsonb;
    v_transfer_result jsonb;
    v_cash_result jsonb;
    v_page_result jsonb;

    v_item jsonb;

    v_before_total integer;
    v_before_recorded integer;
    v_before_cancelled integer;

    v_before_recorded_amount numeric;
    v_before_allocated_amount numeric;
    v_before_unallocated_amount numeric;

    v_after_total integer;
    v_after_recorded integer;
    v_after_cancelled integer;

    v_after_recorded_amount numeric;
    v_after_allocated_amount numeric;
    v_after_unallocated_amount numeric;

    v_found boolean;
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
    -- D. STUDENT
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
    -- E. BASELINE
    -- =====================================================

    v_before :=
        public.get_bendahara_payment_history(
            null,
            null,
            null,
            1,
            100
        );


    v_before_total :=
        (
            v_before
            #>> '{summary,total_count}'
        )::integer;


    v_before_recorded :=
        (
            v_before
            #>> '{summary,recorded_count}'
        )::integer;


    v_before_cancelled :=
        (
            v_before
            #>> '{summary,cancelled_count}'
        )::integer;


    v_before_recorded_amount :=
        (
            v_before
            #>> '{summary,recorded_amount}'
        )::numeric;


    v_before_allocated_amount :=
        (
            v_before
            #>> '{summary,active_allocated_amount}'
        )::numeric;


    v_before_unallocated_amount :=
        (
            v_before
            #>> '{summary,unallocated_amount}'
        )::numeric;


    raise notice
        'PAYMENT HISTORY BASELINE SUCCESS';


    -- =====================================================
    -- F. BILL 1
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

        'VERIFY-HISTORY-BILL-1-' ||
            v_suffix,

        'Verification History Bill 1',

        'verification',

        500000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_1_id;


    -- =====================================================
    -- G. RECORDED PAYMENT = 300K / TRANSFER
    -- =====================================================

    v_item :=
        public.record_bendahara_bill_payment(
            p_bill_id =>
                v_bill_1_id,

            p_payment_date =>
                current_date,

            p_amount =>
                300000,

            p_payment_method =>
                'transfer',

            p_reference_number =>
                'HIST-' ||
                v_suffix ||
                '-A',

            p_notes =>
                'Recorded history verification'
        );


    v_payment_1_id :=
        (
            v_item
            #>> '{payment,id}'
        )::uuid;


    if v_payment_1_id is null then
        raise exception
            'Payment verification pertama tidak dibuat.';
    end if;


    -- =====================================================
    -- H. BILL 2
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

        'VERIFY-HISTORY-BILL-2-' ||
            v_suffix,

        'Verification History Bill 2',

        'verification',

        250000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_2_id;


    -- =====================================================
    -- I. PAYMENT 2 = 250K / CASH
    -- =====================================================

    v_item :=
        public.record_bendahara_bill_payment(
            p_bill_id =>
                v_bill_2_id,

            p_payment_date =>
                current_date,

            p_amount =>
                250000,

            p_payment_method =>
                'cash',

            p_reference_number =>
                'HIST-' ||
                v_suffix ||
                '-B',

            p_notes =>
                'Cancelled history verification'
        );


    v_payment_2_id :=
        (
            v_item
            #>> '{payment,id}'
        )::uuid;


    if v_payment_2_id is null then
        raise exception
            'Payment verification kedua tidak dibuat.';
    end if;


    -- =====================================================
    -- J. CANCEL PAYMENT 2
    --
    -- RPC pembatalan belum kita buat.
    -- Untuk verification foundation, status diubah langsung.
    -- =====================================================

    update public.payments
    set
        status =
            'cancelled',

        cancelled_at =
            now(),

        cancelled_by_staff_id =
            v_bendahara_staff_id,

        cancellation_reason =
            'Verification cancellation',

        updated_by_staff_id =
            v_bendahara_staff_id

    where id =
          v_payment_2_id;


    -- Trigger dari Finance Foundation akan menghitung ulang
    -- status Bill 2 menjadi unpaid.


    -- =====================================================
    -- K. GLOBAL SUMMARY AFTER
    -- =====================================================

    v_after :=
        public.get_bendahara_payment_history(
            null,
            null,
            null,
            1,
            100
        );


    v_after_total :=
        (
            v_after
            #>> '{summary,total_count}'
        )::integer;


    v_after_recorded :=
        (
            v_after
            #>> '{summary,recorded_count}'
        )::integer;


    v_after_cancelled :=
        (
            v_after
            #>> '{summary,cancelled_count}'
        )::integer;


    v_after_recorded_amount :=
        (
            v_after
            #>> '{summary,recorded_amount}'
        )::numeric;


    v_after_allocated_amount :=
        (
            v_after
            #>> '{summary,active_allocated_amount}'
        )::numeric;


    v_after_unallocated_amount :=
        (
            v_after
            #>> '{summary,unallocated_amount}'
        )::numeric;


    if v_after_total <>
       v_before_total + 2
    then
        raise exception
            'Total payment count gagal. Before %, After %.',
            v_before_total,
            v_after_total;
    end if;


    if v_after_recorded <>
       v_before_recorded + 1
    then
        raise exception
            'Recorded payment count gagal.';
    end if;


    if v_after_cancelled <>
       v_before_cancelled + 1
    then
        raise exception
            'Cancelled payment count gagal.';
    end if;


    if v_after_recorded_amount <>
       v_before_recorded_amount +
       300000
    then
        raise exception
            'Recorded amount gagal.';
    end if;


    if v_after_allocated_amount <>
       v_before_allocated_amount +
       300000
    then
        raise exception
            'Active allocated amount gagal.';
    end if;


    if v_after_unallocated_amount <>
       v_before_unallocated_amount
    then
        raise exception
            'Unallocated amount berubah tidak semestinya.';
    end if;


    raise notice
        'PAYMENT HISTORY SUMMARY SUCCESS';


    -- =====================================================
    -- L. BOTH ITEMS MUST APPEAR
    -- =====================================================

    if not exists (
        select 1

        from jsonb_array_elements(
            v_after -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_payment_1_id
    ) then
        raise exception
            'Recorded payment tidak muncul di history.';
    end if;


    if not exists (
        select 1

        from jsonb_array_elements(
            v_after -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_payment_2_id
    ) then
        raise exception
            'Cancelled payment tidak muncul di history.';
    end if;


    raise notice
        'PAYMENT HISTORY ITEMS SUCCESS';


    -- =====================================================
    -- M. SEARCH BY REFERENCE
    -- =====================================================

    v_search_result :=
        public.get_bendahara_payment_history(
            'HIST-' ||
            v_suffix ||
            '-A',

            null,
            null,
            1,
            20
        );


    if (
        v_search_result
        #>> '{summary,filtered_count}'
    )::integer <>
       1
    then
        raise exception
            'Search reference number gagal.';
    end if;


    if (
        v_search_result
        -> 'items'
        -> 0
        ->> 'id'
    )::uuid <>
       v_payment_1_id
    then
        raise exception
            'Search mengembalikan payment yang salah.';
    end if;


    raise notice
        'PAYMENT HISTORY SEARCH SUCCESS';


    -- =====================================================
    -- N. RECORDED FILTER
    -- =====================================================

    v_recorded_result :=
        public.get_bendahara_payment_history(
            null,
            'recorded',
            null,
            1,
            100
        );


    v_found :=
        false;


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_recorded_result -> 'items'
        )

    loop

        if (
            v_item
            ->> 'status'
        ) <> 'recorded'
        then
            raise exception
                'Filter recorded menghasilkan status lain.';
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_payment_1_id
        then
            v_found :=
                true;
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_payment_2_id
        then
            raise exception
                'Cancelled payment bocor ke filter recorded.';
        end if;

    end loop;


    if not v_found then
        raise exception
            'Recorded verification payment tidak ditemukan.';
    end if;


    raise notice
        'RECORDED PAYMENT FILTER SUCCESS';


    -- =====================================================
    -- O. CANCELLED FILTER
    -- =====================================================

    v_cancelled_result :=
        public.get_bendahara_payment_history(
            null,
            'cancelled',
            null,
            1,
            100
        );


    v_found :=
        false;


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_cancelled_result -> 'items'
        )

    loop

        if (
            v_item
            ->> 'status'
        ) <> 'cancelled'
        then
            raise exception
                'Filter cancelled menghasilkan status lain.';
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_payment_2_id
        then
            v_found :=
                true;
        end if;

    end loop;


    if not v_found then
        raise exception
            'Cancelled verification payment tidak ditemukan.';
    end if;


    raise notice
        'CANCELLED PAYMENT FILTER SUCCESS';


    -- =====================================================
    -- P. TRANSFER METHOD FILTER
    -- =====================================================

    v_transfer_result :=
        public.get_bendahara_payment_history(
            null,
            null,
            'transfer',
            1,
            100
        );


    v_found :=
        false;


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_transfer_result -> 'items'
        )

    loop

        if (
            v_item
            ->> 'payment_method'
        ) <> 'transfer'
        then
            raise exception
                'Filter transfer menghasilkan metode lain.';
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_payment_1_id
        then
            v_found :=
                true;
        end if;

    end loop;


    if not v_found then
        raise exception
            'Transfer verification payment tidak ditemukan.';
    end if;


    raise notice
        'PAYMENT METHOD FILTER SUCCESS';


    -- =====================================================
    -- Q. CANCELLED PAYMENT ALLOCATION
    --
    -- Historical allocation tetap 250K,
    -- tetapi allocated_amount aktif harus 0.
    -- =====================================================

    select
        item.value

    into
        v_item

    from jsonb_array_elements(
        v_cancelled_result -> 'items'
    ) as item(value)

    where (
        item.value
        ->> 'id'
    )::uuid =
          v_payment_2_id

    limit 1;


    if (
        v_item
        ->> 'historical_allocated_amount'
    )::numeric <>
       250000
    then
        raise exception
            'Historical allocation cancelled payment salah.';
    end if;


    if (
        v_item
        ->> 'allocated_amount'
    )::numeric <>
       0
    then
        raise exception
            'Cancelled payment tidak boleh memiliki active allocated amount.';
    end if;


    if jsonb_array_length(
        v_item -> 'allocations'
    ) <> 1
    then
        raise exception
            'Cancelled payment allocation history harus tetap tersedia.';
    end if;


    if (
        v_item
        #>> '{allocations,0,bill,id}'
    )::uuid <>
       v_bill_2_id
    then
        raise exception
            'Allocation bill pada payment history salah.';
    end if;


    raise notice
        'PAYMENT ALLOCATION HISTORY SUCCESS';


    -- =====================================================
    -- R. CASH FILTER
    -- =====================================================

    v_cash_result :=
        public.get_bendahara_payment_history(
            null,
            null,
            'cash',
            1,
            100
        );


    if not exists (
        select 1

        from jsonb_array_elements(
            v_cash_result -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_payment_2_id
    ) then
        raise exception
            'Cash payment tidak ditemukan.';
    end if;


    -- =====================================================
    -- S. PAGINATION
    -- =====================================================

    v_page_result :=
        public.get_bendahara_payment_history(
            null,
            null,
            null,
            1,
            1
        );


    if jsonb_array_length(
        v_page_result -> 'items'
    ) > 1
    then
        raise exception
            'Payment history pagination gagal.';
    end if;


    if (
        v_page_result
        #>> '{pagination,page_size}'
    )::integer <>
       1
    then
        raise exception
            'Payment history page_size salah.';
    end if;


    raise notice
        'PAYMENT HISTORY PAGINATION SUCCESS';


    -- =====================================================
    -- T. INVALID STATUS
    -- =====================================================

    begin

        perform
            public.get_bendahara_payment_history(
                null,
                'invalid_status',
                null,
                1,
                20
            );


        raise exception
            'EXPECTED_INVALID_STATUS_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INVALID_STATUS_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%status pembayaran tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID PAYMENT STATUS FILTER PROTECTION SUCCESS';


    -- =====================================================
    -- U. INVALID METHOD
    -- =====================================================

    begin

        perform
            public.get_bendahara_payment_history(
                null,
                null,
                'bitcoin',
                1,
                20
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
               '%metode pembayaran tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID PAYMENT METHOD FILTER PROTECTION SUCCESS';


    -- =====================================================
    -- V. NON-BENDAHARA
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
            public.get_bendahara_payment_history(
                null,
                null,
                null,
                1,
                20
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
               '%Akses Riwayat Pembayaran Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA PAYMENT HISTORY PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'BENDAHARA PAYMENT HISTORY VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Riwayat Pembayaran Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;