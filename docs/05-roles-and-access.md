# Roles and Access E-Ma'had

## 1. Scope Aplikasi

E-Ma'had digunakan untuk pemantauan dan pengelolaan kegiatan
asrama.

Sekolah non-asrama tidak termasuk dalam scope awal aplikasi.

## 2. Prinsip Akses

Akses pengguna ditentukan melalui:

1. Supabase Auth
2. Profile pengguna
3. Role pengguna
4. Assignment atau cakupan tugas
5. Pemeriksaan server-side
6. Supabase Row Level Security

Role menentukan jenis pekerjaan.

Assignment menentukan data yang boleh diakses.

## 3. Daftar Role

| Kode | Nama Tampilan |
|---|---|
| admin | Admin |
| penanggung_jawab | Penanggung Jawab / Kepala Sekolah |
| kepala_mahad | Kepala Ma'had / Ketua Asrama |
| pengasuh | Pengasuh |
| pembina_tahfiz | Pembina Tahfiz |
| bendahara | Bendahara |
| guardian | Orang Tua/Wali |

Santri tidak memiliki akun login pada MVP.

## 4. Banyak Role

Satu pengguna dapat memiliki lebih dari satu role.

Contoh:

- Pengasuh Putra
- Pembina Tahfiz Kelompok 7 Putra

Pengguna tersebut tetap memiliki satu akun Supabase Auth dan
satu profile.

Jika pengguna hanya memiliki satu role, sistem langsung
mengarahkan pengguna ke dashboard role tersebut.

Jika pengguna memiliki lebih dari satu role, sistem
mengarahkan pengguna ke halaman pemilihan role aktif.

## 5. Penanggung Jawab

Penanggung Jawab adalah Kepala Sekolah.

Penanggung Jawab dapat:

- Melihat seluruh kegiatan asrama
- Memantau Kepala Ma'had
- Melihat data santri
- Melihat jurnal pengasuhan
- Melihat perkembangan tahfiz
- Melihat Klinik Tahsin
- Melihat jurnal Kepala Ma'had
- Melihat laporan operasional

Penanggung Jawab tidak dapat:

- Melihat data keuangan
- Mengelola tagihan
- Mengelola pembayaran
- Mengubah transaksi operasional secara normal

Akses Penanggung Jawab bersifat monitoring atau read-only.

## 6. Kepala Ma'had

Kepala Ma'had dan Ketua Asrama merupakan role yang sama.

Kepala Ma'had dapat:

- Melihat seluruh santri asrama
- Melihat seluruh jurnal pengasuhan
- Melakukan review jurnal pengasuhan
- Mengembalikan jurnal untuk revisi
- Melihat seluruh laporan tahfiz
- Melihat seluruh Klinik Tahsin
- Melihat ringkasan dan data keuangan
- Membuat jurnal Kepala Ma'had
- Melihat laporan operasional

Kepala Ma'had dapat melihat data keuangan, tetapi tidak
mengelola atau memverifikasi pembayaran.

## 7. Pengasuh

Role Pengasuh tetap satu.

Cakupan Pengasuh dibedakan melalui assignment:

- Pengasuh Putra
- Pengasuh Putri

Pengasuh dapat:

- Melihat santri sesuai assignment
- Membuat jurnal pengasuhan
- Menyimpan jurnal sebagai draft
- Submit jurnal
- Memperbaiki jurnal yang dikembalikan
- Melihat riwayat jurnal sendiri

Pengasuh tidak dapat:

- Melihat santri di luar assignment
- Melihat laporan tahfiz
- Melihat Klinik Tahsin
- Melihat data keuangan
- Melihat data santri lain

## 8. Pembina Tahfiz

Pembina Tahfiz ditugaskan berdasarkan kelompok tahfiz.

Pembina dapat:

