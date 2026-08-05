begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 002-identity-and-access.sql
-- PURPOSE:
-- - Profile pengguna
-- - Role
-- - Banyak role untuk satu pengguna
-- - Trigger otomatis dari auth.users
-- =========================================================

-- =========================================================
-- TABLE: PROFILES
-- =========================================================

create table public.profiles (
    id uuid primary key
        references auth.users(id)
        on update cascade
        on delete cascade,

    full_name text not null
        check (char_length(btrim(full_name)) >= 2),

    phone text,
    avatar_url text,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.profiles is
'Profile aplikasi untuk pengguna yang mempunyai akun Supabase Auth.';

comment on column public.profiles.id is
'ID yang sama dengan auth.users.id.';

comment on column public.profiles.is_active is
'Menentukan apakah pengguna diperbolehkan menggunakan aplikasi.';

create trigger set_profiles_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: ROLES
-- =========================================================

create table public.roles (
    id smallint generated always as identity primary key,

    code text not null unique
        check (code ~ '^[a-z][a-z0-9_]*$'),

    name text not null unique,
    description text,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.roles is
'Daftar role aplikasi E-Ma''had.';

comment on column public.roles.code is
'Kode internal role yang digunakan pada authorization dan routing.';

create trigger set_roles_updated_at
before update on public.roles
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: USER ROLES
-- =========================================================

create table public.user_roles (
    id uuid primary key default gen_random_uuid(),

    user_id uuid not null
        references public.profiles(id)
        on update cascade
        on delete cascade,

    role_id smallint not null
        references public.roles(id)
        on update cascade
        on delete restrict,

    assigned_by uuid
        references public.profiles(id)
        on update cascade
        on delete set null,

    created_at timestamptz not null default now(),

    constraint user_roles_user_role_unique
        unique (user_id, role_id)
);

comment on table public.user_roles is
'Menghubungkan satu pengguna dengan satu atau beberapa role.';

create index user_roles_user_id_idx
    on public.user_roles(user_id);

create index user_roles_role_id_idx
    on public.user_roles(role_id);

-- =========================================================
-- SEED: APPLICATION ROLES
-- =========================================================

insert into public.roles (
    code,
    name,
    description
)
values
    (
        'admin',
        'Admin',
        'Mengelola akun, role, data master, assignment, dan konfigurasi sistem.'
    ),
    (
        'penanggung_jawab',
        'Penanggung Jawab',
        'Kepala Sekolah yang memonitor seluruh kegiatan asrama kecuali keuangan.'
    ),
    (
        'kepala_mahad',
        'Kepala Ma''had',
        'Kepala Ma''had sekaligus Ketua Asrama yang memonitor operasional asrama.'
    ),
    (
        'pengasuh',
        'Pengasuh',
        'Mengelola jurnal pengasuhan santri sesuai cakupan Putra atau Putri.'
    ),
    (
        'pembina_tahfiz',
        'Pembina Tahfiz',
        'Mengelola perkembangan tahfiz dan Klinik Tahsin sesuai kelompok ampuan.'
    ),
    (
        'bendahara',
        'Bendahara',
        'Mengelola tagihan, pembayaran, dan laporan keuangan.'
    ),
    (
        'guardian',
        'Orang Tua/Wali',
        'Memantau tahfiz dan keuangan anak yang terhubung dengan akun.'
    )
on conflict (code)
do update set
    name = excluded.name,
    description = excluded.description,
    is_active = true,
    updated_at = now();

-- =========================================================
-- FUNCTION: CREATE PROFILE AFTER AUTH USER CREATED
-- =========================================================

create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
    resolved_full_name text;
    resolved_phone text;
begin
    resolved_full_name := coalesce(
        nullif(btrim(new.raw_user_meta_data ->> 'full_name'), ''),
        nullif(btrim(new.email), ''),
        nullif(btrim(new.phone), ''),
        'Pengguna E-Ma''had'
    );

    resolved_phone := coalesce(
        nullif(btrim(new.phone), ''),
        nullif(btrim(new.raw_user_meta_data ->> 'phone'), '')
    );

    insert into public.profiles (
        id,
        full_name,
        phone
    )
    values (
        new.id,
        resolved_full_name,
        resolved_phone
    )
    on conflict (id) do nothing;

    return new;
end;
$$;

comment on function public.handle_new_auth_user() is
'Membuat profile E-Ma''had setelah akun Supabase Auth dibuat.';

revoke all on function public.handle_new_auth_user()
from public;

revoke all on function public.handle_new_auth_user()
from anon;

revoke all on function public.handle_new_auth_user()
from authenticated;

drop trigger if exists on_auth_user_created
on auth.users;

create trigger on_auth_user_created
after insert on auth.users
for each row
execute function public.handle_new_auth_user();

-- =========================================================
-- BACKFILL EXISTING AUTH USERS
-- =========================================================

insert into public.profiles (
    id,
    full_name,
    phone
)
select
    auth_user.id,

    coalesce(
        nullif(btrim(auth_user.raw_user_meta_data ->> 'full_name'), ''),
        nullif(btrim(auth_user.email), ''),
        nullif(btrim(auth_user.phone), ''),
        'Pengguna E-Ma''had'
    ),

    coalesce(
        nullif(btrim(auth_user.phone), ''),
        nullif(btrim(auth_user.raw_user_meta_data ->> 'phone'), '')
    )
from auth.users as auth_user
on conflict (id) do nothing;

commit;