# Database Design E-Ma'had

## 1. Prinsip Database

- Supabase PostgreSQL menjadi sumber data utama.
- Supabase Auth mengelola akun login.
- Primary key aplikasi menggunakan UUID.
- ID dari spreadsheet disimpan sebagai legacy identifier.
- Santri tidak wajib memiliki akun login.
- Pengurus dapat dibuat sebelum mempunyai akun.
- Satu pengguna dapat memiliki banyak role.
- Assignment menentukan cakupan data.
- Seluruh tabel aplikasi menggunakan RLS.
- SQL dijalankan melalui Supabase SQL Editor.
- Setiap SQL disimpan di repository.

## 2. Identity dan Access

### profiles

Menyimpan profile pengguna yang mempunyai akun Supabase Auth.

Kolom utama:

- id
- full_name
- phone
- avatar_url
- is_active
- created_at
- updated_at

Relasi:

- profiles.id mengacu ke auth.users.id

### roles

Menyimpan role aplikasi.

Data awal:

- admin
- penanggung_jawab
- kepala_mahad
- pengasuh
- pembina_tahfiz
- bendahara
- guardian

### user_roles

Menghubungkan pengguna dengan satu atau beberapa role.

Kolom utama:

- id
- user_id
- role_id
- created_at

Constraint:

- Satu user tidak boleh mempunyai role yang sama dua kali.

### staff

Menyimpan data pengurus atau pegawai.

Kolom utama:

- id
- profile_id
- legacy_staff_id
- full_name
- phone
- position
- is_active
- created_at
- updated_at

profile_id boleh kosong jika pengurus belum memiliki akun.

### guardians

Menyimpan orang tua atau wali pemegang akun.

Kolom utama:

- id
- profile_id
- full_name
- phone
- relationship_label
- is_active
- created_at
- updated_at

Satu guardian dapat terhubung dengan beberapa santri.

## 3. Data Santri

### students

Menyimpan data utama santri.

Kolom utama:

- id
- legacy_student_id
- nis
- full_name
- gender
- birth_date
- address
- photo_url
- status
- created_at
- updated_at
- deleted_at

Santri tidak memiliki profile login pada MVP.

### guardian_students

Menghubungkan guardian dengan santri.

Kolom utama:

- id
- guardian_id
- student_id
- is_primary
- created_at

Constraint:

- Kombinasi guardian_id dan student_id harus unik.

Model ini memungkinkan:

- Satu guardian mempunyai beberapa anak.
- Satu santri mempunyai lebih dari satu guardian di masa depan.

## 4. Tahun Ajaran dan Kelas

### academic_years

Menyimpan tahun ajaran.

Kolom utama:

- id
- name
- start_date
- end_date
- is_current
- created_at
- updated_at

### classes

Menyimpan kelas santri.

Kolom utama:

- id
- academic_year_id
- name
- grade_level
- gender
- created_at
- updated_at

### class_enrollments

Menyimpan riwayat kelas santri.

Kolom utama:

- id
- student_id
- class_id
- enrolled_at
- left_at
- is_active
- created_at

Constraint:

- Satu santri tidak boleh mempunyai dua enrollment aktif
  pada tahun ajaran yang sama.

## 5. Kelompok Pengasuhan

### care_groups

Menyimpan cakupan pengasuhan.

Data awal:

- Pengasuhan Putra
- Pengasuhan Putri

Kolom utama:

- id
- name
- gender
- academic_year_id
- is_active
- created_at
- updated_at

Tabel dibuat generik agar di masa depan dapat dikembangkan
menjadi kamar atau kelompok pengasuhan lain.

### care_group_members

Menghubungkan santri dengan kelompok pengasuhan.

Kolom utama:

- id
- care_group_id
- student_id
- joined_at
- left_at
- is_active
- created_at

### caregiver_assignments

Menghubungkan Pengasuh dengan kelompok pengasuhan.