- Melihat kelompok tahfiz ampuan
- Melihat anggota kelompok ampuan
- Membuat laporan tahfiz per santri per pekan
- Menyimpan laporan sebagai draft
- Mempublikasikan laporan kepada orang tua
- Membuat rujukan Klinik Tahsin
- Mengelola sesi Klinik Tahsin sesuai assignment

Pembina tidak dapat mengakses kelompok yang tidak ditugaskan.

## 9. Bendahara

Bendahara dapat:

- Mengelola jenis tagihan
- Membuat tagihan bulanan
- Membuat tagihan massal
- Mencatat pembayaran
- Memilih bulan yang dibayar
- Memverifikasi pembayaran
- Melihat laporan keuangan

Bendahara hanya melihat data identitas santri yang diperlukan
untuk pengelolaan keuangan.

## 10. Orang Tua/Wali

Satu akun orang tua dapat terhubung ke satu atau beberapa
santri.

Contoh:

Akun orang tua:
- Anak pertama
- Anak kedua

Orang tua hanya dapat melihat santri yang terhubung dengan
akunnya.

Orang tua dapat melihat:

- Identitas dasar anak
- Laporan tahfiz yang sudah dipublikasikan
- Tagihan anak
- Status pembayaran anak
- Riwayat pembayaran anak

Orang tua tidak dapat melihat:

- Jurnal pengasuhan
- Kondisi psikologis
- Kasus atau kejadian santri
- Catatan internal
- Klinik Tahsin
- Data santri lain
- Data pengurus
- Draft laporan tahfiz

## 11. Klinik Tahsin

Klinik Tahsin merupakan fitur internal pesantren.

Akses Klinik Tahsin:

| Role | Hak Akses |
|---|---|
| Admin | Kelola seluruh data |
| Penanggung Jawab | Lihat untuk monitoring |
| Kepala Ma'had | Lihat seluruh proses |
| Pembina Tahfiz | Kelola sesuai assignment |
| Pengasuh | Tidak ada |
| Bendahara | Tidak ada |
| Orang Tua | Tidak ada |

Data Klinik Tahsin tidak pernah ditampilkan pada dashboard
orang tua.

## 12. Matriks Akses

| Modul | Admin | Penanggung Jawab | Kepala Ma'had | Pengasuh | Pembina Tahfiz | Bendahara | Orang Tua |
|---|---|---|---|---|---|---|---|
| Data santri | Kelola | Lihat semua | Lihat semua | Lihat cakupan | Lihat kelompok | Lihat dasar | Lihat anak |
| Data pengurus | Kelola | Lihat | Lihat | Lihat sendiri | Lihat sendiri | Lihat sendiri | Tidak |
| Jurnal pengasuhan | Kelola | Lihat | Review | Isi | Tidak | Tidak | Tidak |
| Laporan tahfiz | Kelola | Lihat | Lihat | Tidak | Kelola | Tidak | Lihat anak |
| Klinik Tahsin | Kelola | Lihat | Lihat | Tidak | Kelola | Tidak | Tidak |
| Tagihan | Kelola | Tidak | Lihat | Tidak | Tidak | Kelola | Lihat anak |
| Pembayaran | Kelola | Tidak | Lihat | Tidak | Tidak | Kelola | Lihat anak |
| Jurnal Kepala Ma'had | Kelola | Lihat | Kelola | Tidak | Tidak | Tidak | Tidak |

## 13. Prinsip Keamanan

- Authentication bukan authorization.
- Role yang dikirim browser tidak langsung dipercaya.
- User ID diperoleh dari Supabase Auth.
- Cakupan Pengasuh diverifikasi melalui assignment.
- Cakupan Pembina diverifikasi melalui kelompok tahfiz.
- Orang tua hanya dapat mengakses santri yang terhubung.
- Klinik Tahsin tidak dapat diakses orang tua.
- Penanggung Jawab tidak dapat mengakses data keuangan.
- Seluruh tabel aplikasi wajib menggunakan RLS.