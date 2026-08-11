-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 134-verify-bendahara-bill-list-functions.sql
--
-- PURPOSE:
-- Verification:
--
-- - Function exists
-- - Privilege
-- - Bill list
-- - Search
-- - Status filter
-- - Overdue filter
-- - Pagination
-- - Student options
-- - Finance summary per student
-- - Non-Bendahara protection
--
-- Semua test data di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FUNCTION EXISTS
-- =========================================================

select
    to_regprocedure(
        'public.get_bendahara_bill_list(text,text,integer,integer)'
    ) is not null
        as bill_list_exists,

    to_regprocedure(
        'public.get_bendahara_bill_student_options(text,integer)'
    ) is not null
        as student_options_exists,

    has_function_privilege(
        'authenticated',
        'public.get_bendahara_bill_list(text,text,integer,integer)',
        'execute'
    ) as authenticated_bill_list_execute,

    has_function_privilege(
        'anon',
        'public.get_bendahara_bill_list(text,text,integer,integer)',
        'execute'
    ) as anon_bill_list_execute,

    has_function_privilege(
        'authenticated',
        'public.get_bendahara_bill_student_options(text,integer)',
        'execute'
    ) as authenticated_student_options_execute,

    has_function_privilege(
        'anon',
        'public.get_bendahara_bill_student_options(text,integer)',
        'execute'
    ) as anon_student_options_execute;


begin;


