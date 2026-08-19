-- ============================================================
-- E-MA'HAD
-- STAGE 191E-1
--
-- ADD STAFF MASTER: ANIDA
--
-- Target:
-- Name            : Anida
-- Legacy Staff ID : 20-P-001
-- Position        : Admin
--
-- Catatan:
-- Script ini hanya menambahkan master staf.
-- Akun Auth dibuat melalui aplikasi setelah script ini.
-- ============================================================


begin;


-- ============================================================
-- 01. SAFETY CHECK
-- ============================================================

do $$
begin

    if exists (
        select 1
        from public.staff
        where upper(
            btrim(
                coalesce(
                    legacy_staff_id,
                    ''
                )
            )
        ) = '20-P-001'
    ) then
        raise exception
            'SAFETY CHECK FAILED: Staff ID 20-P-001 sudah digunakan.';
    end if;


    if exists (
        select 1
        from public.staff
        where lower(
            btrim(full_name)
        ) = lower('Anida')
    ) then
        raise exception
            'SAFETY CHECK FAILED: Staf dengan nama Anida sudah tersedia.';
    end if;


    if exists (
        select 1
        from public.profiles
        where upper(
            btrim(
                coalesce(
                    login_id,
                    ''
                )
            )
        ) = 'ADM-20-P-001'
    ) then
        raise exception
            'SAFETY CHECK FAILED: Login ID ADM-20-P-001 sudah digunakan.';
    end if;


    if not exists (
        select 1
        from public.roles
        where code = 'admin'
          and is_active = true
    ) then
        raise exception
            'SAFETY CHECK FAILED: Role admin tidak tersedia atau tidak aktif.';
    end if;

end
$$;


-- ============================================================
-- 02. INSERT STAFF
-- ============================================================

insert into public.staff (
    legacy_staff_id,
    full_name,
    phone,
    position,
    is_active
)
values (
    '20-P-001',
    'Anida',
    null,
    'Admin',
    true
);


commit;


-- ============================================================
-- 03. RESULT
-- ============================================================

select
    id as staff_id,
    legacy_staff_id,
    full_name,
    phone,
    position,
    is_active,
    profile_id,
    created_at

from public.staff

where legacy_staff_id =
      '20-P-001';