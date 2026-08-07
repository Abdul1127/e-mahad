begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 063-create-admin-staff-list-detail-functions.sql
--
-- PURPOSE:
-- - Menyediakan daftar staf untuk Admin
-- - Menyediakan detail staf untuk Admin
-- - Menampilkan ID Pengguna, status akun, dan role
-- - Mendukung pencarian, filter, dan pagination
-- - Tidak menampilkan email Auth internal
-- =========================================================


-- =========================================================
-- 1. DAFTAR STAF
-- =========================================================

create or replace function
public.get_admin_staff_list(
    p_search text default null,
    p_is_active boolean default null,
    p_account_status text default null,
    p_role_code text default null,
    p_page integer default 1,
    p_page_size integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_search text;
    v_account_status text;
    v_role_code text;

    v_page integer;
    v_page_size integer;
    v_offset integer;

    v_result jsonb;
begin
    -- =====================================================
    -- A. VALIDASI SESSION DAN ADMIN
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses daftar staf ditolak.';
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
    -- B. NORMALISASI FILTER
    -- =====================================================

    v_search :=
        nullif(
            btrim(
                coalesce(
                    p_search,
                    ''
                )
            ),
            ''
        );

    v_account_status :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_account_status,
                        ''
                    )
                )
            ),
            ''
        );

    v_role_code :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_role_code,
                        ''
                    )
                )
            ),
            ''
        );

    v_page :=
        greatest(
            coalesce(
                p_page,
                1
            ),
            1
        );

    v_page_size :=
        least(
            greatest(
                coalesce(
                    p_page_size,
                    20
                ),
                1
            ),
            100
        );

    v_offset :=
        (v_page - 1) * v_page_size;

    if v_account_status is not null
       and v_account_status not in (
           'linked',
           'unlinked'
       ) then
        raise exception
            'Filter status akun tidak valid.';
    end if;

    if v_role_code is not null
       and not exists (
           select 1

           from public.roles as role

           where role.code = v_role_code
             and role.is_active = true
             and role.code not in (
                 'admin',
                 'guardian'
             )
       ) then
        raise exception
            'Filter role staf tidak valid.';
    end if;

    -- =====================================================
    -- C. DATA DASAR
    -- =====================================================

    with base_staff as (
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
                as account_login_id,

            coalesce(
                role_data.roles,
                '[]'::jsonb
            ) as roles,

            coalesce(
                role_data.role_codes,
                array[]::text[]
            ) as role_codes,

            coalesce(
                role_data.role_count,
                0
            )::integer as role_count

        from public.staff as staff

        left join public.profiles as profile
            on profile.id =
               staff.profile_id

        left join lateral (
            select
                jsonb_agg(
                    jsonb_build_object(
                        'code',
                        role.code,

                        'name',
                        role.name
                    )
                    order by
                        role.name,
                        role.code
                ) as roles,

                array_agg(
                    role.code
                    order by role.code
                ) as role_codes,

                count(*)::integer
                    as role_count

            from public.user_roles as user_role

            inner join public.roles as role
                on role.id =
                   user_role.role_id

            where user_role.user_id =
                  staff.profile_id

              and role.is_active = true

              and role.code not in (
                  'admin',
                  'guardian'
              )
        ) as role_data
            on true
    ),

    filtered_staff as (
        select
            staff.*

        from base_staff as staff

        where (
            v_search is null

            or staff.full_name ilike
               '%' || v_search || '%'

            or coalesce(
                staff.legacy_staff_id,
                ''
            ) ilike
               '%' || v_search || '%'

            or coalesce(
                staff.phone,
                ''
            ) ilike
               '%' || v_search || '%'

            or coalesce(
                staff.position,
                ''
            ) ilike
               '%' || v_search || '%'

            or coalesce(
                staff.account_login_id,
                ''
            ) ilike
               '%' || v_search || '%'
        )

        and (
            p_is_active is null

            or staff.is_active =
               p_is_active
        )

        and (
            v_account_status is null

            or (
                v_account_status = 'linked'
                and staff.account_linked = true
            )

            or (
                v_account_status = 'unlinked'
                and staff.account_linked = false
            )
        )

        and (
            v_role_code is null

            or v_role_code =
               any(staff.role_codes)
        )
    ),

    total_data as (
        select
            count(*)::integer
                as total_items

        from filtered_staff
    ),

    page_data as (
        select
            staff.*

        from filtered_staff as staff

        order by
            lower(staff.full_name),
            staff.created_at,
            staff.id

        limit v_page_size
        offset v_offset
    ),

    summary_data as (
        select
            count(*)::integer
                as total_staff,

            count(*) filter (
                where is_active = true
            )::integer
                as active_staff,

            count(*) filter (
                where account_linked = true
            )::integer
                as linked_accounts,

            count(*) filter (
                where account_linked = false
            )::integer
                as unlinked_accounts,

            count(*) filter (
                where account_linked = true
                  and account_active = true
            )::integer
                as active_accounts,

            count(*) filter (
                where account_linked = true
                  and account_active = false
            )::integer
                as inactive_accounts,

            coalesce(
                sum(role_count),
                0
            )::integer
                as total_role_assignments

        from base_staff
    )

    select jsonb_build_object(
        'generated_at',
        now(),

        'filters',
        jsonb_build_object(
            'search',
            v_search,

            'is_active',
            p_is_active,

            'account_status',
            v_account_status,

            'role_code',
            v_role_code
        ),

        'summary',
        (
            select jsonb_build_object(
                'total_staff',
                summary.total_staff,

                'active_staff',
                summary.active_staff,

                'linked_accounts',
                summary.linked_accounts,

                'unlinked_accounts',
                summary.unlinked_accounts,

                'active_accounts',
                summary.active_accounts,

                'inactive_accounts',
                summary.inactive_accounts,

                'total_role_assignments',
                summary.total_role_assignments
            )

            from summary_data as summary
        ),

        'pagination',
        (
            select jsonb_build_object(
                'current_page',
                v_page,

                'page_size',
                v_page_size,

                'total_items',
                total.total_items,

                'total_pages',
                case
                    when total.total_items = 0
                        then 0

                    else ceil(
                        total.total_items::numeric /
                        v_page_size
                    )::integer
                end,

                'from_item',
                case
                    when total.total_items = 0
                        then 0

                    else least(
                        v_offset + 1,
                        total.total_items
                    )
                end,

                'to_item',
                least(
                    v_offset + v_page_size,
                    total.total_items
                )
            )

            from total_data as total
        ),

        'items',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
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

                        'account_linked',
                        staff.account_linked,

                        'account_active',
                        staff.account_active,

                        'account_login_id',
                        staff.account_login_id,

                        'roles',
                        staff.roles,

                        'role_count',
                        staff.role_count,

                        'created_at',
                        staff.created_at,

                        'updated_at',
                        staff.updated_at
                    )

                    order by
                        lower(staff.full_name),
                        staff.created_at,
                        staff.id
                ),
                '[]'::jsonb
            )

            from page_data as staff
        )
    )
    into v_result;

    return v_result;
