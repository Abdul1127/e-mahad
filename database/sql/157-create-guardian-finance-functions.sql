begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 157-create-guardian-finance-functions.sql
--
-- PURPOSE:
-- Finance untuk Wali:
--
-- 1. Daftar tagihan anak
-- 2. Riwayat pembayaran anak
-- 3. Private payment proof access
--
-- SECURITY:
--
-- Guardian hanya boleh melihat student yang terhubung
-- melalui:
--
-- public.guardian_students
--
-- guardian.profile_id = auth.uid()
--
-- Tidak ada akses ke santri lain.
-- =========================================================


-- =========================================================
-- A. GUARDIAN PAYMENT PROOF ACCESS HELPER
-- =========================================================

create or replace function
public.can_guardian_access_payment_proof(
    p_object_name text
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_guardian_id uuid;

    v_parts text[];
    v_payment_id_text text;
    v_file_name text;
begin

    -- =====================================================
    -- AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        return false;
    end if;


    -- =====================================================
    -- ROLE
    -- =====================================================

    if not public.has_role(
        'guardian'
    ) then
        return false;
    end if;


    -- =====================================================
    -- ACTIVE PROFILE
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
    -- ACTIVE GUARDIAN
    -- =====================================================

    select
        guardian.id

    into
        v_guardian_id

    from public.guardians
        as guardian

    where guardian.profile_id =
          v_profile_id

      and guardian.is_active =
          true

    limit 1;


    if v_guardian_id is null then
        return false;
    end if;


    -- =====================================================
    -- PATH
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
    -- UUID FORMAT
    -- =====================================================

    if v_payment_id_text !~
       '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
    then
        return false;
    end if;


    -- =====================================================
    -- ACCESS
    --
    -- Payment harus:
    --
    -- - milik anak yang terhubung
    -- - tahun ajaran aktif
    -- - proof_path sama persis
    --
    -- Recorded maupun cancelled tetap boleh membaca proof
    -- lama sebagai audit trail.
    -- =====================================================

    return exists (
        select 1

        from public.payments
            as payment

        inner join public.students
            as student

            on student.id =
               payment.student_id

        inner join public.guardian_students
            as relation

            on relation.student_id =
               payment.student_id

        inner join public.academic_years
            as academic_year

            on academic_year.id =
               payment.academic_year_id

        where relation.guardian_id =
              v_guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null

          and academic_year.is_current =
              true

          and lower(
                  payment.id::text
              ) =
              lower(
                  v_payment_id_text
              )

          and payment.proof_path =
              p_object_name
    );

end;
$function$;


comment on function
public.can_guardian_access_payment_proof(
    text
)
is
'Memvalidasi akses Wali terhadap private payment proof milik anak yang terhubung.';


revoke all
on function
public.can_guardian_access_payment_proof(
    text
)
from public;


revoke all
on function
public.can_guardian_access_payment_proof(
    text
)
from anon;


grant execute
on function
public.can_guardian_access_payment_proof(
    text
)
to authenticated;


-- =========================================================
-- B. GUARDIAN STORAGE SELECT POLICY
-- =========================================================

drop policy if exists
"payment_proofs_guardian_select"
on storage.objects;


create policy
"payment_proofs_guardian_select"

on storage.objects

for select

to authenticated

using (
    bucket_id =
        'payment-proofs'

    and public.can_guardian_access_payment_proof(
        name
    )
);


-- =========================================================
-- C. GUARDIAN BILL LIST
-- =========================================================

create or replace function
public.get_guardian_bill_list(
    p_student_id uuid default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_guardian_id uuid;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_children jsonb :=
        '[]'::jsonb;

    v_items jsonb :=
        '[]'::jsonb;

    v_total_count integer :=
        0;

    v_unpaid_count integer :=
        0;

    v_partial_count integer :=
        0;

    v_paid_count integer :=
        0;

    v_overdue_count integer :=
        0;

    v_billed_amount numeric(14,2) :=
        0;

    v_paid_amount numeric(14,2) :=
        0;

    v_outstanding_amount numeric(14,2) :=
        0;
begin

    -- =====================================================
    -- AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'guardian'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses tagihan Wali ditolak.';
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
            message = 'Profile Wali tidak aktif.';
    end if;


    select
        guardian.id

    into
        v_guardian_id

    from public.guardians
        as guardian

    where guardian.profile_id =
          v_profile_id

      and guardian.is_active =
          true

    limit 1;


    if v_guardian_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data Wali aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- CURRENT YEAR
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
    -- SELECTED STUDENT SECURITY
    -- =====================================================

    if p_student_id is not null
       and not exists (
           select 1

           from public.guardian_students
               as relation

           inner join public.students
               as student

               on student.id =
                  relation.student_id

           where relation.guardian_id =
                 v_guardian_id

             and relation.student_id =
                 p_student_id

             and student.status =
                 'active'

             and student.deleted_at
                 is null
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Wali tidak memiliki akses ke data santri tersebut.';
    end if;


    -- =====================================================
    -- CHILDREN
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                child.payload

                order by
                    child.full_name,
                    child.student_id
            ),
            '[]'::jsonb
        )

    into
        v_children

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
                student.gender::text
            )
                as payload

        from public.guardian_students
            as relation

        inner join public.students
            as student

            on student.id =
               relation.student_id

        where relation.guardian_id =
              v_guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null
    )
        as child;


    -- =====================================================
    -- SUMMARY
    -- =====================================================

    with bill_finance as (
        select
            bill.id,

            bill.status,

            bill.amount,

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

        inner join public.students
            as student

            on student.id =
               bill.student_id

        inner join public.guardian_students
            as relation

            on relation.student_id =
               bill.student_id

        where relation.guardian_id =
              v_guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null

          and bill.academic_year_id =
              v_academic_year_id

          and bill.status <>
              'cancelled'

          and (
              p_student_id is null

              or bill.student_id =
                 p_student_id
          )
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
            where due_date <
                  current_date

              and status in (
                  'unpaid',
                  'partial'
              )
        )::integer,

        coalesce(
            sum(
                amount
            ),
            0
        ),

        coalesce(
            sum(
                least(
                    paid_amount,
                    amount
                )
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
            ),
            0
        )

    into
        v_total_count,
        v_unpaid_count,
        v_partial_count,
        v_paid_count,
        v_overdue_count,
        v_billed_amount,
        v_paid_amount,
        v_outstanding_amount

    from bill_finance;


    -- =====================================================
    -- ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                item.payload

                order by
                    item.due_date nulls last,
                    item.created_at desc,
                    item.bill_id
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            bill.id
                as bill_id,

            bill.due_date,

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
                ),

                'outstanding_amount',
                greatest(
                    bill.amount -
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
                    ),
                    0
                ),

                'due_date',
                bill.due_date,

                'is_overdue',
                (
                    bill.due_date is not null

                    and bill.due_date <
                        current_date

                    and bill.status in (
                        'unpaid',
                        'partial'
                    )
                ),

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

        inner join public.guardian_students
            as relation

            on relation.student_id =
               bill.student_id

        where relation.guardian_id =
              v_guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null

          and bill.academic_year_id =
              v_academic_year_id

          and bill.status <>
              'cancelled'

          and (
              p_student_id is null

              or bill.student_id =
                 p_student_id
          )
    )
        as item;


    -- =====================================================
    -- RESPONSE
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

        'guardian',
        jsonb_build_object(
            'id',
            v_guardian_id
        ),

        'children',
        v_children,

        'selected_student_id',
        p_student_id,

        'summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_total_count,
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

        'items',
        v_items
    );

