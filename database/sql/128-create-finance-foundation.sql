begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 128-create-finance-foundation.sql
--
-- PURPOSE:
-- Fondasi Modul Keuangan:
--
-- 1. student_bills
--    Tagihan per santri.
--
-- 2. payments
--    Transaksi pembayaran per santri.
--
-- 3. payment_allocations
--    Alokasi pembayaran ke tagihan.
--
-- DESIGN:
-- - Satu santri dapat memiliki banyak tagihan.
-- - Satu pembayaran dapat dialokasikan ke satu atau
--   beberapa tagihan.
-- - Satu tagihan dapat dibayar melalui beberapa pembayaran.
-- - Pembayaran yang salah tidak dihapus, tetapi dapat
--   dibatalkan.
-- - Status tagihan dihitung ulang otomatis berdasarkan
--   alokasi pembayaran aktif.
--
-- SECURITY:
-- - RLS aktif.
-- - Authenticated user tidak diberi akses tabel langsung.
-- - Akses aplikasi nantinya melalui SECURITY DEFINER RPC.
-- =========================================================


-- =========================================================
-- A. STUDENT BILLS
-- =========================================================

create table
if not exists public.student_bills (
    id uuid
        primary key
        default gen_random_uuid(),

    academic_year_id uuid
        not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    student_id uuid
        not null
        references public.students(id)
        on update cascade
        on delete restrict,

    bill_code text
        not null,

    title text
        not null,

    description text,

    category text
        not null,

    period_label text,

    period_start date,

    period_end date,

    amount numeric(14,2)
        not null,

    due_date date,

    status text
        not null
        default 'unpaid',

    created_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    updated_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    cancelled_at timestamptz,

    cancelled_by_staff_id uuid
        references public.staff(id)
        on update cascade
        on delete restrict,

    cancellation_reason text,

    created_at timestamptz
        not null
        default now(),

    updated_at timestamptz
        not null
        default now(),

    constraint student_bills_bill_code_not_blank
        check (
            length(
                btrim(
                    bill_code
                )
            ) > 0
        ),

    constraint student_bills_title_not_blank
        check (
            length(
                btrim(
                    title
                )
            ) > 0
        ),

    constraint student_bills_category_not_blank
        check (
            length(
                btrim(
                    category
                )
            ) > 0
        ),

    constraint student_bills_amount_positive
        check (
            amount > 0
        ),

    constraint student_bills_period_valid
        check (
            period_start is null
            or period_end is null
            or period_end >= period_start
        ),

    constraint student_bills_status_valid
        check (
            status in (
                'unpaid',
                'partial',
                'paid',
                'cancelled'
            )
        ),

    constraint student_bills_cancellation_consistency
        check (
            (
                status = 'cancelled'
                and cancelled_at is not null
                and cancelled_by_staff_id is not null
                and cancellation_reason is not null
                and length(
                    btrim(
                        cancellation_reason
                    )
                ) > 0
            )
            or
            (
                status <> 'cancelled'
                and cancelled_at is null
                and cancelled_by_staff_id is null
                and cancellation_reason is null
            )
        )
);


-- =========================================================
-- B. PAYMENTS
-- =========================================================

create table
if not exists public.payments (
    id uuid
        primary key
        default gen_random_uuid(),

    academic_year_id uuid
        not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    student_id uuid
        not null
        references public.students(id)
        on update cascade
        on delete restrict,

    payment_code text
        not null,

    payment_date date
        not null,

    amount numeric(14,2)
        not null,

    payment_method text
        not null,

    reference_number text,

    notes text,

    proof_path text,

    status text
        not null
        default 'recorded',

    recorded_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    updated_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    cancelled_at timestamptz,

    cancelled_by_staff_id uuid
        references public.staff(id)
        on update cascade
        on delete restrict,

    cancellation_reason text,

    created_at timestamptz
        not null
        default now(),

    updated_at timestamptz
        not null
        default now(),

    constraint payments_payment_code_not_blank
        check (
            length(
                btrim(
                    payment_code
                )
            ) > 0
        ),

    constraint payments_amount_positive
        check (
            amount > 0
        ),

    constraint payments_payment_method_not_blank
        check (
            length(
                btrim(
                    payment_method
                )
            ) > 0
        ),

    constraint payments_status_valid
        check (
            status in (
                'recorded',
                'cancelled'
            )
        ),

    constraint payments_cancellation_consistency
        check (
            (
                status = 'cancelled'
                and cancelled_at is not null
                and cancelled_by_staff_id is not null
                and cancellation_reason is not null
                and length(
                    btrim(
                        cancellation_reason
                    )
                ) > 0
            )
            or
            (
                status = 'recorded'
                and cancelled_at is null
                and cancelled_by_staff_id is null
                and cancellation_reason is null
            )
        )
);


