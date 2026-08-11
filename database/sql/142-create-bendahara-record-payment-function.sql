begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 142-create-bendahara-record-payment-function.sql
--
-- PURPOSE:
-- Mencatat pembayaran Bendahara untuk satu tagihan.
--
-- FLOW:
--
-- student_bills
--      ↓
-- payments
--      ↓
-- payment_allocations
--      ↓
-- trigger otomatis menghitung status tagihan:
--
-- unpaid
-- partial
-- paid
--
-- SECURITY:
-- - authenticated
-- - role bendahara
-- - profile aktif
-- - staff aktif
-- - current academic year
-- - bill harus aktif
-- - pembayaran tidak boleh > sisa tagihan
--
-- CATATAN:
-- Pada workflow awal ini:
--
-- 1 transaksi pembayaran
--      =
-- 1 alokasi penuh ke 1 tagihan
--
-- Struktur payment_allocations tetap mendukung pengembangan
-- multi-tagihan pada masa mendatang.
-- =========================================================


create or replace function
public.record_bendahara_bill_payment(
    p_bill_id uuid,
    p_payment_date date,
    p_amount numeric,
    p_payment_method text,
    p_reference_number text default null,
    p_notes text default null
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

    v_bill_code text;
    v_bill_title text;
    v_bill_amount numeric(14,2);
    v_bill_status text;

    v_paid_amount numeric(14,2) := 0;
    v_outstanding_amount numeric(14,2) := 0;

    v_payment_method text;
    v_reference_number text;
    v_notes text;

    v_payment_code text;
    v_payment_id uuid;
    v_allocation_id uuid;

    v_new_bill_status text;

    v_created_at timestamptz;
begin

    -- =====================================================
    -- A. AUTHENTICATION
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- B. ROLE
    -- =====================================================

    if not public.has_role(
        'bendahara'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses pencatatan pembayaran Bendahara ditolak.';
    end if;


    -- =====================================================
    -- C. ACTIVE PROFILE
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
    -- D. ACTIVE STAFF
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
    -- E. CURRENT ACADEMIC YEAR
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
    -- F. INPUT
    -- =====================================================

    if p_bill_id is null then
        raise exception
            'Tagihan wajib dipilih.';
    end if;


    if p_payment_date is null then
        raise exception
            'Tanggal pembayaran wajib diisi.';
    end if;


    if p_payment_date >
       current_date
    then
        raise exception
            'Tanggal pembayaran tidak boleh melebihi hari ini.';
    end if;


    if p_amount is null
       or p_amount <= 0
    then
        raise exception
            'Nominal pembayaran harus lebih besar dari 0.';
    end if;


    if p_amount >
       999999999999.99
    then
        raise exception
            'Nominal pembayaran melebihi batas yang diperbolehkan.';
    end if;


    -- =====================================================
    -- G. PAYMENT METHOD
    -- =====================================================

    v_payment_method :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_payment_method,
                        ''
                    )
                )
            ),
            ''
        );


    if v_payment_method is null then
        raise exception
            'Metode pembayaran wajib dipilih.';
    end if;


    if v_payment_method not in (
        'cash',
        'transfer',
        'bank_transfer',
        'other'
    ) then
        raise exception
            'Metode pembayaran tidak valid.';
    end if;


    -- =====================================================
    -- H. OPTIONAL TEXT
    -- =====================================================

    v_reference_number :=
        nullif(
            btrim(
                coalesce(
                    p_reference_number,
                    ''
                )
            ),
            ''
        );


    v_notes :=
        nullif(
            btrim(
                coalesce(
                    p_notes,
                    ''
                )
            ),
            ''
        );


    if v_reference_number is not null
       and length(
           v_reference_number
       ) > 150
    then
        raise exception
            'Nomor referensi maksimal 150 karakter.';
    end if;


    if v_notes is not null
       and length(
           v_notes
       ) > 1000
    then
        raise exception
            'Catatan pembayaran maksimal 1000 karakter.';
    end if;


    -- =====================================================
    -- I. LOCK BILL
    --
    -- FOR UPDATE mencegah dua transaksi membayar sisa
    -- tagihan yang sama secara bersamaan.
    -- =====================================================

    select
        bill.student_id,
        bill.bill_code,
        bill.title,
        bill.amount,
        bill.status

    into
        v_student_id,
        v_bill_code,
        v_bill_title,
        v_bill_amount,
        v_bill_status

    from public.student_bills
        as bill

    where bill.id =
          p_bill_id

      and bill.academic_year_id =
          v_academic_year_id

    for update;


    if not found then
        raise exception
            'Tagihan tidak ditemukan pada tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- J. BILL STATUS
    -- =====================================================

    if v_bill_status =
       'cancelled'
    then
        raise exception
            'Tagihan yang dibatalkan tidak dapat menerima pembayaran.';
    end if;


    if v_bill_status =
       'paid'
    then
        raise exception
            'Tagihan sudah lunas.';
    end if;


    -- =====================================================
    -- K. STUDENT
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
    -- L. CURRENT PAID AMOUNT
    -- =====================================================

    select
        coalesce(
            sum(
                allocation.amount
            ),
            0
        )

    into
        v_paid_amount

    from public.payment_allocations
        as allocation

    inner join public.payments
        as payment
        on payment.id =
           allocation.payment_id

    where allocation.bill_id =
          p_bill_id

      and payment.status =
          'recorded';


    v_outstanding_amount :=
        greatest(
            v_bill_amount -
            v_paid_amount,
            0
        );


    if v_outstanding_amount <= 0 then
        raise exception
            'Tagihan sudah tidak memiliki sisa pembayaran.';
    end if;


    -- =====================================================
    -- M. PREVENT OVERPAYMENT
    -- =====================================================

    if p_amount >
       v_outstanding_amount
    then
        raise exception
            'Nominal pembayaran melebihi sisa tagihan sebesar %.',
            v_outstanding_amount;
    end if;


    -- =====================================================
    -- N. PAYMENT CODE
    --
    -- Example:
    -- BAY-202608-A1B2C3D4
    -- =====================================================

    v_payment_code :=
        'BAY-' ||
        to_char(
            current_date,
            'YYYYMM'
        ) ||
        '-' ||
        upper(
            substr(
                replace(
                    gen_random_uuid()::text,
                    '-',
                    ''
                ),
                1,
                8
            )
        );


    -- =====================================================
    -- O. CREATE PAYMENT
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

        status,

        recorded_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        v_student_id,

        v_payment_code,
        p_payment_date,

        p_amount,
        v_payment_method,

        v_reference_number,
        v_notes,

        'recorded',

        v_staff_id,
        v_staff_id
    )
    returning
        id,
        created_at

    into
        v_payment_id,
        v_created_at;


    -- =====================================================
    -- P. ALLOCATION
    --
    -- Seluruh pembayaran pada workflow ini langsung
    -- dialokasikan ke bill yang dipilih.
    -- =====================================================

    insert into public.payment_allocations (
        payment_id,
        bill_id,
        amount,
        created_by_staff_id
    )
    values (
        v_payment_id,
        p_bill_id,
        p_amount,
        v_staff_id
    )
    returning id
    into v_allocation_id;


    -- =====================================================
    -- Q. READ NEW BILL STATUS
    --
    -- Trigger payment_allocations otomatis melakukan
    -- recalculate_student_bill_status().
    -- =====================================================

    select
        bill.status

    into
        v_new_bill_status

    from public.student_bills
        as bill

    where bill.id =
          p_bill_id;


    -- =====================================================
    -- R. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'message',
        'Pembayaran berhasil dicatat.',

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

        'bill',
        jsonb_build_object(
            'id',
            p_bill_id,

            'bill_code',
            v_bill_code,

            'title',
            v_bill_title,

            'amount',
            v_bill_amount,

            'previous_paid_amount',
            v_paid_amount,

            'payment_amount',
            p_amount,

            'paid_amount',
            v_paid_amount +
            p_amount,

            'outstanding_amount',
            greatest(
                v_outstanding_amount -
                p_amount,
                0
            ),

            'status',
            v_new_bill_status
        ),

        'payment',
        jsonb_build_object(
            'id',
            v_payment_id,

            'payment_code',
            v_payment_code,

            'payment_date',
            p_payment_date,

            'amount',
            p_amount,

            'payment_method',
            v_payment_method,

            'reference_number',
            v_reference_number,

            'notes',
            v_notes,

            'status',
            'recorded',

            'created_at',
            v_created_at
        ),

        'allocation',
        jsonb_build_object(
            'id',
            v_allocation_id,

            'bill_id',
            p_bill_id,

            'payment_id',
            v_payment_id,

            'amount',
            p_amount
        )
    );

end;
$function$;


-- =========================================================
-- COMMENT
-- =========================================================

comment on function
public.record_bendahara_bill_payment(
    uuid,
    date,
    numeric,
    text,
    text,
    text
)
is
'Mencatat transaksi pembayaran Bendahara dan langsung mengalokasikannya ke satu tagihan santri.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all
on function
public.record_bendahara_bill_payment(
    uuid,
    date,
    numeric,
    text,
    text,
    text
)
from public;


revoke all
on function
public.record_bendahara_bill_payment(
    uuid,
    date,
    numeric,
    text,
    text,
    text
)
from anon;


grant execute
on function
public.record_bendahara_bill_payment(
    uuid,
    date,
    numeric,
    text,
    text,
    text
)
to authenticated;


commit;