begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 133-create-bendahara-bill-list-functions.sql
--
-- PURPOSE:
--
-- 1. get_bendahara_bill_list()
--    Daftar tagihan tahun ajaran aktif.
--
-- 2. get_bendahara_bill_student_options()
--    Kandidat santri aktif untuk pembuatan tagihan.
--
-- SECURITY:
-- - auth.uid()
-- - role bendahara
-- - profile aktif
-- - staff aktif
-- - RPC only
-- =========================================================


-- =========================================================
-- A. BILL LIST
-- =========================================================

create or replace function
public.get_bendahara_bill_list(
    p_search text default null,
    p_status text default null,
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

    v_page integer;
    v_page_size integer;
    v_offset integer;

    v_total_count integer := 0;
    v_filtered_count integer := 0;

    v_unpaid_count integer := 0;
    v_partial_count integer := 0;
    v_paid_count integer := 0;
    v_cancelled_count integer := 0;
    v_overdue_count integer := 0;

    v_billed_amount numeric(14,2) := 0;
    v_paid_amount numeric(14,2) := 0;
    v_outstanding_amount numeric(14,2) := 0;

    v_items jsonb := '[]'::jsonb;
begin

    -- =====================================================
    -- 1. AUTH
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
            message = 'Akses Daftar Tagihan Bendahara ditolak.';
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
    -- 2. CURRENT ACADEMIC YEAR
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
    -- 3. FILTER
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


    if v_status is not null
       and v_status not in (
           'unpaid',
           'partial',
           'paid',
           'cancelled',
           'overdue'
       )
    then
        raise exception
            'Filter status tagihan tidak valid.';
    end if;


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
    -- 4. GLOBAL SUMMARY
    -- =====================================================

    with bill_finance as (
        select
            bill.id,
            bill.amount,
            bill.status,
            bill.due_date,

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
    )

    select
        count(*)::integer,

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

              and due_date
                  is not null

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
                paid_amount
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
        v_total_count,
        v_unpaid_count,
        v_partial_count,
        v_paid_count,
        v_cancelled_count,
        v_overdue_count,
        v_billed_amount,
        v_paid_amount,
        v_outstanding_amount

    from bill_finance;


    -- =====================================================
    -- 5. FILTERED COUNT
    -- =====================================================

    select
        count(*)::integer

    into
        v_filtered_count

    from public.student_bills
        as bill

    inner join public.students
        as student
        on student.id =
           bill.student_id

    where bill.academic_year_id =
          v_academic_year_id

      and (
          v_status is null

          or (
              v_status =
              'overdue'

              and bill.status in (
                  'unpaid',
                  'partial'
              )

              and bill.due_date
                  is not null

              and bill.due_date <
                  current_date
          )

          or (
              v_status <>
              'overdue'

              and bill.status =
                  v_status
          )
      )

      and (
          v_search is null

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

          or bill.bill_code
             ilike
             '%' || v_search || '%'

          or bill.title
             ilike
             '%' || v_search || '%'

          or bill.category
             ilike
             '%' || v_search || '%'

          or coalesce(
              bill.period_label,
              ''
          ) ilike
             '%' || v_search || '%'
      );


    -- =====================================================
    -- 6. ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                bill_item.payload

                order by
                    bill_item.created_at desc,
                    bill_item.bill_id desc
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            bill.id
                as bill_id,

            bill.created_at,

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
                ) as paid_amount

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

        where bill.academic_year_id =
              v_academic_year_id

          and (
              v_status is null

              or (
                  v_status =
                  'overdue'

                  and bill.status in (
                      'unpaid',
                      'partial'
                  )

                  and bill.due_date
                      is not null

                  and bill.due_date <
                      current_date
              )

              or (
                  v_status <>
                  'overdue'

                  and bill.status =
                      v_status
              )
          )

          and (
              v_search is null

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

              or bill.bill_code
                 ilike
                 '%' || v_search || '%'

              or bill.title
                 ilike
                 '%' || v_search || '%'

              or bill.category
                 ilike
                 '%' || v_search || '%'

              or coalesce(
                  bill.period_label,
                  ''
              ) ilike
                 '%' || v_search || '%'
          )

        order by
            bill.created_at desc,
            bill.id desc

        limit
            v_page_size

        offset
            v_offset
    ) as bill_item;


    -- =====================================================
    -- 7. RESPONSE
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
            v_status
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
-- B. STUDENT OPTIONS
-- =========================================================