-- =========================================================
-- C. PAYMENT ALLOCATIONS
--
-- Contoh:
--
-- Bill SPP Rp1.000.000
--
-- Payment A Rp400.000
-- allocation = Rp400.000
--
-- Payment B Rp600.000
-- allocation = Rp600.000
--
-- Bill otomatis menjadi PAID.
-- =========================================================

create table
if not exists public.payment_allocations (
    id uuid
        primary key
        default gen_random_uuid(),

    payment_id uuid
        not null
        references public.payments(id)
        on update cascade
        on delete restrict,

    bill_id uuid
        not null
        references public.student_bills(id)
        on update cascade
        on delete restrict,

    amount numeric(14,2)
        not null,

    created_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    created_at timestamptz
        not null
        default now(),

    constraint payment_allocations_amount_positive
        check (
            amount > 0
        ),

    constraint payment_allocations_payment_bill_unique
        unique (
            payment_id,
            bill_id
        )
);


-- =========================================================
-- D. UNIQUE BUSINESS CODES
-- =========================================================

create unique index
if not exists student_bills_bill_code_unique_idx
on public.student_bills (
    lower(
        btrim(
            bill_code
        )
    )
);


create unique index
if not exists payments_payment_code_unique_idx
on public.payments (
    lower(
        btrim(
            payment_code
        )
    )
);


-- =========================================================
-- E. QUERY INDEXES
-- =========================================================

create index
if not exists student_bills_student_year_idx
on public.student_bills (
    student_id,
    academic_year_id
);


create index
if not exists student_bills_student_status_idx
on public.student_bills (
    student_id,
    status
);


create index
if not exists student_bills_due_date_idx
on public.student_bills (
    due_date
)
where status in (
    'unpaid',
    'partial'
);


create index
if not exists student_bills_year_status_idx
on public.student_bills (
    academic_year_id,
    status
);


create index
if not exists payments_student_year_idx
on public.payments (
    student_id,
    academic_year_id
);


create index
if not exists payments_student_date_idx
on public.payments (
    student_id,
    payment_date desc
);


create index
if not exists payments_status_idx
on public.payments (
    status
);


create index
if not exists payment_allocations_payment_idx
on public.payment_allocations (
    payment_id
);


create index
if not exists payment_allocations_bill_idx
on public.payment_allocations (
    bill_id
);


-- =========================================================
-- F. UPDATED_AT
--
-- set_updated_at() sudah dipakai oleh modul sebelumnya.
-- =========================================================

drop trigger
if exists set_student_bills_updated_at
on public.student_bills;


create trigger
set_student_bills_updated_at
before update
on public.student_bills
for each row
execute function public.set_updated_at();


drop trigger
if exists set_payments_updated_at
on public.payments;


create trigger
set_payments_updated_at
before update
on public.payments
for each row
execute function public.set_updated_at();


-- =========================================================
-- G. VALIDATE PAYMENT ALLOCATION
--
-- Menjamin:
--
-- 1. payment dan bill berasal dari santri yang sama.
-- 2. payment dan bill berasal dari tahun ajaran yang sama.
-- 3. payment harus aktif / recorded.
-- 4. bill tidak boleh cancelled.
-- 5. total alokasi payment tidak melebihi nilai payment.
-- 6. total pembayaran bill tidak melebihi nilai bill.
-- =========================================================

create or replace function
public.validate_payment_allocation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_payment_student_id uuid;
    v_payment_academic_year_id uuid;
    v_payment_amount numeric(14,2);
    v_payment_status text;

    v_bill_student_id uuid;
    v_bill_academic_year_id uuid;
    v_bill_amount numeric(14,2);
    v_bill_status text;

    v_existing_payment_allocated numeric(14,2);
    v_existing_bill_allocated numeric(14,2);
