# Technical Decisions E-Ma'had

## DEC-001 — Project Mandiri

E-Ma'had merupakan project yang sepenuhnya terpisah dari
project lain.

Tidak membawa asumsi struktur, workflow, atau konvensi dari
project lain.

## DEC-002 — Package Manager

Package manager utama adalah npm.

Project tidak menggunakan pnpm atau yarn.

## DEC-003 — Supabase Cloud

Development menggunakan Supabase Cloud secara langsung.

Project tidak mewajibkan:

- Supabase CLI
- Docker
- Supabase lokal
- Database PostgreSQL lokal

## DEC-004 — Database SQL

SQL disimpan di folder database/sql.

Developer menjalankan SQL secara manual melalui Supabase
SQL Editor.

Setiap perubahan database harus mempunyai file SQL baru atau
versi baru yang dapat ditinjau.

## DEC-005 — Source of Truth

Supabase PostgreSQL adalah sumber data transaksional utama.

Google Sheets bukan database aplikasi.

## DEC-006 — Authentication

Authentication menggunakan Supabase Auth.

Integrasi Next.js menggunakan cookie-based SSR melalui
@supabase/ssr.

## DEC-007 — Authorization

Authorization dilakukan melalui:

1. Pemeriksaan server-side
2. Role
3. Assignment
4. Supabase Row Level Security

Redirect halaman bukan mekanisme keamanan utama.

## DEC-008 — Database Lama

Database Supabase sebelumnya digunakan sebagai referensi.

Database lama tidak langsung digunakan sebagai database
production E-Ma'had V2.

## DEC-009 — Bahasa

Nama folder, tabel, kolom, function, dan type menggunakan
bahasa Inggris.

Teks antarmuka menggunakan bahasa Indonesia.

## DEC-010 — Penerapan Kode

Kode diberikan lengkap beserta path file.

Developer memindahkan dan meninjau kode secara manual
di VS Code.

## DEC-011 — Pengerjaan Fitur

Fitur dikembangkan secara bertahap.

Urutan fitur:

1. Workflow
2. Database
3. RLS
4. Query
5. Action
6. UI
7. Validasi
8. Pengujian