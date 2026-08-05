begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 006-bootstrap-first-admin.sql
-- PURPOSE:
-- - Menetapkan akun Auth pertama sebagai Admin
-- - Memperbarui nama profile
-- =========================================================

do $$
declare
    target_email constant text := 'admin@emahad.id';

    target_user_id uuid;
    admin_role_id smallint;
begin
    -- =====================================================
    -- CARI USER BERDASARKAN EMAIL
    -- =====================================================

    select auth_user.id
    into target_user_id
    from auth.users as auth_user
    where lower(auth_user.email) = lower(target_email)
    limit 1;

    if target_user_id is null then
        raise exception
            'Akun Auth dengan email % tidak ditemukan.',
            target_email;
    end if;

    -- =====================================================
    -- CARI ROLE ADMIN
    -- =====================================================

    select role.id
    into admin_role_id
    from public.roles as role
    where role.code = 'admin'
      and role.is_active = true
    limit 1;

    if admin_role_id is null then
        raise exception
            'Role admin tidak ditemukan atau sedang tidak aktif.';
    end if;

    -- =====================================================
    -- PERBARUI NAMA PROFILE
    -- =====================================================

    update public.profiles
    set
        full_name = 'Administrator E-Ma''had',
        is_active = true
    where id = target_user_id;

    if not found then
        raise exception
            'Profile untuk akun % tidak ditemukan.',
            target_email;
    end if;

    -- =====================================================
    -- TAMBAHKAN ROLE ADMIN
    -- =====================================================

    insert into public.user_roles (
        user_id,
        role_id,
        assigned_by
    )
    values (
        target_user_id,
        admin_role_id,
        target_user_id
    )
    on conflict (user_id, role_id)
    do update set
        assigned_by = excluded.assigned_by;
end;
$$;

commit;