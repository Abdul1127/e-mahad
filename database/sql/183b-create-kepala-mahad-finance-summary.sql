-- ============================================================
-- E-MA'HAD
-- STAGE 183B
--
-- KEPALA MA'HAD FINANCE SUMMARY
--
-- PURPOSE:
-- - Monitoring keuangan oleh Kepala Ma'had
-- - READ ONLY
-- - Current academic year only
-- - Penanggung Jawab TIDAK memiliki akses
-- - Bendahara TIDAK menggunakan RPC ini
-- ============================================================


create or replace function public.get_kepala_mahad_finance_summary()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$

declare

    -- ========================================================
    -- AUTH / VIEWER
    -- ========================================================

    v_profile_id uuid;

    v_login_id text;

    v_staff_id uuid;
    v_staff_name text;
    v_staff_legacy_id text;


    -- ========================================================
    -- ACADEMIC YEAR
    -- ========================================================

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;


    -- ========================================================
    -- BILL SUMMARY
    -- ========================================================

    v_active_bill_count integer := 0;

    v_unpaid_count integer := 0;
    v_partial_count integer := 0;
    v_paid_count integer := 0;
    v_cancelled_count integer := 0;

    v_overdue_count integer := 0;


    -- ========================================================
    -- FINANCIAL SUMMARY
    -- ========================================================

    v_billed_amount numeric(14,2) := 0;

    v_paid_amount numeric(14,2) := 0;

    v_outstanding_amount numeric(14,2) := 0;


    -- ========================================================
    -- MONTHLY RECEIPTS
    -- ========================================================

    v_payment_count_this_month integer := 0;

    v_payment_amount_this_month numeric(14,2) := 0;


    -- ========================================================
    -- LISTS
    -- ========================================================

    v_overdue_bills jsonb :=
        '[]'::jsonb;

    v_recent_payments jsonb :=
        '[]'::jsonb;

