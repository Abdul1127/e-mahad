-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 097-verify-pengasuh-care-journal-functions.sql
--
-- PURPOSE:
-- - Verify RPC Jurnal Pengasuhan dari SQL 096
-- - Verify isolation berdasarkan auth.uid()
-- - Verify Pengasuh hanya dapat mengakses group assignment
-- - Verify journal initialization
-- - Verify save entry
-- - Verify completeness sebelum submit
-- - Verify temporary lock pada submitted
-- - Verify revision/review dapat diedit kembali
-- - Verify non-Pengasuh ditolak
--
-- SELURUH DATA TEST DI-ROLLBACK
-- =========================================================


-- =========================================================
-- 1. FUNCTION EXISTS + PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.get_pengasuh_journal_overview(date)'
    ) is not null
        as overview_function_exists,

    to_regprocedure(
        'public.create_or_open_pengasuh_journal(uuid,date,text)'
    ) is not null
        as create_open_function_exists,

    to_regprocedure(
        'public.get_pengasuh_journal_detail(uuid)'
    ) is not null
        as detail_function_exists,

    to_regprocedure(
        'public.save_pengasuh_journal_entry(uuid,uuid,text,text,text,boolean,text,text)'
    ) is not null
        as save_entry_function_exists,

    to_regprocedure(
        'public.submit_pengasuh_journal(uuid)'
    ) is not null
        as submit_function_exists;


select
    has_function_privilege(
        'authenticated',
        'public.get_pengasuh_journal_overview(date)',
        'execute'
    ) as authenticated_overview,

    has_function_privilege(
        'authenticated',
        'public.create_or_open_pengasuh_journal(uuid,date,text)',
        'execute'
    ) as authenticated_create_open,

    has_function_privilege(
        'authenticated',
        'public.get_pengasuh_journal_detail(uuid)',
        'execute'
    ) as authenticated_detail,

    has_function_privilege(
        'authenticated',
        'public.save_pengasuh_journal_entry(uuid,uuid,text,text,text,boolean,text,text)',
        'execute'
    ) as authenticated_save,

    has_function_privilege(
        'authenticated',
        'public.submit_pengasuh_journal(uuid)',
        'execute'
    ) as authenticated_submit,

    has_function_privilege(
        'anon',
        'public.get_pengasuh_journal_overview(date)',
        'execute'
    ) as anon_overview,

    has_function_privilege(
        'anon',
        'public.create_or_open_pengasuh_journal(uuid,date,text)',
        'execute'
    ) as anon_create_open,

    has_function_privilege(
        'anon',
        'public.get_pengasuh_journal_detail(uuid)',
        'execute'
    ) as anon_detail,

    has_function_privilege(
        'anon',
        'public.save_pengasuh_journal_entry(uuid,uuid,text,text,text,boolean,text,text)',
        'execute'
    ) as anon_save,

    has_function_privilege(
        'anon',
        'public.submit_pengasuh_journal(uuid)',
        'execute'
    ) as anon_submit;


-- =========================================================
-- 2. BEGIN TEST TRANSACTION
-- =========================================================

begin;


do $verification$
declare
    -- Pengasuh test
    v_profile_id uuid;
    v_auth_email text;

    v_staff_id uuid;
    v_staff_name text;

    -- Group milik Pengasuh
    v_own_group_id uuid;
    v_own_group_name text;

    -- Group bukan milik Pengasuh
    v_other_group_id uuid;
    v_other_group_name text;

    -- Academic year
    v_academic_year_id uuid;
    v_start_date date;
    v_end_date date;

    -- Free journal slot
    v_test_date date;
    v_test_session text;

    -- RPC result
    v_create_result jsonb;
    v_open_result jsonb;
    v_overview_result jsonb;
    v_detail_result jsonb;
    v_save_result jsonb;
    v_submit_result jsonb;

    -- Journal
    v_journal_id uuid;
    v_journal_status text;

    -- Students
    v_expected_student_count integer;
    v_created_entry_count integer;
    v_complete_entry_count integer;

    v_test_student_id uuid;
    v_test_entry_id uuid;

    -- Non pengasuh
    v_non_pengasuh_profile_id uuid;
    v_non_pengasuh_email text;

    -- Version
    v_submission_version integer;
