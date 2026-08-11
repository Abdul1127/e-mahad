-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 152-verify-payment-proof-storage-foundation.sql
--
-- PURPOSE:
-- Verification payment-proofs Storage foundation.
--
-- TEST:
--
-- - bucket exists
-- - bucket private
-- - file limit = 5 MB
-- - MIME restrictions
-- - security helper exists
-- - authenticated execute
-- - anon denied
-- - 4 Storage policies exist
-- - Bendahara read access = true
-- - Bendahara write access = true for recorded payment
-- - malformed path denied
-- - cancelled payment remains readable
-- - cancelled payment cannot receive new upload/update
-- - non-Bendahara denied
--
-- IMPORTANT:
--
-- Verification TIDAK insert/update/delete storage.objects.
-- File operation akan diuji melalui Supabase Storage API
-- pada tahap frontend upload.
--
-- Test data finance menggunakan transaction + rollback.
-- =========================================================


-- =========================================================
-- 1. BUCKET CONFIGURATION
-- =========================================================

select
    bucket.id,

    bucket.name,

    bucket.public,

    bucket.file_size_limit,

    bucket.allowed_mime_types

from storage.buckets
    as bucket

where bucket.id =
      'payment-proofs';


-- =========================================================
-- 2. FUNCTION / PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.can_bendahara_access_payment_proof(text,boolean)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.can_bendahara_access_payment_proof(text,boolean)',
        'execute'
    )
        as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.can_bendahara_access_payment_proof(text,boolean)',
        'execute'
    )
        as anon_can_execute;


-- =========================================================
-- 3. STORAGE POLICIES
-- =========================================================

select
    policyname,
    cmd,
    roles,
    qual,
    with_check

from pg_policies

where schemaname =
      'storage'

  and tablename =
      'objects'

  and policyname in (
      'payment_proofs_bendahara_select',
      'payment_proofs_bendahara_insert',
      'payment_proofs_bendahara_update',
      'payment_proofs_bendahara_delete'
  )

order by
    policyname;


-- =========================================================
-- 4. VERIFICATION TRANSACTION
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

    v_payment_path text;

    v_result jsonb;

    v_bucket_public boolean;
    v_bucket_limit bigint;
    v_bucket_mimes text[];

    v_policy_count integer;

    v_suffix text;
