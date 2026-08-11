begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 153-create-bendahara-payment-proof-function.sql
--
-- PURPOSE:
-- Menghubungkan object Storage payment-proofs yang sudah
-- berhasil di-upload dengan payments.proof_path.
--
-- FLOW:
--
-- Browser
--   ↓
-- upload ke private bucket payment-proofs
--   ↓
-- {payment_id}/{uuid}.{ext}
--   ↓
-- attach_bendahara_payment_proof()
--   ↓
-- payments.proof_path
--
-- SECURITY:
-- - authenticated
-- - Bendahara
-- - profile aktif
-- - staff aktif
-- - current academic year
-- - payment harus recorded
-- - path harus milik payment tersebut
-- - object Storage harus benar-benar ada
--
-- IMPORTANT:
-- Payment cancelled tidak boleh diberi bukti baru.
-- Existing proof tidak boleh ditimpa dengan path berbeda.
-- =========================================================


-- =========================================================
-- A. UPDATE STORAGE SECURITY HELPER
--
-- Setelah proof_path sudah tercatat:
--
-- WRITE hanya boleh ke object yang sama.
--
-- Ini mencegah Bendahara membuat object-object tambahan
-- untuk payment yang sudah mempunyai bukti pembayaran.
-- =========================================================

create or replace function
public.can_bendahara_access_payment_proof(
    p_object_name text,
    p_for_write boolean default false
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_payment_id_text text;
    v_file_name text;

    v_parts text[];
begin

    -- =====================================================
    -- 1. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        return false;
    end if;


    -- =====================================================
    -- 2. ROLE
    -- =====================================================

    if not public.has_role(
        'bendahara'
    ) then
        return false;
    end if;


    -- =====================================================
    -- 3. ACTIVE PROFILE
    -- =====================================================

    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        return false;
    end if;


    -- =====================================================
    -- 4. ACTIVE STAFF
    -- =====================================================

    if not exists (
        select 1

        from public.staff
            as staff

        where staff.profile_id =
              v_profile_id

          and staff.is_active =
              true
    ) then
        return false;
    end if;


    -- =====================================================
    -- 5. PATH
    --
    -- Required:
    --
    -- payment_id/file_name
    -- =====================================================

    if p_object_name is null
       or btrim(
           p_object_name
       ) = ''
    then
        return false;
    end if;


    v_parts :=
        string_to_array(
            p_object_name,
            '/'
        );


    if coalesce(
        array_length(
            v_parts,
            1
        ),
        0
    ) <> 2
    then
        return false;
    end if;


    v_payment_id_text :=
        nullif(
            btrim(
                v_parts[1]
            ),
            ''
        );


    v_file_name :=
        nullif(
            btrim(
                v_parts[2]
            ),
            ''
        );


    if v_payment_id_text is null
       or v_file_name is null
    then
        return false;
    end if;


    -- =====================================================
    -- 6. UUID FORMAT
    -- =====================================================

    if v_payment_id_text !~
       '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
    then
        return false;
    end if;


    -- =====================================================
    -- 7. PAYMENT ACCESS
    --
    -- READ:
    -- recorded/cancelled boleh membaca historical proof.
    --
    -- WRITE:
    -- - payment harus recorded
    -- - kalau proof_path masih NULL → boleh initial upload
    -- - kalau proof_path sudah ada → hanya object yang sama
    -- =====================================================

    return exists (
        select 1

        from public.payments
            as payment

        inner join public.academic_years
            as academic_year

            on academic_year.id =
               payment.academic_year_id

        where lower(
                  payment.id::text
              ) =
              lower(
                  v_payment_id_text
              )

          and academic_year.is_current =
              true

          and (
              coalesce(
                  p_for_write,
                  false
              ) =
              false

              or (
                  payment.status =
                      'recorded'

                  and (
                      payment.proof_path
                          is null

                      or payment.proof_path =
                         p_object_name
                  )
              )
          )
    );

end;
$function$;


-- =========================================================
-- B. ATTACH PROOF FUNCTION
-- =========================================================

create or replace function
public.attach_bendahara_payment_proof(
    p_payment_id uuid,
    p_proof_path text
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_staff_id uuid;
    v_staff_name text;

    v_academic_year_id uuid;
    v_academic_year_name text;

    v_student_id uuid;
    v_student_name text;
    v_student_nis text;

    v_payment_code text;
    v_payment_status text;
    v_existing_proof_path text;

    v_proof_path text;
    v_parts text[];
    v_path_payment_id text;
    v_file_name text;

    v_storage_object_id uuid;
begin

    -- =====================================================
    -- 1. AUTHENTICATION
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- 2. ROLE
    -- =====================================================

    if not public.has_role(
        'bendahara'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses bukti pembayaran Bendahara ditolak.';
    end if;


    -- =====================================================
    -- 3. ACTIVE PROFILE
    -- =====================================================

    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Bendahara tidak aktif.';
    end if;


    -- =====================================================
    -- 4. ACTIVE STAFF
    -- =====================================================

    select
        staff.id,
        staff.full_name

    into
        v_staff_id,
        v_staff_name

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Bendahara aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- 5. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.name

    into
        v_academic_year_id,
        v_academic_year_name

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;


    -- =====================================================
    -- 6. INPUT
    -- =====================================================

    if p_payment_id is null then
        raise exception
            'ID pembayaran wajib tersedia.';
    end if;


    v_proof_path :=
        nullif(
            btrim(
                coalesce(
                    p_proof_path,
                    ''
                )
            ),
            ''
        );


    if v_proof_path is null then
        raise exception
            'Path bukti pembayaran wajib tersedia.';
    end if;


    if length(
        v_proof_path
    ) > 500 then
        raise exception
            'Path bukti pembayaran terlalu panjang.';
    end if;


    -- =====================================================
    -- 7. VALIDATE PATH
    -- =====================================================

    v_parts :=
        string_to_array(
            v_proof_path,
            '/'
        );


    if coalesce(
        array_length(
            v_parts,
            1
        ),
        0
    ) <> 2
    then
        raise exception
            'Format path bukti pembayaran tidak valid.';
    end if;


    v_path_payment_id :=
        nullif(
            btrim(
                v_parts[1]
            ),
            ''
        );


    v_file_name :=
        nullif(
            btrim(
                v_parts[2]
            ),
            ''
        );


    if v_path_payment_id is null
       or v_file_name is null
    then
        raise exception
            'Format path bukti pembayaran tidak valid.';
    end if;


    if lower(
        v_path_payment_id
    ) <>
       lower(
           p_payment_id::text
       )
    then
        raise exception
            'Path bukti pembayaran tidak sesuai dengan transaksi.';
    end if;


    -- =====================================================
    -- 8. PAYMENT
    -- =====================================================

    select
        payment.student_id,
        payment.payment_code,
        payment.status,
        payment.proof_path

    into
        v_student_id,
        v_payment_code,
        v_payment_status,
        v_existing_proof_path

    from public.payments
        as payment

    where payment.id =
          p_payment_id

      and payment.academic_year_id =
          v_academic_year_id

    for update;


    if not found then
        raise exception
            'Pembayaran tidak ditemukan pada tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- 9. PAYMENT STATUS
    -- =====================================================

    if v_payment_status =
       'cancelled'
    then
        raise exception
            'Bukti baru tidak dapat ditambahkan pada pembayaran yang sudah dibatalkan.';
    end if;


    if v_payment_status <>
       'recorded'
    then
        raise exception
            'Status pembayaran tidak dapat menerima bukti pembayaran.';
    end if;


    -- =====================================================
    -- 10. EXISTING PROOF
    -- =====================================================

    if v_existing_proof_path is not null
       and v_existing_proof_path <>
           v_proof_path
    then
        raise exception
            'Pembayaran sudah memiliki bukti pembayaran.';
    end if;


    -- =====================================================
    -- 11. STORAGE OBJECT MUST EXIST
    --
    -- Kita hanya READ metadata.
    -- File tetap dibuat melalui Supabase Storage API.
    -- =====================================================

    select
        object.id

    into
        v_storage_object_id

    from storage.objects
        as object

    where object.bucket_id =
          'payment-proofs'

      and object.name =
          v_proof_path

    limit 1;


    if v_storage_object_id is null then
        raise exception
            'File bukti pembayaran belum tersedia di Storage.';
    end if;


    -- =====================================================
    -- 12. STUDENT
    -- =====================================================

    select
        student.full_name,
        student.nis

    into
        v_student_name,
        v_student_nis

    from public.students
        as student

    where student.id =
          v_student_id;


    -- =====================================================
    -- 13. ATTACH PROOF PATH
    -- =====================================================

    update public.payments
    set
        proof_path =
            v_proof_path,

        updated_by_staff_id =
            v_staff_id

    where id =
          p_payment_id;


    -- =====================================================
    -- 14. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'message',
        'Bukti pembayaran berhasil disimpan.',

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name
        ),

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'full_name',
            v_staff_name
        ),

        'student',
        jsonb_build_object(
            'id',
            v_student_id,

            'nis',
            v_student_nis,

            'full_name',
            v_student_name
        ),

        'payment',
        jsonb_build_object(
            'id',
            p_payment_id,

            'payment_code',
            v_payment_code,

            'status',
            v_payment_status,

            'proof_path',
            v_proof_path,

            'has_proof',
            true
        )
    );

end;
$function$;


-- =========================================================
-- C. COMMENT
-- =========================================================

comment on function
public.attach_bendahara_payment_proof(
    uuid,
    text
)
is
'Menghubungkan object private Storage payment-proofs dengan transaksi pembayaran Bendahara.';


-- =========================================================
-- D. PRIVILEGES
-- =========================================================

revoke all
on function
public.attach_bendahara_payment_proof(
    uuid,
    text
)
from public;


revoke all
on function
public.attach_bendahara_payment_proof(
    uuid,
    text
)
from anon;


grant execute
on function
public.attach_bendahara_payment_proof(
    uuid,
    text
)
to authenticated;


commit;