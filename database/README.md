# Database E-Ma'had

Folder ini menyimpan seluruh SQL database E-Ma'had.

## Cara Menjalankan SQL

1. Buka Supabase Dashboard.
2. Pilih project E-Ma'had.
3. Buka menu SQL Editor.
4. Buka file SQL berdasarkan urutan folder dan nomor.
5. Salin seluruh isi SQL.
6. Tempel ke Supabase SQL Editor.
7. Periksa kembali SQL.
8. Klik Run.
9. Catat hasil eksekusi.
10. Jangan menjalankan file yang sama dua kali kecuali
    file tersebut memang idempotent.

## Struktur

- reference: Referensi dari database dan spreadsheet lama.
- sql: Script SQL database baru.
- rollback: Catatan pembatalan perubahan jika diperlukan.

## Aturan

- Jangan mengubah SQL yang sudah dijalankan tanpa catatan.
- Perbaikan dibuat sebagai file SQL baru.
- Gunakan nomor urut.
- Satu file sebaiknya fokus pada satu kelompok perubahan.
- Semua tabel aplikasi harus menggunakan RLS.
- Secret key tidak boleh digunakan di browser.
- SQL production harus ditinjau sebelum dijalankan.