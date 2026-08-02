# Workflows E-Ma'had

## 1. Login

1. Pengguna memasukkan email dan password.
2. Supabase Auth memvalidasi kredensial.
3. Sistem membaca profile pengguna.
4. Sistem memastikan profile aktif.
5. Sistem membaca role pengguna.
6. Jika tidak memiliki role, akses ditolak.
7. Jika memiliki satu role, pengguna diarahkan ke dashboard.
8. Jika memiliki beberapa role, pengguna memilih role aktif.
9. Setiap route dilindungi melalui pemeriksaan server-side.
10. Setiap query dibatasi melalui Supabase RLS.

## 2. Assignment Pengasuh

1. Admin membuat data pengasuh.
2. Admin memberikan role Pengasuh.
3. Admin memilih cakupan Putra atau Putri.
4. Sistem menghubungkan Pengasuh dengan kelompok pengasuhan.
5. Pengasuh hanya dapat melihat santri dalam cakupan tersebut.

## 3. Assignment Pembina Tahfiz

1. Admin membuat data Pembina Tahfiz.
2. Admin memberikan role Pembina Tahfiz.
3. Admin memilih kelompok tahfiz.
4. Sistem menghubungkan Pembina dengan kelompok.
5. Pembina hanya dapat melihat anggota kelompok tersebut.

## 4. Jurnal Pengasuhan

### Pembuatan

1. Pengasuh memilih tanggal.
2. Pengasuh memilih sesi.
3. Sistem membaca assignment Pengasuh.
4. Sistem menampilkan santri sesuai cakupan.
5. Pengasuh mengisi kondisi setiap santri.
6. Jurnal disimpan sebagai draft.

### Submit

1. Pengasuh memeriksa jurnal.
2. Sistem memvalidasi data wajib.
3. Pengasuh melakukan submit.
4. Status jurnal berubah menjadi submitted.
5. Jurnal tidak dapat diubah oleh Pengasuh.

### Review

1. Kepala Ma'had membuka jurnal submitted.
2. Kepala Ma'had melakukan review.
3. Jika sesuai, status menjadi reviewed.
4. Jika perlu perbaikan, status menjadi revision_requested.
5. Kepala Ma'had menulis catatan revisi.

### Revisi

1. Pengasuh membuka jurnal revision_requested.
2. Pengasuh memperbaiki jurnal.
3. Pengasuh submit ulang.
4. Status kembali menjadi submitted.
5. Kepala Ma'had melakukan review ulang.

### Status

- draft
- submitted
- revision_requested
- reviewed

Tidak terdapat status locked permanen.

Data jurnal pengasuhan tidak ditampilkan kepada orang tua.

## 5. Laporan Tahfiz Mingguan

### Pemilihan Kelompok

1. Pembina memilih kelompok tahfiz.
2. Pembina memilih pekan laporan.
3. Sistem memverifikasi assignment Pembina.
4. Sistem menampilkan seluruh anggota kelompok.

### Pengisian

1. Daftar santri ditampilkan pada sisi kiri.
2. Pembina memilih salah satu santri.
3. Form perkembangan tampil pada sisi kanan.
4. Pembina mengisi:
   - Total kehadiran
   - Capaian ziyadah
   - Capaian muraja'ah
   - Kelancaran
   - Status target pekanan
   - Catatan
5. Pembina menyimpan laporan sebagai draft.
6. Pembina berpindah ke santri berikutnya.

### Publikasi

1. Pembina memeriksa laporan santri.
2. Pembina mempublikasikan laporan.
3. Status laporan berubah menjadi published.
4. Orang tua dapat melihat laporan anaknya.
5. Orang tua tidak dapat melihat laporan santri lain.

### Ketentuan

- Satu santri memiliki satu laporan per pekan.
- Input dilakukan melalui kelompok tahfiz.
- Hasil laporan tetap bersifat individual.
- Ziyadah menggunakan teks.
- Muraja'ah menggunakan teks.
- Kelancaran menggunakan pilihan.
- Target pekanan menggunakan pilihan.

## 6. Klinik Tahsin

### Rujukan

1. Pembina menemukan santri yang memerlukan pendampingan.
2. Pembina membuat kasus Klinik Tahsin.
3. Kasus dapat dikaitkan dengan laporan tahfiz.
4. Status awal kasus adalah open.

### Pendampingan

1. Pembina membuat sesi bimbingan.
2. Pembina mengisi tanggal sesi.
3. Pembina memilih satu atau beberapa diagnosis.
4. Pembina mengisi materi intervensi.
5. Pembina mengisi capaian sesi.
6. Pembina menulis catatan.
7. Status kasus dapat berubah menjadi in_progress.

### Penyelesaian

Kasus dapat berakhir sebagai:

- graduated
- continued
- escalated
- closed

### Akses

Klinik Tahsin hanya digunakan secara internal.

Data Klinik Tahsin tidak ditampilkan kepada orang tua.

## 7. Tagihan Bulanan

1. Bendahara memilih jenis tagihan.
2. Bendahara memilih bulan dan tahun.
3. Bendahara menentukan nominal.
4. Bendahara menghasilkan tagihan santri.
5. Setiap bulan menjadi satu tagihan terpisah.
6. Status awal tagihan adalah unpaid.

Contoh:

- Januari: unpaid
- Februari: unpaid
- Maret: unpaid

## 8. Pembayaran Beberapa Bulan

1. Bendahara memilih santri.
2. Sistem menampilkan tagihan yang belum dibayar.
3. Bendahara memilih bulan yang dibayar.
4. Sistem dapat memilih tagihan tertua secara otomatis.
5. Satu pembayaran dapat melunasi beberapa tagihan.
6. Setiap tagihan yang dibayar penuh berubah menjadi paid.

Contoh:

Pembayaran Rp1.000.000:

- Januari Rp500.000 menjadi paid
- Februari Rp500.000 menjadi paid
- Maret tetap unpaid

Status tagihan:

- unpaid
- paid
- cancelled

Pembayaran sebagian pada satu tagihan belum digunakan.

## 9. Jurnal Kepala Ma'had

1. Kepala Ma'had memilih tanggal.
2. Sistem menampilkan katalog aktivitas.
3. Kepala Ma'had memilih aktivitas yang dilakukan.
4. Kepala Ma'had mengisi catatan kinerja.
5. Kepala Ma'had mengisi kendala.
6. Kepala Ma'had mengisi tindak lanjut.
7. Kepala Ma'had mengunggah bukti kegiatan.
8. Jurnal disimpan sebagai draft atau submitted.
9. Penanggung Jawab dapat melihat jurnal.

## 10. Akun Orang Tua

1. Admin membuat atau mengundang akun orang tua.
2. Akun terhubung dengan data wali.
3. Data wali terhubung dengan satu atau beberapa santri.
4. Orang tua login menggunakan satu akun.
5. Sistem menampilkan seluruh anak yang terhubung.
6. Orang tua memilih anak yang ingin dipantau.
7. Orang tua hanya melihat:
   - Laporan tahfiz published
   - Tagihan
   - Pembayaran
8. Orang tua tidak melihat jurnal pengasuhan dan Klinik Tahsin.