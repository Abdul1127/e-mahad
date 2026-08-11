-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 137-verify-create-bendahara-student-bill-function.sql
--
-- PURPOSE:
-- Verification create_bendahara_student_bill()
--
-- TEST:
--
-- 1. Function exists
-- 2. Authenticated can execute
-- 3. Anon cannot execute
-- 4. Bendahara can create bill
-- 5. Bill stored correctly
-- 6. New bill status = unpaid
-- 7. paid_amount = 0
-- 8. outstanding = full amount
-- 9. Invalid amount rejected
-- 10. Empty title rejected
-- 11. Invalid period rejected
-- 12. Invalid student rejected
-- 13. Non-Bendahara rejected
--
-- TEST DATA:
-- ROLLBACK
-- =========================================================


-- =========================================================
-- 1. FUNCTION / PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.create_bendahara_student_bill(uuid,text,text,numeric,text,text,date,date,date)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.create_bendahara_student_bill(uuid,text,text,numeric,text,text,date,date,date)',
        'execute'
    )
        as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.create_bendahara_student_bill(uuid,text,text,numeric,text,text,date,date,date)',
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

    v_student_id uuid;

    v_academic_year_id uuid;

    v_result jsonb;

    v_created_bill_id uuid;
    v_created_bill_code text;

    v_db_status text;
    v_db_title text;
    v_db_category text;

    v_db_amount numeric;
    v_db_due_date date;

    v_db_student_id uuid;
    v_db_academic_year_id uuid;

    v_db_created_by uuid;
    v_db_updated_by uuid;

    v_suffix text;
