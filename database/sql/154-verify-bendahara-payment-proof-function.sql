-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 154-verify-bendahara-payment-proof-function.sql
--
-- PURPOSE:
-- Verification backend payment proof.
--
-- TEST:
-- - function exists
-- - authenticated execute
-- - anon denied
-- - helper still exists
-- - malformed path protection
-- - wrong payment path protection
-- - missing Storage object protection
-- - cancelled payment protection
-- - non-Bendahara protection
--
-- SUCCESS PATH:
-- Upload nyata + attach akan diverifikasi di tahap 155.
--
-- Semua data finance verification di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FUNCTIONS / PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.attach_bendahara_payment_proof(uuid,text)'
    ) is not null
        as attach_function_exists,

    has_function_privilege(
        'authenticated',
        'public.attach_bendahara_payment_proof(uuid,text)',
        'execute'
    )
        as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.attach_bendahara_payment_proof(uuid,text)',
        'execute'
    )
        as anon_can_execute,

    to_regprocedure(
        'public.can_bendahara_access_payment_proof(text,boolean)'
    ) is not null
        as access_helper_exists;


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

    v_bill_id uuid;
    v_payment_id uuid;

    v_result jsonb;

    v_suffix text;

    v_fake_path text;
begin

    v_suffix :=
        lower(
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

        amount,

        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_id,

        'VERIFY-ATTACH-PROOF-' ||
            v_suffix,

        'Verification Attach Payment Proof',

        'verification',

        100000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_id;


    -- =====================================================
    -- E. CREATE PAYMENT
    -- =====================================================

    v_result :=
        public.record_bendahara_bill_payment(
            p_bill_id =>
                v_bill_id,

            p_payment_date =>
                current_date,

            p_amount =>
                100000,

            p_payment_method =>
                'transfer',

            p_reference_number =>
                'VERIFY-ATTACH-' ||
                v_suffix,

            p_notes =>
                'Verification attach payment proof'
        );


    v_payment_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    if v_payment_id is null then
        raise exception
            'Payment verification gagal dibuat.';
    end if;


    -- =====================================================
    -- F. MALFORMED PATH
    -- =====================================================

    begin

        perform
            public.attach_bendahara_payment_proof(
                p_payment_id =>
                    v_payment_id,

                p_proof_path =>
                    'receipt.jpg'
            );


        raise exception
            'EXPECTED_MALFORMED_PATH_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_MALFORMED_PATH_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Format path bukti pembayaran tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'PAYMENT PROOF MALFORMED PATH PROTECTION SUCCESS';


    -- =====================================================
    -- G. WRONG PAYMENT ID IN PATH
    -- =====================================================

    begin

        perform
            public.attach_bendahara_payment_proof(
                p_payment_id =>
                    v_payment_id,

                p_proof_path =>
                    gen_random_uuid()::text ||
                    '/receipt.jpg'
            );


        raise exception
            'EXPECTED_WRONG_PAYMENT_PATH_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_WRONG_PAYMENT_PATH_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%tidak sesuai dengan transaksi%'
            then
                raise;
            end if;

    end;


    raise notice
        'PAYMENT PROOF WRONG PAYMENT PATH PROTECTION SUCCESS';


    -- =====================================================
    -- H. STORAGE OBJECT MUST EXIST
    -- =====================================================

    v_fake_path :=
        v_payment_id::text ||
        '/' ||
        v_suffix ||
        '.jpg';


    begin

        perform
            public.attach_bendahara_payment_proof(
                p_payment_id =>
                    v_payment_id,

                p_proof_path =>
                    v_fake_path
            );


        raise exception
            'EXPECTED_MISSING_STORAGE_OBJECT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_MISSING_STORAGE_OBJECT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%belum tersedia di Storage%'
            then
                raise;
            end if;

    end;


    raise notice
        'PAYMENT PROOF STORAGE OBJECT PROTECTION SUCCESS';


    -- =====================================================
    -- I. CANCEL PAYMENT
    -- =====================================================

    perform
        public.cancel_bendahara_payment(
            p_payment_id =>
                v_payment_id,

            p_cancellation_reason =>
                'Verification cancelled payment proof attach'
        );


    -- =====================================================
    -- J. CANCELLED PAYMENT CANNOT ATTACH
    -- =====================================================

    begin

        perform
            public.attach_bendahara_payment_proof(
                p_payment_id =>
                    v_payment_id,

                p_proof_path =>
                    v_fake_path
            );


        raise exception
            'EXPECTED_CANCELLED_PAYMENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_CANCELLED_PAYMENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%sudah dibatalkan%'
            then
                raise;
            end if;

    end;


    raise notice
        'CANCELLED PAYMENT PROOF ATTACH PROTECTION SUCCESS';


    -- =====================================================
    -- K. NON-BENDAHARA
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
            public.attach_bendahara_payment_proof(
                p_payment_id =>
                    v_payment_id,

                p_proof_path =>
                    v_fake_path
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
               '%Akses bukti pembayaran Bendahara ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-BENDAHARA PAYMENT PROOF ATTACH PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'BENDAHARA PAYMENT PROOF BACKEND VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Backend Bukti Pembayaran Bendahara berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;