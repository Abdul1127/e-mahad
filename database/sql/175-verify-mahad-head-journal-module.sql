-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 175-verify-mahad-head-journal-module.sql
--
-- READ + TRANSACTIONAL VERIFICATION
-- DATA TEST DI-ROLLBACK
-- =========================================================


-- =========================================================
-- 1. FOUNDATION CHECK
-- =========================================================

select
    to_regclass(
        'public.mahad_head_journal_checklist_items'
    ) is not null
        as checklist_table_exists,

    to_regclass(
        'public.mahad_head_journals'
    ) is not null
        as journals_table_exists,

    to_regclass(
        'public.mahad_head_journal_checks'
    ) is not null
        as checks_table_exists,

    to_regprocedure(
        'public.create_or_open_kepala_mahad_journal(date)'
    ) is not null
        as create_function_exists,

    to_regprocedure(
        'public.save_kepala_mahad_journal(uuid,text[],text,text)'
    ) is not null
        as save_function_exists,

    to_regprocedure(
        'public.submit_kepala_mahad_journal(uuid)'
    ) is not null
        as submit_function_exists,

    to_regprocedure(
        'public.get_penanggung_jawab_mahad_head_journal_overview(date,date)'
    ) is not null
        as monitoring_function_exists;


-- =========================================================
-- 2. CHECKLIST SEED
-- =========================================================

select
    pillar_code,
    pillar_name,
    count(*)::integer
        as item_count

from public.mahad_head_journal_checklist_items

where is_active =
      true

group by
    pillar_code,
    pillar_name

order by
    case pillar_code
        when 'student_care'
            then 1

        when 'tahfiz_academic'
            then 2

        when 'facilities_digital'
            then 3

        when 'administration_staff'
            then 4

        else 99
    end;


-- Expected:
--
-- student_care          5
-- tahfiz_academic       5
-- facilities_digital    5
-- administration_staff 4
--
-- TOTAL = 19


-- =========================================================
-- 3. STORAGE BUCKET
-- =========================================================

select
    id,
    public,
    file_size_limit,
    allowed_mime_types

from storage.buckets

where id =
      'mahad-head-journal-evidence';


-- =========================================================
-- 4. TRANSACTIONAL RPC VERIFICATION
-- =========================================================

begin;


do $verification$
declare
    v_kepala_profile_id uuid;
    v_kepala_email text;

    v_penanggung_profile_id uuid;
    v_penanggung_email text;

    v_journal_id uuid;

    v_result jsonb;

    v_checked_keys text[] :=
        array[
            'student_care_01',
            'tahfiz_academic_01',
            'facilities_digital_01',
            'administration_staff_02'
        ]::text[];

    v_checked_count integer;