begin

    -- =====================================================
    -- PAYMENT
    -- =====================================================

    select
        payment.student_id,
        payment.academic_year_id,
        payment.amount,
        payment.status

    into
        v_payment_student_id,
        v_payment_academic_year_id,
        v_payment_amount,
        v_payment_status

    from public.payments
        as payment

    where payment.id =
          new.payment_id

    for update;


    if not found then
        raise exception
            'Pembayaran tidak ditemukan.';
    end if;


    if v_payment_status <>
       'recorded'
    then
        raise exception
            'Pembayaran yang dibatalkan tidak dapat dialokasikan.';
    end if;


    -- =====================================================
    -- BILL
    -- =====================================================

    select
        bill.student_id,
        bill.academic_year_id,
        bill.amount,
        bill.status

    into
        v_bill_student_id,
        v_bill_academic_year_id,
        v_bill_amount,
        v_bill_status

    from public.student_bills
        as bill

    where bill.id =
          new.bill_id

    for update;


    if not found then
        raise exception
            'Tagihan tidak ditemukan.';
    end if;


    if v_bill_status =
       'cancelled'
    then
        raise exception
            'Tagihan yang dibatalkan tidak dapat menerima pembayaran.';
    end if;


    -- =====================================================
    -- SAME STUDENT
    -- =====================================================

    if v_payment_student_id <>
       v_bill_student_id
    then
        raise exception
            'Pembayaran dan tagihan harus berasal dari santri yang sama.';
    end if;


    -- =====================================================
    -- SAME ACADEMIC YEAR
    -- =====================================================

    if v_payment_academic_year_id <>
       v_bill_academic_year_id
    then
        raise exception
            'Pembayaran dan tagihan harus berada pada tahun ajaran yang sama.';
    end if;


    -- =====================================================
    -- PAYMENT LIMIT
    -- =====================================================

    select
        coalesce(
            sum(
                allocation.amount
            ),
            0
        )

    into
        v_existing_payment_allocated

    from public.payment_allocations
        as allocation

    where allocation.payment_id =
          new.payment_id

      and allocation.id <>
          coalesce(
              new.id,
              gen_random_uuid()
          );


    if (
        v_existing_payment_allocated +
        new.amount
    ) >
       v_payment_amount
    then
        raise exception
            'Total alokasi melebihi nominal pembayaran.';
    end if;


    -- =====================================================
    -- BILL LIMIT
    --
    -- Hanya allocation dari payment RECORDed yang dihitung.
    -- =====================================================

    select
        coalesce(
            sum(
                allocation.amount
            ),
            0
        )

    into
        v_existing_bill_allocated

    from public.payment_allocations
        as allocation

    inner join public.payments
        as payment
        on payment.id =
           allocation.payment_id

    where allocation.bill_id =
          new.bill_id

      and allocation.id <>
          coalesce(
              new.id,
              gen_random_uuid()
          )

      and payment.status =
          'recorded';


    if (
        v_existing_bill_allocated +
        new.amount
    ) >
       v_bill_amount
    then
        raise exception
            'Total pembayaran melebihi nominal tagihan.';
    end if;


    return new;

end;
$function$;


drop trigger
if exists validate_payment_allocation_before_write
on public.payment_allocations;


create trigger
validate_payment_allocation_before_write
before insert or update
on public.payment_allocations
for each row
execute function public.validate_payment_allocation();


-- =========================================================
-- H. RECALCULATE BILL STATUS
--
-- Tagihan:
--
-- allocated = 0
-- → unpaid
--
-- 0 < allocated < bill amount
-- → partial
--
-- allocated >= bill amount
-- → paid
--
-- cancelled
-- → tidak diubah otomatis.
-- =========================================================

