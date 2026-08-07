begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 057-update-guardian-account-display-functions.sql
--
-- PURPOSE:
-- - Menambahkan login_id pada detail akun wali
-- - Menambahkan account_login_id pada daftar wali
-- - Menambahkan pencarian berdasarkan login ID
-- - Mempertahankan login_email sementara untuk kompatibilitas
--
-- CATATAN:
-- Email Auth internal akan disembunyikan dari UI pada
-- tahap frontend berikutnya.
-- =========================================================


-- =========================================================
-- 1. DAFTAR WALI
-- =========================================================

create or replace function
public.get_admin_guardian_list(
    p_search text default null,
    p_is_active boolean default null,
    p_account_status text default null,
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

    v_page integer;
    v_page_size integer;
    v_offset integer;

    v_result jsonb;
begin
    -- =====================================================
    -- A. VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses daftar wali ditolak.';
    end if;

    -- =====================================================
    -- B. NORMALISASI PARAMETER
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

    -- =====================================================
    -- C. SUSUN DATA DASAR
    -- =====================================================

    with base_guardians as (
        select
            guardian.id,
            guardian.profile_id,
            guardian.legacy_guardian_id,
            guardian.full_name,
            guardian.phone,
            guardian.email,
            guardian.is_active,
            guardian.created_at,
            guardian.updated_at,

            (
                guardian.profile_id
                is not null
            ) as account_linked,

            coalesce(
                profile.is_active,
                false
            ) as account_active,

            profile.login_id
                as account_login_id,

            coalesce(
                child_data.children_count,
                0
            )::integer
                as children_count,

            coalesce(
                child_data.active_children_count,
                0
            )::integer
                as active_children_count,

            coalesce(
                child_data.primary_contact_count,
                0
            )::integer
                as primary_contact_count

        from public.guardians
            as guardian

        left join public.profiles
            as profile
            on profile.id =
               guardian.profile_id

        left join lateral (
            select
                count(
                    distinct relation.student_id
                )::integer
                    as children_count,

                count(
                    distinct relation.student_id
                ) filter (
                    where student.status =
                          'active'::public.student_status

                      and student.deleted_at
                          is null
                )::integer
                    as active_children_count,

                count(*) filter (
                    where relation.is_primary_contact =
                          true
                )::integer
                    as primary_contact_count

            from public.guardian_students
                as relation

            inner join public.students
                as student
                on student.id =
                   relation.student_id

            where relation.guardian_id =
                  guardian.id
        ) as child_data
            on true
    ),

    filtered_guardians as (
        select
            guardian.*

        from base_guardians
            as guardian

        where (
            v_search is null

            or guardian.full_name ilike
               '%' || v_search || '%'

            or coalesce(
                guardian.legacy_guardian_id,
                ''
            ) ilike
               '%' || v_search || '%'

            or coalesce(
                guardian.email,
                ''
            ) ilike
               '%' || v_search || '%'

            or coalesce(
                guardian.phone,
                ''
            ) ilike
               '%' || v_search || '%'

            or coalesce(
                guardian.account_login_id,
                ''
            ) ilike
               '%' || v_search || '%'
        )

        and (
            p_is_active is null

            or guardian.is_active =
               p_is_active
        )

        and (
            v_account_status is null

            or (
                v_account_status = 'linked'

                and guardian.account_linked =
                    true
            )

            or (
                v_account_status = 'unlinked'

                and guardian.account_linked =
                    false
            )
        )
    ),

    total_data as (
        select
            count(*)::integer
                as total_items

        from filtered_guardians
    ),

    page_data as (
        select
            guardian.*

        from filtered_guardians
            as guardian

        order by
            lower(
                guardian.full_name
            ),
            guardian.created_at,
            guardian.id

        limit v_page_size
        offset v_offset
    ),

    summary_data as (
        select
            count(*)::integer
                as total_guardians,

            count(*) filter (
                where is_active = true
            )::integer
                as active_guardians,

            count(*) filter (
                where account_linked = true
            )::integer
                as linked_accounts,

            count(*) filter (
                where account_linked = false
            )::integer
                as unlinked_accounts,

            coalesce(
                sum(
                    children_count
                ),
                0
            )::integer
                as total_child_links

        from base_guardians
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
            v_account_status
        ),

        'summary',
        (
            select jsonb_build_object(
                'total_guardians',
                summary.total_guardians,

                'active_guardians',
                summary.active_guardians,

                'linked_accounts',
                summary.linked_accounts,

                'unlinked_accounts',
                summary.unlinked_accounts,

                'total_child_links',
                summary.total_child_links
            )

            from summary_data
                as summary
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

            from total_data
                as total
        ),

        'items',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'id',
                        guardian.id,

                        'profile_id',
                        guardian.profile_id,

                        'legacy_guardian_id',
                        guardian.legacy_guardian_id,

                        'full_name',
                        guardian.full_name,

                        'phone',
                        guardian.phone,

                        'email',
                        guardian.email,

                        'is_active',
                        guardian.is_active,

                        'account_linked',
                        guardian.account_linked,

                        'account_active',
                        guardian.account_active,

                        'account_login_id',
                        guardian.account_login_id,

                        'children_count',
                        guardian.children_count,

                        'active_children_count',
                        guardian.active_children_count,

                        'primary_contact_count',
                        guardian.primary_contact_count,

                        'created_at',
                        guardian.created_at,

                        'updated_at',
                        guardian.updated_at
                    )

                    order by
                        lower(
                            guardian.full_name
                        ),
                        guardian.created_at,
                        guardian.id
                ),
                '[]'::jsonb
            )

            from page_data
                as guardian
        )
    )
    into v_result;

    return v_result;
