-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 026-link-staff-accounts-template.sql
-- PURPOSE:
-- - Template menghubungkan akun Auth dengan staff
-- - Jangan jalankan sebelum email sebenarnya tersedia
-- - Jalankan satu per satu setelah akun Auth dibuat
-- =========================================================

-- =========================================================
-- PENANGGUNG JAWAB / KEPALA SEKOLAH
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_KEPALA_SEKOLAH',
--     '22-P-001',
--     array[
--         'penanggung_jawab'
--     ]::text[]
-- );

-- =========================================================
-- KEPALA MA'HAD / KETUA ASRAMA
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_KEPALA_MAHAD',
--     '20-P-002',
--     array[
--         'kepala_mahad'
--     ]::text[]
-- );

-- =========================================================
-- BENDAHARA
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_BENDAHARA',
--     '20-P-003',
--     array[
--         'bendahara'
--     ]::text[]
-- );

-- =========================================================
-- PEMBINA TAHFIZ 8 PUTRI
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_EDY_NOR_SOBAH',
--     '22-P-004',
--     array[
--         'pembina_tahfiz'
--     ]::text[]
-- );

-- =========================================================
-- PEMBINA TAHFIZ 9 PUTRI
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_DAYANEU_PERMATASARI',
--     '22-P-005',
--     array[
--         'pembina_tahfiz'
--     ]::text[]
-- );

-- =========================================================
-- ADMIN / FARNIDA
-- =========================================================

-- Gunakan bagian ini hanya jika admin@emahad.id memang
-- merupakan akun milik Farnida.
--
-- Jika admin@emahad.id adalah akun teknis developer,
-- jangan hubungkan akun tersebut ke staff Farnida.

-- select public.provision_staff_account(
--     'admin@emahad.id',
--     '22-P-006',
--     array[
--         'admin'
--     ]::text[]
-- );

-- =========================================================
-- MUH LUBIS
-- MULTI ROLE: PENGASUH + PEMBINA TAHFIZ
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_MUH_LUBIS',
--     '24-P-007',
--     array[
--         'pengasuh',
--         'pembina_tahfiz'
--     ]::text[]
-- );

-- =========================================================
-- NUR JANNAH
-- MULTI ROLE: PENGASUH + PEMBINA TAHFIZ
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_NUR_JANNAH',
--     '24-P-008',
--     array[
--         'pengasuh',
--         'pembina_tahfiz'
--     ]::text[]
-- );

-- =========================================================
-- PEMBINA TAHFIZ 9 PUTRA
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_YUS_MUNANDAR',
--     '25-P-009',
--     array[
--         'pembina_tahfiz'
--     ]::text[]
-- );

-- =========================================================
-- PENGASUH PUTRI
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_DEVI_PERMATASARI',
--     '25-P-010',
--     array[
--         'pengasuh'
--     ]::text[]
-- );

-- =========================================================
-- PEMBINA TAHFIZ 8 PUTRA
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_FAIZ_SHODIQ',
--     '25-P-011',
--     array[
--         'pembina_tahfiz'
--     ]::text[]
-- );

-- =========================================================
-- PENGASUH PUTRI
-- =========================================================

-- select public.provision_staff_account(
--     'EMAIL_GUSMAWATI',
--     '26-P-012',
--     array[
--         'pengasuh'
--     ]::text[]
-- );