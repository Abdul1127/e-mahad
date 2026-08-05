-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 007-verify-first-admin.sql
-- PURPOSE:
-- - Memastikan akun Admin pertama sudah benar
-- - File ini hanya membaca data
-- =========================================================

select
    auth_user.id as auth_user_id,
    auth_user.email,
    profile.full_name,
    profile.is_active,
    role.code as role_code,
    role.name as role_name,
    user_role.created_at as role_assigned_at
from auth.users as auth_user
inner join public.profiles as profile
    on profile.id = auth_user.id
left join public.user_roles as user_role
    on user_role.user_id = profile.id
left join public.roles as role
    on role.id = user_role.role_id
where lower(auth_user.email) = lower('admin@emahad.id')
order by role.code; 