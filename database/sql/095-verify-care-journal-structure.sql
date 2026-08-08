-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 095-verify-care-journal-structure.sql
--
-- PURPOSE:
-- - Verifikasi struktur Jurnal Pengasuhan dari SQL 094
-- - Verifikasi tabel, RLS, privilege, constraint, index
-- - Verifikasi unique jurnal per group/tanggal/sesi
-- - Verifikasi satu santri tidak duplikat dalam jurnal
-- - Verifikasi nilai status/session/kondisi
-- - Verifikasi revision_requested wajib memiliki catatan
-- - Verifikasi cascade delete header -> entries/reviews
--
-- TEST DATA SELURUHNYA DI-ROLLBACK
-- =========================================================


-- =========================================================
-- 1. TABLE EXISTS
-- =========================================================

select
    to_regclass(
        'public.care_journals'
    ) is not null
        as care_journals_exists,

    to_regclass(
        'public.care_journal_entries'
    ) is not null
        as care_journal_entries_exists,

    to_regclass(
        'public.care_journal_reviews'
    ) is not null
        as care_journal_reviews_exists;


-- =========================================================
-- 2. RLS STATUS
-- =========================================================

select
    relation.relname
        as table_name,

    relation.relrowsecurity
        as rls_enabled,

    relation.relforcerowsecurity
        as force_rls

from pg_class
    as relation

inner join pg_namespace
    as namespace
    on namespace.oid =
       relation.relnamespace

where namespace.nspname =
      'public'

  and relation.relname in (
      'care_journals',
      'care_journal_entries',
      'care_journal_reviews'
  )

order by
    relation.relname;


-- =========================================================
-- 3. DIRECT TABLE PRIVILEGES
--
-- authenticated & anon HARUS false.
-- service_role HARUS true.
-- =========================================================

select
    table_name,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_name
        ),
        'SELECT'
    ) as authenticated_select,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_name
        ),
        'INSERT'
    ) as authenticated_insert,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_name
        ),
        'UPDATE'
    ) as authenticated_update,

    has_table_privilege(
        'authenticated',
        format(
            'public.%I',
            table_name
        ),
        'DELETE'
    ) as authenticated_delete,

    has_table_privilege(
        'anon',
        format(
            'public.%I',
            table_name
        ),
        'SELECT'
    ) as anon_select,

    has_table_privilege(
        'service_role',
        format(
            'public.%I',
            table_name
        ),
        'SELECT'
    ) as service_role_select,

    has_table_privilege(
        'service_role',
        format(
            'public.%I',
            table_name
        ),
        'INSERT'
    ) as service_role_insert,

    has_table_privilege(
        'service_role',
        format(
            'public.%I',
            table_name
        ),
        'UPDATE'
    ) as service_role_update,

    has_table_privilege(
        'service_role',
        format(
            'public.%I',
            table_name
        ),
        'DELETE'
    ) as service_role_delete

from (
    values
        ('care_journals'),
        ('care_journal_entries'),
        ('care_journal_reviews')
) as tested_table(table_name)

order by
    table_name;


-- =========================================================
-- 4. POLICIES
--
-- Saat ini memang belum dibuat direct-access policy.
-- Aplikasi nanti masuk melalui SECURITY DEFINER RPC.
-- =========================================================

select
    policy.tablename,

    policy.policyname,

    policy.cmd,

    policy.roles

from pg_policies
    as policy

where policy.schemaname =
      'public'

  and policy.tablename in (
      'care_journals',
      'care_journal_entries',
      'care_journal_reviews'
  )

order by
    policy.tablename,
    policy.policyname;


-- =========================================================
-- 5. IMPORTANT CONSTRAINTS
-- =========================================================

select
    relation.relname
        as table_name,

    constraint_data.conname
        as constraint_name,

    constraint_data.contype
        as constraint_type,

    pg_get_constraintdef(
        constraint_data.oid,
        true
    ) as definition

from pg_constraint
    as constraint_data

inner join pg_class
    as relation
    on relation.oid =
       constraint_data.conrelid

inner join pg_namespace
    as namespace
    on namespace.oid =
       relation.relnamespace

