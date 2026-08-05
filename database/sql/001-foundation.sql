begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 001-foundation.sql
-- PURPOSE:
-- - Extension dasar
-- - Enum dasar
-- - Fungsi updated_at
-- =========================================================

create extension if not exists pgcrypto with schema extensions;

-- =========================================================
-- ENUM: GENDER
-- =========================================================

create type public.gender_type as enum (
    'male',
    'female'
);

comment on type public.gender_type is
'Jenis kelamin santri atau kelompok dalam E-Ma''had.';

-- =========================================================
-- ENUM: STUDENT STATUS
-- =========================================================

create type public.student_status as enum (
    'active',
    'inactive',
    'graduated',
    'withdrawn'
);

comment on type public.student_status is
'Status keaktifan santri dalam sistem E-Ma''had.';

-- =========================================================
-- FUNCTION: AUTOMATIC UPDATED_AT
-- =========================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

comment on function public.set_updated_at() is
'Memperbarui kolom updated_at secara otomatis sebelum row diubah.';

-- Fungsi trigger tidak perlu dipanggil langsung melalui API.
revoke all on function public.set_updated_at() from public;
revoke all on function public.set_updated_at() from anon;
revoke all on function public.set_updated_at() from authenticated;

commit;