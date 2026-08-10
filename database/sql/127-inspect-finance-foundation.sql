-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 127-inspect-finance-foundation.sql
--
-- PURPOSE:
-- Audit fondasi database Keuangan sebelum membangun:
--
-- - Tagihan Santri
-- - Pembayaran
-- - Riwayat Pembayaran
-- - Bukti Pembayaran
-- - Dashboard Bendahara
-- - Akses Keuangan Orang Tua/Wali
--
-- READ ONLY
--
-- Tidak membuat / mengubah / menghapus data.
--
-- Semua hasil utama dibuat dalam SATU result set agar
-- mudah dikirim kembali dari Supabase SQL Editor.
-- =========================================================


-- =========================================================
-- 1. FINANCE RELATED TABLES
-- =========================================================

select
    'TABLE'
        as object_type,

    table_data.table_name
        as object_name,

    null::text
        as detail_1,

    null::text
        as detail_2,

    null::text
        as detail_3,

    null::text
        as detail_4

from information_schema.tables
    as table_data

where table_data.table_schema =
      'public'

  and table_data.table_type =
      'BASE TABLE'

  and (
      table_data.table_name ilike '%billing%'

      or table_data.table_name ilike '%bill%'

      or table_data.table_name ilike '%invoice%'

      or table_data.table_name ilike '%payment%'

      or table_data.table_name ilike '%transaction%'

      or table_data.table_name ilike '%finance%'

      or table_data.table_name ilike '%financial%'

      or table_data.table_name ilike '%fee%'

      or table_data.table_name ilike '%tuition%'

      or table_data.table_name ilike '%spp%'

      or table_data.table_name ilike '%tagihan%'

      or table_data.table_name ilike '%pembayaran%'

      or table_data.table_name ilike '%keuangan%'
  )


union all


-- =========================================================
-- 2. COLUMNS FROM FINANCE RELATED TABLES
-- =========================================================

select
    'COLUMN'
        as object_type,

    column_data.table_name
        as object_name,

    column_data.column_name
        as detail_1,

    column_data.data_type
        as detail_2,

    case
        when column_data.is_nullable =
             'YES'
        then 'nullable'

        else 'required'
    end
        as detail_3,

    coalesce(
        column_data.column_default,
        ''
    )
        as detail_4

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and (
      column_data.table_name ilike '%billing%'

      or column_data.table_name ilike '%bill%'

      or column_data.table_name ilike '%invoice%'

      or column_data.table_name ilike '%payment%'

      or column_data.table_name ilike '%transaction%'

      or column_data.table_name ilike '%finance%'

      or column_data.table_name ilike '%financial%'

      or column_data.table_name ilike '%fee%'

      or column_data.table_name ilike '%tuition%'

      or column_data.table_name ilike '%spp%'

      or column_data.table_name ilike '%tagihan%'

      or column_data.table_name ilike '%pembayaran%'

      or column_data.table_name ilike '%keuangan%'
  )


union all


-- =========================================================
-- 3. FINANCE-LIKE COLUMNS IN OTHER TABLES
--
-- Berguna kalau struktur lama ternyata tidak memakai nama
-- tabel finance/payment tetapi menyimpan kolom keuangan
-- di tabel lain.
-- =========================================================

select
    'RELATED_COLUMN'
        as object_type,

    column_data.table_name
        as object_name,

    column_data.column_name
        as detail_1,

    column_data.data_type
        as detail_2,

    case
        when column_data.is_nullable =
             'YES'
        then 'nullable'

        else 'required'
    end
        as detail_3,

    coalesce(
        column_data.column_default,
        ''
    )
        as detail_4

from information_schema.columns
    as column_data

where column_data.table_schema =
      'public'

  and (
      column_data.column_name ilike '%billing%'

      or column_data.column_name ilike '%bill%'

      or column_data.column_name ilike '%invoice%'

      or column_data.column_name ilike '%payment%'

      or column_data.column_name ilike '%paid%'

      or column_data.column_name ilike '%transaction%'

      or column_data.column_name ilike '%amount%'

      or column_data.column_name ilike '%balance%'

      or column_data.column_name ilike '%fee%'

      or column_data.column_name ilike '%tuition%'

      or column_data.column_name ilike '%spp%'

      or column_data.column_name ilike '%tagihan%'

      or column_data.column_name ilike '%pembayaran%'

      or column_data.column_name ilike '%nominal%'

      or column_data.column_name ilike '%jatuh_tempo%'

      or column_data.column_name ilike '%due_date%'

      or column_data.column_name ilike '%payment_method%'

      or column_data.column_name ilike '%reference_number%'

      or column_data.column_name ilike '%proof%'
  )