where namespace.nspname =
      'public'

  and relation.relname in (
      'care_journals',
      'care_journal_entries',
      'care_journal_reviews'
  )

order by
    relation.relname,
    constraint_data.conname;


-- =========================================================
-- 6. INDEXES
-- =========================================================

select
    index_data.tablename,

    index_data.indexname,

    index_data.indexdef

from pg_indexes
    as index_data

where index_data.schemaname =
      'public'

  and index_data.tablename in (
      'care_journals',
      'care_journal_entries',
      'care_journal_reviews'
  )

order by
    index_data.tablename,
    index_data.indexname;


-- =========================================================
-- 7. UPDATED_AT TRIGGERS
-- =========================================================

select
    event_object_table
        as table_name,

    trigger_name,

    action_timing,

    event_manipulation

from information_schema.triggers

where trigger_schema =
      'public'

  and event_object_table in (
      'care_journals',
      'care_journal_entries'
  )

order by
    event_object_table,
    trigger_name;


-- =========================================================
-- 8. BEGIN TRANSACTION TEST
-- =========================================================

begin;


do $verification$
declare
    v_care_group_id uuid;

    v_creator_staff_id uuid;

    v_student_id uuid;

    v_reviewer_staff_id uuid;

    v_academic_year_start date;

    v_academic_year_end date;

    v_test_date date;

    v_test_session text;

    v_journal_id uuid;

    v_entry_id uuid;

    v_review_id uuid;

    v_child_entry_count integer;

    v_child_review_count integer;
