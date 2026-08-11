-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 158-verify-guardian-finance-functions.sql
--
-- TEST:
--
-- Guardian:
-- - hanya linked child
-- - tidak bisa lihat student lain
-- - tagihan linked child muncul
-- - pembayaran linked child muncul
-- - private proof linked child allowed
-- - private proof unlinked child denied
-- - selected unlinked student denied
-- - non-Guardian denied
--
-- Semua test data di-ROLLBACK.
-- =========================================================


-- =========================================================
-- 1. FUNCTIONS
-- =========================================================

select
    to_regprocedure(
        'public.get_guardian_bill_list(uuid)'
    ) is not null
        as bill_function_exists,

    to_regprocedure(
        'public.get_guardian_payment_history(uuid,integer,integer)'
    ) is not null
        as payment_function_exists,

    to_regprocedure(
        'public.can_guardian_access_payment_proof(text)'
    ) is not null
        as proof_helper_exists,

    has_function_privilege(
        'authenticated',
        'public.get_guardian_bill_list(uuid)',
        'execute'
    )
        as authenticated_bill_access,

    has_function_privilege(
        'authenticated',
        'public.get_guardian_payment_history(uuid,integer,integer)',
        'execute'
    )
        as authenticated_payment_access,

    has_function_privilege(
        'anon',
        'public.get_guardian_bill_list(uuid)',
        'execute'
    )
        as anon_bill_access;


-- =========================================================
-- 2. STORAGE POLICY
-- =========================================================

select
    policyname,
    cmd,
    roles

from pg_policies

where schemaname =
      'storage'

  and tablename =
      'objects'

  and policyname =
      'payment_proofs_guardian_select';


-- =========================================================
-- 3. TRANSACTION
-- =========================================================

begin;


