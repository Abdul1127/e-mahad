-- ============================================================
-- E-MA'HAD
-- STAGE 184A
--
-- BENDAHARA FINANCE REPORT
--
-- READ ONLY REPORT
-- Current academic year
-- Period based
-- ============================================================

create or replace function public.get_bendahara_finance_report(
    p_start_date date default null,
    p_end_date date default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$

declare
    -- ========================================================
    -- AUTH
    -- ========================================================

    v_profile_id uuid;

    v_staff_id uuid;
    v_staff_name text;

    -- ========================================================
    -- ACADEMIC YEAR
    -- ========================================================

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    -- ========================================================
    -- PERIOD
    -- ========================================================

    v_start_date date;
    v_end_date date;

    -- ========================================================
    -- BILL SUMMARY
    -- ========================================================

    v_bill_count integer := 0;
    v_active_bill_count integer := 0;
    v_unpaid_count integer := 0;
    v_partial_count integer := 0;
    v_paid_count integer := 0;
    v_cancelled_bill_count integer := 0;
    v_overdue_count integer := 0;

    v_billed_amount numeric(14,2) := 0;
    v_paid_for_selected_bills numeric(14,2) := 0;
    v_outstanding_amount numeric(14,2) := 0;

    -- ========================================================
    -- PAYMENT SUMMARY
    -- ========================================================

    v_payment_count integer := 0;
    v_recorded_payment_count integer := 0;
    v_cancelled_payment_count integer := 0;

    v_payment_amount numeric(14,2) := 0;
    v_allocated_amount numeric(14,2) := 0;
    v_unallocated_amount numeric(14,2) := 0;

    -- ========================================================
    -- LISTS
    -- ========================================================

    v_category_summary jsonb := '[]'::jsonb;
    v_payment_method_summary jsonb := '[]'::jsonb;

    v_bill_items jsonb := '[]'::jsonb;
    v_payment_items jsonb := '[]'::jsonb;

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
    -- ========================================================

    if not public.has_role(
        'bendahara'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Laporan Keuangan Bendahara ditolak.';
    end if;


    -- ========================================================
    -- 3. ACTIVE PROFILE
    -- ========================================================

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


    -- ========================================================
    -- 4. ACTIVE STAFF
    -- ========================================================

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
    -- 6. PERIOD
    --
    -- Default = bulan berjalan.
    -- Tetap dibatasi tahun ajaran aktif.
    -- ========================================================

    v_start_date :=
        coalesce(
            p_start_date,
            date_trunc(
                'month',
                current_date
            )::date
        );


    v_end_date :=
        coalesce(
            p_end_date,
            current_date
        );


    if v_start_date <
       v_academic_year_start
    then
        v_start_date :=
            v_academic_year_start;
    end if;


    if v_end_date >
       v_academic_year_end
    then
        v_end_date :=
            v_academic_year_end;
    end if;


    if v_end_date >
       current_date
    then
        v_end_date :=
            current_date;
    end if;


    if v_start_date >
       v_end_date
    then
        raise exception
            'Tanggal awal laporan tidak boleh setelah tanggal akhir.';
    end if;


    -- ========================================================
    -- 7. BILL SUMMARY
    --
    -- Tanggal acuan tagihan:
    -- period_start -> due_date -> created_at::date
    -- ========================================================

    with selected_bills as (
        select
            bill.*,

            coalesce(
                bill.period_start,
                bill.due_date,
                bill.created_at::date
            ) as report_date,

            coalesce(
                (
                    select
                        sum(
                            allocation.amount
                        )

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
                ),
                0
            )::numeric(14,2)
                as paid_amount

        from public.student_bills
            as bill

        where bill.academic_year_id =
              v_academic_year_id

          and coalesce(
              bill.period_start,
              bill.due_date,
              bill.created_at::date
          ) between
              v_start_date
              and
              v_end_date
    )

    select
        count(*)::integer,

        count(*) filter (
            where status <>
                  'cancelled'
        )::integer,

        count(*) filter (
            where status =
                  'unpaid'
        )::integer,

        count(*) filter (
            where status =
                  'partial'
        )::integer,

        count(*) filter (
            where status =
                  'paid'
        )::integer,

        count(*) filter (
            where status =
                  'cancelled'
        )::integer,

        count(*) filter (
            where status in (
                'unpaid',
                'partial'
            )

              and due_date is not null

              and due_date <
                  current_date
        )::integer,

        coalesce(
            sum(
                amount
            ) filter (
                where status <>
                      'cancelled'
            ),
            0
        ),

        coalesce(
            sum(
                least(
                    paid_amount,
                    amount
                )
            ) filter (
                where status <>
                      'cancelled'
            ),
            0
        ),

        coalesce(
            sum(
                greatest(
                    amount -
                    paid_amount,
                    0
                )
            ) filter (
                where status in (
                    'unpaid',
                    'partial'
                )
            ),
            0
        )

    into
        v_bill_count,
        v_active_bill_count,
        v_unpaid_count,
        v_partial_count,
        v_paid_count,
        v_cancelled_bill_count,
        v_overdue_count,
        v_billed_amount,
        v_paid_for_selected_bills,
        v_outstanding_amount

    from selected_bills;


    -- ========================================================
    -- 8. PAYMENT SUMMARY
    --
    -- Berdasarkan payment_date.
    -- ========================================================

    with selected_payments as (
        select
            payment.*,

            coalesce(
                (
                    select
                        sum(
                            allocation.amount
                        )

                    from public.payment_allocations
                        as allocation

                    where allocation.payment_id =
                          payment.id
                ),
                0
            )::numeric(14,2)
                as historical_allocated_amount

        from public.payments
            as payment

        where payment.academic_year_id =
              v_academic_year_id

          and payment.payment_date
              between
              v_start_date
              and
              v_end_date
    )

    select
        count(*)::integer,

        count(*) filter (
            where status =
                  'recorded'
        )::integer,

        count(*) filter (
            where status =
                  'cancelled'
        )::integer,

        coalesce(
            sum(
                amount
            ) filter (
                where status =
                      'recorded'
            ),
            0
        ),

        coalesce(
            sum(
                historical_allocated_amount
            ) filter (
                where status =
                      'recorded'
            ),
            0
        ),

        coalesce(
            sum(
                greatest(
                    amount -
                    historical_allocated_amount,
                    0
                )
            ) filter (
                where status =
                      'recorded'
            ),
            0
        )

    into
        v_payment_count,
        v_recorded_payment_count,
        v_cancelled_payment_count,
        v_payment_amount,
        v_allocated_amount,
        v_unallocated_amount

    from selected_payments;


    -- ========================================================
    -- 9. CATEGORY SUMMARY
    -- ========================================================

    select
        coalesce(
            jsonb_agg(
                category_data.payload

                order by
                    category_data.billed_amount desc,
                    category_data.category
            ),
            '[]'::jsonb
        )

    into
        v_category_summary

    from (
        select
            bill.category,

            sum(
                bill.amount
            ) filter (
                where bill.status <>
                      'cancelled'
            )::numeric(14,2)
                as billed_amount,

            count(*) filter (
                where bill.status <>
                      'cancelled'
            )::integer
                as bill_count,

            jsonb_build_object(
                'category',
                bill.category,

                'bill_count',
                count(*) filter (
                    where bill.status <>
                          'cancelled'
                ),

                'billed_amount',
                coalesce(
                    sum(
                        bill.amount
                    ) filter (
                        where bill.status <>
                              'cancelled'
                    ),
                    0
                )
            ) as payload

        from public.student_bills
            as bill

        where bill.academic_year_id =
              v_academic_year_id

          and coalesce(
              bill.period_start,
              bill.due_date,
              bill.created_at::date
          ) between
              v_start_date
              and
              v_end_date

        group by
            bill.category
    ) as category_data;


    -- ========================================================
    -- 10. PAYMENT METHOD SUMMARY
    -- ========================================================

    select
        coalesce(
            jsonb_agg(
                method_data.payload

                order by
                    method_data.amount desc,
                    method_data.payment_method
            ),
            '[]'::jsonb
        )

    into
        v_payment_method_summary

    from (
        select
            payment.payment_method,

            count(*)::integer
                as payment_count,

            sum(
                payment.amount
            )::numeric(14,2)
                as amount,

            jsonb_build_object(
                'payment_method',
                payment.payment_method,

                'payment_count',
                count(*),

                'amount',
                coalesce(
                    sum(
                        payment.amount
                    ),
                    0
                )
            ) as payload

        from public.payments
            as payment

        where payment.academic_year_id =
              v_academic_year_id

          and payment.status =
              'recorded'

          and payment.payment_date
              between
              v_start_date
              and
              v_end_date

        group by
            payment.payment_method
    ) as method_data;


    -- ========================================================
    -- 11. BILL ITEMS
    -- ========================================================

    select
        coalesce(
            jsonb_agg(
                bill_data.payload

                order by
                    bill_data.report_date desc,
                    bill_data.student_name,
                    bill_data.bill_id
            ),
            '[]'::jsonb
        )

    into
        v_bill_items

    from (
        select
            bill.id
                as bill_id,

            student.full_name
                as student_name,

            coalesce(
                bill.period_start,
                bill.due_date,
                bill.created_at::date
            ) as report_date,

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

                'report_date',
                coalesce(
                    bill.period_start,
                    bill.due_date,
                    bill.created_at::date
                ),

                'due_date',
                bill.due_date,

                'amount',
                bill.amount,

                'paid_amount',
                coalesce(
                    bill_payment.paid_amount,
                    0
                ),

                'outstanding_amount',
                case
                    when bill.status =
                         'cancelled'
                    then 0

                    else greatest(
                        bill.amount -
                        coalesce(
                            bill_payment.paid_amount,
                            0
                        ),
                        0
                    )
                end,

                'status',
                bill.status,

                'student',
                jsonb_build_object(
                    'id',
                    student.id,

                    'nis',
                    student.nis,

                    'legacy_student_id',
                    student.legacy_student_id,

                    'full_name',
                    student.full_name,

                    'gender',
                    student.gender::text
                )
            ) as payload

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

          and coalesce(
              bill.period_start,
              bill.due_date,
              bill.created_at::date
          ) between
              v_start_date
              and
              v_end_date

        order by
            report_date desc,
            student.full_name,
            bill.id

        limit 100
    ) as bill_data;


    -- ========================================================
    -- 12. PAYMENT ITEMS
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
        v_payment_items

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

                'payment_method',
                payment.payment_method,

                'reference_number',
                payment.reference_number,

                'status',
                payment.status,

                'historical_allocated_amount',
                coalesce(
                    allocation_data.allocated_amount,
                    0
                ),

                'student',
                jsonb_build_object(
                    'id',
                    student.id,

                    'nis',
                    student.nis,

                    'legacy_student_id',
                    student.legacy_student_id,

                    'full_name',
                    student.full_name,

                    'gender',
                    student.gender::text
                )
            ) as payload

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
        ) as allocation_data
            on true

        where payment.academic_year_id =
              v_academic_year_id

          and payment.payment_date
              between
              v_start_date
              and
              v_end_date

        order by
            payment.payment_date desc,
            payment.created_at desc,
            payment.id desc

        limit 100
    ) as payment_data;


    -- ========================================================
    -- 13. RESPONSE
    -- ========================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'access_mode',
        'bendahara_read_only_report',

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'full_name',
            v_staff_name
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

        'period',
        jsonb_build_object(
            'start_date',
            v_start_date,

            'end_date',
            v_end_date
        ),

        'bill_summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_bill_count,
                0
            ),

            'active_count',
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
                v_cancelled_bill_count,
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
                v_paid_for_selected_bills,
                0
            ),

            'outstanding_amount',
            coalesce(
                v_outstanding_amount,
                0
            )
        ),

        'payment_summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_payment_count,
                0
            ),

            'recorded_count',
            coalesce(
                v_recorded_payment_count,
                0
            ),

            'cancelled_count',
            coalesce(
                v_cancelled_payment_count,
                0
            ),

            'recorded_amount',
            coalesce(
                v_payment_amount,
                0
            ),

            'allocated_amount',
            coalesce(
                v_allocated_amount,
                0
            ),

            'unallocated_amount',
            coalesce(
                v_unallocated_amount,
                0
            )
        ),

        'category_summary',
        coalesce(
            v_category_summary,
            '[]'::jsonb
        ),

        'payment_method_summary',
        coalesce(
            v_payment_method_summary,
            '[]'::jsonb
        ),

        'bills',
        coalesce(
            v_bill_items,
            '[]'::jsonb
        ),

        'payments',
        coalesce(
            v_payment_items,
            '[]'::jsonb
        )
    );

end;

$function$;


-- ============================================================
-- SECURITY
-- ============================================================

revoke all
on function public.get_bendahara_finance_report(date, date)
from public;


revoke all
on function public.get_bendahara_finance_report(date, date)
from anon;


grant execute
on function public.get_bendahara_finance_report(date, date)
to authenticated;


grant execute
on function public.get_bendahara_finance_report(date, date)
to service_role;


comment on function public.get_bendahara_finance_report(date, date)
is
'Laporan keuangan read-only berdasarkan periode untuk Bendahara E-Ma''had.';