Kolom utama:

- id
- staff_id
- care_group_id
- assigned_at
- ended_at
- is_active
- created_at

## 6. Kelompok Tahfiz

### tahfiz_groups

Menyimpan kelompok tahfiz.

Contoh:

- 7 Putra
- 7 Putri
- 8 Putra
- 8 Putri
- 9 Putra
- 9 Putri

Kolom utama:

- id
- academic_year_id
- name
- gender
- grade_level
- is_active
- created_at
- updated_at

### tahfiz_group_members

Menghubungkan santri dengan kelompok tahfiz.

Kolom utama:

- id
- tahfiz_group_id
- student_id
- joined_at
- left_at
- is_active
- created_at

### tahfiz_supervisor_assignments

Menghubungkan Pembina Tahfiz dengan kelompok.

Kolom utama:

- id
- staff_id
- tahfiz_group_id
- is_primary
- assigned_at
- ended_at
- is_active
- created_at

## 7. Jurnal Pengasuhan

### care_journals

Menjadi header jurnal pengasuhan.

Kolom utama:

- id
- caregiver_assignment_id
- journal_date
- session
- status
- submitted_at
- reviewed_by
- reviewed_at
- review_note
- created_at
- updated_at

Status:

- draft
- submitted
- revision_requested
- reviewed

Constraint:

- Satu assignment hanya memiliki satu jurnal untuk tanggal
  dan sesi yang sama.

### care_journal_entries

Menyimpan observasi setiap santri.

Kolom utama:

- id
- care_journal_id
- student_id
- health_condition
- sleep_compliance
- psychological_condition
- parent_visit
- incident_notes
- handling_notes
- created_at
- updated_at

Constraint:

- Satu santri hanya memiliki satu entry dalam satu jurnal.

Data ini bersifat internal dan tidak dapat diakses guardian.

## 8. Laporan Tahfiz

### tahfiz_report_batches

Menyimpan proses input berdasarkan kelompok dan pekan.

Kolom utama:

- id
- tahfiz_group_id
- supervisor_assignment_id
- week_start
- week_end
- status
- created_at
- updated_at

Constraint:

- Satu kelompok hanya mempunyai satu batch pada periode
  pekan yang sama.

### tahfiz_weekly_reports

Menyimpan laporan individual santri.

Kolom utama:

- id
- batch_id
- student_id
- attendance_total
- ziyadah_achievement
- murajaah_achievement
- fluency_level
- target_status
- notes
- status
- published_at
- created_at
- updated_at

Status:

- draft
- published

Constraint:

- Satu santri hanya memiliki satu laporan dalam satu batch.

Orang tua hanya dapat membaca laporan berstatus published.

## 9. Klinik Tahsin

### tahsin_cases

Menyimpan kasus Klinik Tahsin.

Kolom utama:

- id
- student_id
- source_report_id
- referred_by
- referral_reason
- status
- opened_at
- closed_at
- created_at
- updated_at

Status:

- open
- in_progress
- graduated
- continued
- escalated
- closed

### tahsin_sessions

Menyimpan sesi pendampingan.

Kolom utama:

- id
- tahsin_case_id
- session_number
- session_date
- mentor_staff_id
- intervention_material
- achievement_level
- notes
- decision
- created_at
- updated_at

### tahsin_diagnoses

Menyimpan master diagnosis.

Contoh:

- Makhraj Huruf
- Sifat Huruf
- Mad dan Qashr
- Ghunnah dan Hukum Nun/Mim Mati
- Tempo Bacaan
- Fokus dan Kedisiplinan

### tahsin_session_diagnoses

Menghubungkan satu sesi dengan satu atau beberapa diagnosis.

Kolom utama:

- id
- tahsin_session_id
- diagnosis_id
- created_at

Klinik Tahsin bersifat internal.

Tidak ada policy guardian untuk tabel Klinik Tahsin.

