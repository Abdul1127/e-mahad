# Database Execution Log E-Ma'had

Dokumen ini mencatat SQL yang sudah dijalankan melalui
Supabase SQL Editor.

## Project

- Project: E-Ma'had
- Environment: Development
- Platform: Supabase Cloud

## Execution History

| No. | File | Tanggal | Status | Catatan |
|---:|---|---|---|---|
| 1 | 001-foundation.sql | - | Success | Enum dan fungsi dasar |
| 2 | 002-identity-and-access.sql | - | Success | Profile, role, dan trigger Auth |
| 3 | 003-students-and-guardians.sql | - | Success| Pengurus, santri, dan orang tua |
| 4 | 004-baseline-rls.sql | - | Success | RLS dan policy dasar |
| 5 | 005-verify-foundation.sql | - | Success | Query verifikasi |
| 6 | 006-bootstrap-first-admin.sql | 2026-08-03 | Success | Admin pertama berhasil ditetapkan |
| 7 | 007-verify-first-admin.sql | 2026-08-03 | Success | Profile dan role Admin terverifikasi |
| 8 | 008-academic-structure.sql | 2026-08-03 | Success | Tahun ajaran, kelas, dan enrollment berhasil dibuat |
| 9 | 009-care-structure.sql | 2026-08-03 | Success | Struktur pengasuhan berhasil dibuat |
| 10 | 010-tahfiz-structure.sql | 2026-08-03 | Success | Struktur tahfiz berhasil dibuat |
| 11 | 011-structure-access-policies.sql | 2026-08-03 | Success | Helper authorization dan RLS berhasil dibuat |
| 12 | 012-verify-structure.sql | 2026-08-03 | Success | Seluruh struktur terverifikasi |
| 13 | 013-seed-academic-year-2026-2027.sql | 2026-08-03 | Success | Data referensi 2026/2027 berhasil dibuat |
| 14 | 014-verify-initial-reference-data.sql | 2026-08-03 | Success | Terdapat 1 tahun aktif, 3 kelas, 2 kelompok pengasuhan, dan 6 kelompok tahfiz |
## Status Values

Gunakan salah satu status berikut:

- Not Run
- Success
- Failed
- Rolled Back

## Rules

1. Jalankan SQL berdasarkan nomor.
2. Jangan menandai Success sebelum SQL Editor selesai.
3. Catat pesan error jika status Failed.
4. Jangan mengubah file yang sudah berhasil dijalankan.
5. Perbaikan database dibuat melalui file SQL baru.
6. File verifikasi boleh dijalankan berulang kali.