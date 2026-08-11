begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 151-create-payment-proof-storage-foundation.sql
--
-- PURPOSE:
-- Fondasi private Supabase Storage untuk bukti pembayaran.
--
-- BUCKET:
-- payment-proofs
--
-- PRIVATE:
-- public = false
--
-- LIMIT:
-- 5 MB
--
-- ALLOWED MIME TYPES:
-- - image/jpeg
-- - image/png
-- - image/webp
-- - application/pdf
--
-- OBJECT PATH FORMAT:
--
-- {payment_id}/{unique_file_name}
--
-- Example:
--
-- 7b763252-....../f6a413c1-receipt.jpg
--
-- ACCESS:
--
-- BENDAHARA
--   SELECT  = yes
--   INSERT  = yes, payment harus recorded
--   UPDATE  = yes, payment harus recorded
--   DELETE  = yes
--
-- Untuk payment cancelled:
--   bukti lama tetap bisa dibaca sebagai audit trail,
--   tetapi file baru tidak boleh di-upload/update.
--
-- IMPORTANT:
-- Tidak ada akses public ke bucket.
-- =========================================================


-- =========================================================
-- A. CREATE / NORMALIZE PRIVATE BUCKET
-- =========================================================

insert into storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values (
    'payment-proofs',
    'payment-proofs',
    false,
    5242880,
    array[
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf'
    ]::text[]
)

on conflict (id)
do update
set
    name =
        excluded.name,

    public =
        false,

    file_size_limit =
        5242880,

    allowed_mime_types =
        array[
            'image/jpeg',
            'image/png',
            'image/webp',
            'application/pdf'
        ]::text[];


-- =========================================================
-- B. SECURITY HELPER
--
-- Kenapa menggunakan SECURITY DEFINER:
--
-- public.payments menggunakan RLS dan tidak memberikan
-- direct table access kepada authenticated.
--
-- Storage policy tetap perlu memvalidasi:
--
-- - auth user
-- - Bendahara
-- - profile aktif
-- - staff aktif
-- - payment valid
-- - tahun ajaran aktif
--
-- Helper ini melakukan validasi tersebut dengan aman.
--
-- p_for_write:
--
-- false
--   payment recorded/cancelled boleh diakses untuk membaca
--   historical proof.
--
-- true
--   payment wajib recorded.
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
    -- 5. OBJECT PATH
    --
    -- Required:
    --
    -- payment_id/file_name
    --
    -- Tidak menerima:
    --
    -- file.jpg
    --
    -- payment_id/folder/file.jpg
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
    -- 6. UUID SHAPE
    --
    -- Tidak melakukan direct cast terlebih dahulu supaya
    -- malformed path menghasilkan false, bukan SQL error.
    -- =====================================================

    if v_payment_id_text !~
       '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
    then
        return false;
    end if;


    -- =====================================================
    -- 7. PAYMENT ACCESS
    --
    -- Payment harus:
    --
    -- - termasuk tahun ajaran aktif
    -- - student/payment benar-benar ada
    --
    -- WRITE:
    -- payment wajib status recorded
    --
    -- READ:
    -- recorded maupun cancelled dapat dibaca.
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

              or payment.status =
                 'recorded'
          )
    );

end;
$function$;


comment on function
public.can_bendahara_access_payment_proof(
    text,
    boolean
)
is
'Security helper RLS Storage untuk validasi akses Bendahara terhadap bukti pembayaran berdasarkan path payment_id/file_name.';


-- =========================================================
-- C. FUNCTION PRIVILEGES
-- =========================================================

revoke all
on function
public.can_bendahara_access_payment_proof(
    text,
    boolean
)
from public;


revoke all
on function
public.can_bendahara_access_payment_proof(
    text,
    boolean
)
from anon;


grant execute
on function
public.can_bendahara_access_payment_proof(
    text,
    boolean
)
to authenticated;


-- =========================================================
-- D. REMOVE PREVIOUS POLICIES IF SCRIPT RE-RUN
-- =========================================================

drop policy if exists
"payment_proofs_bendahara_select"
on storage.objects;


drop policy if exists
"payment_proofs_bendahara_insert"
on storage.objects;


drop policy if exists
"payment_proofs_bendahara_update"
on storage.objects;


drop policy if exists
"payment_proofs_bendahara_delete"
on storage.objects;


-- =========================================================
-- E. SELECT POLICY
--
-- Recorded + cancelled payment boleh dibaca.
--
-- Ini penting karena bukti pembayaran yang kemudian
-- dibatalkan tetap bagian dari audit trail.
-- =========================================================

create policy
"payment_proofs_bendahara_select"

on storage.objects

for select

to authenticated

using (
    bucket_id =
        'payment-proofs'

    and public.can_bendahara_access_payment_proof(
        name,
        false
    )
);


-- =========================================================
-- F. INSERT POLICY
--
-- Hanya payment recorded yang boleh mendapat file baru.
-- =========================================================

create policy
"payment_proofs_bendahara_insert"

on storage.objects

for insert

to authenticated

with check (
    bucket_id =
        'payment-proofs'

    and public.can_bendahara_access_payment_proof(
        name,
        true
    )
);


-- =========================================================
-- G. UPDATE POLICY
--
-- Untuk replacement/upsert di masa mendatang.
--
-- Hanya payment recorded.
-- =========================================================

create policy
"payment_proofs_bendahara_update"

on storage.objects

for update

to authenticated

using (
    bucket_id =
        'payment-proofs'

    and public.can_bendahara_access_payment_proof(
        name,
        true
    )
)

with check (
    bucket_id =
        'payment-proofs'

    and public.can_bendahara_access_payment_proof(
        name,
        true
    )
);


-- =========================================================
-- H. DELETE POLICY
--
-- Dibuka untuk Bendahara agar file orphan dapat dibersihkan.
--
-- Payment recorded maupun cancelled dapat dihapus dari
-- Storage oleh workflow aplikasi yang terkontrol.
--
-- Penghapusan bukti pembayaran dari aplikasi belum kita
-- aktifkan pada frontend sekarang.
-- =========================================================

create policy
"payment_proofs_bendahara_delete"

on storage.objects

for delete

to authenticated

using (
    bucket_id =
        'payment-proofs'

    and public.can_bendahara_access_payment_proof(
        name,
        false
    )
);


commit;