union all


-- =========================================================
-- 4. FINANCE RELATED FUNCTIONS / RPC
-- =========================================================

select
    'FUNCTION'
        as object_type,

    procedure_data.proname
        as object_name,

    pg_get_function_identity_arguments(
        procedure_data.oid
    )
        as detail_1,

    pg_get_function_result(
        procedure_data.oid
    )
        as detail_2,

    case
        when procedure_data.prosecdef
        then 'security definer'

        else 'security invoker'
    end
        as detail_3,

    procedure_data.provolatile::text
        as detail_4

from pg_proc
    as procedure_data

inner join pg_namespace
    as namespace
    on namespace.oid =
       procedure_data.pronamespace

where namespace.nspname =
      'public'

  and (
      procedure_data.proname ilike '%billing%'

      or procedure_data.proname ilike '%bill%'

      or procedure_data.proname ilike '%invoice%'

      or procedure_data.proname ilike '%payment%'

      or procedure_data.proname ilike '%transaction%'

      or procedure_data.proname ilike '%finance%'

      or procedure_data.proname ilike '%financial%'

      or procedure_data.proname ilike '%fee%'

      or procedure_data.proname ilike '%tuition%'

      or procedure_data.proname ilike '%spp%'

      or procedure_data.proname ilike '%tagihan%'

      or procedure_data.proname ilike '%pembayaran%'

      or procedure_data.proname ilike '%keuangan%'

      or procedure_data.proname ilike '%bendahara%'
  )


union all


-- =========================================================
-- 5. FOREIGN KEYS INVOLVING FINANCE TABLES
-- =========================================================

select
    'FOREIGN_KEY'
        as object_type,

    source_table.relname
        as object_name,

    constraint_data.conname
        as detail_1,

    target_table.relname
        as detail_2,

    pg_get_constraintdef(
        constraint_data.oid
    )
        as detail_3,

    null::text
        as detail_4

from pg_constraint
    as constraint_data

inner join pg_class
    as source_table
    on source_table.oid =
       constraint_data.conrelid

inner join pg_namespace
    as source_namespace
    on source_namespace.oid =
       source_table.relnamespace

inner join pg_class
    as target_table
    on target_table.oid =
       constraint_data.confrelid

where constraint_data.contype =
      'f'

  and source_namespace.nspname =
      'public'

  and (
      source_table.relname ilike '%billing%'

      or source_table.relname ilike '%bill%'

      or source_table.relname ilike '%invoice%'

      or source_table.relname ilike '%payment%'

      or source_table.relname ilike '%transaction%'

      or source_table.relname ilike '%finance%'

      or source_table.relname ilike '%fee%'

      or source_table.relname ilike '%tuition%'

      or source_table.relname ilike '%spp%'

      or source_table.relname ilike '%tagihan%'

      or source_table.relname ilike '%pembayaran%'

      or source_table.relname ilike '%keuangan%'

      or target_table.relname ilike '%billing%'

      or target_table.relname ilike '%invoice%'

      or target_table.relname ilike '%payment%'

      or target_table.relname ilike '%transaction%'

      or target_table.relname ilike '%finance%'

      or target_table.relname ilike '%fee%'

      or target_table.relname ilike '%tagihan%'

      or target_table.relname ilike '%pembayaran%'
  )


union all


-- =========================================================
-- 6. TABLES WITH DIRECT STUDENT FINANCIAL RELATION
--
-- Cari tabel mana pun yang mempunyai student_id dan juga
-- kolom yang terlihat seperti nominal/tagihan/pembayaran.
-- =========================================================

select distinct
    'STUDENT_FINANCE_CANDIDATE'
        as object_type,

    student_column.table_name
        as object_name,

    student_column.column_name
        as detail_1,

    finance_column.column_name
        as detail_2,

    finance_column.data_type
        as detail_3,

    null::text
        as detail_4

from information_schema.columns
    as student_column

inner join information_schema.columns
    as finance_column
    on finance_column.table_schema =
       student_column.table_schema

   and finance_column.table_name =
       student_column.table_name

where student_column.table_schema =
      'public'

  and student_column.column_name =
      'student_id'

  and (
      finance_column.column_name ilike '%amount%'

      or finance_column.column_name ilike '%payment%'

      or finance_column.column_name ilike '%paid%'

      or finance_column.column_name ilike '%balance%'

      or finance_column.column_name ilike '%fee%'

      or finance_column.column_name ilike '%nominal%'

      or finance_column.column_name ilike '%tagihan%'

      or finance_column.column_name ilike '%pembayaran%'

      or finance_column.column_name ilike '%invoice%'

      or finance_column.column_name ilike '%due_date%'
  )


