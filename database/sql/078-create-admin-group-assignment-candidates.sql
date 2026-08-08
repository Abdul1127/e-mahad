begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 078-create-admin-group-assignment-candidates.sql
--
-- PURPOSE:
-- - Kandidat Pengasuh untuk kelompok pengasuhan
-- - Kandidat Pembina Tahfiz untuk kelompok tahfiz
-- - Hanya staf aktif
-- - Harus memiliki akun aktif
-- - Harus memiliki role aplikasi yang sesuai
-- - Menampilkan assignment staf saat ini
-- - Hanya Admin aktif
-- =========================================================


create or replace function
public.get_admin_group_assignment_candidates(
    p_group_type text,
    p_group_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_group_type text;
    v_result jsonb;
begin

    -- =====================================================
    -- 1. SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- 2. ROLE ADMIN
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses kandidat assignment ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id = auth.uid()
          and profile.is_active = true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Admin tidak aktif.';
    end if;


    -- =====================================================
    -- 3. PARAMETER
    -- =====================================================

    if p_group_id is null then
        raise exception
            'Group ID wajib diisi.';
    end if;


    v_group_type :=
        lower(
            btrim(
                coalesce(
                    p_group_type,
                    ''
                )
            )
        );


    if v_group_type not in (
        'care',
        'tahfiz'
    ) then
        raise exception
            'Tipe kelompok tidak valid.';
    end if;


    -- =====================================================
    -- 4. CARE GROUP
    -- =====================================================

    if v_group_type = 'care' then

        if not exists (
            select 1

            from public.care_groups
                as care_group

            inner join public.academic_years
                as academic_year
                on academic_year.id =
                   care_group.academic_year_id

            where care_group.id =
                  p_group_id

              and care_group.is_active = true

              and academic_year.is_current = true
        ) then
            return null;
        end if;


        with target_group as (
            select
                care_group.id,
                care_group.code,
                care_group.name,
                care_group.gender::text
                    as gender,

                academic_year.id
                    as academic_year_id,

                academic_year.name
                    as academic_year_name

            from public.care_groups
                as care_group

            inner join public.academic_years
                as academic_year
                on academic_year.id =
                   care_group.academic_year_id

            where care_group.id =
                  p_group_id

              and care_group.is_active = true

              and academic_year.is_current = true
        ),


        candidate_base as (
            select
                staff.id
                    as staff_id,

                staff.legacy_staff_id,

                staff.full_name,

                staff.position,

                staff.profile_id,

                profile.login_id,

                staff.is_active
                    as staff_is_active,

                profile.is_active
                    as account_active,

                coalesce(
                    jsonb_agg(
                        distinct role.code
                        order by role.code
                    ) filter (
                        where role.code is not null
                    ),
                    '[]'::jsonb
                ) as roles

            from public.staff
                as staff

            inner join public.profiles
                as profile
                on profile.id =
                   staff.profile_id

            left join public.user_roles
                as user_role
                on user_role.user_id =
                   profile.id

            left join public.roles
                as role
                on role.id =
                   user_role.role_id

            where staff.is_active = true
              and profile.is_active = true

              and exists (
                  select 1

                  from public.user_roles
                      as required_user_role

                  inner join public.roles
                      as required_role
                      on required_role.id =
                         required_user_role.role_id

                  where required_user_role.user_id =
                        profile.id

                    and required_role.code =
                        'pengasuh'
              )

            group by
                staff.id,
                staff.legacy_staff_id,
                staff.full_name,
                staff.position,
                staff.profile_id,
                profile.login_id,
                staff.is_active,
                profile.is_active
        ),


        candidate_data as (
            select
                candidate.*,

                exists (
                    select 1

                    from public.caregiver_assignments
                        as assignment

                    where assignment.staff_id =
                          candidate.staff_id

                      and assignment.care_group_id =
                          p_group_id

                      and assignment.is_active = true
                ) as assigned_to_target,

                (
                    select count(*)::integer

                    from public.caregiver_assignments
                        as assignment

                    inner join public.care_groups
                        as care_group
                        on care_group.id =
                           assignment.care_group_id

                    inner join public.academic_years
                        as academic_year
                        on academic_year.id =
                           care_group.academic_year_id

                    where assignment.staff_id =
                          candidate.staff_id

                      and assignment.is_active = true

                      and academic_year.is_current =
                          true
                ) as active_assignment_count,

                coalesce(
                    (
                        select jsonb_agg(
                            jsonb_build_object(
                                'assignment_id',
                                assignment.id,

                                'group_id',
                                care_group.id,

                                'group_name',
                                care_group.name,

                                'group_gender',
                                care_group.gender::text,

                                'is_primary',
                                assignment.is_primary,

                                'assigned_at',
                                assignment.assigned_at
                            )

                            order by
                                care_group.name
                        )

                        from public.caregiver_assignments
                            as assignment

                        inner join public.care_groups
                            as care_group
                            on care_group.id =
                               assignment.care_group_id

                        inner join public.academic_years
                            as academic_year
                            on academic_year.id =
                               care_group.academic_year_id

                        where assignment.staff_id =
                              candidate.staff_id

                          and assignment.is_active =
                              true

                          and academic_year.is_current =
                              true
                    ),
                    '[]'::jsonb
                ) as active_assignments

            from candidate_base
                as candidate
        ),


        current_assignments as (
            select
                assignment.id
                    as assignment_id,

                assignment.staff_id,

                assignment.is_primary,

                assignment.assigned_at,

                staff.legacy_staff_id,

                staff.full_name,

                staff.position,

                staff.profile_id,

                profile.login_id,

                staff.is_active
                    as staff_is_active,

                coalesce(
                    profile.is_active,
                    false
                ) as account_active

            from public.caregiver_assignments
                as assignment

            inner join public.staff
                as staff
                on staff.id =
                   assignment.staff_id

            left join public.profiles
                as profile
                on profile.id =
                   staff.profile_id

            where assignment.care_group_id =
                  p_group_id

              and assignment.is_active = true
        )


        select jsonb_build_object(
            'generated_at',
            now(),

            'group_type',
            'care',

            'required_role',
            'pengasuh',

            'group',
            (
                select jsonb_build_object(
                    'id',
                    target.id,

                    'code',
                    target.code,

                    'name',
                    target.name,

                    'gender',
                    target.gender,

                    'grade_level',
                    null,

                    'academic_year_id',
                    target.academic_year_id,

                    'academic_year_name',
                    target.academic_year_name
                )

                from target_group
                    as target
            ),

            'summary',
            jsonb_build_object(
                'candidate_count',
                (
                    select count(*)::integer

                    from candidate_data
                ),

                'current_assignment_count',
                (
                    select count(*)::integer

                    from current_assignments
                ),

                'current_primary_count',
                (
                    select count(*)::integer

                    from current_assignments

                    where is_primary = true
                )
            ),

            'current_assignments',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'assignment_id',
                            assignment.assignment_id,

                            'staff_id',
                            assignment.staff_id,

                            'legacy_staff_id',
                            assignment.legacy_staff_id,

                            'full_name',
                            assignment.full_name,

                            'position',
                            assignment.position,

                            'profile_id',
                            assignment.profile_id,

                            'login_id',
                            assignment.login_id,

                            'staff_is_active',
                            assignment.staff_is_active,

                            'account_active',
                            assignment.account_active,

                            'is_primary',
                            assignment.is_primary,

                            'assigned_at',
                            assignment.assigned_at
                        )

                        order by
                            assignment.is_primary desc,
                            assignment.full_name
                    ),
                    '[]'::jsonb
                )

                from current_assignments
                    as assignment
            ),

            'candidates',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'staff_id',
                            candidate.staff_id,

                            'legacy_staff_id',
                            candidate.legacy_staff_id,

                            'full_name',
                            candidate.full_name,

                            'position',
                            candidate.position,

                            'profile_id',
                            candidate.profile_id,

                            'login_id',
                            candidate.login_id,

                            'staff_is_active',
                            candidate.staff_is_active,

                            'account_active',
                            candidate.account_active,

                            'roles',
                            candidate.roles,

                            'assigned_to_target',
                            candidate.assigned_to_target,

                            'active_assignment_count',
                            candidate.active_assignment_count,

                            'active_assignments',
                            candidate.active_assignments
                        )

                        order by
                            candidate.assigned_to_target desc,

                            candidate.full_name
                    ),
                    '[]'::jsonb
                )

                from candidate_data
                    as candidate
            )
        )

        into v_result;


        return v_result;

    end if;


    -- =====================================================
    -- 5. TAHFIZ GROUP
    -- =====================================================

    if not exists (
        select 1

        from public.tahfiz_groups
            as tahfiz_group

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               tahfiz_group.academic_year_id

        where tahfiz_group.id =
              p_group_id

          and tahfiz_group.is_active = true

          and academic_year.is_current = true
    ) then
        return null;
    end if;


    with target_group as (
        select
            tahfiz_group.id,
            tahfiz_group.code,
            tahfiz_group.name,
            tahfiz_group.grade_level,
            tahfiz_group.gender::text
                as gender,

            academic_year.id
                as academic_year_id,

            academic_year.name
                as academic_year_name

        from public.tahfiz_groups
            as tahfiz_group

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               tahfiz_group.academic_year_id

        where tahfiz_group.id =
              p_group_id

          and tahfiz_group.is_active = true

          and academic_year.is_current = true
    ),


    candidate_base as (
        select
            staff.id
                as staff_id,

            staff.legacy_staff_id,

            staff.full_name,

            staff.position,

            staff.profile_id,

            profile.login_id,

            staff.is_active
                as staff_is_active,

            profile.is_active
                as account_active,

            coalesce(
                jsonb_agg(
                    distinct role.code
                    order by role.code
                ) filter (
                    where role.code is not null
                ),
                '[]'::jsonb
            ) as roles

        from public.staff
            as staff

        inner join public.profiles
            as profile
            on profile.id =
               staff.profile_id

        left join public.user_roles
            as user_role
            on user_role.user_id =
               profile.id

        left join public.roles
            as role
            on role.id =
               user_role.role_id

        where staff.is_active = true
          and profile.is_active = true

          and exists (
              select 1

              from public.user_roles
                  as required_user_role

              inner join public.roles
                  as required_role
                  on required_role.id =
                     required_user_role.role_id

              where required_user_role.user_id =
                    profile.id

                and required_role.code =
                    'pembina_tahfiz'
          )

        group by
            staff.id,
            staff.legacy_staff_id,
            staff.full_name,
            staff.position,
            staff.profile_id,
            profile.login_id,
            staff.is_active,
            profile.is_active
    ),


    candidate_data as (
        select
            candidate.*,

            exists (
                select 1

                from public.tahfiz_supervisor_assignments
                    as assignment

                where assignment.staff_id =
                      candidate.staff_id

                  and assignment.tahfiz_group_id =
                      p_group_id

                  and assignment.is_active = true
            ) as assigned_to_target,

            (
                select count(*)::integer

                from public.tahfiz_supervisor_assignments
                    as assignment

                inner join public.tahfiz_groups
                    as tahfiz_group
                    on tahfiz_group.id =
                       assignment.tahfiz_group_id

                inner join public.academic_years
                    as academic_year
                    on academic_year.id =
                       tahfiz_group.academic_year_id

                where assignment.staff_id =
                      candidate.staff_id

                  and assignment.is_active = true

                  and academic_year.is_current =
                      true
            ) as active_assignment_count,

            coalesce(
                (
                    select jsonb_agg(
                        jsonb_build_object(
                            'assignment_id',
                            assignment.id,

                            'group_id',
                            tahfiz_group.id,

                            'group_name',
                            tahfiz_group.name,

                            'group_gender',
                            tahfiz_group.gender::text,

                            'grade_level',
                            tahfiz_group.grade_level,

                            'is_primary',
                            assignment.is_primary,

                            'assigned_at',
                            assignment.assigned_at
                        )

                        order by
                            tahfiz_group.grade_level,
                            tahfiz_group.gender,
                            tahfiz_group.name
                    )

                    from public.tahfiz_supervisor_assignments
                        as assignment

                    inner join public.tahfiz_groups
                        as tahfiz_group
                        on tahfiz_group.id =
                           assignment.tahfiz_group_id

                    inner join public.academic_years
                        as academic_year
                        on academic_year.id =
                           tahfiz_group.academic_year_id

                    where assignment.staff_id =
                          candidate.staff_id

                      and assignment.is_active =
                          true

                      and academic_year.is_current =
                          true
                ),
                '[]'::jsonb
            ) as active_assignments

        from candidate_base
            as candidate
    ),


    current_assignments as (
        select
            assignment.id
                as assignment_id,

            assignment.staff_id,

            assignment.is_primary,

            assignment.assigned_at,

            staff.legacy_staff_id,

            staff.full_name,

            staff.position,

            staff.profile_id,

            profile.login_id,

            staff.is_active
                as staff_is_active,

            coalesce(
                profile.is_active,
                false
            ) as account_active

        from public.tahfiz_supervisor_assignments
            as assignment

        inner join public.staff
            as staff
            on staff.id =
               assignment.staff_id

        left join public.profiles
            as profile
            on profile.id =
               staff.profile_id

        where assignment.tahfiz_group_id =
              p_group_id

          and assignment.is_active = true
    )


    select jsonb_build_object(
        'generated_at',
        now(),

        'group_type',
        'tahfiz',

        'required_role',
        'pembina_tahfiz',

        'group',
        (
            select jsonb_build_object(
                'id',
                target.id,

                'code',
                target.code,

                'name',
                target.name,

                'gender',
                target.gender,

                'grade_level',
                target.grade_level,

                'academic_year_id',
                target.academic_year_id,

                'academic_year_name',
                target.academic_year_name
            )

            from target_group
                as target
        ),

        'summary',
        jsonb_build_object(
            'candidate_count',
            (
                select count(*)::integer

                from candidate_data
            ),

            'current_assignment_count',
            (
                select count(*)::integer

                from current_assignments
            ),

            'current_primary_count',
            (
                select count(*)::integer

                from current_assignments

                where is_primary = true
            )
        ),

        'current_assignments',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'assignment_id',
                        assignment.assignment_id,

                        'staff_id',
                        assignment.staff_id,

                        'legacy_staff_id',
                        assignment.legacy_staff_id,

                        'full_name',
                        assignment.full_name,

                        'position',
                        assignment.position,

                        'profile_id',
                        assignment.profile_id,

                        'login_id',
                        assignment.login_id,

                        'staff_is_active',
                        assignment.staff_is_active,

                        'account_active',
                        assignment.account_active,

                        'is_primary',
                        assignment.is_primary,

                        'assigned_at',
                        assignment.assigned_at
                    )

                    order by
                        assignment.is_primary desc,
                        assignment.full_name
                ),
                '[]'::jsonb
            )

            from current_assignments
                as assignment
        ),

        'candidates',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'staff_id',
                        candidate.staff_id,

                        'legacy_staff_id',
                        candidate.legacy_staff_id,

                        'full_name',
                        candidate.full_name,

                        'position',
                        candidate.position,

                        'profile_id',
                        candidate.profile_id,

                        'login_id',
                        candidate.login_id,

                        'staff_is_active',
                        candidate.staff_is_active,

                        'account_active',
                        candidate.account_active,

                        'roles',
                        candidate.roles,

                        'assigned_to_target',
                        candidate.assigned_to_target,

                        'active_assignment_count',
                        candidate.active_assignment_count,

                        'active_assignments',
                        candidate.active_assignments
                    )

                    order by
                        candidate.assigned_to_target desc,

                        candidate.full_name
                ),
                '[]'::jsonb
            )

            from candidate_data
                as candidate
        )
    )

    into v_result;


    return v_result;
end;
$function$;


-- =========================================================
-- COMMENT
-- =========================================================

comment on function
public.get_admin_group_assignment_candidates(
    text,
    uuid
)
is
'Mengambil kandidat staf aktif dengan akun aktif dan role yang sesuai untuk assignment Pengasuh atau Pembina Tahfiz.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.get_admin_group_assignment_candidates(
    text,
    uuid
)
from public;


revoke all on function
public.get_admin_group_assignment_candidates(
    text,
    uuid
)
from anon;


grant execute on function
public.get_admin_group_assignment_candidates(
    text,
    uuid
)
to authenticated;


commit;