end;
$function$;


comment on function
public.get_guardian_bill_list(
    uuid
)
is
'Daftar tagihan tahun ajaran aktif untuk anak yang terhubung ke akun Wali.';


revoke all
on function
public.get_guardian_bill_list(
    uuid
)
from public;


revoke all
on function
public.get_guardian_bill_list(
    uuid
)
from anon;


grant execute
on function
public.get_guardian_bill_list(
    uuid
)
to authenticated;


-- =========================================================
-- D. GUARDIAN PAYMENT HISTORY
-- =========================================================

create or replace function
public.get_guardian_payment_history(
    p_student_id uuid default null,
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
    v_guardian_id uuid;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_page integer;
    v_page_size integer;
    v_offset integer;

    v_children jsonb :=
        '[]'::jsonb;

    v_items jsonb :=
        '[]'::jsonb;

    v_total_count integer :=
        0;

    v_recorded_count integer :=
        0;

    v_cancelled_count integer :=
        0;

    v_recorded_amount numeric(14,2) :=
        0;
begin

    -- =====================================================
    -- AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'guardian'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses riwayat pembayaran Wali ditolak.';
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
            message = 'Profile Wali tidak aktif.';
    end if;


    select
        guardian.id

    into
        v_guardian_id

    from public.guardians
        as guardian

    where guardian.profile_id =
          v_profile_id

      and guardian.is_active =
          true

    limit 1;


    if v_guardian_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data Wali aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- CURRENT YEAR
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
    -- SELECTED CHILD SECURITY
    -- =====================================================

    if p_student_id is not null
       and not exists (
           select 1

           from public.guardian_students
               as relation

           inner join public.students
               as student

               on student.id =
                  relation.student_id

           where relation.guardian_id =
                 v_guardian_id

             and relation.student_id =
                 p_student_id

             and student.status =
                 'active'

             and student.deleted_at
                 is null
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Wali tidak memiliki akses ke data santri tersebut.';
    end if;


    -- =====================================================
    -- PAGINATION
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
    -- CHILDREN
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                child.payload

                order by
                    child.full_name,
                    child.student_id
            ),
            '[]'::jsonb
        )

    into
        v_children

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
                student.gender::text
            )
                as payload

        from public.guardian_students
            as relation

        inner join public.students
            as student

            on student.id =
               relation.student_id

        where relation.guardian_id =
              v_guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null
    )
        as child;


    -- =====================================================
    -- SUMMARY
    -- =====================================================

    select
        count(*)::integer,

        count(*) filter (
            where payment.status =
                  'recorded'
        )::integer,

        count(*) filter (
            where payment.status =
                  'cancelled'
        )::integer,

        coalesce(
            sum(
                payment.amount
            ) filter (
                where payment.status =
                      'recorded'
            ),
            0
        )

    into
        v_total_count,
        v_recorded_count,
        v_cancelled_count,
        v_recorded_amount

    from public.payments
        as payment

    inner join public.students
        as student

        on student.id =
           payment.student_id

    inner join public.guardian_students
        as relation

        on relation.student_id =
           payment.student_id

    where relation.guardian_id =
          v_guardian_id

      and student.status =
          'active'

      and student.deleted_at
          is null

      and payment.academic_year_id =
          v_academic_year_id

      and (
          p_student_id is null

          or payment.student_id =
             p_student_id
      );


    -- =====================================================
    -- ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                item.payload

                order by
                    item.payment_date desc,
                    item.created_at desc,
                    item.payment_id desc
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

                'status',
                payment.status,

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
                    (
                        select
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

                                        'period_label',
                                        bill.period_label
                                    )
                                )

                                order by
                                    allocation.created_at,
                                    allocation.id
                            )

                        from public.payment_allocations
                            as allocation

                        inner join public.student_bills
                            as bill

                            on bill.id =
                               allocation.bill_id

                        where allocation.payment_id =
                              payment.id
                    ),
                    '[]'::jsonb
                )
            )
                as payload

        from public.payments
            as payment

        inner join public.students
            as student

            on student.id =
               payment.student_id

        inner join public.guardian_students
            as relation

            on relation.student_id =
               payment.student_id

        where relation.guardian_id =
              v_guardian_id

          and student.status =
              'active'

          and student.deleted_at
              is null

          and payment.academic_year_id =
              v_academic_year_id

          and (
              p_student_id is null

              or payment.student_id =
                 p_student_id
          )

        order by
            payment.payment_date desc,
            payment.created_at desc,
            payment.id desc

        limit
            v_page_size

        offset
            v_offset
    )
        as item;


    -- =====================================================
    -- RESPONSE
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

        'guardian',
        jsonb_build_object(
            'id',
            v_guardian_id
        ),

        'children',
        v_children,

        'selected_student_id',
        p_student_id,

        'summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_total_count,
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
            v_total_count
        ),

        'items',
        v_items
    );

end;
$function$;


comment on function
public.get_guardian_payment_history(
    uuid,
    integer,
    integer
)
is
'Riwayat pembayaran tahun ajaran aktif milik anak yang terhubung ke akun Wali.';


revoke all
on function
public.get_guardian_payment_history(
    uuid,
    integer,
    integer
)
from public;


revoke all
on function
public.get_guardian_payment_history(
    uuid,
    integer,
    integer
)
from anon;


grant execute
on function
public.get_guardian_payment_history(
    uuid,
    integer,
    integer
)
to authenticated;


commit;