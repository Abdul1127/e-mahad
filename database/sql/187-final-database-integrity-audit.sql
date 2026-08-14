-- ============================================================
-- E-MA'HAD
-- STAGE 187
--
-- FINAL DATABASE INTEGRITY AUDIT
--
-- READ ONLY
--
-- Pemeriksaan:
-- 01. Current academic year
-- 02. Active students
-- 03. Login identity
-- 04. Database constraints
-- 05. Tahfiz integrity
-- 06. Care journal integrity
-- 07. Mahad Head Journal integrity
-- 08. Finance cancellation integrity
-- 09. Payment allocation integrity
-- 10. Bill balance/status integrity
-- 11. Critical RPC security
-- 12. Private Storage buckets
-- ============================================================


create temporary table if not exists
emahad_stage_187_result (
    step_order integer,
    test_name text,
    status text,
    detail text
);


truncate table
emahad_stage_187_result;


-- ============================================================
-- 01. EXACTLY ONE CURRENT ACADEMIC YEAR
-- ============================================================

insert into emahad_stage_187_result
select
    1,

    'Current academic year',

    case
        when count(*) = 1
            then 'PASS'

        else 'FAIL'
    end,

    format(
        'current_academic_year_count=%s',
        count(*)
    )

from public.academic_years

where is_current =
      true;


-- ============================================================
-- 02. CURRENT ACADEMIC YEAR DATE RANGE
-- ============================================================

insert into emahad_stage_187_result
select
    2,

    'Academic year date range',

    case
        when count(*) = 1
            then 'PASS'

        else 'FAIL'
    end,

    coalesce(
        string_agg(
            format(
                '%s [%s - %s]',
                name,
                start_date,
                end_date
            ),
            ', '
        ),
        'Current academic year tidak ditemukan.'
    )

from public.academic_years

where is_current =
      true

  and start_date <=
      current_date

  and end_date >=
      current_date

  and start_date <=
      end_date;


-- ============================================================
-- 03. ACTIVE STUDENT BASELINE
--
-- Baseline MVP saat audit akhir = 127 santri aktif.
-- ============================================================

insert into emahad_stage_187_result
select
    3,

    'Active student baseline',

    case
        when count(*) = 127
            then 'PASS'

        else 'FAIL'
    end,

    format(
        'active_students=%s, expected=127',
        count(*)
    )

from public.students

where status =
      'active'

  and deleted_at
      is null;


-- ============================================================
-- 04. DUPLICATE LOGIN ID
--
-- Login ID harus unik walaupun berbeda kapitalisasi.
-- ============================================================

insert into emahad_stage_187_result

with duplicate_login as (
    select
        lower(
            btrim(
                login_id
            )
        ) as normalized_login_id,

        count(*) as total

    from public.profiles

    where login_id
          is not null

      and btrim(
          login_id
      ) <> ''

    group by
        lower(
            btrim(
                login_id
            )
        )

    having count(*) > 1
)

select
    4,

    'Duplicate login ID',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Tidak ada duplicate login_id.'

        else
            format(
                'duplicate_login_groups=%s',
                count(*)
            )
    end

from duplicate_login;


-- ============================================================
-- 05. ACTIVE PROFILE WITHOUT ROLE
--
-- Profile aplikasi yang aktif dan memiliki login ID
-- harus mempunyai minimal satu role.
-- ============================================================

insert into emahad_stage_187_result

with invalid_profile as (
    select
        profile.id,
        profile.login_id

    from public.profiles
        as profile

    where profile.is_active =
          true

      and profile.login_id
          is not null

      and not exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role

              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.is_active =
                true
      )
)

select
    5,

    'Active login profile has role',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Seluruh profile login aktif mempunyai role aktif.'

        else
            format(
                'profiles_without_active_role=%s',
                count(*)
            )
    end

from invalid_profile;


-- ============================================================
-- 06. FOREIGN KEY CONSTRAINT VALIDATION
-- ============================================================

insert into emahad_stage_187_result

select
    6,

    'Foreign key constraints validated',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Seluruh foreign key public telah tervalidasi.'

        else
            format(
                'unvalidated_foreign_keys=%s',
                count(*)
            )
    end

from pg_constraint
    as constraint_item

inner join pg_namespace
    as namespace

    on namespace.oid =
       constraint_item.connamespace