do $verification$
declare
    v_guardian_profile_id uuid;
    v_guardian_email text;
    v_guardian_id uuid;

    v_bendahara_profile_id uuid;
    v_bendahara_email text;
    v_bendahara_staff_id uuid;

    v_academic_year_id uuid;

    v_linked_student_id uuid;
    v_unlinked_student_id uuid;

    v_linked_bill_id uuid;
    v_unlinked_bill_id uuid;

    v_linked_payment_id uuid;
    v_unlinked_payment_id uuid;

    v_linked_proof_path text;
    v_unlinked_proof_path text;

    v_result jsonb;
    v_item jsonb;

    v_found boolean;

    v_suffix text;
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
    -- A. GUARDIAN WITH LINKED CHILD
    -- =====================================================

    select
        profile.id,
        auth_user.email,
        guardian.id,
        student.id

    into
        v_guardian_profile_id,
        v_guardian_email,
        v_guardian_id,
        v_linked_student_id

    from public.guardians
        as guardian

    inner join public.profiles
        as profile

        on profile.id =
           guardian.profile_id

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    inner join public.guardian_students
        as relation

        on relation.guardian_id =
           guardian.id

    inner join public.students
        as student

        on student.id =
           relation.student_id

    where guardian.is_active =
          true

      and profile.is_active =
          true

      and role.code =
          'guardian'

      and role.is_active =
          true

      and student.status =
          'active'

      and student.deleted_at
          is null

    order by
        guardian.id,
        student.full_name,
        student.id

    limit 1;


    if v_guardian_profile_id is null
       or v_linked_student_id is null
    then
        raise exception
            'Guardian aktif dengan linked child tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. UNLINKED STUDENT
    -- =====================================================

    select
        student.id

    into
        v_unlinked_student_id

    from public.students
        as student

    where student.status =
          'active'

      and student.deleted_at
          is null

      and not exists (
          select 1

          from public.guardian_students
              as relation

          where relation.guardian_id =
                v_guardian_id

            and relation.student_id =
                student.id
      )

    order by
        student.full_name,
        student.id

    limit 1;


    if v_unlinked_student_id is null then
        raise exception
            'Student yang tidak terhubung ke Guardian tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. BENDAHARA
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

    limit 1;


    if v_bendahara_profile_id is null then
        raise exception
            'Bendahara aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- D. LOGIN BENDAHARA
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
    -- E. CURRENT YEAR
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
    -- F. CREATE LINKED BILL
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
        v_linked_student_id,

        'VERIFY-GUARDIAN-LINKED-' ||
            v_suffix,

        'Verification Guardian Linked Bill',

        'verification',

        500000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_linked_bill_id;


    -- =====================================================
    -- G. LINKED PAYMENT
    -- =====================================================

    v_result :=
        public.record_bendahara_bill_payment(
            p_bill_id =>
                v_linked_bill_id,

            p_payment_date =>
                current_date,

            p_amount =>
                200000,

            p_payment_method =>
                'transfer',

            p_reference_number =>
                'VERIFY-GUARDIAN-LINKED-' ||
                v_suffix,

            p_notes =>
                'Guardian linked verification'
        );


    v_linked_payment_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    v_linked_proof_path :=
        v_linked_payment_id::text ||
        '/' ||
        v_suffix ||
        '-linked.jpg';


    update public.payments
    set
        proof_path =
            v_linked_proof_path,

        updated_by_staff_id =
            v_bendahara_staff_id

    where id =
          v_linked_payment_id;


    -- =====================================================
    -- H. CREATE UNLINKED BILL
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
        v_unlinked_student_id,

        'VERIFY-GUARDIAN-UNLINKED-' ||
            v_suffix,

        'Verification Guardian Unlinked Bill',

        'verification',

        600000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_unlinked_bill_id;


    v_result :=
        public.record_bendahara_bill_payment(
            p_bill_id =>
                v_unlinked_bill_id,

            p_payment_date =>
                current_date,

            p_amount =>
                100000,

            p_payment_method =>
                'cash',

            p_reference_number =>
                'VERIFY-GUARDIAN-UNLINKED-' ||
                v_suffix,

            p_notes =>
                'Guardian unlinked verification'
        );


    v_unlinked_payment_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    v_unlinked_proof_path :=
        v_unlinked_payment_id::text ||
        '/' ||
        v_suffix ||
        '-unlinked.jpg';


    update public.payments
    set
        proof_path =
            v_unlinked_proof_path,

        updated_by_staff_id =
            v_bendahara_staff_id

    where id =
          v_unlinked_payment_id;


    -- =====================================================
    -- I. LOGIN GUARDIAN
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_guardian_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_guardian_profile_id,

            'role',
            'authenticated',

            'email',
            v_guardian_email
        )::text,
        true
    );


    -- =====================================================
    -- J. BILL LIST
    -- =====================================================

    v_result :=
        public.get_guardian_bill_list(
            null
        );


    v_found :=
        false;


    for v_item in

        select
            value

        from jsonb_array_elements(
            v_result -> 'items'
        )

    loop

        if (
            v_item
            ->> 'id'
        )::uuid =
           v_linked_bill_id
        then
            v_found :=
                true;
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_unlinked_bill_id
        then
            raise exception
                'UNLINKED BILL BOCOR KE GUARDIAN.';
        end if;

    end loop;


    if not v_found then
        raise exception
            'Linked bill tidak muncul untuk Guardian.';
    end if;


    raise notice
        'GUARDIAN LINKED BILL ACCESS SUCCESS';


    -- =====================================================
    -- K. PAYMENT HISTORY
    -- =====================================================

    v_result :=
        public.get_guardian_payment_history(
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
            v_result -> 'items'
        )

    loop

        if (
            v_item
            ->> 'id'
        )::uuid =
           v_linked_payment_id
        then
            v_found :=
                true;
        end if;


        if (
            v_item
            ->> 'id'
        )::uuid =
           v_unlinked_payment_id
        then
            raise exception
                'UNLINKED PAYMENT BOCOR KE GUARDIAN.';
        end if;

    end loop;


    if not v_found then
        raise exception
            'Linked payment tidak muncul untuk Guardian.';
    end if;


    raise notice
        'GUARDIAN LINKED PAYMENT ACCESS SUCCESS';


    -- =====================================================
    -- L. PROOF ACCESS
    -- =====================================================

    if public.can_guardian_access_payment_proof(
        v_linked_proof_path
    ) <>
       true
    then
        raise exception
            'Guardian gagal mendapat akses proof linked child.';
    end if;


    if public.can_guardian_access_payment_proof(
        v_unlinked_proof_path
    ) <>
       false
    then
        raise exception
            'Guardian mendapat akses proof milik unlinked child.';
    end if;


    raise notice
        'GUARDIAN PAYMENT PROOF SECURITY SUCCESS';


    -- =====================================================
    -- M. UNLINKED STUDENT FILTER MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_guardian_bill_list(
                v_unlinked_student_id
            );


        raise exception
            'EXPECTED_UNLINKED_STUDENT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_UNLINKED_STUDENT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%tidak memiliki akses%'
            then
                raise;
            end if;

    end;


    raise notice
        'GUARDIAN UNLINKED STUDENT PROTECTION SUCCESS';


    -- =====================================================
    -- N. LOGIN NON-GUARDIAN / BENDAHARA
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


    begin

        perform
            public.get_guardian_bill_list(
                null
            );


        raise exception
            'EXPECTED_NON_GUARDIAN_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_GUARDIAN_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses tagihan Wali ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-GUARDIAN FINANCE PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'GUARDIAN FINANCE VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Finance Wali berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;