-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 029-provision-muh-lubis-test-account.sql
-- PURPOSE:
-- - Menghubungkan akun Auth pengujian dengan staff Muh Lubis
-- - Memberikan role Pengasuh dan Pembina Tahfiz
-- - Assignment tidak dibuat ulang karena sudah tersedia
-- =========================================================

select public.provision_staff_account(
    'muh.lubis.test@emahad.test',
    '24-P-007',
    array[
        'pengasuh',
        'pembina_tahfiz'
    ]::text[]
) as provisioning_result;