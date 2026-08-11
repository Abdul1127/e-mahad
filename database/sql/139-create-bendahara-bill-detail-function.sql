begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 139-create-bendahara-bill-detail-function.sql
--
-- PURPOSE:
-- Detail satu tagihan untuk Bendahara.
--
-- MENAMPILKAN:
-- - Data santri
-- - Informasi tagihan
-- - Nominal tagihan
-- - Total pembayaran aktif
-- - Sisa tagihan
-- - Riwayat pembayaran yang dialokasikan
-- - Status pembayaran
-- - Flag apakah masih bisa menerima pembayaran
-- - Flag apakah tagihan bisa dibatalkan
--
-- SECURITY:
-- - authenticated
-- - role bendahara
-- - profile aktif
-- - staff aktif
-- - hanya tahun ajaran aktif
-- =========================================================


create or replace function
public.get_bendahara_bill_detail(
    p_bill_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_staff_id uuid;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_bill jsonb;

    v_payment_items jsonb :=
        '[]'::jsonb;

    v_paid_amount numeric(14,2) :=
        0;

    v_outstanding_amount numeric(14,2) :=
        0;

    v_bill_amount numeric(14,2);

    v_bill_status text;

    v_payment_count integer :=
        0;

    v_recorded_payment_count integer :=
        0;

    v_cancelled_payment_count integer :=
        0;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'bendahara'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Detail Tagihan Bendahara ditolak.';
    end if;


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


    select
        staff.id

    into
        v_staff_id

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
    -- B. INPUT
    -- =====================================================

    if p_bill_id is null then
        raise exception
            'ID tagihan wajib tersedia.';
    end if;


    -- =====================================================
    -- C. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.name,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
        v_academic_year_name,
        v_academic_year_start,
        v_academic_year_end

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
    -- D. BILL FINANCIAL TOTAL
    -- =====================================================

    select
        bill.amount,
        bill.status

    into
        v_bill_amount,
        v_bill_status

    from public.student_bills
        as bill

    where bill.id =
          p_bill_id

      and bill.academic_year_id =
          v_academic_year_id;


    if not found then
        raise exception
            'Tagihan tidak ditemukan pada tahun ajaran aktif.';
    end if;


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


    if v_bill_status =
       'cancelled'
    then
        v_outstanding_amount :=
            0;
    else
        v_outstanding_amount :=
            greatest(
                v_bill_amount -
                v_paid_amount,
                0
            );
    end if;


    -- =====================================================
    -- E. BILL DATA
    -- =====================================================

    select
        jsonb_build_object(
            'id',
            bill.id,

            'bill_code',
            bill.bill_code,

            'title',
            bill.title,

            'description',
            bill.description,

            'category',
            bill.category,

            'period_label',
            bill.period_label,

            'period_start',
            bill.period_start,

            'period_end',
            bill.period_end,

            'amount',
            bill.amount,

            'paid_amount',
            v_paid_amount,

            'outstanding_amount',
            v_outstanding_amount,

            'due_date',
            bill.due_date,

            'is_overdue',
            (
                bill.status in (
                    'unpaid',
                    'partial'
                )
                and bill.due_date
                    is not null
                and bill.due_date <
                    current_date
            ),

            'status',
            bill.status,

            'cancelled_at',
            bill.cancelled_at,

            'cancellation_reason',
            bill.cancellation_reason,

            'created_at',
            bill.created_at,

            'updated_at',
            bill.updated_at,

            'can_record_payment',
            (
                bill.status in (
                    'unpaid',
                    'partial'
                )
                and v_outstanding_amount > 0
            ),

            'can_cancel',
            (
                bill.status <>
                    'cancelled'
                and v_paid_amount =
                    0
            ),

            'student',
            jsonb_build_object(
                'id',
                student.id,

                'legacy_student_id',
                student.legacy_student_id,

                'nis',
                student.nis,

                'full_name',
                student.full_name,

                'gender',
                student.gender::text
            ),

            'class',
            case
                when current_class.class_id
                     is null
                then null

                else jsonb_build_object(
                    'id',
                    current_class.class_id,

                    'name',
                    current_class.class_name,

                    'grade_level',
                    current_class.grade_level
                )
            end
        )

    into
        v_bill

    from public.student_bills
        as bill

    inner join public.students
        as student
        on student.id =
           bill.student_id

    left join lateral (
        select
            class.id
                as class_id,

            class.name
                as class_name,

            class.grade_level

        from public.class_enrollments
            as enrollment

        inner join public.classes
            as class
            on class.id =
               enrollment.class_id

        where enrollment.student_id =
              student.id

          and enrollment.is_active =
              true

          and class.is_active =
              true

          and class.academic_year_id =
              v_academic_year_id

        order by
            enrollment.enrolled_at desc,
            enrollment.created_at desc

        limit 1
    ) as current_class
        on true

    where bill.id =
          p_bill_id

      and bill.academic_year_id =
          v_academic_year_id;


    -- =====================================================
    -- F. PAYMENT HISTORY
    --
    -- Semua payment yang pernah dialokasikan ke bill
    -- ditampilkan, termasuk payment cancelled.
    --
    -- Tetapi total paid_amount hanya menghitung recorded.
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                payment_data.payload

                order by
                    payment_data.payment_date desc,
                    payment_data.created_at desc,
                    payment_data.payment_id desc
            ),
            '[]'::jsonb
        ),

        count(*)::integer,

        count(*) filter (
            where payment_data.payment_status =
                  'recorded'
        )::integer,

        count(*) filter (
            where payment_data.payment_status =
                  'cancelled'
        )::integer

    into
        v_payment_items,
        v_payment_count,
        v_recorded_payment_count,
        v_cancelled_payment_count

    from (
        select
            payment.id
                as payment_id,

            payment.payment_date,

            payment.created_at,

            payment.status
                as payment_status,

            jsonb_build_object(
                'allocation_id',
                allocation.id,

                'allocation_amount',
                allocation.amount,

                'payment',
                jsonb_build_object(
                    'id',
                    payment.id,

                    'payment_code',
                    payment.payment_code,

                    'payment_date',
                    payment.payment_date,

                    'amount',
                    payment.amount,

                    'payment_method',
                    payment.payment_method,

                    'reference_number',
                    payment.reference_number,

                    'notes',
                    payment.notes,

                    'proof_path',
                    payment.proof_path,

                    'status',
                    payment.status,

                    'cancelled_at',
                    payment.cancelled_at,

                    'cancellation_reason',
                    payment.cancellation_reason,

                    'created_at',
                    payment.created_at,

                    'updated_at',
                    payment.updated_at
                )
            ) as payload

        from public.payment_allocations
            as allocation

        inner join public.payments
            as payment
            on payment.id =
               allocation.payment_id

        where allocation.bill_id =
              p_bill_id

        order by
            payment.payment_date desc,
            payment.created_at desc,
            payment.id desc
    ) as payment_data;


    -- =====================================================
    -- G. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name,

            'start_date',
            v_academic_year_start,

            'end_date',
            v_academic_year_end
        ),

        'summary',
        jsonb_build_object(
            'payment_count',
            coalesce(
                v_payment_count,
                0
            ),

            'recorded_payment_count',
            coalesce(
                v_recorded_payment_count,
                0
            ),

            'cancelled_payment_count',
            coalesce(
                v_cancelled_payment_count,
                0
            ),

            'bill_amount',
            v_bill_amount,

            'paid_amount',
            v_paid_amount,

            'outstanding_amount',
            v_outstanding_amount
        ),

        'bill',
        v_bill,

        'payments',
        coalesce(
            v_payment_items,
            '[]'::jsonb
        )
    );

end;
$function$;


comment on function
public.get_bendahara_bill_detail(
    uuid
)
is
'Detail tagihan santri beserta riwayat pembayaran untuk Bendahara.';


revoke all
on function
public.get_bendahara_bill_detail(
    uuid
)
from public;


revoke all
on function
public.get_bendahara_bill_detail(
    uuid
)
from anon;


grant execute
on function
public.get_bendahara_bill_detail(
    uuid
)
to authenticated;


commit;