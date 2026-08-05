begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 015-create-student-import-staging.sql
-- PURPOSE:
-- - Membuat schema staging internal
-- - Menyimpan data mentah santri sebelum masuk ke tabel utama
-- - Mencegah data spreadsheet langsung mencemari data produksi
-- =========================================================

create schema if not exists staging;

comment on schema staging is
'Area kerja internal untuk validasi import. Schema ini tidak digunakan langsung oleh aplikasi.';

revoke all on schema staging from public;
revoke all on schema staging from anon;
revoke all on schema staging from authenticated;

create table if not exists staging.student_import_rows (
    id bigint generated always as identity primary key,

    batch_code text not null
        check (char_length(btrim(batch_code)) > 0),

    source_row integer not null
        check (source_row > 0),

    legacy_student_id text not null
        check (char_length(btrim(legacy_student_id)) > 0),

    full_name text not null
        check (char_length(btrim(full_name)) >= 2),

    gender_code text not null
        check (char_length(btrim(gender_code)) > 0),

    grade_level smallint not null
        check (grade_level between 1 and 12),

    tahfiz_group_name text not null
        check (char_length(btrim(tahfiz_group_name)) > 0),

    supervisor_name text,

    loaded_at timestamptz not null default now(),

    constraint student_import_rows_batch_source_unique
        unique (batch_code, source_row)
);

comment on table staging.student_import_rows is
'Data mentah santri dari spreadsheet sebelum divalidasi dan dipindahkan ke tabel public.';

create index if not exists student_import_rows_batch_code_idx
    on staging.student_import_rows(batch_code);

create index if not exists student_import_rows_batch_legacy_id_idx
    on staging.student_import_rows(
        batch_code,
        legacy_student_id
    );

revoke all on table staging.student_import_rows
from public, anon, authenticated;

commit;