begin

    -- =====================================================
    -- A. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_start,
        v_academic_year_end

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_start is null
       or v_academic_year_end is null
    then
        raise exception
            'Tahun ajaran aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. FIND VALID CARE GROUP + PENGASUH + STUDENT
    -- =====================================================

    select
        care_group.id,
        assignment.staff_id,
        membership.student_id

    into
        v_care_group_id,
        v_creator_staff_id,
        v_student_id

    from public.care_groups
        as care_group

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

    inner join public.caregiver_assignments
        as assignment
        on assignment.care_group_id =
           care_group.id

       and assignment.is_active =
           true

    inner join public.staff
        as staff
        on staff.id =
           assignment.staff_id

       and staff.is_active =
           true

    inner join public.care_group_members
        as membership
        on membership.care_group_id =
           care_group.id

       and membership.is_active =
           true

    inner join public.students
        as student
        on student.id =
           membership.student_id

       and student.status =
           'active'

       and student.deleted_at
           is null

    where care_group.is_active =
          true

      and academic_year.is_current =
          true

    order by
        care_group.name,
        staff.full_name,
        student.full_name

    limit 1;


    if v_care_group_id is null
       or v_creator_staff_id is null
       or v_student_id is null
    then
        raise exception
            'Data kelompok, Pengasuh, atau santri untuk verification tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. FIND ACTIVE KEPALA MA'HAD
    -- =====================================================

    select
        staff.id

    into
        v_reviewer_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile
        on profile.id =
           staff.profile_id

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

    order by
        staff.full_name,
        staff.id

    limit 1;


    if v_reviewer_staff_id is null then
        raise exception
            'Kepala Ma''had aktif untuk verification tidak ditemukan.';
    end if;


    -- =====================================================
    -- D. FIND FREE GROUP + DATE + SESSION
    --
    -- Supaya script tetap bisa digunakan ulang walaupun
    -- suatu saat jurnal produksi sudah ada.
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
                as session

        from generate_series(
            v_academic_year_start::timestamp,
            v_academic_year_end::timestamp,
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
                  v_care_group_id

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


    if v_test_date is null
       or v_test_session is null
    then
        raise exception
            'Tidak tersedia slot jurnal kosong untuk verification.';
    end if;


    -- =====================================================
    -- E. CREATE VALID TEST JOURNAL
    -- =====================================================

    insert into public.care_journals (
        care_group_id,
        journal_date,
        session,
        status,
        submission_version,
        created_by_staff_id,
        updated_by_staff_id
    )

    values (
        v_care_group_id,
        v_test_date,
        v_test_session,
        'draft',
        0,
        v_creator_staff_id,
        v_creator_staff_id
    )

    returning id
    into v_journal_id;


    if v_journal_id is null then
        raise exception
            'Gagal membuat jurnal test.';
    end if;


    raise notice
        'VALID JOURNAL INSERT SUCCESS';


    -- =====================================================
    -- F. DUPLICATE GROUP + DATE + SESSION MUST FAIL
    -- =====================================================

    begin

        insert into public.care_journals (
            care_group_id,
            journal_date,
            session,
            status,
            submission_version,
            created_by_staff_id,
            updated_by_staff_id
        )

        values (
            v_care_group_id,
            v_test_date,
            v_test_session,
            'draft',
            0,
            v_creator_staff_id,
            v_creator_staff_id
        );


        raise exception
            'Duplicate journal berhasil dibuat.';

    exception
        when unique_violation then
            null;
    end;


    raise notice
        'JOURNAL UNIQUE GROUP/DATE/SESSION SUCCESS';


    -- =====================================================
    -- G. INVALID SESSION MUST FAIL
    -- =====================================================

    begin

        insert into public.care_journals (
            care_group_id,
            journal_date,
            session,
            status,
            submission_version,
            created_by_staff_id,
            updated_by_staff_id
        )

        values (
            v_care_group_id,
            v_test_date,
            'night',
            'draft',
            0,
            v_creator_staff_id,
            v_creator_staff_id
        );


        raise exception
            'Session invalid berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'INVALID JOURNAL SESSION PROTECTION SUCCESS';


    -- =====================================================
    -- H. INVALID STATUS MUST FAIL
    -- =====================================================

    begin

        update public.care_journals

        set
            status =
                'approved'

        where id =
              v_journal_id;


        raise exception
            'Status invalid berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'INVALID JOURNAL STATUS PROTECTION SUCCESS';


    -- =====================================================
    -- I. NEGATIVE SUBMISSION VERSION MUST FAIL
    -- =====================================================

    begin

        update public.care_journals

        set
            submission_version =
                -1

        where id =
              v_journal_id;


        raise exception
            'Submission version negatif berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'INVALID SUBMISSION VERSION PROTECTION SUCCESS';


    -- =====================================================
    -- J. CREATE VALID STUDENT ENTRY
    -- =====================================================

    insert into public.care_journal_entries (
        journal_id,
        student_id,
        health_condition,
        sleep_compliance,
        psychological_condition,
        parent_visit,
        case_notes,
        handling_notes,
        updated_by_staff_id
    )

    values (
        v_journal_id,
        v_student_id,
        'healthy',
        'on_time',
        'cheerful',
        false,
        null,
        null,
        v_creator_staff_id
    )

    returning id
    into v_entry_id;


    if v_entry_id is null then
        raise exception
            'Gagal membuat entry jurnal test.';
    end if;


    raise notice
        'VALID JOURNAL ENTRY INSERT SUCCESS';


    -- =====================================================
    -- K. SAME STUDENT DUPLICATE MUST FAIL
    -- =====================================================

    begin

        insert into public.care_journal_entries (
            journal_id,
            student_id,
            health_condition,
            sleep_compliance,
            psychological_condition,
            parent_visit,
            updated_by_staff_id
        )

        values (
            v_journal_id,
            v_student_id,
            'healthy',
            'on_time',
            'cheerful',
            false,
            v_creator_staff_id
        );


        raise exception
            'Santri duplikat berhasil dimasukkan ke jurnal yang sama.';

    exception
        when unique_violation then
            null;
    end;


    raise notice
        'JOURNAL STUDENT UNIQUE SUCCESS';


    -- =====================================================
    -- L. INVALID HEALTH CONDITION MUST FAIL
    -- =====================================================

    begin

        update public.care_journal_entries

        set
            health_condition =
                'very_healthy'

        where id =
              v_entry_id;


        raise exception
            'Health condition invalid berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'INVALID HEALTH CONDITION PROTECTION SUCCESS';


    -- =====================================================
    -- M. INVALID SLEEP COMPLIANCE MUST FAIL
    -- =====================================================

    begin

        update public.care_journal_entries

        set
            sleep_compliance =
                'late'

        where id =
              v_entry_id;


        raise exception
            'Sleep compliance invalid berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'INVALID SLEEP COMPLIANCE PROTECTION SUCCESS';


    -- =====================================================
    -- N. INVALID PSYCHOLOGICAL CONDITION MUST FAIL
    -- =====================================================

    begin

        update public.care_journal_entries

        set
            psychological_condition =
                'angry'

        where id =
              v_entry_id;


        raise exception
            'Psychological condition invalid berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'INVALID PSYCHOLOGICAL CONDITION PROTECTION SUCCESS';


    -- =====================================================
    -- O. PREPARE SUBMISSION VERSION 1
    -- =====================================================

    update public.care_journals

    set
        status =
            'submitted',

        submission_version =
            1,

        submitted_by_staff_id =
            v_creator_staff_id,

        submitted_at =
            now()

    where id =
          v_journal_id;


    -- =====================================================
    -- P. REVISION REQUEST WITHOUT NOTE MUST FAIL
    -- =====================================================

    begin

        insert into public.care_journal_reviews (
            journal_id,
            reviewer_staff_id,
            submission_version,
            action,
            note
        )

        values (
            v_journal_id,
            v_reviewer_staff_id,
            1,
            'revision_requested',
            null
        );


        raise exception
            'Revision request tanpa catatan berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'REVISION NOTE REQUIREMENT SUCCESS';


    -- =====================================================
    -- Q. INVALID REVIEW ACTION MUST FAIL
    -- =====================================================

    begin

        insert into public.care_journal_reviews (
            journal_id,
            reviewer_staff_id,
            submission_version,
            action,
            note
        )

        values (
            v_journal_id,
            v_reviewer_staff_id,
            1,
            'approved',
            'Test'
        );


        raise exception
            'Review action invalid berhasil disimpan.';

    exception
        when check_violation then
            null;
    end;


    raise notice
        'INVALID REVIEW ACTION PROTECTION SUCCESS';


    -- =====================================================
    -- R. VALID REVISION REQUEST
    -- =====================================================

    insert into public.care_journal_reviews (
        journal_id,
        reviewer_staff_id,
        submission_version,
        action,
        note
    )

    values (
        v_journal_id,
        v_reviewer_staff_id,
        1,
        'revision_requested',
        'Catatan verification permintaan revisi.'
    )

    returning id
    into v_review_id;


    if v_review_id is null then
        raise exception
            'Gagal membuat review test.';
    end if;


    raise notice
        'VALID JOURNAL REVIEW INSERT SUCCESS';


    -- =====================================================
    -- S. CHILD ROWS MUST EXIST BEFORE CASCADE TEST
    -- =====================================================

    select
        count(*)::integer

    into
        v_child_entry_count

    from public.care_journal_entries

    where journal_id =
          v_journal_id;


    select
        count(*)::integer

    into
        v_child_review_count

    from public.care_journal_reviews

    where journal_id =
          v_journal_id;


    if v_child_entry_count <> 1 then
        raise exception
            'Jumlah test entry sebelum cascade tidak sesuai: %.',
            v_child_entry_count;
    end if;


    if v_child_review_count <> 1 then
        raise exception
            'Jumlah test review sebelum cascade tidak sesuai: %.',
            v_child_review_count;
    end if;


    -- =====================================================
    -- T. CASCADE DELETE
    -- =====================================================

    delete from public.care_journals

    where id =
          v_journal_id;


    if exists (
        select 1

        from public.care_journal_entries

        where journal_id =
              v_journal_id
    ) then
        raise exception
            'Entry jurnal tidak terhapus melalui cascade.';
    end if;


    if exists (
        select 1

        from public.care_journal_reviews

        where journal_id =
              v_journal_id
    ) then
        raise exception
            'Review jurnal tidak terhapus melalui cascade.';
    end if;


    raise notice
        'JOURNAL CHILD CASCADE DELETE SUCCESS';


    -- =====================================================
    -- U. FINAL
    -- =====================================================

    raise notice
        'CARE JOURNAL STRUCTURE VERIFICATION SUCCESS';

end;
$verification$;


-- =========================================================
-- 9. ROLLBACK ALL TEST DATA
-- =========================================================

rollback;


-- =========================================================
-- 10. FINAL OUTPUT
-- =========================================================

select
    'Struktur Jurnal Pengasuhan berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;