begin

    -- =====================================================
    -- A. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
        v_start_date,
        v_end_date

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. PICK OPERATIONAL PENGASUH
    -- =====================================================

    select
        profile.id,
        auth_user.email,
        staff.id,
        staff.full_name

    into
        v_profile_id,
        v_auth_email,
        v_staff_id,
        v_staff_name

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
          'pengasuh'

      and role.is_active =
          true

      and profile.is_active =
          true

      and staff.is_active =
          true

      and exists (
          select 1

          from public.caregiver_assignments
              as assignment

          inner join public.care_groups
              as care_group
              on care_group.id =
                 assignment.care_group_id

          where assignment.staff_id =
                staff.id

            and assignment.is_active =
                true

            and care_group.is_active =
                true

            and care_group.academic_year_id =
                v_academic_year_id
      )

    order by
        staff.full_name,
        staff.id

    limit 1;


    if v_profile_id is null
       or v_staff_id is null
    then
        raise exception
            'Pengasuh operational untuk verification tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. OWN GROUP
    -- =====================================================

    select
        care_group.id,
        care_group.name

    into
        v_own_group_id,
        v_own_group_name

    from public.caregiver_assignments
        as assignment

    inner join public.care_groups
        as care_group
        on care_group.id =
           assignment.care_group_id

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active =
          true

      and care_group.is_active =
          true

      and care_group.academic_year_id =
          v_academic_year_id

    order by
        care_group.name,
        care_group.id

    limit 1;


    if v_own_group_id is null then
        raise exception
            'Kelompok assignment Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- D. OTHER GROUP
    -- =====================================================

    select
        care_group.id,
        care_group.name

    into
        v_other_group_id,
        v_other_group_name

    from public.care_groups
        as care_group

    where care_group.is_active =
          true

      and care_group.academic_year_id =
          v_academic_year_id

      and care_group.id <>
          v_own_group_id

      and not exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.care_group_id =
                care_group.id

            and assignment.is_active =
                true
      )

    order by
        care_group.name,
        care_group.id

    limit 1;


    if v_other_group_id is null then
        raise exception
            'Kelompok lain untuk isolation test tidak ditemukan.';
    end if;


    -- =====================================================
    -- E. EMULATE PENGASUH LOGIN
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


    raise notice
        'TEST PENGASUH: % | own group: % | other group: %',
        v_staff_name,
        v_own_group_name,
        v_other_group_name;


    -- =====================================================
    -- F. FIND EMPTY JOURNAL SLOT
    -- =====================================================

    select
        available_slot.journal_date,
        available_slot.session

    into
        v_test_date,
        v_test_session

    from (
        select
            generated_day.day_value::date
                as journal_date,

            session_value.session

        from generate_series(
            v_start_date::timestamp,
            v_end_date::timestamp,
            interval '1 day'
        ) as generated_day(day_value)

        cross join (
            values
                ('morning'::text),
                ('evening'::text)
        ) as session_value(session)

        where not exists (
            select 1

            from public.care_journals
                as journal

            where journal.care_group_id =
                  v_own_group_id

              and journal.journal_date =
                  generated_day.day_value::date

              and journal.session =
                  session_value.session
        )

        order by
            generated_day.day_value desc,
            session_value.session
    ) as available_slot

    limit 1;


    if v_test_date is null then
        raise exception
            'Slot jurnal kosong untuk verification tidak ditemukan.';
    end if;


    -- =====================================================
    -- G. OVERVIEW BEFORE CREATE
    -- =====================================================

    v_overview_result :=
        public.get_pengasuh_journal_overview(
            v_test_date
        );


    if (
        v_overview_result
        #>> '{staff,id}'
    )::uuid <>
       v_staff_id
    then
        raise exception
            'Overview mengembalikan staff yang salah.';
    end if;


    if not exists (
        select 1

        from jsonb_array_elements(
            v_overview_result
            -> 'groups'
        ) as group_item(item)

        where (
            group_item.item
            ->> 'id'
        )::uuid =
        v_own_group_id
    ) then
        raise exception
            'Overview tidak menampilkan group milik Pengasuh.';
    end if;


    if exists (
        select 1

        from jsonb_array_elements(
            v_overview_result
            -> 'groups'
        ) as group_item(item)

        where (
            group_item.item
            ->> 'id'
        )::uuid =
        v_other_group_id
    ) then
        raise exception
            'DATA LEAK: Overview menampilkan group lain.';
    end if;


    raise notice
        'PENGASUH JOURNAL OVERVIEW ISOLATION SUCCESS';


    -- =====================================================
    -- H. CREATE OWN JOURNAL
    -- =====================================================

    v_create_result :=
        public.create_or_open_pengasuh_journal(
            v_own_group_id,
            v_test_date,
            v_test_session
        );


    if coalesce(
        (
            v_create_result
            ->> 'created'
        )::boolean,
        false
    ) <> true
    then
        raise exception
            'Jurnal baru tidak ditandai created=true.';
    end if;


    v_journal_id :=
        (
            v_create_result
            ->> 'journal_id'
        )::uuid;


    if v_journal_id is null then
        raise exception
            'Journal ID tidak dikembalikan.';
    end if;


    raise notice
        'CREATE OWN JOURNAL SUCCESS';


    -- =====================================================
    -- I. EXPECTED ACTIVE STUDENTS
    -- =====================================================

    select
        count(*)::integer

    into
        v_expected_student_count

    from public.care_group_members
        as membership

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where membership.care_group_id =
          v_own_group_id

      and membership.is_active =
          true

      and student.status =
          'active'

      and student.deleted_at
          is null;


    select
        count(*)::integer

    into
        v_created_entry_count

    from public.care_journal_entries
        as entry

    where entry.journal_id =
          v_journal_id;


    if v_created_entry_count <>
       v_expected_student_count
    then
        raise exception
            'Jumlah initialized journal entries salah. Expected %, actual %.',
            v_expected_student_count,
            v_created_entry_count;
    end if;


    raise notice
        'AUTO INITIALIZE JOURNAL ENTRIES SUCCESS: % STUDENTS',
        v_created_entry_count;


    -- =====================================================
    -- J. OPEN SAME JOURNAL AGAIN
    -- =====================================================

    v_open_result :=
        public.create_or_open_pengasuh_journal(
            v_own_group_id,
            v_test_date,
            v_test_session
        );


    if (
        v_open_result
        ->> 'created'
    )::boolean <> false
    then
        raise exception
            'Existing journal salah ditandai sebagai jurnal baru.';
    end if;


    if (
        v_open_result
        ->> 'journal_id'
    )::uuid <>
       v_journal_id
    then
        raise exception
            'Open existing journal menghasilkan ID berbeda.';
    end if;


    raise notice
        'OPEN EXISTING JOURNAL SUCCESS';


    -- =====================================================
    -- K. OTHER GROUP MUST FAIL
    -- =====================================================

    begin

        perform
            public.create_or_open_pengasuh_journal(
                v_other_group_id,
                v_test_date,
                v_test_session
            );


        raise exception
            'Pengasuh berhasil membuat jurnal group lain.';

    exception
        when others then

            if sqlerrm not ilike
               '%tidak memiliki assignment aktif%'
            then
                raise;
            end if;

    end;


    raise notice
        'OTHER GROUP ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- L. DETAIL
    -- =====================================================

    v_detail_result :=
        public.get_pengasuh_journal_detail(
            v_journal_id
        );


    if (
        v_detail_result
        #>> '{journal,id}'
    )::uuid <>
       v_journal_id
    then
        raise exception
            'Detail jurnal menghasilkan journal ID yang salah.';
    end if;


    if (
        v_detail_result
        #>> '{summary,entry_count}'
    )::integer <>
       v_expected_student_count
    then
        raise exception
            'Jumlah entry detail jurnal tidak sesuai.';
    end if;


    raise notice
        'GET JOURNAL DETAIL SUCCESS';


    -- =====================================================
    -- M. INCOMPLETE JOURNAL MUST NOT SUBMIT
    -- =====================================================

    begin

        perform
            public.submit_pengasuh_journal(
                v_journal_id
            );


        raise exception
            'Jurnal belum lengkap berhasil disubmit.';

    exception
        when others then

            if sqlerrm not ilike
               '%Jurnal belum lengkap%'
            then
                raise;
            end if;

    end;


    raise notice
        'INCOMPLETE JOURNAL SUBMIT PROTECTION SUCCESS';


    -- =====================================================
    -- N. PICK ONE ENTRY
    -- =====================================================

    select
        entry.id,
        entry.student_id

    into
        v_test_entry_id,
        v_test_student_id

    from public.care_journal_entries
        as entry

    inner join public.students
        as student
        on student.id =
           entry.student_id

    where entry.journal_id =
          v_journal_id

    order by
        student.full_name,
        student.id

    limit 1;


    if v_test_student_id is null then
        raise exception
            'Entry santri untuk save test tidak ditemukan.';
    end if;


    -- =====================================================
    -- O. SAVE ONE ENTRY THROUGH RPC
    -- =====================================================

    v_save_result :=
        public.save_pengasuh_journal_entry(
            v_journal_id,
            v_test_student_id,
            'healthy',
            'on_time',
            'cheerful',
            false,
            null,
            null
        );


    if (
        v_save_result
        ->> 'status'
    ) <> 'draft'
    then
        raise exception
            'Status jurnal setelah save draft tidak sesuai.';
    end if;


    if not exists (
        select 1

        from public.care_journal_entries
            as entry

        where entry.id =
              v_test_entry_id

          and entry.health_condition =
              'healthy'

          and entry.sleep_compliance =
              'on_time'

          and entry.psychological_condition =
              'cheerful'

          and entry.parent_visit =
              false
    ) then
        raise exception
            'Perubahan journal entry tidak tersimpan.';
    end if;


    raise notice
        'SAVE JOURNAL ENTRY SUCCESS';


    -- =====================================================
    -- P. COMPLETE ALL REMAINING ENTRIES
    --
    -- Direct update hanya untuk menyiapkan test submit.
    -- Seluruh data akan rollback.
    -- =====================================================

    update public.care_journal_entries

    set
        health_condition =
            coalesce(
                health_condition,
                'healthy'
            ),

        sleep_compliance =
            coalesce(
                sleep_compliance,
                'on_time'
            ),

        psychological_condition =
            coalesce(
                psychological_condition,
                'cheerful'
            ),

        parent_visit =
            coalesce(
                parent_visit,
                false
            ),

        updated_by_staff_id =
            v_staff_id

    where journal_id =
          v_journal_id;


    select
        count(*)::integer

    into
        v_complete_entry_count

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


    if v_complete_entry_count <>
       v_expected_student_count
    then
        raise exception
            'Setup complete entries gagal.';
    end if;


    -- =====================================================
    -- Q. SUBMIT VERSION 1
    -- =====================================================

    v_submit_result :=
        public.submit_pengasuh_journal(
            v_journal_id
        );


    if (
        v_submit_result
        ->> 'status'
    ) <> 'submitted'
    then
        raise exception
            'Status hasil submit bukan submitted.';
    end if;


    if (
        v_submit_result
        ->> 'submission_version'
    )::integer <> 1
    then
        raise exception
            'Submission pertama tidak menghasilkan version 1.';
    end if;


    select
        journal.status,
        journal.submission_version

    into
        v_journal_status,
        v_submission_version

    from public.care_journals
        as journal

    where journal.id =
          v_journal_id;


    if v_journal_status <>
       'submitted'
       or v_submission_version <> 1
    then
        raise exception
            'Header jurnal tidak berubah menjadi submitted version 1.';
    end if;


    raise notice
        'SUBMIT COMPLETE JOURNAL SUCCESS - VERSION 1';


    -- =====================================================
    -- R. SUBMITTED JOURNAL MUST BE LOCKED
    -- =====================================================

    begin

        perform
            public.save_pengasuh_journal_entry(
                v_journal_id,
                v_test_student_id,
                'unwell',
                'needs_reminder',
                'quiet',
                true,
                'Test edit submitted',
                'Tidak boleh tersimpan'
            );


        raise exception
            'Jurnal submitted berhasil diedit.';

    exception
        when others then

            if sqlerrm not ilike
               '%sedang menunggu review%'
            then
                raise;
            end if;

    end;


    raise notice
        'SUBMITTED JOURNAL TEMPORARY LOCK SUCCESS';


    -- =====================================================
    -- S. SIMULATE REVISION REQUEST
    --
    -- RPC Kepala Ma'had belum dibuat.
    -- Di verification ini status disiapkan langsung.
    -- =====================================================

    update public.care_journals

    set
        status =
            'revision_requested',

        last_reviewed_at =
            now()

    where id =
          v_journal_id;


    -- =====================================================
    -- T. EDIT AFTER REVISION -> DRAFT
    -- =====================================================

    v_save_result :=
        public.save_pengasuh_journal_entry(
            v_journal_id,
            v_test_student_id,
            'unwell',
            'needs_reminder',
            'quiet',
            true,
            'Santri perlu perhatian.',
            'Pengasuh melakukan pendampingan.'
        );


    if (
        v_save_result
        ->> 'status'
    ) <> 'draft'
    then
        raise exception
            'Edit revision_requested tidak mengembalikan jurnal ke draft.';
    end if;


    select
        journal.status

    into
        v_journal_status

    from public.care_journals
        as journal

    where journal.id =
          v_journal_id;


    if v_journal_status <>
       'draft'
    then
        raise exception
            'Header jurnal tidak kembali menjadi draft setelah revisi.';
    end if;


    raise notice
        'REVISION REQUESTED EDIT -> DRAFT SUCCESS';


    -- =====================================================
    -- U. RESUBMIT VERSION 2
    -- =====================================================

    v_submit_result :=
        public.submit_pengasuh_journal(
            v_journal_id
        );


    if (
        v_submit_result
        ->> 'submission_version'
    )::integer <> 2
    then
        raise exception
            'Resubmit tidak menghasilkan submission version 2.';
    end if;


    raise notice
        'RESUBMIT JOURNAL SUCCESS - VERSION 2';


    -- =====================================================
    -- V. SIMULATE REVIEWED
    -- =====================================================

    update public.care_journals

    set
        status =
            'reviewed',

        last_reviewed_at =
            now()

    where id =
          v_journal_id;


    -- =====================================================
    -- W. EDIT REVIEWED JOURNAL -> DRAFT
    -- =====================================================

    v_save_result :=
        public.save_pengasuh_journal_entry(
            v_journal_id,
            v_test_student_id,
            'healthy',
            'on_time',
            'cheerful',
            false,
            null,
            null
        );


    if (
        v_save_result
        ->> 'status'
    ) <> 'draft'
    then
        raise exception
            'Jurnal reviewed tidak kembali ke draft setelah diedit.';
    end if;


    raise notice
        'REVIEWED JOURNAL REMAINS EDITABLE SUCCESS';


    -- =====================================================
    -- X. NON-PENGASUH MUST FAIL
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_non_pengasuh_profile_id,
        v_non_pengasuh_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user
        on auth_user.id =
           profile.id

    where profile.is_active =
          true

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
                'admin'
      )

      and not exists (
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
      )

    order by
        profile.created_at,
        profile.id

    limit 1;


    if v_non_pengasuh_profile_id is null then
        raise exception
            'Akun non-Pengasuh untuk security test tidak ditemukan.';
    end if;


    perform set_config(
        'request.jwt.claim.sub',
        v_non_pengasuh_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_non_pengasuh_profile_id,

            'role',
            'authenticated',

            'email',
            v_non_pengasuh_email
        )::text,
        true
    );


    begin

        perform
            public.get_pengasuh_journal_overview(
                v_test_date
            );


        raise exception
            'Akun non-Pengasuh berhasil membuka overview jurnal.';

    exception
        when others then

            if sqlerrm not ilike
               '%Akses Jurnal Pengasuhan ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-PENGASUH JOURNAL ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- Y. FINAL
    -- =====================================================

    raise notice
        'PENGASUH CARE JOURNAL FUNCTIONS VERIFICATION SUCCESS';

end;
$verification$;


-- =========================================================
-- 3. ROLLBACK ALL TEST DATA
-- =========================================================

rollback;


-- =========================================================
-- 4. FINAL OUTPUT
-- =========================================================

select
    'RPC Jurnal Pengasuhan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;