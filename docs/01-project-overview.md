# Project Overview E-Ma'had

## 1. Ringkasan

E-Ma'had adalah aplikasi web terpusat untuk menyimpan,
mengolah, memantau, dan menyajikan perkembangan santri.

## 2. Technology Stack

- Next.js App Router
- TypeScript
- Tailwind CSS
- Supabase Cloud PostgreSQL
- Supabase Auth
- Supabase Storage
- Vercel
- npm

## 3. Sumber Data Utama

Supabase PostgreSQL menjadi sumber data utama aplikasi.

Google Sheets hanya digunakan sebagai jembatan:

- Import data
- Export data
- Pertukaran data sementara

Google Sheets tidak digunakan sebagai database transaksional.

## 4. Domain Utama

- Pengguna dan role
- Pengurus
- Santri
- Wali santri
- Kelas
- Kelompok tahfiz
- Assignment pengurus
- Jurnal pengasuhan
- Laporan tahfiz mingguan
- Klinik Tahsin
- Tagihan
- Pembayaran
- Jurnal Kepala Ma'had
- Dashboard wali santri
- Import dan export

## 5. Prinsip Pengembangan

- E-Ma'had adalah project mandiri.
- Database lama hanya digunakan sebagai referensi.
- Database baru dibangun berdasarkan kebutuhan terbaru.
- Setiap SQL disimpan di repository.
- SQL dijalankan manual melalui Supabase SQL Editor.
- Setiap kode ditinjau sebelum dipindahkan ke VS Code.
- Fitur dikerjakan secara bertahap.
- Keamanan tidak hanya mengandalkan tampilan menu.
- Supabase Row Level Security wajib digunakan.