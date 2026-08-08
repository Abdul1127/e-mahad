-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 099-verify-pengasuh-journal-normal-fill.sql
--
-- PURPOSE:
-- - Verify bulk normal fill
-- - Pastikan data khusus tidak ditimpa
-- - Pastikan seluruh entry kosong menjadi lengkap
-- - Pastikan submitted tetap terkunci
-- - Seluruh test di-ROLLBACK
-- =========================================================


select
    to_regprocedure(
        'public.fill_normal_pengasuh_journal_entries(uuid)'
    ) is not null
        as function_exists,

    has_function_privilege(
        'authenticated',
        'public.fill_normal_pengasuh_journal_entries(uuid)',
        'execute'
    ) as authenticated_can_execute,

    has_function_privilege(
        'anon',
        'public.fill_normal_pengasuh_journal_entries(uuid)',
        'execute'
    ) as anon_can_execute;


begin;


do $verification$
declare
    v_profile_id uuid;

    v_auth_email text;

    v_staff_id uuid;

    v_group_id uuid;

    v_start_date date;

    v_end_date date;

    v_test_date date;

    v_test_session text;

    v_journal_id uuid;

    v_special_student_id uuid;

    v_result jsonb;

    v_expected_count integer;

    v_complete_count integer;
begin

    -- =====================================================
    -- A. PICK OPERATIONAL PENGASUH
    -- =====================================================

    select
        profile.id,
        auth_user.email,
        staff.id,
        care_group.id

    into
        v_profile_id,
        v_auth_email,
        v_staff_id,
        v_group_id

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

    inner join public.caregiver_assignments
        as assignment
        on assignment.staff_id =
           staff.id

       and assignment.is_active =
           true

    inner join public.care_groups
        as care_group
        on care_group.id =
           assignment.care_group_id

       and care_group.is_active =
           true

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

       and academic_year.is_current =
           true

    where role.code =
          'pengasuh'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true

    order by
        staff.full_name,
        staff.id

    limit 1;


    if v_profile_id is null
       or v_group_id is null
    then
        raise exception
            'Pengasuh test tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.start_date,
        academic_year.end_date

    into
        v_start_date,
        v_end_date

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    -- =====================================================
    -- C. LOGIN EMULATION
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_profile_id,

            'role',
            'authenticated',

            'email',
            v_auth_email
        )::text,
        true
    );


    -- =====================================================
    -- D. FIND FREE SLOT
    -- =====================================================

    select
        available.journal_date,
        available.session

    into
        v_test_date,
        v_test_session

    from (
        select
            generated.day_value::date
                as journal_date,

            session_data.session

        from generate_series(
            v_start_date::timestamp,
            v_end_date::timestamp,
            interval '1 day'
        ) as generated(day_value)

        cross join (
            values
                ('morning'::text),
                ('evening'::text)
        ) as session_data(session)

        where not exists (
            select 1

            from public.care_journals
                as journal

            where journal.care_group_id =
                  v_group_id

              and journal.journal_date =
                  generated.day_value::date

              and journal.session =
                  session_data.session
        )

        order by
            generated.day_value desc,
            session_data.session
    ) as available

    limit 1;


    if v_test_date is null then
        raise exception
            'Slot jurnal test tidak tersedia.';
    end if;


    -- =====================================================
    -- E. CREATE JOURNAL
    -- =====================================================

    v_result :=
        public.create_or_open_pengasuh_journal(
            v_group_id,
            v_test_date,
            v_test_session
        );


    v_journal_id :=
        (
            v_result
            ->> 'journal_id'
        )::uuid;


    if v_journal_id is null then
        raise exception
            'Jurnal test gagal dibuat.';
    end if;


    select
        count(*)::integer

    into
        v_expected_count

    from public.care_journal_entries
        as entry

    where entry.journal_id =
          v_journal_id;


    if v_expected_count = 0 then
        raise exception
            'Jurnal test tidak memiliki entry.';
    end if;


    -- =====================================================
    -- F. SAVE ONE SPECIAL STUDENT
    --
    -- Nilai ini TIDAK BOLEH tertimpa bulk normal.
    -- =====================================================

    select
        entry.student_id

    into
        v_special_student_id

    from public.care_journal_entries
        as entry

    where entry.journal_id =
          v_journal_id

    order by
        entry.student_id

    limit 1;


    perform
        public.save_pengasuh_journal_entry(
            v_journal_id,
            v_special_student_id,
            'unwell',
            'needs_reminder',
            'quiet',
            true,
            'Santri test mempunyai kondisi khusus.',
            'Dilakukan pendampingan.'
        );


    -- =====================================================
    -- G. BULK NORMAL
    -- =====================================================

    v_result :=
        public.fill_normal_pengasuh_journal_entries(
            v_journal_id
        );


    if (
        v_result
        ->> 'complete_entry_count'
    )::integer <>
       v_expected_count
    then
        raise exception
            'Bulk normal tidak melengkapi seluruh entry.';
    end if;


    -- =====================================================
    -- H. SPECIAL VALUE MUST REMAIN
    -- =====================================================

    if not exists (
        select 1

        from public.care_journal_entries
            as entry

        where entry.journal_id =
              v_journal_id

          and entry.student_id =
              v_special_student_id

          and entry.health_condition =
              'unwell'

          and entry.sleep_compliance =
              'needs_reminder'

          and entry.psychological_condition =
              'quiet'

          and entry.parent_visit =
              true

          and entry.case_notes =
              'Santri test mempunyai kondisi khusus.'

          and entry.handling_notes =
              'Dilakukan pendampingan.'
    ) then
        raise exception
            'Bulk normal menimpa kondisi khusus santri.';
    end if;


    raise notice
        'EXISTING SPECIAL ENTRY PRESERVED SUCCESS';


    -- =====================================================
    -- I. ALL ENTRIES COMPLETE
    -- =====================================================

    select
        count(*)::integer

    into
        v_complete_count

    from public.care_journal_entries
        as entry

    where entry.journal_id =
          v_journal_id

      and entry.health_condition
          is not null

      and entry.sleep_compliance
          is not null

      and entry.psychological_condition
          is not null

      and entry.parent_visit
          is not null;


    if v_complete_count <>
       v_expected_count
    then
        raise exception
            'Masih terdapat entry belum lengkap setelah bulk normal.';
    end if;


    raise notice
        'BULK NORMAL COMPLETES ALL EMPTY ENTRIES SUCCESS';


    -- =====================================================
    -- J. SUBMIT
    -- =====================================================

    perform
        public.submit_pengasuh_journal(
            v_journal_id
        );


    -- =====================================================
    -- K. SUBMITTED MUST BE LOCKED
    -- =====================================================

    begin

        perform
            public.fill_normal_pengasuh_journal_entries(
                v_journal_id
            );


        raise exception
            'Bulk normal dapat dijalankan pada jurnal submitted.';

    exception
        when others then

            if sqlerrm not ilike
               '%sedang menunggu review%'
            then
                raise;
            end if;

    end;


    raise notice
        'SUBMITTED BULK NORMAL LOCK SUCCESS';


    raise notice
        'PENGASUH JOURNAL NORMAL FILL VERIFICATION SUCCESS';

end;
$verification$;


rollback;


select
    'Bulk kondisi normal Jurnal Pengasuhan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;