create or replace function
public.recalculate_student_bill_status(
    p_bill_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_bill_amount numeric(14,2);
    v_current_status text;

    v_paid_amount numeric(14,2) := 0;
    v_new_status text;
begin

    select
        bill.amount,
        bill.status

    into
        v_bill_amount,
        v_current_status

    from public.student_bills
        as bill

    where bill.id =
          p_bill_id

    for update;


    if not found then
        return;
    end if;


    -- Tagihan cancelled tidak boleh diaktifkan kembali
    -- oleh recalculation otomatis.
    if v_current_status =
       'cancelled'
    then
        return;
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


    if v_paid_amount <= 0 then

        v_new_status :=
            'unpaid';

    elsif v_paid_amount <
          v_bill_amount
    then

        v_new_status :=
            'partial';

    else

        v_new_status :=
            'paid';

    end if;


    update public.student_bills
    set
        status =
            v_new_status

    where id =
          p_bill_id

      and status <>
          v_new_status;

end;
$function$;


-- =========================================================
-- I. ALLOCATION STATUS TRIGGER
-- =========================================================

create or replace function
public.handle_payment_allocation_bill_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin

    if tg_op =
       'DELETE'
    then

        perform
            public.recalculate_student_bill_status(
                old.bill_id
            );

        return old;

    end if;


    -- Recalculate current bill.
    perform
        public.recalculate_student_bill_status(
            new.bill_id
        );


    -- Kalau allocation dipindahkan ke bill lain,
    -- bill lama juga harus dihitung ulang.
    if tg_op =
       'UPDATE'
       and old.bill_id <>
           new.bill_id
    then

        perform
            public.recalculate_student_bill_status(
                old.bill_id
            );

    end if;


    return new;

end;
$function$;


drop trigger
if exists recalculate_bill_after_allocation_change
on public.payment_allocations;


create trigger
recalculate_bill_after_allocation_change
after insert or update or delete
on public.payment_allocations
for each row
execute function public.handle_payment_allocation_bill_status();


-- =========================================================
-- J. PAYMENT STATUS CHANGE
--
-- Jika payment RECORDed → CANCELLED atau sebaliknya,
-- semua tagihan yang pernah menggunakan payment tersebut
-- harus dihitung ulang.
-- =========================================================

create or replace function
public.handle_payment_status_bill_recalculation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_bill_id uuid;
begin

    if old.status =
       new.status
    then
        return new;
    end if;


    for v_bill_id in

        select distinct
            allocation.bill_id

        from public.payment_allocations
            as allocation

        where allocation.payment_id =
              new.id

    loop

        perform
            public.recalculate_student_bill_status(
                v_bill_id
            );

    end loop;


    return new;

end;
$function$;


drop trigger
if exists recalculate_bills_after_payment_status_change
on public.payments;


create trigger
recalculate_bills_after_payment_status_change
after update of status
on public.payments
for each row
execute function public.handle_payment_status_bill_recalculation();


-- =========================================================
-- K. PREVENT BILL CANCELLATION WITH ACTIVE PAYMENT
--
-- Tagihan yang sudah menerima pembayaran tidak boleh
-- langsung cancelled.
--
-- Pembayaran/alokasinya harus dibereskan terlebih dahulu.
-- =========================================================

create or replace function
public.prevent_paid_bill_cancellation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_active_paid_amount numeric(14,2);
begin

    if old.status <>
       'cancelled'

       and new.status =
           'cancelled'
    then

        select
            coalesce(
                sum(
                    allocation.amount
                ),
                0
            )

        into
            v_active_paid_amount

        from public.payment_allocations
            as allocation

        inner join public.payments
            as payment
            on payment.id =
               allocation.payment_id

        where allocation.bill_id =
              new.id

          and payment.status =
              'recorded';


        if v_active_paid_amount > 0 then
            raise exception
                'Tagihan yang sudah memiliki pembayaran aktif tidak dapat dibatalkan.';
        end if;

    end if;


    return new;

end;
$function$;


drop trigger
if exists prevent_student_bill_invalid_cancellation
on public.student_bills;


create trigger
prevent_student_bill_invalid_cancellation
before update of status
on public.student_bills
for each row
execute function public.prevent_paid_bill_cancellation();


-- =========================================================
-- L. RLS
-- =========================================================

alter table
public.student_bills
enable row level security;


alter table
public.payments
enable row level security;


alter table
public.payment_allocations
enable row level security;


-- =========================================================
-- M. DIRECT TABLE PRIVILEGES
--
-- Authenticated user tidak mengakses tabel langsung.
-- RPC akan dibuat pada tahap berikutnya.
-- =========================================================

revoke all
on public.student_bills
from public;


revoke all
on public.student_bills
from anon;


revoke all
on public.student_bills
from authenticated;


revoke all
on public.payments
from public;


revoke all
on public.payments
from anon;


revoke all
on public.payments
from authenticated;


revoke all
on public.payment_allocations
from public;


revoke all
on public.payment_allocations
from anon;


revoke all
on public.payment_allocations
from authenticated;


-- Service role tetap dapat digunakan untuk maintenance.
grant
select,
insert,
update,
delete
on public.student_bills
to service_role;


grant
select,
insert,
update,
delete
on public.payments
to service_role;


grant
select,
insert,
update,
delete
on public.payment_allocations
to service_role;


-- =========================================================
-- N. COMMENTS
-- =========================================================

comment on table
public.student_bills
is
'Tagihan keuangan per santri. Status unpaid/partial/paid dihitung dari payment_allocations aktif.';


comment on table
public.payments
is
'Transaksi pembayaran santri. Pembayaran yang salah dibatalkan melalui status cancelled dan tidak dihapus.';


comment on table
public.payment_allocations
is
'Alokasi nominal pembayaran ke satu atau beberapa tagihan santri.';


comment on column
public.payments.proof_path
is
'Path file bukti pembayaran pada private Supabase Storage bucket.';


commit;