begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 145-create-bendahara-payment-history-function.sql
--
-- PURPOSE:
-- Riwayat seluruh transaksi pembayaran Bendahara pada
-- tahun ajaran aktif.
--
-- FEATURES:
-- - Search:
--   payment code
--   reference number
--   nama santri
--   NIS
--
-- - Filter status:
--   recorded
--   cancelled
--
-- - Filter metode:
--   cash
--   transfer
--   bank_transfer
--   other
--
-- - Pagination
-- - Summary pembayaran
-- - Menampilkan tagihan yang menerima allocation
--
-- SECURITY:
-- - authenticated
-- - role bendahara
-- - profile aktif
-- - staff aktif
-- - SECURITY DEFINER
-- =========================================================


create or replace function
public.get_bendahara_payment_history(
    p_search text default null,
    p_status text default null,
    p_method text default null,
    p_page integer default 1,
    p_page_size integer default 20
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

    v_search text;
    v_status text;
    v_method text;

    v_page integer;
    v_page_size integer;
    v_offset integer;

    v_total_count integer := 0;
    v_filtered_count integer := 0;

    v_recorded_count integer := 0;
    v_cancelled_count integer := 0;

    v_recorded_amount numeric(14,2) := 0;
    v_active_allocated_amount numeric(14,2) := 0;
    v_unallocated_amount numeric(14,2) := 0;

    v_items jsonb :=
        '[]'::jsonb;
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
            message = 'Akses Riwayat Pembayaran Bendahara ditolak.';
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
    -- B. CURRENT ACADEMIC YEAR
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
    -- C. NORMALIZE FILTER
    -- =====================================================

    v_search :=
        nullif(
            btrim(
                coalesce(
                    p_search,
                    ''
                )
            ),
            ''
        );


    v_status :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_status,
                        ''
                    )
                )
            ),
            ''
        );


    v_method :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_method,
                        ''
                    )
                )
            ),
            ''
        );


    -- =====================================================
    -- D. FILTER VALIDATION
    -- =====================================================

    if v_status is not null
       and v_status not in (
           'recorded',
           'cancelled'
       )
    then
        raise exception
            'Filter status pembayaran tidak valid.';
    end if;


    if v_method is not null
       and v_method not in (
           'cash',
           'transfer',
           'bank_transfer',
           'other'
       )
    then
        raise exception
            'Filter metode pembayaran tidak valid.';
    end if;


    -- =====================================================
    -- E. PAGINATION
    -- =====================================================

    v_page :=
        greatest(
            coalesce(
                p_page,
                1
            ),
            1
        );


    v_page_size :=
        least(
            greatest(
                coalesce(
                    p_page_size,
                    20
                ),
                1
            ),
            100
        );


    v_offset :=
        (
            v_page - 1
        ) * v_page_size;


    -- =====================================================
    -- F. GLOBAL SUMMARY
    --
    -- Cancelled payment tidak dihitung sebagai penerimaan
    -- aktif.
    -- =====================================================

    with payment_finance as (
        select
            payment.id,

            payment.amount,

            payment.status,

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
        v_total_count,
        v_recorded_count,
        v_cancelled_count,
        v_recorded_amount,
        v_active_allocated_amount,
        v_unallocated_amount

    from payment_finance;


    -- =====================================================
    -- G. FILTERED COUNT
    -- =====================================================

    select
        count(*)::integer

    into
        v_filtered_count

    from public.payments
        as payment

    inner join public.students
        as student
        on student.id =
           payment.student_id

    where payment.academic_year_id =
          v_academic_year_id

      and (
          v_status is null
          or payment.status =
             v_status
      )

      and (
          v_method is null
          or payment.payment_method =
             v_method
      )

      and (
          v_search is null

          or payment.payment_code
             ilike
             '%' || v_search || '%'

          or coalesce(
              payment.reference_number,
              ''
          ) ilike
             '%' || v_search || '%'

          or student.full_name
             ilike
             '%' || v_search || '%'

          or coalesce(
              student.nis,
              ''
          ) ilike
             '%' || v_search || '%'

          or coalesce(
              student.legacy_student_id,
              ''
          ) ilike
             '%' || v_search || '%'
      );


    -- =====================================================
    -- H. PAYMENT ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                payment_item.payload

                order by
                    payment_item.payment_date desc,
                    payment_item.created_at desc,
                    payment_item.payment_id desc
            ),
            '[]'::jsonb
        )

    into
        v_items

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

                'notes',
                payment.notes,

                'proof_path',
                payment.proof_path,

                'has_proof',
                (
                    payment.proof_path
                        is not null

                    and length(
                        btrim(
                            payment.proof_path
                        )
                    ) > 0
                ),

                'status',
                payment.status,

                'historical_allocated_amount',
                coalesce(
                    payment_allocation.total_allocated,
                    0
                ),

                'allocated_amount',
                case
                    when payment.status =
                         'recorded'
                    then
                        coalesce(
                            payment_allocation.total_allocated,
                            0
                        )

                    else
                        0
                end,

                'unallocated_amount',
                case
                    when payment.status =
                         'recorded'
                    then
                        greatest(
                            payment.amount -
                            coalesce(
                                payment_allocation.total_allocated,
                                0
                            ),
                            0
                        )

                    else
                        0
                end,

                'cancelled_at',
                payment.cancelled_at,

                'cancellation_reason',
                payment.cancellation_reason,

                'created_at',
                payment.created_at,

                'updated_at',
                payment.updated_at,

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

                'allocations',
                coalesce(
                    payment_allocation.allocations,
                    '[]'::jsonb
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
                    as total_allocated,

                coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'allocation_id',
                            allocation.id,

                            'amount',
                            allocation.amount,

                            'bill',
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

                                'status',
                                bill.status
                            )
                        )

                        order by
                            allocation.created_at,
                            allocation.id
                    ),
                    '[]'::jsonb
                ) as allocations

            from public.payment_allocations
                as allocation

            inner join public.student_bills
                as bill
                on bill.id =
                   allocation.bill_id

            where allocation.payment_id =
                  payment.id
        ) as payment_allocation
            on true

        where payment.academic_year_id =
              v_academic_year_id

          and (
              v_status is null
              or payment.status =
                 v_status
          )

          and (
              v_method is null
              or payment.payment_method =
                 v_method
          )

          and (
              v_search is null

              or payment.payment_code
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                  payment.reference_number,
                  ''
              ) ilike
                 '%' || v_search || '%'

              or student.full_name
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.nis,
                  ''
              ) ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.legacy_student_id,
                  ''
              ) ilike
                 '%' || v_search || '%'
          )

        order by
            payment.payment_date desc,
            payment.created_at desc,
            payment.id desc

        limit
            v_page_size

        offset
            v_offset
    ) as payment_item;


    -- =====================================================
    -- I. RESPONSE
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

        'filters',
        jsonb_build_object(
            'search',
            v_search,

            'status',
            v_status,

            'method',
            v_method
        ),

        'summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_total_count,
                0
            ),

            'filtered_count',
            coalesce(
                v_filtered_count,
                0
            ),

            'recorded_count',
            coalesce(
                v_recorded_count,
                0
            ),

            'cancelled_count',
            coalesce(
                v_cancelled_count,
                0
            ),

            'recorded_amount',
            coalesce(
                v_recorded_amount,
                0
            ),

            'active_allocated_amount',
            coalesce(
                v_active_allocated_amount,
                0
            ),

            'unallocated_amount',
            coalesce(
                v_unallocated_amount,
                0
            )
        ),

        'pagination',
        jsonb_build_object(
            'page',
            v_page,

            'page_size',
            v_page_size,

            'offset',
            v_offset,

            'has_previous',
            v_page > 1,

            'has_next',
            (
                v_offset +
                jsonb_array_length(
                    v_items
                )
            ) <
            v_filtered_count
        ),

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- COMMENT
-- =========================================================

comment on function
public.get_bendahara_payment_history(
    text,
    text,
    text,
    integer,
    integer
)
is
'Riwayat transaksi pembayaran santri tahun ajaran aktif untuk Bendahara.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all
on function
public.get_bendahara_payment_history(
    text,
    text,
    text,
    integer,
    integer
)
from public;


revoke all
on function
public.get_bendahara_payment_history(
    text,
    text,
    text,
    integer,
    integer
)
from anon;


grant execute
on function
public.get_bendahara_payment_history(
    text,
    text,
    text,
    integer,
    integer
)
to authenticated;


commit;