create or replace function
public.get_bendahara_bill_student_options(
    p_search text default null,
    p_limit integer default 30
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

    v_search text;
    v_limit integer;

    v_items jsonb := '[]'::jsonb;
begin

    -- =====================================================
    -- 1. AUTH
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
            message = 'Akses Kandidat Santri Tagihan ditolak.';
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
    -- 2. CURRENT YEAR
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
    -- 3. INPUT
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


    v_limit :=
        least(
            greatest(
                coalesce(
                    p_limit,
                    30
                ),
                1
            ),
            100
        );


    -- =====================================================
    -- 4. STUDENTS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                student_data.payload

                order by
                    student_data.full_name,
                    student_data.student_id
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            student.id
                as student_id,

            student.full_name,

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
                student.gender::text,

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
                end,

                'finance_summary',
                jsonb_build_object(
                    'active_bill_count',
                    (
                        select
                            count(*)::integer

                        from public.student_bills
                            as bill

                        where bill.student_id =
                              student.id

                          and bill.academic_year_id =
                              v_academic_year_id

                          and bill.status <>
                              'cancelled'
                    ),

                    'open_bill_count',
                    (
                        select
                            count(*)::integer

                        from public.student_bills
                            as bill

                        where bill.student_id =
                              student.id

                          and bill.academic_year_id =
                              v_academic_year_id

                          and bill.status in (
                              'unpaid',
                              'partial'
                          )
                    ),

                    'outstanding_amount',
                    (
                        select
                            coalesce(
                                sum(
                                    greatest(
                                        bill.amount -
                                        coalesce(
                                            bill_paid.paid_amount,
                                            0
                                        ),
                                        0
                                    )
                                ),
                                0
                            )

                        from public.student_bills
                            as bill

                        left join lateral (
                            select
                                coalesce(
                                    sum(
                                        allocation.amount
                                    ),
                                    0
                                ) as paid_amount

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
                        ) as bill_paid
                            on true

                        where bill.student_id =
                              student.id

                          and bill.academic_year_id =
                              v_academic_year_id

                          and bill.status in (
                              'unpaid',
                              'partial'
                          )
                    )
                )
            ) as payload

        from public.students
            as student

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

        where student.status =
              'active'

          and student.deleted_at
              is null

          and (
              v_search is null

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
            student.full_name,
            student.id

        limit
            v_limit
    ) as student_data;


    -- =====================================================
    -- 5. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name
        ),

        'filters',
        jsonb_build_object(
            'search',
            v_search,

            'limit',
            v_limit
        ),

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- PRIVILEGES
-- =========================================================

comment on function
public.get_bendahara_bill_list(
    text,
    text,
    integer,
    integer
)
is
'Daftar tagihan santri tahun ajaran aktif untuk Bendahara.';


comment on function
public.get_bendahara_bill_student_options(
    text,
    integer
)
is
'Daftar santri aktif yang dapat dipilih Bendahara saat membuat tagihan.';


revoke all on function
public.get_bendahara_bill_list(
    text,
    text,
    integer,
    integer
)
from public;


revoke all on function
public.get_bendahara_bill_list(
    text,
    text,
    integer,
    integer
)
from anon;


grant execute on function
public.get_bendahara_bill_list(
    text,
    text,
    integer,
    integer
)
to authenticated;


revoke all on function
public.get_bendahara_bill_student_options(
    text,
    integer
)
from public;


revoke all on function
public.get_bendahara_bill_student_options(
    text,
    integer
)
from anon;


grant execute on function
public.get_bendahara_bill_student_options(
    text,
    integer
)
to authenticated;


commit;