begin

    v_suffix :=
        substr(
            replace(
                gen_random_uuid()::text,
                '-',
                ''
            ),
            1,
            8
        );


    -- =====================================================
    -- A. BENDAHARA ACCOUNT
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
    -- E. VALID CREATE
    -- =====================================================

    v_result :=
        public.create_bendahara_student_bill(
            p_student_id =>
                v_student_id,

            p_title =>
                'SPP Verification ' ||
                v_suffix,

            p_category =>
                'SPP',

            p_amount =>
                750000,

            p_description =>
                'Tagihan verification create bill.',

            p_period_label =>
                'Agustus 2026',

            p_period_start =>
                date '2026-08-01',

            p_period_end =>
                date '2026-08-31',

            p_due_date =>
                current_date + 10
        );


    -- =====================================================
    -- F. RESPONSE
    -- =====================================================

    if (
        v_result
        ->> 'success'
    )::boolean <>
       true
    then
        raise exception
            'Response success seharusnya true.';
    end if;


    v_created_bill_id :=
        (
            v_result
            #>> '{bill,id}'
        )::uuid;


    v_created_bill_code :=
        v_result
        #>> '{bill,bill_code}';


    if v_created_bill_id is null then
        raise exception
            'Bill ID tidak dikembalikan.';
    end if;


    if v_created_bill_code is null
       or v_created_bill_code not like
          'TAG-%'
    then
        raise exception
            'Bill code tidak valid: %.',
            v_created_bill_code;
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
        #>> '{bill,paid_amount}'
    )::numeric <>
       0
    then
        raise exception
            'Paid amount bill baru seharusnya 0.';
    end if;


    if (
        v_result
        #>> '{bill,outstanding_amount}'
    )::numeric <>
       750000
    then
        raise exception
            'Outstanding bill baru seharusnya Rp750.000.';
    end if;


    raise notice
        'CREATE BILL RESPONSE SUCCESS';


    -- =====================================================
    -- G. DATABASE RECORD
    -- =====================================================

    select
        bill.status,
        bill.title,
        bill.category,
        bill.amount,
        bill.due_date,
        bill.student_id,
        bill.academic_year_id,
        bill.created_by_staff_id,
        bill.updated_by_staff_id

    into
        v_db_status,
        v_db_title,
        v_db_category,
        v_db_amount,
        v_db_due_date,
        v_db_student_id,
        v_db_academic_year_id,
        v_db_created_by,
        v_db_updated_by

    from public.student_bills
        as bill

    where bill.id =
          v_created_bill_id;


    if not found then
        raise exception
            'Bill yang dibuat tidak ditemukan di database.';
    end if;


    if v_db_status <>
       'unpaid'
    then
        raise exception
            'Status database bill baru bukan unpaid.';
    end if;


    if v_db_category <>
       'spp'
    then
        raise exception
            'Normalisasi category gagal. Hasil: %.',
            v_db_category;
    end if;


    if v_db_amount <>
       750000
    then
        raise exception
            'Nominal database salah.';
    end if;


    if v_db_student_id <>
       v_student_id
    then
        raise exception
            'Student ID database salah.';
    end if;


    if v_db_academic_year_id <>
       v_academic_year_id
    then
        raise exception
            'Academic year database salah.';
    end if;


    if v_db_created_by <>
       v_bendahara_staff_id
    then
        raise exception
            'created_by_staff_id salah.';
    end if;


    if v_db_updated_by <>
       v_bendahara_staff_id
    then
        raise exception
            'updated_by_staff_id salah.';
    end if;


    raise notice
        'CREATE BILL DATABASE RECORD SUCCESS';


    -- =====================================================
    -- H. BILL MUST APPEAR IN BILL LIST RPC
    -- =====================================================

    if not exists (
        select 1

        from jsonb_array_elements(
            (
                public.get_bendahara_bill_list(
                    v_created_bill_code,
                    null,
                    1,
                    20
                )
            ) -> 'items'
        ) as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_created_bill_id
    ) then
        raise exception
            'Tagihan baru tidak muncul di get_bendahara_bill_list().';
    end if;


    raise notice
        'CREATE BILL LIST INTEGRATION SUCCESS';


    -- =====================================================
    -- I. DASHBOARD MUST REFLECT BILL
    -- =====================================================

    if not exists (
        select 1

        from public.student_bills
            as bill

        where bill.id =
              v_created_bill_id

          and bill.status =
              'unpaid'
    ) then
        raise exception
            'Tagihan baru tidak siap untuk Dashboard Bendahara.';
    end if;


    raise notice
        'CREATE BILL DASHBOARD FOUNDATION SUCCESS';


    -- =====================================================
    -- J. ZERO AMOUNT MUST FAIL
    -- =====================================================

    begin

        perform
            public.create_bendahara_student_bill(
                p_student_id =>
                    v_student_id,

                p_title =>
                    'Invalid Zero Amount',

                p_category =>
                    'verification',

                p_amount =>
                    0
            );


        raise exception
            'EXPECTED_ZERO_AMOUNT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_ZERO_AMOUNT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%lebih besar dari 0%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID AMOUNT PROTECTION SUCCESS';


    -- =====================================================
    -- K. EMPTY TITLE MUST FAIL
    -- =====================================================

    begin

        perform
            public.create_bendahara_student_bill(
                p_student_id =>
                    v_student_id,

                p_title =>
                    '   ',

                p_category =>
                    'verification',

                p_amount =>
                    100000
            );


        raise exception
            'EXPECTED_EMPTY_TITLE_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_EMPTY_TITLE_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Nama tagihan wajib diisi%'
            then
                raise;
            end if;

    end;


    raise notice
        'EMPTY TITLE PROTECTION SUCCESS';


    -- =====================================================
    -- L. INVALID CATEGORY MUST FAIL
    -- =====================================================

    begin

        perform
            public.create_bendahara_student_bill(
                p_student_id =>
                    v_student_id,

                p_title =>
                    'Invalid Category',

                p_category =>
                    '   ',

                p_amount =>
                    100000
            );


        raise exception
            'EXPECTED_EMPTY_CATEGORY_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_EMPTY_CATEGORY_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Kategori tagihan wajib diisi%'
            then
                raise;
            end if;

    end;


    raise notice
        'EMPTY CATEGORY PROTECTION SUCCESS';


    -- =====================================================
    -- M. INVALID PERIOD MUST FAIL
    -- =====================================================

    begin

        perform
            public.create_bendahara_student_bill(
                p_student_id =>
                    v_student_id,

                p_title =>
                    'Invalid Period',

                p_category =>
                    'verification',

                p_amount =>
                    100000,

                p_period_start =>
                    date '2026-08-31',

                p_period_end =>
                    date '2026-08-01'
            );


        raise exception
            'EXPECTED_INVALID_PERIOD_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INVALID_PERIOD_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Tanggal akhir periode%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID PERIOD PROTECTION SUCCESS';


    -- =====================================================
    -- N. INVALID STUDENT MUST FAIL
    -- =====================================================

    begin

        perform
            public.create_bendahara_student_bill(
                p_student_id =>
                    gen_random_uuid(),

                p_title =>
                    'Invalid Student',

                p_category =>
                    'verification',

                p_amount =>
                    100000
            );


        raise exception
            'EXPECTED_INVALID_STUDENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INVALID_STUDENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Santri aktif tidak ditemukan%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID STUDENT PROTECTION SUCCESS';


    -- =====================================================
    -- O. NON-BENDAHARA ACCOUNT
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


    -- =====================================================
    -- P. LOGIN AS NON-BENDAHARA
    -- =====================================================

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
            public.create_bendahara_student_bill(
                p_student_id =>
                    v_student_id,

                p_title =>
                    'Unauthorized Bill',

                p_category =>
                    'verification',

                p_amount =>
                    100000
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
               '%Akses pembuatan tagihan Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA CREATE BILL PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'CREATE BENDAHARA STUDENT BILL VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Pembuatan Tagihan Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;