end;
$function$;


comment on function
public.get_admin_guardian_list(
    text,
    boolean,
    text,
    integer,
    integer
)
is
'Daftar wali untuk Admin termasuk login ID, status akun, pencarian, dan pagination.';


-- =========================================================
-- 2. DETAIL WALI
-- =========================================================

create or replace function
public.get_admin_guardian_detail(
    p_guardian_id uuid
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

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
    end if;

    -- =====================================================
    -- B. VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses detail wali ditolak.';
    end if;

    -- =====================================================
    -- C. SUSUN DETAIL WALI
    -- =====================================================

    with target_guardian as (
        select
            guardian.id,
            guardian.profile_id,
            guardian.legacy_guardian_id,
            guardian.full_name,
            guardian.phone,
            guardian.email,
            guardian.is_active,
            guardian.created_at,
            guardian.updated_at,

            (
                guardian.profile_id
                is not null
            ) as account_linked,

            coalesce(
                profile.is_active,
                false
            ) as account_active,

            profile.login_id
                as account_login_id,

            auth_user.email::text
                as account_email

        from public.guardians
            as guardian

        left join public.profiles
            as profile
            on profile.id =
               guardian.profile_id

        left join auth.users
            as auth_user
            on auth_user.id =
               guardian.profile_id

        where guardian.id =
              p_guardian_id

        limit 1
    ),

    child_data as (
        select
            relation.id
                as relation_id,

            relation.relationship_type,
            relation.is_primary_contact,

            relation.created_at
                as linked_at,

            student.id
                as student_id,

            student.legacy_student_id,
            student.nis,
            student.full_name,
            student.gender,
            student.status,

            class_data.class_id,
            class_data.class_name,
            class_data.grade_level,
            class_data.academic_year_name

        from target_guardian
            as guardian

        inner join public.guardian_students
            as relation
            on relation.guardian_id =
               guardian.id

        inner join public.students
            as student
            on student.id =
               relation.student_id

        left join lateral (
            select
                class.id
                    as class_id,

                class.name
                    as class_name,

                class.grade_level,

                academic_year.name
                    as academic_year_name

            from public.class_enrollments
                as enrollment

            inner join public.classes
                as class
                on class.id =
                   enrollment.class_id

            inner join public.academic_years
                as academic_year
                on academic_year.id =
                   class.academic_year_id

            where enrollment.student_id =
                  student.id

              and enrollment.is_active =
                  true

              and class.is_active =
                  true

            order by
                academic_year.is_current
                    desc,

                enrollment.enrolled_at
                    desc

            limit 1
        ) as class_data
            on true
    ),

    child_summary as (
        select
            count(*)::integer
                as children_count,

            count(*) filter (
                where status =
                      'active'::public.student_status
            )::integer
                as active_children_count,

            count(*) filter (
                where is_primary_contact =
                      true
            )::integer
                as primary_contact_count

        from child_data
    )

    select
        case
            when not exists (
                select 1

                from target_guardian
            ) then null

            else jsonb_build_object(
                'generated_at',
                now(),

                'guardian',
                (
                    select jsonb_build_object(
                        'id',
                        guardian.id,

                        'profile_id',
                        guardian.profile_id,

                        'legacy_guardian_id',
                        guardian.legacy_guardian_id,

                        'full_name',
                        guardian.full_name,

                        'phone',
                        guardian.phone,

                        'email',
                        guardian.email,

                        'is_active',
                        guardian.is_active,

                        'created_at',
                        guardian.created_at,

                        'updated_at',
                        guardian.updated_at
                    )

                    from target_guardian
                        as guardian
                ),

                'account',
                (
                    select jsonb_build_object(
                        'linked',
                        guardian.account_linked,

                        'active',
                        guardian.account_active,

                        'profile_id',
                        guardian.profile_id,

                        'login_id',
                        guardian.account_login_id,

                        -- Dipertahankan sementara agar
                        -- frontend lama tidak langsung rusak.
                        'login_email',
                        guardian.account_email
                    )

                    from target_guardian
                        as guardian
                ),

                'summary',
                (
                    select jsonb_build_object(
                        'children_count',
                        summary.children_count,

                        'active_children_count',
                        summary.active_children_count,

                        'primary_contact_count',
                        summary.primary_contact_count
                    )

                    from child_summary
                        as summary
                ),

                'children',
                (
                    select coalesce(
                        jsonb_agg(
                            jsonb_build_object(
                                'relation_id',
                                child.relation_id,

                                'relationship_type',
                                child.relationship_type,

                                'is_primary_contact',
                                child.is_primary_contact,

                                'linked_at',
                                child.linked_at,

                                'student_id',
                                child.student_id,

                                'legacy_student_id',
                                child.legacy_student_id,

                                'nis',
                                child.nis,

                                'full_name',
                                child.full_name,

                                'gender',
                                child.gender,

                                'status',
                                child.status,

                                'class_id',
                                child.class_id,

                                'class_name',
                                child.class_name,

                                'grade_level',
                                child.grade_level,

                                'academic_year_name',
                                child.academic_year_name
                            )

                            order by
                                child.is_primary_contact
                                    desc,

                                lower(
                                    child.full_name
                                )
                        ),
                        '[]'::jsonb
                    )

                    from child_data
                        as child
                )
            )
        end
    into v_result;

    return v_result;
end;
$function$;


comment on function
public.get_admin_guardian_detail(uuid)
is
'Detail wali untuk Admin termasuk login ID, status akun, dan santri yang terhubung.';


commit;