-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 079-verify-admin-group-assignment-candidates.sql
--
-- PURPOSE:
-- - Verifikasi RPC kandidat assignment
-- - Bandingkan kandidat dengan role aktual
-- - Pastikan akun kandidat aktif
-- - Pastikan assignment aktif tampil
-- - Tidak mengubah data
-- =========================================================


-- =========================================================
-- 1. FUNCTION + PRIVILEGE
-- =========================================================

select
    to_regprocedure(
        'public.get_admin_group_assignment_candidates(text,uuid)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_admin_group_assignment_candidates(text,uuid)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.get_admin_group_assignment_candidates(text,uuid)',
        'execute'
    ) as anon_can_execute;


-- =========================================================
-- 2. TRANSACTION
-- =========================================================

begin;


-- =========================================================
-- 3. EMULASI ADMIN
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


-- =========================================================
-- 4. VERIFICATION
-- =========================================================

do $verification$
declare
    v_care_group_id uuid;
    v_tahfiz_group_id uuid;

    v_care_result jsonb;
    v_tahfiz_result jsonb;

    v_expected_care_candidates integer;
    v_expected_tahfiz_candidates integer;

    v_expected_care_assignments integer;
    v_expected_tahfiz_assignments integer;

    v_expected_tahfiz_primary integer;
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

    where care_group.is_active = true
      and academic_year.is_current = true

    order by
        care_group.name,
        care_group.id

    limit 1;


    if v_care_group_id is null then
        raise exception
            'Kelompok pengasuhan aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- EXPECTED CARE CANDIDATES
    -- =====================================================

    select count(distinct staff.id)::integer

    into v_expected_care_candidates

    from public.staff
        as staff

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    where staff.is_active = true
      and profile.is_active = true

      and exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'pengasuh'
      );


    select count(*)::integer

    into v_expected_care_assignments

    from public.caregiver_assignments

    where care_group_id =
          v_care_group_id

      and is_active = true;


    v_care_result :=
        public.get_admin_group_assignment_candidates(
            'care',
            v_care_group_id
        );


    if v_care_result is null then
        raise exception
            'RPC kandidat Pengasuh mengembalikan NULL.';
    end if;


    if (
        v_care_result
        #>> '{group_type}'
    ) <> 'care' then
        raise exception
            'group_type kandidat Pengasuh salah.';
    end if;


    if (
        v_care_result
        #>> '{required_role}'
    ) <> 'pengasuh' then
        raise exception
            'required_role Pengasuh salah.';
    end if;


    if (
        v_care_result
        #>> '{summary,candidate_count}'
    )::integer <>
       v_expected_care_candidates
    then
        raise exception
            'Jumlah kandidat Pengasuh tidak sesuai. Expected %, actual %.',
            v_expected_care_candidates,
            v_care_result
            #>> '{summary,candidate_count}';
    end if;


    if (
        v_care_result
        #>> '{summary,current_assignment_count}'
    )::integer <>
       v_expected_care_assignments
    then
        raise exception
            'Jumlah assignment Pengasuh tidak sesuai.';
    end if;


    -- Semua candidate harus punya login ID
    if exists (
        select 1

        from jsonb_array_elements(
            v_care_result -> 'candidates'
        ) as candidate(item)

        where nullif(
            btrim(
                candidate.item
                ->> 'login_id'
            ),
            ''
        ) is null
    ) then
        raise exception
            'Terdapat kandidat Pengasuh tanpa Login ID.';
    end if;


    -- Semua candidate harus punya role pengasuh
    if exists (
        select 1

        from jsonb_array_elements(
            v_care_result -> 'candidates'
        ) as candidate(item)

        where not (
            candidate.item
            -> 'roles'
            ? 'pengasuh'
        )
    ) then
        raise exception
            'Terdapat kandidat tanpa role pengasuh.';
    end if;


    raise notice
        'CARE GROUP: %',
        v_care_result
        #>> '{group,name}';


    raise notice
        'CARE CANDIDATES: %',
        v_care_result
        #>> '{summary,candidate_count}';


    raise notice
        'CARE ASSIGNMENTS: %',
        v_care_result
        #>> '{summary,current_assignment_count}';


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

    where tahfiz_group.is_active = true
      and academic_year.is_current = true

    order by
        tahfiz_group.grade_level,
        tahfiz_group.gender,
        tahfiz_group.name,
        tahfiz_group.id

    limit 1;


    if v_tahfiz_group_id is null then
        raise exception
            'Kelompok Tahfiz aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- EXPECTED TAHFIZ CANDIDATES
    -- =====================================================

    select count(distinct staff.id)::integer

    into v_expected_tahfiz_candidates

    from public.staff
        as staff

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

    where staff.is_active = true
      and profile.is_active = true

      and exists (
          select 1

          from public.user_roles
              as user_role

          inner join public.roles
              as role
              on role.id =
                 user_role.role_id

          where user_role.user_id =
                profile.id

            and role.code =
                'pembina_tahfiz'
      );


    select
        count(*)::integer,

        count(*) filter (
            where is_primary = true
        )::integer

    into
        v_expected_tahfiz_assignments,
        v_expected_tahfiz_primary

    from public.tahfiz_supervisor_assignments

    where tahfiz_group_id =
          v_tahfiz_group_id

      and is_active = true;


    v_tahfiz_result :=
        public.get_admin_group_assignment_candidates(
            'tahfiz',
            v_tahfiz_group_id
        );


    if v_tahfiz_result is null then
        raise exception
            'RPC kandidat Pembina Tahfiz mengembalikan NULL.';
    end if;


    if (
        v_tahfiz_result
        #>> '{group_type}'
    ) <> 'tahfiz' then
        raise exception
            'group_type kandidat Tahfiz salah.';
    end if;


    if (
        v_tahfiz_result
        #>> '{required_role}'
    ) <> 'pembina_tahfiz' then
        raise exception
            'required_role Tahfiz salah.';
    end if;


    if (
        v_tahfiz_result
        #>> '{summary,candidate_count}'
    )::integer <>
       v_expected_tahfiz_candidates
    then
        raise exception
            'Jumlah kandidat Pembina Tahfiz tidak sesuai. Expected %, actual %.',
            v_expected_tahfiz_candidates,
            v_tahfiz_result
            #>> '{summary,candidate_count}';
    end if;


    if (
        v_tahfiz_result
        #>> '{summary,current_assignment_count}'
    )::integer <>
       v_expected_tahfiz_assignments
    then
        raise exception
            'Jumlah assignment Pembina Tahfiz tidak sesuai.';
    end if;


    if (
        v_tahfiz_result
        #>> '{summary,current_primary_count}'
    )::integer <>
       v_expected_tahfiz_primary
    then
        raise exception
            'Jumlah Pembina utama tidak sesuai.';
    end if;


    if exists (
        select 1

        from jsonb_array_elements(
            v_tahfiz_result -> 'candidates'
        ) as candidate(item)

        where nullif(
            btrim(
                candidate.item
                ->> 'login_id'
            ),
            ''
        ) is null
    ) then
        raise exception
            'Terdapat kandidat Pembina Tahfiz tanpa Login ID.';
    end if;


    if exists (
        select 1

        from jsonb_array_elements(
            v_tahfiz_result -> 'candidates'
        ) as candidate(item)

        where not (
            candidate.item
            -> 'roles'
            ? 'pembina_tahfiz'
        )
    ) then
        raise exception
            'Terdapat kandidat tanpa role pembina_tahfiz.';
    end if;


    raise notice
        'TAHFIZ GROUP: %',
        v_tahfiz_result
        #>> '{group,name}';


    raise notice
        'TAHFIZ CANDIDATES: %',
        v_tahfiz_result
        #>> '{summary,candidate_count}';


    raise notice
        'TAHFIZ ASSIGNMENTS: %',
        v_tahfiz_result
        #>> '{summary,current_assignment_count}';


    raise notice
        'TAHFIZ PRIMARY: %',
        v_tahfiz_result
        #>> '{summary,current_primary_count}';


    -- =====================================================
    -- INVALID GROUP TYPE
    -- =====================================================

    begin
        perform
            public.get_admin_group_assignment_candidates(
                'invalid',
                v_care_group_id
            );

        raise exception
            'Tipe group invalid tidak ditolak.';

    exception
        when others then

            if sqlerrm not ilike
               '%tipe kelompok tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'GROUP ASSIGNMENT CANDIDATE VERIFICATION SUCCESS';

end;
$verification$;


rollback;


-- =========================================================
-- 5. FINAL OUTPUT
-- =========================================================

select
    'Kandidat Assignment Admin berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;