end;
$function$;


comment on function
public.get_admin_staff_list(
    text,
    boolean,
    text,
    text,
    integer,
    integer
)
is
'Daftar staf untuk Admin termasuk ID Pengguna, status akun, role, filter, pencarian, dan pagination.';


-- =========================================================
-- 2. DETAIL STAF
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
    -- A. VALIDASI INPUT
    -- =====================================================

    if p_staff_id is null then
        raise exception
            'Staff ID wajib diisi.';
    end if;

    -- =====================================================
    -- B. VALIDASI SESSION DAN ADMIN
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
    -- C. SUSUN DETAIL
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
            user_role.assigned_at,
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

                                'assigned_at',
                                role.assigned_at,

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
'Detail staf untuk Admin termasuk ID Pengguna, status akun, dan seluruh role aktif staf.';


-- =========================================================
-- 3. PRIVILEGE
-- =========================================================

revoke all on function
public.get_admin_staff_list(
    text,
    boolean,
    text,
    text,
    integer,
    integer
)
from public;

revoke all on function
public.get_admin_staff_list(
    text,
    boolean,
    text,
    text,
    integer,
    integer
)
from anon;

grant execute on function
public.get_admin_staff_list(
    text,
    boolean,
    text,
    text,
    integer,
    integer
)
to authenticated;


revoke all on function
public.get_admin_staff_detail(uuid)
from public;

revoke all on function
public.get_admin_staff_detail(uuid)
from anon;

grant execute on function
public.get_admin_staff_detail(uuid)
to authenticated;

commit;