begin

    -- ========================================================
    -- 1. AUTHENTICATION
    -- ========================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then

        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';

    end if;


    -- ========================================================
    -- 2. ROLE
    --
    -- HANYA Kepala Ma'had.
    --
    -- Penanggung Jawab tetap tidak mempunyai akses keuangan.
    -- ========================================================

    if not public.has_role(
        'kepala_mahad'
    ) then

        raise exception using
            errcode = '42501',
            message = 'Akses Ringkasan Keuangan Kepala Ma''had ditolak.';

    end if;


    -- ========================================================
    -- 3. ACTIVE PROFILE
    -- ========================================================

    select
        profile.login_id

    into
        v_login_id

    from public.profiles
        as profile

    where profile.id =
          v_profile_id

      and profile.is_active =
          true;


    if not found then

        raise exception using
            errcode = '42501',
            message = 'Profile Kepala Ma''had tidak aktif.';

    end if;


    -- ========================================================
    -- 4. ACTIVE STAFF
    -- ========================================================

    select
        staff.id,
        staff.full_name,
        staff.legacy_staff_id

    into
        v_staff_id,
        v_staff_name,
        v_staff_legacy_id

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
            message = 'Data staf Kepala Ma''had aktif tidak ditemukan.';

    end if;


    -- ========================================================
    -- 5. CURRENT ACADEMIC YEAR
    -- ========================================================

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


    -- ========================================================
    -- 6. BILL STATUS COUNTS
    -- ========================================================

    select

        count(*) filter (
            where bill.status <>
                  'cancelled'
        )::integer,


        count(*) filter (
            where bill.status =
                  'unpaid'
        )::integer,


        count(*) filter (
            where bill.status =
                  'partial'
        )::integer,


        count(*) filter (
            where bill.status =
                  'paid'
        )::integer,


        count(*) filter (
            where bill.status =
                  'cancelled'
        )::integer,


        count(*) filter (

            where bill.status in (
                'unpaid',
                'partial'
            )

              and bill.due_date
                  is not null

              and bill.due_date <
                  current_date

        )::integer

    into
        v_active_bill_count,
        v_unpaid_count,
        v_partial_count,
        v_paid_count,
        v_cancelled_count,
        v_overdue_count

    from public.student_bills
        as bill

    where bill.academic_year_id =
          v_academic_year_id;


    -- ========================================================
    -- 7. TOTAL ACTIVE BILLS
    --
    -- Cancelled bill tidak lagi dianggap sebagai kewajiban.
    -- ========================================================

    select
        coalesce(
            sum(
                bill.amount
            ),
            0
        )

    into
        v_billed_amount

    from public.student_bills
        as bill

    where bill.academic_year_id =
          v_academic_year_id

      and bill.status <>
          'cancelled';


    -- ========================================================
    -- 8. TOTAL PAID
    --
    -- Hanya menghitung:
    --
    -- - payment = recorded
    -- - bill tidak cancelled
    -- - tahun ajaran aktif
    --
    -- Allocation dari payment cancelled tetap berada
    -- di database sebagai audit trail tetapi tidak dihitung.
    -- ========================================================

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

    inner join public.student_bills
        as bill

        on bill.id =
           allocation.bill_id

    where bill.academic_year_id =
          v_academic_year_id

      and payment.academic_year_id =
          v_academic_year_id

      and payment.status =
          'recorded'

      and bill.status <>
          'cancelled';


    v_outstanding_amount :=
        greatest(
            v_billed_amount -
            v_paid_amount,
            0
        );


    -- ========================================================
    -- 9. PAYMENT THIS MONTH
    --
    -- Menggunakan payment.amount karena ini merupakan
    -- penerimaan kas/transaksi pada bulan berjalan.
    --
    -- Payment cancelled tidak dihitung.
    -- ========================================================

    select
        count(*)::integer,

        coalesce(
            sum(
                payment.amount
            ),
            0
        )

    into
        v_payment_count_this_month,
        v_payment_amount_this_month

    from public.payments
        as payment

    where payment.academic_year_id =
          v_academic_year_id

      and payment.status =
          'recorded'

      and payment.payment_date >=
          date_trunc(
              'month',
              current_date
          )::date

      and payment.payment_date <
          (
              date_trunc(
                  'month',
                  current_date
              )
              +
              interval '1 month'
          )::date;


    -- ========================================================
    -- 10. OVERDUE BILLS
    --
    -- Maksimal 10 tagihan.
    -- Read-only monitoring.
    -- ========================================================

    select
        coalesce(
            jsonb_agg(
                overdue_data.payload

                order by
                    overdue_data.due_date,
                    overdue_data.student_name,
                    overdue_data.bill_id
            ),
            '[]'::jsonb
        )

    into
        v_overdue_bills

    from (

        select

            bill.id
                as bill_id,

            bill.due_date,

            student.full_name
                as student_name,


            jsonb_build_object(

                'id',
                bill.id,

                'bill_code',
                bill.bill_code,

                'title',
                bill.title,

                'category',
                bill.category,

                'period_label',
                bill.period_label,

                'amount',
                bill.amount,

                'paid_amount',
                coalesce(
                    bill_payment.paid_amount,
                    0
                ),

                'outstanding_amount',
                greatest(
                    bill.amount -
                    coalesce(
                        bill_payment.paid_amount,
                        0
                    ),
                    0
                ),

                'due_date',
                bill.due_date,

                'status',
                bill.status,

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
                )
            )
                as payload

        from public.student_bills
            as bill

        inner join public.students
            as student

            on student.id =
               bill.student_id


        left join lateral (

            select

                coalesce(
                    sum(
                        allocation.amount
                    ),
                    0
                )::numeric(14,2)
                    as paid_amount

            from public.payment_allocations
                as allocation

            inner join public.payments
                as payment

                on payment.id =
                   allocation.payment_id

            where allocation.bill_id =
                  bill.id

              and payment.status =
                  'recorded'

        ) as bill_payment
            on true


        where bill.academic_year_id =
              v_academic_year_id

          and bill.status in (
              'unpaid',
              'partial'
          )

          and bill.due_date
              is not null

          and bill.due_date <
              current_date

        order by
            bill.due_date,
            student.full_name,
            bill.id

        limit 10

    ) as overdue_data;


    -- ========================================================
    -- 11. RECENT PAYMENTS
    --
    -- Recorded dan cancelled tetap terlihat pada monitoring
    -- supaya histori koreksi transaksi tidak hilang.
    --
    -- Tidak mengirim proof_path karena Kepala Ma'had hanya
    -- membutuhkan monitoring ringkasan, bukan akses dokumen
    -- pembayaran.
    -- ========================================================

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
        )

    into
        v_recent_payments

    from (

        select

            payment.id
                as payment_id,

            payment.payment_date,

            payment.created_at,


            jsonb_build_object(

                'id',
                    payment.id,

                'payment_code',
                    payment.payment_code,

                'payment_date',
                    payment.payment_date,

                'amount',
                    payment.amount,

                'allocated_amount',
                    case

                        when payment.status =
                             'recorded'

                        then coalesce(
                            payment_allocation.allocated_amount,
                            0
                        )

                        else 0

                    end,

                'payment_method',
                    payment.payment_method,

                'reference_number',
                    payment.reference_number,

                'status',
                    payment.status,

                'cancelled_at',
                    payment.cancelled_at,

                'cancellation_reason',
                    payment.cancellation_reason,

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
                    )
            )
                as payload

        from public.payments
            as payment

        inner join public.students
            as student

            on student.id =
               payment.student_id


        left join lateral (

            select

                coalesce(
                    sum(
                        allocation.amount
                    ),
                    0
                )::numeric(14,2)
                    as allocated_amount

            from public.payment_allocations
                as allocation

            where allocation.payment_id =
                  payment.id

        ) as payment_allocation
            on true


        where payment.academic_year_id =
              v_academic_year_id

        order by
            payment.payment_date desc,
            payment.created_at desc,
            payment.id desc

        limit 10

    ) as payment_data;


    -- ========================================================
    -- 12. RESPONSE
    -- ========================================================

    return jsonb_build_object(

        'generated_at',
            now(),


        'access_mode',
            'read_only',


        'viewer',
            jsonb_build_object(

                'profile_id',
                    v_profile_id,

                'login_id',
                    v_login_id,

                'staff_id',
                    v_staff_id,

                'legacy_staff_id',
                    v_staff_legacy_id,

                'full_name',
                    v_staff_name,

                'role',
                    'kepala_mahad'
            ),


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

                'active_bill_count',
                    coalesce(
                        v_active_bill_count,
                        0
                    ),

                'unpaid_count',
                    coalesce(
                        v_unpaid_count,
                        0
                    ),

                'partial_count',
                    coalesce(
                        v_partial_count,
                        0
                    ),

                'paid_count',
                    coalesce(
                        v_paid_count,
                        0
                    ),

                'cancelled_count',
                    coalesce(
                        v_cancelled_count,
                        0
                    ),

                'overdue_count',
                    coalesce(
                        v_overdue_count,
                        0
                    ),

                'billed_amount',
                    coalesce(
                        v_billed_amount,
                        0
                    ),

                'paid_amount',
                    coalesce(
                        v_paid_amount,
                        0
                    ),

                'outstanding_amount',
                    coalesce(
                        v_outstanding_amount,
                        0
                    ),

                'payment_count_this_month',
                    coalesce(
                        v_payment_count_this_month,
                        0
                    ),

                'payment_amount_this_month',
                    coalesce(
                        v_payment_amount_this_month,
                        0
                    )
            ),


        'overdue_bills',
            coalesce(
                v_overdue_bills,
                '[]'::jsonb
            ),


        'recent_payments',
            coalesce(
                v_recent_payments,
                '[]'::jsonb
            )
    );

end;

$function$;


-- ============================================================
-- FUNCTION SECURITY
-- ============================================================

revoke all
on function public.get_kepala_mahad_finance_summary()
from public;


revoke all
on function public.get_kepala_mahad_finance_summary()
from anon;


grant execute
on function public.get_kepala_mahad_finance_summary()
to authenticated;


grant execute
on function public.get_kepala_mahad_finance_summary()
to service_role;


-- ============================================================
-- DOCUMENTATION
-- ============================================================

comment on function public.get_kepala_mahad_finance_summary()
is
'Read-only monitoring keuangan tahun ajaran aktif untuk Kepala Ma''had. Penanggung Jawab dan role lain ditolak oleh role gate di dalam SECURITY DEFINER function.';