where namespace.nspname =
      'public'

  and constraint_item.contype =
      'f'

  and constraint_item.convalidated =
      false;


-- ============================================================
-- 07. CHECK CONSTRAINT VALIDATION
-- ============================================================

insert into emahad_stage_187_result

select
    7,

    'Check constraints validated',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Seluruh CHECK constraint public telah tervalidasi.'

        else
            format(
                'unvalidated_check_constraints=%s',
                count(*)
            )
    end

from pg_constraint
    as constraint_item

inner join pg_namespace
    as namespace

    on namespace.oid =
       constraint_item.connamespace

where namespace.nspname =
      'public'

  and constraint_item.contype =
      'c'

  and constraint_item.convalidated =
      false;


-- ============================================================
-- 08. TAHFIZ STATUS / TIMESTAMP CONSISTENCY
-- ============================================================

insert into emahad_stage_187_result

with invalid_report as (
    select
        id

    from public.tahfiz_weekly_reports

    where
        (
            status =
                'published'

            and published_at
                is null
        )

        or

        (
            status =
                'draft'

            and published_at
                is not null
        )
)

select
    8,

    'Tahfiz publication integrity',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Status dan published_at laporan Tahfiz konsisten.'

        else
            format(
                'invalid_tahfiz_reports=%s',
                count(*)
            )
    end

from invalid_report;


-- ============================================================
-- 09. CARE JOURNAL STATUS / TIMESTAMP CONSISTENCY
-- ============================================================

insert into emahad_stage_187_result

with invalid_journal as (
    select
        id

    from public.care_journals

    where
        (
            status in (
                'submitted',
                'revision_requested',
                'reviewed'
            )

            and submitted_at
                is null
        )

        or

        (
            status in (
                'revision_requested',
                'reviewed'
            )

            and last_reviewed_at
                is null
        )
)

select
    9,

    'Care journal workflow integrity',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Status workflow Jurnal Pengasuhan konsisten.'

        else
            format(
                'invalid_care_journals=%s',
                count(*)
            )
    end

from invalid_journal;


-- ============================================================
-- 10. MAHAD HEAD JOURNAL STATUS INTEGRITY
-- ============================================================

insert into emahad_stage_187_result

with invalid_journal as (
    select
        id

    from public.mahad_head_journals

    where
        (
            status =
                'submitted'

            and submitted_at
                is null
        )

        or

        (
            status =
                'draft'

            and submitted_at
                is not null
        )
)

select
    10,

    'Mahad Head Journal workflow integrity',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Status workflow Jurnal Kepala Ma''had konsisten.'

        else
            format(
                'invalid_mahad_head_journals=%s',
                count(*)
            )
    end

from invalid_journal;


-- ============================================================
-- 11. PAYMENT CANCELLATION INTEGRITY
-- ============================================================

insert into emahad_stage_187_result

with invalid_payment as (
    select
        id

    from public.payments

    where
        (
            status =
                'cancelled'

            and cancelled_at
                is null
        )

        or

        (
            status =
                'recorded'

            and cancelled_at
                is not null
        )
)

select
    11,

    'Payment cancellation integrity',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Status pembayaran dan cancelled_at konsisten.'

        else
            format(
                'invalid_payments=%s',
                count(*)
            )
    end

from invalid_payment;


-- ============================================================
-- 12. BILL CANCELLATION INTEGRITY
-- ============================================================

insert into emahad_stage_187_result

with invalid_bill as (
    select
        id

    from public.student_bills

    where
        (
            status =
                'cancelled'

            and cancelled_at
                is null
        )

        or

        (
            status <>
                'cancelled'

            and cancelled_at
                is not null
        )
)

select
    12,

    'Bill cancellation integrity',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Status tagihan dan cancelled_at konsisten.'

        else
            format(
                'invalid_bills=%s',
                count(*)
            )
    end

from invalid_bill;


-- ============================================================
-- 13. ALLOCATION AMOUNT MUST BE POSITIVE
-- ============================================================

insert into emahad_stage_187_result

select
    13,

    'Payment allocation positive amount',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Seluruh allocation mempunyai nominal positif.'

        else
            format(
                'invalid_allocations=%s',
                count(*)
            )
    end

from public.payment_allocations

where amount <= 0;


