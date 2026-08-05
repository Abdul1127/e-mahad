begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 027-create-auth-access-context.sql
-- PURPOSE:
-- - Mengambil konteks akses pengguna yang sedang login
-- - Profile
-- - Staff
-- - Guardian
-- - Seluruh role aktif
-- =========================================================

create or replace function public.get_my_access_context()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
    select jsonb_build_object(
        'user_id',
        profile.id,

        'email',
        auth_user.email,

        'full_name',
        profile.full_name,

        'is_active',
        profile.is_active,

        'staff_id',
        (
            select staff.id
            from public.staff as staff
            where staff.profile_id = profile.id
              and staff.is_active = true
            limit 1
        ),

        'guardian_id',
        (
            select guardian.id
            from public.guardians as guardian
            where guardian.profile_id = profile.id
              and guardian.is_active = true
            limit 1
        ),

        'roles',
        coalesce(
            (
                select jsonb_agg(
                    jsonb_build_object(
                        'code',
                        role.code,

                        'name',
                        role.name
                    )
                    order by role.code
                )

                from public.user_roles as user_role

                inner join public.roles as role
                    on role.id = user_role.role_id

                where user_role.user_id = profile.id
                  and role.is_active = true
            ),
            '[]'::jsonb
        )
    )

    from public.profiles as profile

    inner join auth.users as auth_user
        on auth_user.id = profile.id

    where profile.id = auth.uid();
$$;

comment on function public.get_my_access_context() is
'Mengambil profile, staff, guardian, dan role pengguna yang sedang login.';

revoke all on function public.get_my_access_context()
from public;

revoke all on function public.get_my_access_context()
from anon;

grant execute on function public.get_my_access_context()
to authenticated;

commit;