begin

    -- =====================================================
    -- A. FIND KEPALA MA'HAD
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_kepala_profile_id,
        v_kepala_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    inner join public.staff
        as staff

        on staff.profile_id =
           profile.id

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    where role.code =
          'kepala_mahad'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true

    limit 1;


    if v_kepala_profile_id is null then
        raise exception
            'Akun Kepala Ma''had aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. FIND PENANGGUNG JAWAB
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_penanggung_profile_id,
        v_penanggung_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user

        on auth_user.id =
           profile.id

    inner join public.staff
        as staff

        on staff.profile_id =
           profile.id

    inner join public.user_roles
        as user_role

        on user_role.user_id =
           profile.id

    inner join public.roles
        as role

        on role.id =
           user_role.role_id

    where role.code =
          'penanggung_jawab'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true

    limit 1;


    if v_penanggung_profile_id is null then
        raise exception
            'Akun Penanggung Jawab aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. LOGIN KEPALA MA'HAD
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_kepala_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_kepala_profile_id,

            'role',
            'authenticated',

            'email',
            v_kepala_email
        )::text,
        true
    );


    -- =====================================================
    -- D. CREATE / OPEN
    -- =====================================================

    v_result :=
        public.create_or_open_kepala_mahad_journal(
            current_date
        );


    v_journal_id :=
        (
            v_result
            ->> 'journal_id'
        )::uuid;


    if v_journal_id is null then
        raise exception
            'Jurnal verification gagal dibuat.';
    end if;


    raise notice
        'KEPALA MAHAD CREATE/OPEN SUCCESS';


    -- =====================================================
    -- E. SAVE
    -- =====================================================

    v_result :=
        public.save_kepala_mahad_journal(
            v_journal_id,
            v_checked_keys,
            'Verification catatan kinerja Kepala Ma''had.',
            'Verification kendala dan tindak lanjut.'
        );


    v_checked_count :=
        (
            select
                count(*)::integer

            from jsonb_array_elements(
                v_result -> 'checklist'
            )
                as item(value)

            where (
                item.value
                ->> 'is_checked'
            )::boolean =
                  true
        );


    if v_checked_count <>
       4
    then
        raise exception
            'Jumlah checklist tersimpan tidak sesuai.';
    end if;


    if (
        v_result
        #>> '{journal,status}'
    ) <>
       'draft'
    then
        raise exception
            'Status jurnal seharusnya draft.';
    end if;


    raise notice
        'KEPALA MAHAD SAVE DRAFT SUCCESS';


    -- =====================================================
    -- F. INVALID CHECKLIST MUST FAIL
    -- =====================================================

    begin

        perform
            public.save_kepala_mahad_journal(
                v_journal_id,

                array[
                    'INVALID_CHECKLIST_KEY'
                ]::text[],

                'Verification',
                null
            );


        raise exception
            'EXPECTED_INVALID_CHECKLIST_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_INVALID_CHECKLIST_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%checklist yang tidak valid%'
            then
                raise;
            end if;

    end;


    raise notice
        'INVALID CHECKLIST PROTECTION SUCCESS';


    -- =====================================================
    -- G. PENANGGUNG JAWAB CANNOT SEE DRAFT
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_penanggung_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_penanggung_profile_id,

            'role',
            'authenticated',

            'email',
            v_penanggung_email
        )::text,
        true
    );


    v_result :=
        public.get_penanggung_jawab_mahad_head_journal_overview(
            current_date,
            current_date
        );


    if exists (
        select 1

        from jsonb_array_elements(
            v_result -> 'items'
        )
            as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_journal_id
    ) then
        raise exception
            'Draft tidak boleh terlihat oleh Penanggung Jawab.';
    end if;


    raise notice
        'DRAFT VISIBILITY PROTECTION SUCCESS';


    -- =====================================================
    -- H. PENANGGUNG JAWAB CANNOT EDIT
    -- =====================================================

    begin

        perform
            public.save_kepala_mahad_journal(
                v_journal_id,
                v_checked_keys,
                'Tidak boleh',
                null
            );


        raise exception
            'EXPECTED_PJ_EDIT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_PJ_EDIT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses Jurnal Kepala Ma''had ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'PENANGGUNG JAWAB WRITE PROTECTION SUCCESS';


    -- =====================================================
    -- I. LOGIN KEPALA MA'HAD AGAIN
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_kepala_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_kepala_profile_id,

            'role',
            'authenticated',

            'email',
            v_kepala_email
        )::text,
        true
    );


    -- =====================================================
    -- J. SUBMIT
    -- =====================================================

    v_result :=
        public.submit_kepala_mahad_journal(
            v_journal_id
        );


    if (
        v_result
        #>> '{journal,status}'
    ) <>
       'submitted'
    then
        raise exception
            'Jurnal gagal berubah menjadi submitted.';
    end if;


    raise notice
        'KEPALA MAHAD SUBMIT SUCCESS';


    -- =====================================================
    -- K. SUBMITTED CANNOT BE EDITED
    -- =====================================================

    begin

        perform
            public.save_kepala_mahad_journal(
                v_journal_id,
                v_checked_keys,
                'Tidak boleh berubah',
                null
            );


        raise exception
            'EXPECTED_SUBMITTED_EDIT_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_SUBMITTED_EDIT_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%sudah dikirim%'
               and sqlerrm not ilike
                   '%tidak dapat diedit%'
            then
                raise;
            end if;

    end;


    raise notice
        'SUBMITTED JOURNAL LOCK SUCCESS';


    -- =====================================================
    -- L. PENANGGUNG JAWAB CAN SEE SUBMITTED
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_penanggung_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_penanggung_profile_id,

            'role',
            'authenticated',

            'email',
            v_penanggung_email
        )::text,
        true
    );


    v_result :=
        public.get_penanggung_jawab_mahad_head_journal_overview(
            current_date,
            current_date
        );


    if not exists (
        select 1

        from jsonb_array_elements(
            v_result -> 'items'
        )
            as item(value)

        where (
            item.value
            ->> 'id'
        )::uuid =
              v_journal_id
    ) then
        raise exception
            'Submitted jurnal tidak terlihat oleh Penanggung Jawab.';
    end if;


    raise notice
        'PENANGGUNG JAWAB OVERVIEW SUCCESS';


    -- =====================================================
    -- M. PENANGGUNG JAWAB DETAIL
    -- =====================================================

    v_result :=
        public.get_penanggung_jawab_mahad_head_journal_detail(
            v_journal_id
        );


    if (
        v_result
        #>> '{journal,id}'
    )::uuid <>
       v_journal_id
    then
        raise exception
            'Detail monitoring jurnal tidak sesuai.';
    end if;


    raise notice
        'PENANGGUNG JAWAB DETAIL SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'MAHAD HEAD JOURNAL VERIFICATION SUCCESS';

end;
$verification$;


rollback;


-- =========================================================
-- 5. FINAL
-- =========================================================

select
    'Jurnal Kepala Ma''had berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;