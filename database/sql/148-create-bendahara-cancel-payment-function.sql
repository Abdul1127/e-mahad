begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 148-create-bendahara-cancel-payment-function.sql
--
-- PURPOSE:
-- Membatalkan transaksi pembayaran yang salah tanpa
-- menghapus histori transaksi.
--
-- FLOW:
--
-- payments.status
-- recorded
--     ↓
-- cancelled
--
-- Payment tetap tersimpan.
-- Allocation tetap tersimpan sebagai audit trail.
--
-- Trigger Finance Foundation akan menghitung ulang
-- status seluruh tagihan yang pernah menerima alokasi
-- dari payment tersebut.
--
-- CONTOH:
--
-- Tagihan Rp750.000
--
-- Payment A = Rp300.000
-- Payment B = Rp450.000
--
-- Status awal:
-- paid / lunas
--
-- Payment A dibatalkan
--
-- Total pembayaran aktif = Rp450.000
-- Status tagihan = partial
-- Outstanding = Rp300.000
--
-- SECURITY:
-- - authenticated
-- - role Bendahara
-- - profile aktif
-- - staff aktif
-- - current academic year
-- - payment harus recorded
-- - alasan pembatalan wajib
--
-- IMPORTANT:
-- Payment TIDAK dihapus.
-- Payment allocation TIDAK dihapus.
-- =========================================================


create or replace function
public.cancel_bendahara_payment(
    p_payment_id uuid,
    p_cancellation_reason text
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
    v_payment_date date;
    v_payment_amount numeric(14,2);
    v_payment_method text;
    v_reference_number text;
    v_payment_status text;

    v_reason text;

    v_cancelled_at timestamptz;

    v_historical_allocated_amount numeric(14,2) :=
        0;

    v_affected_bill_count integer :=
        0;

    v_affected_bills jsonb :=
        '[]'::jsonb;
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
            message = 'Akses pembatalan pembayaran Bendahara ditolak.';
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

    if p_payment_id is null then
        raise exception
            'ID pembayaran wajib tersedia.';
    end if;


    v_reason :=
        nullif(
            btrim(
                coalesce(
                    p_cancellation_reason,
                    ''
                )
            ),
            ''
        );


    if v_reason is null then
        raise exception
            'Alasan pembatalan pembayaran wajib diisi.';
    end if;


    if length(
        v_reason
    ) > 1000 then
        raise exception
            'Alasan pembatalan maksimal 1000 karakter.';
    end if;


    -- =====================================================
    -- G. LOCK PAYMENT
    --
    -- FOR UPDATE mencegah transaksi yang sama dibatalkan
    -- secara bersamaan.
    -- =====================================================

    select
        payment.student_id,
        payment.payment_code,
        payment.payment_date,
        payment.amount,
        payment.payment_method,
        payment.reference_number,
        payment.status

    into
        v_student_id,
        v_payment_code,
        v_payment_date,
        v_payment_amount,
        v_payment_method,
        v_reference_number,
        v_payment_status

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
    -- H. PAYMENT STATUS
    -- =====================================================

    if v_payment_status =
       'cancelled'
    then
        raise exception
            'Pembayaran sudah dibatalkan sebelumnya.';
    end if;


    if v_payment_status <>
       'recorded'
    then
        raise exception
            'Status pembayaran tidak dapat dibatalkan.';
    end if;


    -- =====================================================
    -- I. STUDENT
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
    -- J. HISTORICAL ALLOCATION
    --
    -- Allocation tetap disimpan walaupun payment cancelled.
    -- =====================================================

    select
        coalesce(
            sum(
                allocation.amount
            ),
            0
        )

    into
        v_historical_allocated_amount

    from public.payment_allocations
        as allocation

    where allocation.payment_id =
          p_payment_id;


    -- =====================================================
    -- K. CANCEL PAYMENT
    --
    -- Trigger handle_payment_status_bill_recalculation()
    -- dari Finance Foundation akan otomatis menghitung ulang
    -- tagihan yang terkait.
    -- =====================================================

    update public.payments
    set
        status =
            'cancelled',

        cancelled_at =
            now(),

        cancelled_by_staff_id =
            v_staff_id,

        cancellation_reason =
            v_reason,

        updated_by_staff_id =
            v_staff_id

    where id =
          p_payment_id

    returning
        cancelled_at

    into
        v_cancelled_at;


    -- =====================================================
    -- L. READ AFFECTED BILLS AFTER RECALCULATION
    -- =====================================================

    select
        count(*)::integer,

        coalesce(
            jsonb_agg(
                affected.payload

                order by
                    affected.bill_code,
                    affected.bill_id
            ),
            '[]'::jsonb
        )

    into
        v_affected_bill_count,
        v_affected_bills

    from (
        select
            bill.id
                as bill_id,

            bill.bill_code,

            jsonb_build_object(
                'id',
                bill.id,

                'bill_code',
                bill.bill_code,

                'title',
                bill.title,

                'amount',
                bill.amount,

                'status',
                bill.status,

                'paid_amount',
                coalesce(
                    (
                        select
                            sum(
                                active_allocation.amount
                            )

                        from public.payment_allocations
                            as active_allocation

                        inner join public.payments
                            as active_payment
                            on active_payment.id =
                               active_allocation.payment_id

                        where active_allocation.bill_id =
                              bill.id

                          and active_payment.status =
                              'recorded'
                    ),
                    0
                ),

                'outstanding_amount',
                case
                    when bill.status =
                         'cancelled'
                    then
                        0

                    else
                        greatest(
                            bill.amount -
                            coalesce(
                                (
                                    select
                                        sum(
                                            active_allocation.amount
                                        )

                                    from public.payment_allocations
                                        as active_allocation

                                    inner join public.payments
                                        as active_payment
                                        on active_payment.id =
                                           active_allocation.payment_id

                                    where active_allocation.bill_id =
                                          bill.id

                                      and active_payment.status =
                                          'recorded'
                                ),
                                0
                            ),
                            0
                        )
                end
            ) as payload

        from public.payment_allocations
            as allocation

        inner join public.student_bills
            as bill
            on bill.id =
               allocation.bill_id

        where allocation.payment_id =
              p_payment_id

        group by
            bill.id,
            bill.bill_code,
            bill.title,
            bill.amount,
            bill.status
    ) as affected;


    -- =====================================================
    -- M. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'message',
        'Pembayaran berhasil dibatalkan.',

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

            'payment_date',
            v_payment_date,

            'amount',
            v_payment_amount,

            'payment_method',
            v_payment_method,

            'reference_number',
            v_reference_number,

            'status',
            'cancelled',

            'historical_allocated_amount',
            v_historical_allocated_amount,

            'cancelled_at',
            v_cancelled_at,

            'cancellation_reason',
            v_reason
        ),

        'affected_bill_count',
        coalesce(
            v_affected_bill_count,
            0
        ),

        'affected_bills',
        coalesce(
            v_affected_bills,
            '[]'::jsonb
        )
    );

end;
$function$;


-- =========================================================
-- COMMENT
-- =========================================================

comment on function
public.cancel_bendahara_payment(
    uuid,
    text
)
is
'Membatalkan transaksi pembayaran Bendahara tanpa menghapus histori pembayaran maupun allocation.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all
on function
public.cancel_bendahara_payment(
    uuid,
    text
)
from public;


revoke all
on function
public.cancel_bendahara_payment(
    uuid,
    text
)
from anon;


grant execute
on function
public.cancel_bendahara_payment(
    uuid,
    text
)
to authenticated;


commit;