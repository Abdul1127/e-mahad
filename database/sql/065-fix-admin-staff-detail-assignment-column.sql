begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 065-fix-admin-staff-detail-assignment-column.sql
--
-- PURPOSE:
-- - Memperbaiki get_admin_staff_detail()
-- - Menghapus referensi user_roles.assigned_at
-- - Tetap menampilkan role dan assigned_by
--
-- REASON:
-- Tabel public.user_roles tidak mempunyai kolom assigned_at.
-- =========================================================

create or replace function
public.get_admin_staff_detail(
    p_staff_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_result jsonb;
begin
    -- =====================================================
    -- 1. VALIDASI INPUT
    -- =====================================================

    if p_staff_id is null then
        raise exception
            'Staff ID wajib diisi.';
    end if;

    -- =====================================================
    -- 2. VALIDASI SESSION DAN ADMIN
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses detail staf ditolak.';
    end if;

    if not exists (
        select 1

        from public.profiles as profile

        where profile.id = auth.uid()
          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;

    -- =====================================================
    -- 3. SUSUN DETAIL STAF
    -- =====================================================

    with target_staff as (
        select
            staff.id,
            staff.profile_id,
            staff.legacy_staff_id,
            staff.full_name,
            staff.phone,
            staff.position,
            staff.is_active,
            staff.created_at,
            staff.updated_at,

            (
                staff.profile_id is not null
            ) as account_linked,

            coalesce(
                profile.is_active,
                false
            ) as account_active,

            profile.login_id
                as account_login_id

        from public.staff as staff

        left join public.profiles as profile
            on profile.id =
               staff.profile_id

        where staff.id =
              p_staff_id

        limit 1
    ),

    role_data as (
        select
            role.code,
            role.name,
            user_role.assigned_by

        from target_staff as staff

        inner join public.user_roles as user_role
            on user_role.user_id =
               staff.profile_id

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where role.is_active = true

          and role.code not in (
              'admin',
              'guardian'
          )
    )

    select
        case
            when not exists (
                select 1

                from target_staff
            ) then null

            else jsonb_build_object(
                'generated_at',
                now(),

                'staff',
                (
                    select jsonb_build_object(
                        'id',
                        staff.id,

                        'profile_id',
                        staff.profile_id,

                        'legacy_staff_id',
                        staff.legacy_staff_id,

                        'full_name',
                        staff.full_name,

                        'phone',
                        staff.phone,

                        'position',
                        staff.position,

                        'is_active',
                        staff.is_active,

                        'created_at',
                        staff.created_at,

                        'updated_at',
                        staff.updated_at
                    )

                    from target_staff as staff
                ),

                'account',
                (
                    select jsonb_build_object(
                        'linked',
                        staff.account_linked,

                        'active',
                        staff.account_active,

                        'profile_id',
                        staff.profile_id,

                        'login_id',
                        staff.account_login_id
                    )

                    from target_staff as staff
                ),

                'summary',
                jsonb_build_object(
                    'role_count',
                    (
                        select count(*)::integer

                        from role_data
                    )
                ),

                'roles',
                (
                    select coalesce(
                        jsonb_agg(
                            jsonb_build_object(
                                'code',
                                role.code,

                                'name',
                                role.name,

                                'assigned_by',
                                role.assigned_by
                            )

                            order by
                                role.name,
                                role.code
                        ),
                        '[]'::jsonb
                    )

                    from role_data as role
                )
            )
        end

    into v_result;

    return v_result;
end;
$function$;


comment on function
public.get_admin_staff_detail(uuid)
is
'Detail staf untuk Admin termasuk ID Pengguna, status akun, role aktif, dan pemberi role.';

commit;