-- ============================================================
-- 14. PAYMENT / BILL ALLOCATION ENTITY CONSISTENCY
--
-- Payment dan bill dalam satu allocation harus:
-- - milik santri yang sama
-- - tahun ajaran yang sama
-- ============================================================

insert into emahad_stage_187_result

with invalid_allocation as (
    select
        allocation.id

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

    where payment.student_id <>
          bill.student_id

       or payment.academic_year_id <>
          bill.academic_year_id
)

select
    14,

    'Payment allocation entity integrity',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Seluruh allocation menghubungkan payment dan bill santri/tahun ajaran yang sama.'

        else
            format(
                'invalid_entity_allocations=%s',
                count(*)
            )
    end

from invalid_allocation;


-- ============================================================
-- 15. ACTIVE PAYMENT MUST NOT BE OVER-ALLOCATED
-- ============================================================

insert into emahad_stage_187_result

with allocation_summary as (
    select
        payment.id,

        payment.amount,

        coalesce(
            sum(
                allocation.amount
            ),
            0
        ) as allocated_amount

    from public.payments
        as payment

    left join public.payment_allocations
        as allocation

        on allocation.payment_id =
           payment.id

    where payment.status =
          'recorded'

    group by
        payment.id,
        payment.amount
),

invalid_payment as (
    select
        id

    from allocation_summary

    where allocated_amount >
          amount
)

select
    15,

    'Recorded payment over-allocation',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Tidak ada pembayaran recorded yang dialokasikan melebihi nominalnya.'

        else
            format(
                'overallocated_payments=%s',
                count(*)
            )
    end

from invalid_payment;


-- ============================================================
-- 16. ACTIVE BILL MUST NOT BE OVERPAID
--
-- Hanya allocation dari payment status=recorded yang dihitung.
-- Allocation payment cancelled tetap histori.
-- ============================================================

insert into emahad_stage_187_result

with bill_balance as (
    select
        bill.id,

        bill.amount,

        coalesce(
            sum(
                allocation.amount
            ) filter (
                where payment.status =
                      'recorded'
            ),
            0
        ) as active_paid_amount

    from public.student_bills
        as bill

    left join public.payment_allocations
        as allocation

        on allocation.bill_id =
           bill.id

    left join public.payments
        as payment

        on payment.id =
           allocation.payment_id

    where bill.status <>
          'cancelled'

    group by
        bill.id,
        bill.amount
),

invalid_bill as (
    select
        id

    from bill_balance

    where active_paid_amount >
          amount
)

select
    16,

    'Active bill overpayment',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Tidak ada tagihan aktif dengan pembayaran aktif melebihi nominal tagihan.'

        else
            format(
                'overpaid_bills=%s',
                count(*)
            )
    end

from invalid_bill;


-- ============================================================
-- 17. BILL STATUS MUST MATCH ACTIVE PAYMENT BALANCE
--
-- cancelled payment tidak dihitung.
-- ============================================================

insert into emahad_stage_187_result

with bill_balance as (
    select
        bill.id,

        bill.status,

        bill.amount,

        bill.cancelled_at,

        coalesce(
            sum(
                allocation.amount
            ) filter (
                where payment.status =
                      'recorded'
            ),
            0
        ) as active_paid_amount

    from public.student_bills
        as bill

    left join public.payment_allocations
        as allocation

        on allocation.bill_id =
           bill.id

    left join public.payments
        as payment

        on payment.id =
           allocation.payment_id

    group by
        bill.id,
        bill.status,
        bill.amount,
        bill.cancelled_at
),

expected_status as (
    select
        id,

        status,

        case

            when cancelled_at
                 is not null
            then
                'cancelled'

            when active_paid_amount <= 0
            then
                'unpaid'

            when active_paid_amount >= amount
            then
                'paid'

            else
                'partial'

        end as calculated_status

    from bill_balance
),

invalid_bill as (
    select
        id

    from expected_status

    where status <>
          calculated_status
)

select
    17,

    'Bill status matches active balance',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Seluruh status tagihan sesuai saldo pembayaran aktif.'

        else
            format(
                'bill_status_mismatch=%s',
                count(*)
            )
    end

from invalid_bill;