do $verification$
declare
    v_bendahara_profile_id uuid;
    v_bendahara_email text;
    v_bendahara_staff_id uuid;

    v_non_bendahara_profile_id uuid;
    v_non_bendahara_email text;

    v_academic_year_id uuid;

    v_student_1_id uuid;
    v_student_1_name text;

    v_student_2_id uuid;

    v_bill_unpaid_id uuid;
    v_bill_partial_id uuid;
    v_bill_paid_id uuid;
    v_bill_cancelled_id uuid;

    v_payment_partial_id uuid;
    v_payment_paid_id uuid;

    v_suffix text;

    v_result jsonb;
    v_search_result jsonb;
    v_filter_result jsonb;
    v_overdue_result jsonb;
    v_student_result jsonb;

    v_item jsonb;

    v_found boolean;
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
    -- B. LOGIN
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
    -- C. ACADEMIC YEAR
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
    -- D. STUDENTS
    -- =====================================================

    select
        student.id,
        student.full_name

    into
        v_student_1_id,
        v_student_1_name

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
            'Minimal dua santri aktif diperlukan.';
    end if;


    -- =====================================================
    -- E. UNPAID + OVERDUE BILL
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
        'VERIFY-LIST-U-' || v_suffix,
        'Verification Unpaid',
        'verification',
        'Agustus 2026',
        500000,
        current_date - 2,
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_unpaid_id;


    -- =====================================================
    -- F. PARTIAL
    -- =====================================================

    insert into public.student_bills (
        academic_year_id,
        student_id,
        bill_code,
        title,
        category,
        amount,
        due_date,
        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_1_id,
        'VERIFY-LIST-PART-' || v_suffix,
        'Verification Partial',
        'verification',
        1000000,
        current_date + 10,
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_partial_id;


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
        'VERIFY-PAY-PART-' || v_suffix,
        current_date,
        400000,
        'transfer',
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_payment_partial_id;


    insert into public.payment_allocations (
        payment_id,
        bill_id,
        amount,
        created_by_staff_id
    )
    values (
        v_payment_partial_id,
        v_bill_partial_id,
        400000,
        v_bendahara_staff_id
    );


    -- =====================================================
    -- G. PAID
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
        'VERIFY-LIST-PAID-' || v_suffix,
        'Verification Paid',
        'verification',
        300000,
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_paid_id;


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
        v_student_2_id,
        'VERIFY-PAY-PAID-' || v_suffix,
        current_date,
        300000,
        'cash',
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_payment_paid_id;


    insert into public.payment_allocations (
        payment_id,
        bill_id,
        amount,
        created_by_staff_id
    )
    values (
        v_payment_paid_id,
        v_bill_paid_id,
        300000,
        v_bendahara_staff_id
    );


    -- =====================================================
    -- H. CANCELLED BILL
    -- =====================================================

    insert into public.student_bills (
        academic_year_id,
        student_id,
        bill_code,
        title,
        category,
        amount,
        status,
        cancelled_at,
        cancelled_by_staff_id,
        cancellation_reason,
        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_2_id,
        'VERIFY-LIST-CANCEL-' || v_suffix,
        'Verification Cancelled',
        'verification',
        200000,
        'cancelled',
        now(),
        v_bendahara_staff_id,
        'Verification cancellation',
        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_cancelled_id;


    -- =====================================================
    -- I. FULL LIST
    -- =====================================================

    v_result :=
        public.get_bendahara_bill_list(
            null,
            null,
            1,
            100
        );


    if not exists (
        select 1

        from jsonb_array_elements(
            v_result -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_bill_unpaid_id
    ) then
        raise exception
            'Unpaid bill tidak muncul di daftar.';
    end if;


    if not exists (
        select 1

        from jsonb_array_elements(
            v_result -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_bill_partial_id
    ) then
        raise exception
            'Partial bill tidak muncul di daftar.';
    end if;


    if not exists (
        select 1

        from jsonb_array_elements(
            v_result -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_bill_paid_id
    ) then
        raise exception
            'Paid bill tidak muncul di daftar.';
    end if;


    if not exists (
        select 1

        from jsonb_array_elements(
            v_result -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_bill_cancelled_id
    ) then
        raise exception
            'Cancelled bill tidak muncul di daftar.';
    end if;


    raise notice
        'BILL LIST SUCCESS';


    -- =====================================================
    -- J. SEARCH
    -- =====================================================

    v_search_result :=
        public.get_bendahara_bill_list(
            'VERIFY-LIST-U-' || v_suffix,
            null,
            1,
            20
        );


    if (
        v_search_result
        #>> '{summary,filtered_count}'
    )::integer <> 1
    then
        raise exception
            'Search bill_code gagal.';
    end if;


    raise notice
        'BILL SEARCH SUCCESS';


    -- =====================================================
    -- K. STATUS FILTER PARTIAL
    -- =====================================================

    v_filter_result :=
        public.get_bendahara_bill_list(
            null,
            'partial',
            1,
            100
        );


    v_found :=
        false;


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_filter_result -> 'items'
        )

    loop

        if (
            v_item
            ->> 'status'
        ) <> 'partial'
        then
            raise exception
                'Filter partial mengembalikan status lain.';
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_bill_partial_id
        then
            v_found :=
                true;
        end if;

    end loop;


    if not v_found then
        raise exception
            'Verification partial bill tidak ditemukan.';
    end if;


    raise notice
        'BILL STATUS FILTER SUCCESS';


    -- =====================================================
    -- L. OVERDUE FILTER
    -- =====================================================

    v_overdue_result :=
        public.get_bendahara_bill_list(
            null,
            'overdue',
            1,
            100
        );


    v_found :=
        false;


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_overdue_result -> 'items'
        )

    loop

        if (
            v_item
            ->> 'is_overdue'
        )::boolean <>
           true
        then
            raise exception
                'Filter overdue mengembalikan item non-overdue.';
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_bill_unpaid_id
        then
            v_found :=
                true;
        end if;

    end loop;


    if not v_found then
        raise exception
            'Verification overdue bill tidak ditemukan.';
    end if;


    raise notice
        'OVERDUE FILTER SUCCESS';


    -- =====================================================
    -- M. PAGINATION
    -- =====================================================

    v_result :=
        public.get_bendahara_bill_list(
            null,
            null,
            1,
            1
        );


    if jsonb_array_length(
        v_result -> 'items'
    ) > 1
    then
        raise exception
            'Bill pagination gagal.';
    end if;


    if (
        v_result
        #>> '{pagination,page_size}'
    )::integer <> 1
    then
        raise exception
            'Bill pagination page_size salah.';
    end if;


    raise notice
        'BILL PAGINATION SUCCESS';


    -- =====================================================
    -- N. STUDENT OPTIONS
    -- =====================================================

    v_student_result :=
        public.get_bendahara_bill_student_options(
            v_student_1_name,
            20
        );


    if not exists (
        select 1

        from jsonb_array_elements(
            v_student_result -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_student_1_id
    ) then
        raise exception
            'Student options search gagal.';
    end if;


    raise notice
        'BILL STUDENT OPTIONS SUCCESS';


    -- =====================================================
    -- O. STUDENT FINANCE SUMMARY
    -- =====================================================

    select
        item.value

    into
        v_item

    from jsonb_array_elements(
        v_student_result -> 'items'
    ) as item(value)

    where (
        item.value
        ->> 'id'
    )::uuid =
          v_student_1_id

    limit 1;


    if (
        v_item
        #>> '{finance_summary,open_bill_count}'
    )::integer < 2
    then
        raise exception
            'Finance summary open bill count salah.';
    end if;


    if (
        v_item
        #>> '{finance_summary,outstanding_amount}'
    )::numeric <
       1100000
    then
        raise exception
            'Finance summary outstanding amount salah.';
    end if;


    raise notice
        'STUDENT FINANCE SUMMARY SUCCESS';


    -- =====================================================
    -- P. INVALID STATUS
    -- =====================================================

    begin

        perform
            public.get_bendahara_bill_list(
                null,
                'invalid_status',
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
               '%status tagihan tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID BILL STATUS PROTECTION SUCCESS';


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
            'Akun non-Bendahara untuk test tidak ditemukan.';
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
            public.get_bendahara_bill_list(
                null,
                null,
                1,
                20
            );


        raise exception
            'EXPECTED_NON_BENDAHARA_LIST_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_BENDAHARA_LIST_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses Daftar Tagihan Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    begin

        perform
            public.get_bendahara_bill_student_options(
                null,
                20
            );


        raise exception
            'EXPECTED_NON_BENDAHARA_STUDENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_BENDAHARA_STUDENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses Kandidat Santri Tagihan ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA BILL ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'BENDAHARA BILL LIST VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Daftar Tagihan Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;