union all


-- =========================================================
-- 7. CHECK CONSTRAINTS
-- =========================================================

select
    'CONSTRAINT'
        as object_type,

    table_data.relname
        as object_name,

    constraint_data.conname
        as detail_1,

    case constraint_data.contype
        when 'p' then 'PRIMARY KEY'
        when 'u' then 'UNIQUE'
        when 'c' then 'CHECK'
        when 'f' then 'FOREIGN KEY'
        when 'x' then 'EXCLUSION'
        else constraint_data.contype::text
    end
        as detail_2,

    pg_get_constraintdef(
        constraint_data.oid
    )
        as detail_3,

    null::text
        as detail_4

from pg_constraint
    as constraint_data

inner join pg_class
    as table_data
    on table_data.oid =
       constraint_data.conrelid

inner join pg_namespace
    as namespace
    on namespace.oid =
       table_data.relnamespace

where namespace.nspname =
      'public'

  and (
      table_data.relname ilike '%billing%'

      or table_data.relname ilike '%bill%'

      or table_data.relname ilike '%invoice%'

      or table_data.relname ilike '%payment%'

      or table_data.relname ilike '%transaction%'

      or table_data.relname ilike '%finance%'

      or table_data.relname ilike '%fee%'

      or table_data.relname ilike '%tuition%'

      or table_data.relname ilike '%spp%'

      or table_data.relname ilike '%tagihan%'

      or table_data.relname ilike '%pembayaran%'

      or table_data.relname ilike '%keuangan%'
  )


union all


-- =========================================================
-- 8. INDEXES
-- =========================================================

select
    'INDEX'
        as object_type,

    index_data.tablename
        as object_name,

    index_data.indexname
        as detail_1,

    index_data.indexdef
        as detail_2,

    null::text
        as detail_3,

    null::text
        as detail_4

from pg_indexes
    as index_data

where index_data.schemaname =
      'public'

  and (
      index_data.tablename ilike '%billing%'

      or index_data.tablename ilike '%bill%'

      or index_data.tablename ilike '%invoice%'

      or index_data.tablename ilike '%payment%'

      or index_data.tablename ilike '%transaction%'

      or index_data.tablename ilike '%finance%'

      or index_data.tablename ilike '%fee%'

      or index_data.tablename ilike '%tuition%'

      or index_data.tablename ilike '%spp%'

      or index_data.tablename ilike '%tagihan%'

      or index_data.tablename ilike '%pembayaran%'

      or index_data.tablename ilike '%keuangan%'
  )


union all


-- =========================================================
-- 9. RLS STATUS
-- =========================================================

select
    'RLS'
        as object_type,

    table_data.relname
        as object_name,

    case
        when table_data.relrowsecurity
        then 'enabled'

        else 'disabled'
    end
        as detail_1,

    case
        when table_data.relforcerowsecurity
        then 'forced'

        else 'not forced'
    end
        as detail_2,

    null::text
        as detail_3,

    null::text
        as detail_4

from pg_class
    as table_data

inner join pg_namespace
    as namespace
    on namespace.oid =
       table_data.relnamespace

where namespace.nspname =
      'public'

  and table_data.relkind =
      'r'

  and (
      table_data.relname ilike '%billing%'

      or table_data.relname ilike '%bill%'

      or table_data.relname ilike '%invoice%'

      or table_data.relname ilike '%payment%'

      or table_data.relname ilike '%transaction%'

      or table_data.relname ilike '%finance%'

      or table_data.relname ilike '%fee%'

      or table_data.relname ilike '%tuition%'

      or table_data.relname ilike '%spp%'

      or table_data.relname ilike '%tagihan%'

      or table_data.relname ilike '%pembayaran%'

      or table_data.relname ilike '%keuangan%'
  )


union all


-- =========================================================
-- 10. RLS POLICIES
-- =========================================================

select
    'RLS_POLICY'
        as object_type,

    policy_data.tablename
        as object_name,

    policy_data.policyname
        as detail_1,

    policy_data.cmd
        as detail_2,

    coalesce(
        policy_data.qual,
        ''
    )
        as detail_3,

    coalesce(
        policy_data.with_check,
        ''
    )
        as detail_4

from pg_policies
    as policy_data