begin

    -- =====================================================
    -- A. BUCKET
    -- =====================================================

    select
        bucket.public,
        bucket.file_size_limit,
        bucket.allowed_mime_types

    into
        v_bucket_public,
        v_bucket_limit,
        v_bucket_mimes

    from storage.buckets
        as bucket

    where bucket.id =
          'payment-proofs';


    if not found then
        raise exception
            'Bucket payment-proofs tidak ditemukan.';
    end if;


    if v_bucket_public <>
       false
    then
        raise exception
            'Bucket payment-proofs wajib private.';
    end if;


    if v_bucket_limit <>
       5242880
    then
        raise exception
            'File size limit payment-proofs bukan 5 MB.';
    end if;


    if not (
        array[
            'image/jpeg',
            'image/png',
            'image/webp',
            'application/pdf'
        ]::text[]
        <@
        v_bucket_mimes

        and

        v_bucket_mimes
        <@
        array[
            'image/jpeg',
            'image/png',
            'image/webp',
            'application/pdf'
        ]::text[]
    ) then
        raise exception
            'Allowed MIME types payment-proofs tidak sesuai.';
    end if;


    raise notice
        'PAYMENT PROOF BUCKET CONFIGURATION SUCCESS';


    -- =====================================================
    -- B. STORAGE POLICIES
    -- =====================================================

    select
        count(*)::integer

    into
        v_policy_count

    from pg_policies

    where schemaname =
          'storage'

      and tablename =
          'objects'

      and policyname in (
          'payment_proofs_bendahara_select',
          'payment_proofs_bendahara_insert',
          'payment_proofs_bendahara_update',
          'payment_proofs_bendahara_delete'
      );


    if v_policy_count <>
       4
    then
        raise exception
            'Jumlah policy payment-proofs harus 4. Ditemukan: %.',
            v_policy_count;
    end if;


    if not exists (
        select 1

        from pg_policies

        where schemaname =
              'storage'

          and tablename =
              'objects'

          and policyname =
              'payment_proofs_bendahara_select'

          and cmd =
              'SELECT'
    ) then
        raise exception
            'SELECT policy payment-proofs tidak ditemukan.';
    end if;


    if not exists (
        select 1

        from pg_policies

        where schemaname =
              'storage'

          and tablename =
              'objects'

          and policyname =
              'payment_proofs_bendahara_insert'

          and cmd =
              'INSERT'
    ) then
        raise exception
            'INSERT policy payment-proofs tidak ditemukan.';
    end if;


    if not exists (
        select 1

        from pg_policies

        where schemaname =
              'storage'

          and tablename =
              'objects'

          and policyname =
              'payment_proofs_bendahara_update'

          and cmd =
              'UPDATE'
    ) then
        raise exception
            'UPDATE policy payment-proofs tidak ditemukan.';
    end if;


    if not exists (
        select 1

        from pg_policies

        where schemaname =
              'storage'

          and tablename =
              'objects'

          and policyname =
              'payment_proofs_bendahara_delete'

          and cmd =
              'DELETE'
    ) then
        raise exception
            'DELETE policy payment-proofs tidak ditemukan.';
    end if;


    raise notice
        'PAYMENT PROOF STORAGE POLICIES SUCCESS';


    -- =====================================================
    -- C. BENDAHARA ACCOUNT
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
    -- D. LOGIN AS BENDAHARA
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
    -- E. CURRENT ACADEMIC YEAR
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
    -- F. ACTIVE STUDENT
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
    -- G. CREATE TEST BILL
    -- =====================================================

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

        'VERIFY-PROOF-' ||
            v_suffix,

        'Verification Payment Proof',

        'verification',

        100000,

        v_bendahara_staff_id,
        v_bendahara_staff_id
    )
    returning id
    into v_bill_id;


    -- =====================================================
    -- H. CREATE RECORDED PAYMENT
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
                'VERIFY-PROOF-' ||
                v_suffix,

            p_notes =>
                'Storage access verification'
        );


    v_payment_id :=
        (
            v_result
            #>> '{payment,id}'
        )::uuid;


    if v_payment_id is null then
        raise exception
            'Payment verification tidak berhasil dibuat.';
    end if;


    v_payment_path :=
        v_payment_id::text ||
        '/' ||
        lower(
            v_suffix
        ) ||
        '-receipt.jpg';


    -- =====================================================
    -- I. BENDAHARA READ ACCESS
    -- =====================================================

    if public.can_bendahara_access_payment_proof(
        v_payment_path,
        false
    ) <>
       true
    then
        raise exception
            'Bendahara gagal mendapatkan READ access payment proof.';
    end if;


    raise notice
        'BENDAHARA PAYMENT PROOF READ ACCESS SUCCESS';


    -- =====================================================
    -- J. BENDAHARA WRITE ACCESS
    -- =====================================================

    if public.can_bendahara_access_payment_proof(
        v_payment_path,
        true
    ) <>
       true
    then
        raise exception
            'Bendahara gagal mendapatkan WRITE access payment proof.';
    end if;


    raise notice
        'BENDAHARA PAYMENT PROOF WRITE ACCESS SUCCESS';


    -- =====================================================
    -- K. INVALID PATHS
    -- =====================================================

    if public.can_bendahara_access_payment_proof(
        'receipt.jpg',
        false
    ) <>
       false
    then
        raise exception
            'Path tanpa payment ID tidak boleh diakses.';
    end if;


    if public.can_bendahara_access_payment_proof(
        v_payment_id::text ||
        '/folder/receipt.jpg',
        false
    ) <>
       false
    then
        raise exception
            'Nested path tidak boleh diakses.';
    end if;


    if public.can_bendahara_access_payment_proof(
        'not-a-uuid/receipt.jpg',
        false
    ) <>
       false
    then
        raise exception
            'Malformed payment UUID tidak boleh diakses.';
    end if;


    if public.can_bendahara_access_payment_proof(
        gen_random_uuid()::text ||
        '/receipt.jpg',
        false
    ) <>
       false
    then
        raise exception
            'Unknown payment tidak boleh diakses.';
    end if;


    raise notice
        'PAYMENT PROOF INVALID PATH PROTECTION SUCCESS';


    -- =====================================================
    -- L. CANCEL PAYMENT
    -- =====================================================

    perform
        public.cancel_bendahara_payment(
            p_payment_id =>
                v_payment_id,

            p_cancellation_reason =>
                'Verification payment proof cancellation'
        );


    -- =====================================================
    -- M. CANCELLED PAYMENT REMAINS READABLE
    --
    -- Audit trail lama tetap dapat dilihat.
    -- =====================================================

    if public.can_bendahara_access_payment_proof(
        v_payment_path,
        false
    ) <>
       true
    then
        raise exception
            'Proof payment cancelled seharusnya tetap readable.';
    end if;


    raise notice
        'CANCELLED PAYMENT PROOF READ ACCESS SUCCESS';


    -- =====================================================
    -- N. CANCELLED PAYMENT CANNOT WRITE
    -- =====================================================

    if public.can_bendahara_access_payment_proof(
        v_payment_path,
        true
    ) <>
       false
    then
        raise exception
            'Payment cancelled tidak boleh menerima WRITE access.';
    end if;


    raise notice
        'CANCELLED PAYMENT PROOF WRITE PROTECTION SUCCESS';


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


    -- =====================================================
    -- Q. NON-BENDAHARA DENIED
    -- =====================================================

    if public.can_bendahara_access_payment_proof(
        v_payment_path,
        false
    ) <>
       false
    then
        raise exception
            'Non-Bendahara mendapat READ access payment proof.';
    end if;


    if public.can_bendahara_access_payment_proof(
        v_payment_path,
        true
    ) <>
       false
    then
        raise exception
            'Non-Bendahara mendapat WRITE access payment proof.';
    end if;


    raise notice
        'NON-BENDAHARA PAYMENT PROOF PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'PAYMENT PROOF STORAGE FOUNDATION VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Payment Proof Storage Foundation berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;