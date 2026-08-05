begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 003-students-and-guardians.sql
-- PURPOSE:
-- - Data pengurus
-- - Data santri
-- - Data orang tua
-- - Relasi orang tua dengan beberapa santri
-- =========================================================

-- =========================================================
-- TABLE: STAFF
-- =========================================================

create table public.staff (
    id uuid primary key default gen_random_uuid(),

    profile_id uuid unique
        references public.profiles(id)
        on update cascade
        on delete set null,

    legacy_staff_id text unique,

    full_name text not null
        check (char_length(btrim(full_name)) >= 2),

    phone text,
    position text,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

comment on table public.staff is
'Data pengurus atau pegawai E-Ma''had. Pengurus dapat dibuat sebelum mempunyai akun login.';

comment on column public.staff.profile_id is
'Profile akun login. Boleh kosong apabila pengurus belum mempunyai akun.';

comment on column public.staff.legacy_staff_id is
'ID pengurus dari spreadsheet atau sistem lama.';

create index staff_profile_id_idx
    on public.staff(profile_id);

create index staff_is_active_idx
    on public.staff(is_active);

create trigger set_staff_updated_at
before update on public.staff
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: STUDENTS
-- =========================================================

create table public.students (
    id uuid primary key default gen_random_uuid(),

    legacy_student_id text unique,
    nis text unique,

    full_name text not null
        check (char_length(btrim(full_name)) >= 2),

    gender public.gender_type not null,

    birth_date date,
    address text,
    photo_url text,

    status public.student_status not null default 'active',

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    deleted_at timestamptz,

    constraint students_nis_not_blank
        check (
            nis is null
            or char_length(btrim(nis)) > 0
        ),

    constraint students_legacy_id_not_blank
        check (
            legacy_student_id is null
            or char_length(btrim(legacy_student_id)) > 0
        )
);

comment on table public.students is
'Data utama santri E-Ma''had. Santri tidak mempunyai akun login pada MVP.';

comment on column public.students.legacy_student_id is
'ID santri dari spreadsheet atau sistem lama.';

comment on column public.students.deleted_at is
'Soft delete. Data tidak dihapus secara fisik agar riwayat tetap tersedia.';

create index students_full_name_idx
    on public.students(full_name);

create index students_gender_idx
    on public.students(gender);

create index students_status_idx
    on public.students(status);

create index students_deleted_at_idx
    on public.students(deleted_at);

create trigger set_students_updated_at
before update on public.students
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: GUARDIANS
-- =========================================================

create table public.guardians (
    id uuid primary key default gen_random_uuid(),

    profile_id uuid unique
        references public.profiles(id)
        on update cascade
        on delete set null,

    legacy_guardian_id text unique,

    full_name text not null
        check (char_length(btrim(full_name)) >= 2),

    phone text,
    email text,

    is_active boolean not null default true,

    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint guardians_email_not_blank
        check (
            email is null
            or char_length(btrim(email)) > 0
        )
);

comment on table public.guardians is
'Orang tua atau wali yang menjadi pemegang akun untuk memantau satu atau beberapa santri.';

comment on column public.guardians.profile_id is
'Profile login orang tua. Boleh kosong sebelum akun dibuat.';

create index guardians_profile_id_idx
    on public.guardians(profile_id);

create index guardians_is_active_idx
    on public.guardians(is_active);

create trigger set_guardians_updated_at
before update on public.guardians
for each row
execute function public.set_updated_at();

-- =========================================================
-- TABLE: GUARDIAN STUDENTS
-- =========================================================

create table public.guardian_students (
    id uuid primary key default gen_random_uuid(),

    guardian_id uuid not null
        references public.guardians(id)
        on update cascade
        on delete cascade,

    student_id uuid not null
        references public.students(id)
        on update cascade
        on delete cascade,

    relationship_type text not null default 'guardian'
        check (
            relationship_type in (
                'father',
                'mother',
                'guardian',
                'other'
            )
        ),

    is_primary_contact boolean not null default true,

    created_at timestamptz not null default now(),

    constraint guardian_students_guardian_student_unique
        unique (guardian_id, student_id)
);

comment on table public.guardian_students is
'Menghubungkan satu akun orang tua dengan satu atau beberapa santri.';

comment on column public.guardian_students.relationship_type is
'Hubungan pemegang akun dengan santri.';

create index guardian_students_guardian_id_idx
    on public.guardian_students(guardian_id);

create index guardian_students_student_id_idx
    on public.guardian_students(student_id);

commit;