where policy_data.schemaname =
      'public'

  and (
      policy_data.tablename ilike '%billing%'

      or policy_data.tablename ilike '%bill%'

      or policy_data.tablename ilike '%invoice%'

      or policy_data.tablename ilike '%payment%'

      or policy_data.tablename ilike '%transaction%'

      or policy_data.tablename ilike '%finance%'

      or policy_data.tablename ilike '%fee%'

      or policy_data.tablename ilike '%tuition%'

      or policy_data.tablename ilike '%spp%'

      or policy_data.tablename ilike '%tagihan%'

      or policy_data.tablename ilike '%pembayaran%'

      or policy_data.tablename ilike '%keuangan%'
  )


union all


-- =========================================================
-- 11. TRIGGERS
-- =========================================================

select
    'TRIGGER'
        as object_type,

    event_data.event_object_table
        as object_name,

    event_data.trigger_name
        as detail_1,

    event_data.action_timing
        as detail_2,

    event_data.event_manipulation
        as detail_3,

    event_data.action_statement
        as detail_4

from information_schema.triggers
    as event_data

where event_data.trigger_schema =
      'public'

  and (
      event_data.event_object_table ilike '%billing%'

      or event_data.event_object_table ilike '%bill%'

      or event_data.event_object_table ilike '%invoice%'

      or event_data.event_object_table ilike '%payment%'

      or event_data.event_object_table ilike '%transaction%'

      or event_data.event_object_table ilike '%finance%'

      or event_data.event_object_table ilike '%fee%'

      or event_data.event_object_table ilike '%tuition%'

      or event_data.event_object_table ilike '%spp%'

      or event_data.event_object_table ilike '%tagihan%'

      or event_data.event_object_table ilike '%pembayaran%'

      or event_data.event_object_table ilike '%keuangan%'
  )


union all


-- =========================================================
-- 12. BENDAHARA ROLE
-- =========================================================

select
    'ROLE'
        as object_type,

    role.code
        as object_name,

    role.name
        as detail_1,

    role.is_active::text
        as detail_2,

    role.id::text
        as detail_3,

    null::text
        as detail_4

from public.roles
    as role

where role.code =
      'bendahara'


union all


-- =========================================================
-- 13. ACTIVE BENDAHARA ACCOUNTS
-- =========================================================

select
    'BENDAHARA_ACCOUNT'
        as object_type,

    staff.full_name
        as object_name,

    staff.legacy_staff_id
        as detail_1,

    profile.login_id
        as detail_2,

    profile.is_active::text
        as detail_3,

    staff.id::text
        as detail_4

from public.staff
    as staff

inner join public.profiles
    as profile
    on profile.id =
       staff.profile_id

inner join public.user_roles
    as user_role
    on user_role.user_id =
       profile.id

inner join public.roles
    as role
    on role.id =
       user_role.role_id

where role.code =
      'bendahara'

  and role.is_active =
      true


union all


-- =========================================================
-- 14. STORAGE BUCKETS POTENTIALLY RELATED TO PAYMENT PROOF
-- =========================================================

select
    'STORAGE_BUCKET'
        as object_type,

    bucket.name
        as object_name,

    bucket.id
        as detail_1,

    bucket.public::text
        as detail_2,

    coalesce(
        bucket.file_size_limit::text,
        ''
    )
        as detail_3,

    coalesce(
        array_to_string(
            bucket.allowed_mime_types,
            ', '
        ),
        ''
    )
        as detail_4

from storage.buckets
    as bucket

where bucket.name ilike '%payment%'

   or bucket.name ilike '%billing%'

   or bucket.name ilike '%invoice%'

   or bucket.name ilike '%finance%'

   or bucket.name ilike '%proof%'

   or bucket.name ilike '%receipt%'

   or bucket.name ilike '%tagihan%'

   or bucket.name ilike '%pembayaran%'


union all


-- =========================================================
-- 15. GENERIC STORAGE BUCKET LIST
--
-- Ditampilkan supaya kita tahu apakah ada bucket lama yang
-- namanya tidak menggunakan kata payment/billing.
-- =========================================================

select
    'STORAGE_BUCKET_ALL'
        as object_type,

    bucket.name
        as object_name,

    bucket.id
        as detail_1,

    bucket.public::text
        as detail_2,

    coalesce(
        bucket.file_size_limit::text,
        ''
    )
        as detail_3,

    coalesce(
        array_to_string(
            bucket.allowed_mime_types,
            ', '
        ),
        ''
    )
        as detail_4

from storage.buckets
    as bucket


-- =========================================================
-- FINAL ORDER
-- =========================================================

order by
    object_type,
    object_name,
    detail_1;