-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 073-verify-admin-group-assignment-detail.sql
--
-- PURPOSE:
-- - Verifikasi detail kelompok pengasuhan
-- - Verifikasi detail kelompok tahfiz
-- - Verifikasi anggota dan assignment
-- - Tidak mengubah data
-- =========================================================


select
    to_regprocedure(
        'public.get_admin_group_assignment_detail(text,uuid)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_group_assignment_detail(text,uuid)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_admin_group_assignment_detail(text,uuid)',
        'execute'
    ) as anon_can_execute;


begin;


-- =========================================================
-- EMULASI ADMIN
-- =========================================================

select set_config(
    'request.jwt.claim.sub',
    (
        select profile.id::text

        from public.profiles
            as profile

        inner join public.user_roles
            as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where role.code = 'admin'
          and profile.is_active = true

        order by
            profile.created_at,
            profile.id

        limit 1
    ),
    true
);


select set_config(
    'request.jwt.claims',
    (
        select jsonb_build_object(
            'sub',
            profile.id,

            'role',
            'authenticated',

            'email',
            auth_user.email
        )::text

        from public.profiles
            as profile

        inner join auth.users
            as auth_user
            on auth_user.id =
               profile.id

        inner join public.user_roles
            as user_role
            on user_role.user_id =
               profile.id

        inner join public.roles
            as role
            on role.id =
               user_role.role_id

        where role.code = 'admin'
          and profile.is_active = true

        order by
            profile.created_at,
            profile.id

        limit 1
    ),
    true
);


do $verification$
declare
    v_care_group_id uuid;
    v_tahfiz_group_id uuid;

    v_care_result jsonb;
    v_tahfiz_result jsonb;
begin
    -- =====================================================
    -- CARE GROUP
    -- =====================================================

    select care_group.id

    into v_care_group_id

    from public.care_groups
        as care_group

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

    where academic_year.is_current = true
      and care_group.is_active = true

    order by
        care_group.name

    limit 1;

    if v_care_group_id is null then
        raise exception
            'Kelompok pengasuhan aktif tidak ditemukan.';
    end if;

    v_care_result :=
        public.get_admin_group_assignment_detail(
            'care',
            v_care_group_id
        );

    if v_care_result is null then
        raise exception
            'Detail kelompok pengasuhan NULL.';
    end if;

    if (
        v_care_result
        #>> '{group_type}'
    ) <> 'care' then
        raise exception
            'group_type pengasuhan tidak sesuai.';
    end if;

    if (
        v_care_result
        #>> '{summary,active_member_count}'
    )::integer <= 0 then
        raise exception
            'Kelompok pengasuhan tidak mempunyai anggota aktif.';
    end if;

    if (
        v_care_result
        #>> '{summary,active_assignment_count}'
    )::integer <= 0 then
        raise exception
            'Kelompok pengasuhan tidak mempunyai assignment aktif.';
    end if;

    -- =====================================================
    -- TAHFIZ GROUP
    -- =====================================================

    select tahfiz_group.id

    into v_tahfiz_group_id

    from public.tahfiz_groups
        as tahfiz_group

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           tahfiz_group.academic_year_id

    where academic_year.is_current = true
      and tahfiz_group.is_active = true

    order by
        tahfiz_group.grade_level,
        tahfiz_group.gender,
        tahfiz_group.name

    limit 1;

    if v_tahfiz_group_id is null then
        raise exception
            'Kelompok tahfiz aktif tidak ditemukan.';
    end if;

    v_tahfiz_result :=
        public.get_admin_group_assignment_detail(
            'tahfiz',
            v_tahfiz_group_id
        );

    if v_tahfiz_result is null then
        raise exception
            'Detail kelompok tahfiz NULL.';
    end if;

    if (
        v_tahfiz_result
        #>> '{group_type}'
    ) <> 'tahfiz' then
        raise exception
            'group_type tahfiz tidak sesuai.';
    end if;

    if (
        v_tahfiz_result
        #>> '{summary,active_member_count}'
    )::integer <= 0 then
        raise exception
            'Kelompok tahfiz tidak mempunyai anggota aktif.';
    end if;

    if (
        v_tahfiz_result
        #>> '{summary,primary_assignment_count}'
    )::integer <> 1 then
        raise exception
            'Kelompok tahfiz harus mempunyai satu Pembina utama.';
    end if;

    -- =====================================================
    -- INVALID TYPE
    -- =====================================================

    begin
        perform
            public.get_admin_group_assignment_detail(
                'invalid',
                v_care_group_id
            );

        raise exception
            'Tipe kelompok invalid tidak ditolak.';

    exception
        when others then
            if sqlerrm not ilike
               '%tipe kelompok tidak valid%' then
                raise;
            end if;
    end;

    raise notice
        'CARE GROUP: %',
        v_care_result
        #>> '{group,name}';

    raise notice
        'CARE MEMBERS: %',
        v_care_result
        #>> '{summary,active_member_count}';

    raise notice
        'CARE ASSIGNMENTS: %',
        v_care_result
        #>> '{summary,active_assignment_count}';

    raise notice
        'TAHFIZ GROUP: %',
        v_tahfiz_result
        #>> '{group,name}';

    raise notice
        'TAHFIZ MEMBERS: %',
        v_tahfiz_result
        #>> '{summary,active_member_count}';

    raise notice
        'TAHFIZ PRIMARY: %',
        v_tahfiz_result
        #>> '{summary,primary_assignment_count}';

    raise notice
        'VERIFICATION SUCCESS';
end;
$verification$;


rollback;


select
    'Detail Kelompok dan Assignment Admin berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;