-- ============================================================
-- 18. CRITICAL RPC SECURITY
--
-- Seluruh RPC kritis:
-- - harus ada
-- - SECURITY DEFINER
-- - authenticated dapat EXECUTE
-- - anon tidak dapat EXECUTE
-- ============================================================

insert into emahad_stage_187_result

with required_functions (
    function_name
) as (
    values

        ('get_my_access_context'),

        ('has_role'),

        ('get_guardian_tahfiz_dashboard'),

        ('get_guardian_tahfiz_report_history'),

        ('get_guardian_bill_list'),

        ('get_guardian_payment_history'),

        ('get_bendahara_dashboard'),

        ('create_bendahara_student_bill'),

        ('record_bendahara_bill_payment'),

        ('cancel_bendahara_payment'),

        ('get_kepala_mahad_finance_summary'),

        ('get_bendahara_finance_report'),

        ('get_penanggung_jawab_dormitory_monitoring'),

        ('get_leadership_tahfiz_monitoring_overview'),

        ('get_leadership_tahfiz_student_history')
),

function_audit as (
    select
        required.function_name,

        count(
            procedure.oid
        ) as function_count,

        coalesce(
            bool_and(
                procedure.prosecdef
            ),
            false
        ) as all_security_definer,

        coalesce(
            bool_and(
                has_function_privilege(
                    'authenticated',
                    procedure.oid,
                    'EXECUTE'
                )
            ),
            false
        ) as authenticated_execute,

        coalesce(
            bool_and(
                not has_function_privilege(
                    'anon',
                    procedure.oid,
                    'EXECUTE'
                )
            ),
            false
        ) as anon_denied

    from required_functions
        as required

    left join pg_proc
        as procedure

        on procedure.proname =
           required.function_name

    left join pg_namespace
        as namespace

        on namespace.oid =
           procedure.pronamespace

       and namespace.nspname =
           'public'

    group by
        required.function_name
),

invalid_function as (
    select
        *

    from function_audit

    where function_count = 0

       or all_security_definer =
          false

       or authenticated_execute =
          false

       or anon_denied =
          false
)

select
    18,

    'Critical RPC security',

    case
        when count(*) = 0
            then 'PASS'

        else 'FAIL'
    end,

    case
        when count(*) = 0
        then
            'Seluruh RPC kritis tersedia, SECURITY DEFINER, authenticated executable, dan anon denied.'

        else
            format(
                'invalid_or_missing_rpc_groups=%s',
                count(*)
            )
    end

from invalid_function;


-- ============================================================
-- 19. PAYMENT PROOF STORAGE PRIVATE
-- ============================================================

insert into emahad_stage_187_result

select
    19,

    'Payment proof bucket private',

    case
        when count(*) = 1
        then
            'PASS'

        else
            'FAIL'
    end,

    case
        when count(*) = 1
        then
            'Bucket payment-proofs tersedia dan private.'

        else
            'Bucket payment-proofs tidak ditemukan atau public.'
    end

from storage.buckets

where id =
      'payment-proofs'

  and public =
      false;


-- ============================================================
-- 20. MAHAD HEAD JOURNAL EVIDENCE STORAGE PRIVATE
-- ============================================================

insert into emahad_stage_187_result

select
    20,

    'Mahad Head Journal evidence bucket private',

    case
        when count(*) = 1
        then
            'PASS'

        else
            'FAIL'
    end,

    case
        when count(*) = 1
        then
            'Bucket mahad-head-journal-evidence tersedia dan private.'

        else
            'Bucket mahad-head-journal-evidence tidak ditemukan atau public.'
    end

from storage.buckets

where id =
      'mahad-head-journal-evidence'

  and public =
      false;


-- ============================================================
-- 21. SUMMARY
-- ============================================================

insert into emahad_stage_187_result

select
    21,

    'FINAL DATABASE INTEGRITY',

    case
        when count(*) filter (
            where status =
                  'FAIL'
        ) = 0
        then
            'PASS'

        else
            'FAIL'
    end,

    format(
        'PASS=%s, FAIL=%s',
        count(*) filter (
            where status =
                  'PASS'
        ),
        count(*) filter (
            where status =
                  'FAIL'
        )
    )

from emahad_stage_187_result;


-- ============================================================
-- FINAL RESULT
-- ============================================================

select
    test_name,
    status,
    detail

from emahad_stage_187_result

order by
    step_order;