## 10. Tagihan dan Pembayaran

### fee_types

Menyimpan jenis tagihan.

Contoh:

- SPP
- Kegiatan
- Seragam
- Tagihan lain

Kolom utama:

- id
- name
- description
- default_amount
- is_active
- created_at
- updated_at

### student_bills

Menyimpan tagihan santri per periode.

Kolom utama:

- id
- student_id
- fee_type_id
- billing_month
- billing_year
- amount
- due_date
- status
- created_by
- created_at
- updated_at

Status:

- unpaid
- paid
- cancelled

Constraint:

- Satu santri tidak boleh memiliki tagihan jenis dan periode
  yang sama lebih dari satu kali.

### payments

Menyimpan transaksi pembayaran.

Kolom utama:

- id
- guardian_id
- payment_date
- total_amount
- payment_method
- receipt_number
- proof_file_id
- status
- verified_by
- verified_at
- notes
- created_at
- updated_at

Status:

- pending
- verified
- rejected
- cancelled

### payment_bill_items

Menghubungkan satu pembayaran dengan satu atau beberapa
tagihan bulanan.

Kolom utama:

- id
- payment_id
- bill_id
- allocated_amount
- created_at

Untuk MVP, allocated_amount harus sama dengan nominal tagihan.

Satu pembayaran dapat melunasi beberapa bulan.

## 11. Jurnal Kepala Ma'had

### head_activity_catalog

Menyimpan daftar aktivitas Kepala Ma'had.

Kolom utama:

- id
- category
- name
- description
- display_order
- is_active
- created_at
- updated_at

### head_journals

Menyimpan jurnal Kepala Ma'had.

Kolom utama:

- id
- staff_id
- journal_date
- performance_notes
- obstacles
- follow_up
- status
- submitted_at
- created_at
- updated_at

### head_journal_activities

Menghubungkan jurnal dengan aktivitas yang dipilih.

Kolom utama:

- id
- head_journal_id
- activity_id
- notes
- created_at

## 12. File dan Audit

### files

Menyimpan metadata file Supabase Storage.

Kolom utama:

- id
- bucket
- path
- original_name
- mime_type
- size_bytes
- uploaded_by
- created_at

### file_attachments

Menghubungkan file dengan entitas aplikasi.

Kolom utama:

- id
- file_id
- entity_type
- entity_id
- created_at

### audit_logs

Menyimpan perubahan penting.

Kolom utama:

- id
- table_name
- row_id
- action
- old_value
- new_value
- changed_by
- changed_at

## 13. Constraint Utama

Constraint yang wajib tersedia:

- user_roles unik berdasarkan user dan role
- guardian_students unik berdasarkan guardian dan student
- care_journal unik berdasarkan assignment, tanggal, dan sesi
- care_journal_entry unik berdasarkan jurnal dan student
- tahfiz batch unik berdasarkan kelompok dan pekan
- tahfiz report unik berdasarkan batch dan student
- student bill unik berdasarkan santri, jenis, bulan, dan tahun
- payment bill item unik berdasarkan pembayaran dan tagihan
- waktu mulai tidak boleh lebih besar dari waktu selesai
- nominal tidak boleh negatif
- total kehadiran tidak boleh negatif

## 14. Index Utama

Foreign key dan kolom filter berikut harus memiliki index:

- user_roles.user_id
- staff.profile_id
- guardians.profile_id
- guardian_students.guardian_id
- guardian_students.student_id
- class_enrollments.student_id
- care_group_members.student_id
- caregiver_assignments.staff_id
- tahfiz_group_members.student_id
- tahfiz_supervisor_assignments.staff_id
- care_journals.journal_date
- care_journal_entries.student_id
- tahfiz_report_batches.week_start
- tahfiz_weekly_reports.student_id
- tahsin_cases.student_id
- student_bills.student_id
- payments.guardian_id
- audit_logs.changed_by