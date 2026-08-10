-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 101-verify-kepala-mahad-care-journal-review-workflow.sql
--
-- PURPOSE:
-- - Verify workflow Pengasuh -> Kepala Ma'had
-- - Verify submit version 1
-- - Verify revision request + note
-- - Verify Pengasuh dapat revisi
-- - Verify resubmit version 2
-- - Verify Kepala Ma'had selesai review
-- - Verify review history
-- - Verify non-Kepala Ma'had ditolak
--
-- ALL TEST DATA WILL BE ROLLED BACK
-- =========================================================


-- =========================================================
-- 1. FUNCTION + PRIVILEGES
-- =========================================================

select
    to_regprocedure(
        'public.get_kepala_mahad_care_journal_overview(text,date)'
    ) is not null
        as overview_function_exists,

    to_regprocedure(
        'public.get_kepala_mahad_care_journal_detail(uuid)'
    ) is not null
        as detail_function_exists,

    to_regprocedure(
        'public.review_kepala_mahad_care_journal(uuid,text,text)'
    ) is not null
        as review_function_exists,

    has_function_privilege(
        'authenticated',
        'public.get_kepala_mahad_care_journal_overview(text,date)',
        'execute'
    ) as authenticated_can_overview,

    has_function_privilege(
        'authenticated',
        'public.get_kepala_mahad_care_journal_detail(uuid)',
        'execute'
    ) as authenticated_can_detail,

    has_function_privilege(
        'authenticated',
        'public.review_kepala_mahad_care_journal(uuid,text,text)',
        'execute'
    ) as authenticated_can_review,

    has_function_privilege(
        'anon',
        'public.get_kepala_mahad_care_journal_overview(text,date)',
        'execute'
    ) as anon_can_overview,

    has_function_privilege(
        'anon',
        'public.get_kepala_mahad_care_journal_detail(uuid)',
        'execute'
    ) as anon_can_detail,

    has_function_privilege(
        'anon',
        'public.review_kepala_mahad_care_journal(uuid,text,text)',
        'execute'
    ) as anon_can_review;


-- =========================================================
-- 2. BEGIN TEST
-- =========================================================

begin;


do $verification$
declare
    -- =====================================================
    -- PENGASUH
    -- =====================================================

    v_pengasuh_profile_id uuid;
    v_pengasuh_email text;

    v_pengasuh_staff_id uuid;
    v_pengasuh_name text;

    v_care_group_id uuid;
    v_care_group_name text;


    -- =====================================================
    -- KEPALA MA'HAD
    -- =====================================================

    v_kepala_profile_id uuid;
    v_kepala_email text;

    v_kepala_staff_id uuid;
    v_kepala_name text;


    -- =====================================================
    -- NON KEPALA MA'HAD
    -- =====================================================

    v_non_kepala_profile_id uuid;
    v_non_kepala_email text;


    -- =====================================================
    -- ACADEMIC YEAR / SLOT
    -- =====================================================

    v_start_date date;
    v_end_date date;

    v_test_date date;
    v_test_session text;


    -- =====================================================
    -- JOURNAL
    -- =====================================================

    v_journal_id uuid;

    v_special_student_id uuid;

    v_result jsonb;

    v_overview jsonb;

    v_detail jsonb;

    v_review_result jsonb;

    v_status text;

    v_submission_version integer;

    v_review_count integer;

    v_revision_count integer;

    v_reviewed_count integer;

begin

    -- =====================================================
    -- A. CURRENT ACADEMIC YEAR
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


    if v_start_date is null
       or v_end_date is null
    then
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
        staff.full_name,

        care_group.id,
        care_group.name

    into
        v_pengasuh_profile_id,
        v_pengasuh_email,

        v_pengasuh_staff_id,
        v_pengasuh_name,

        v_care_group_id,
        v_care_group_name

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
        care_group.name

    limit 1;


    if v_pengasuh_profile_id is null
       or v_care_group_id is null
    then
        raise exception
            'Pengasuh operational untuk test tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. PICK ACTIVE KEPALA MA'HAD
    -- =====================================================

    select
        profile.id,
        auth_user.email,

        staff.id,
        staff.full_name

    into
        v_kepala_profile_id,
        v_kepala_email,

        v_kepala_staff_id,
        v_kepala_name

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

    order by
        staff.full_name

    limit 1;


    if v_kepala_profile_id is null then
        raise exception
            'Kepala Ma''had aktif untuk test tidak ditemukan.';
    end if;


    raise notice
        'TEST PENGASUH: % | GROUP: %',
        v_pengasuh_name,
        v_care_group_name;


    raise notice
        'TEST KEPALA MAHAD: %',
        v_kepala_name;


    -- =====================================================
    -- D. FIND FREE JOURNAL SLOT
    -- =====================================================

    select
        free_slot.journal_date,
        free_slot.session

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
                  v_care_group_id

              and journal.journal_date =
                  generated.day_value::date

              and journal.session =
                  session_data.session
        )

        order by
            generated.day_value desc,
            session_data.session
    ) as free_slot

    limit 1;


    if v_test_date is null then
        raise exception
            'Tidak tersedia slot jurnal kosong untuk verification.';
    end if;


    -- =====================================================
    -- E. LOGIN AS PENGASUH
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_pengasuh_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_pengasuh_profile_id,

            'role',
            'authenticated',

            'email',
            v_pengasuh_email
        )::text,
        true
    );


    -- =====================================================
    -- F. CREATE JOURNAL
    -- =====================================================

    v_result :=
        public.create_or_open_pengasuh_journal(
            v_care_group_id,
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


    raise notice
        'PENGASUH CREATE JOURNAL SUCCESS';


    -- =====================================================
    -- G. FILL NORMAL
    -- =====================================================

    v_result :=
        public.fill_normal_pengasuh_journal_entries(
            v_journal_id
        );


    if (
        v_result
        ->> 'total_entry_count'
    )::integer <>
       (
        v_result
        ->> 'complete_entry_count'
       )::integer
    then
        raise exception
            'Bulk normal tidak melengkapi seluruh jurnal.';
    end if;


    raise notice
        'PENGASUH BULK NORMAL SUCCESS';


    -- =====================================================
    -- H. SUBMIT VERSION 1
    -- =====================================================

    v_result :=
        public.submit_pengasuh_journal(
            v_journal_id
        );


    if (
        v_result
        ->> 'submission_version'
    )::integer <> 1
    then
        raise exception
            'Submission pertama tidak menghasilkan version 1.';
    end if;


    if (
        v_result
        ->> 'status'
    ) <> 'submitted'
    then
        raise exception
            'Submission pertama tidak menghasilkan status submitted.';
    end if;


    raise notice
        'PENGASUH SUBMIT VERSION 1 SUCCESS';


    -- =====================================================
    -- I. LOGIN AS KEPALA MA'HAD
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
    -- J. OVERVIEW MUST CONTAIN SUBMITTED JOURNAL
    -- =====================================================

    v_overview :=
        public.get_kepala_mahad_care_journal_overview(
            'submitted',
            v_test_date
        );


    if not exists (
        select 1

        from jsonb_array_elements(
            v_overview -> 'items'
        ) as journal_item(item)

        where (
            journal_item.item
            ->> 'id'
        )::uuid =
        v_journal_id
    ) then
        raise exception
            'Jurnal submitted tidak muncul pada overview Kepala Ma''had.';
    end if;


    raise notice
        'KEPALA MAHAD OVERVIEW SUBMITTED SUCCESS';


    -- =====================================================
    -- K. DETAIL MUST BE COMPLETE
    -- =====================================================

    v_detail :=
        public.get_kepala_mahad_care_journal_detail(
            v_journal_id
        );


    if (
        v_detail
        #>> '{journal,status}'
    ) <> 'submitted'
    then
        raise exception
            'Detail Kepala Ma''had tidak menunjukkan status submitted.';
    end if;


    if (
        v_detail
        #>> '{summary,entry_count}'
    )::integer <>
       (
        v_detail
        #>> '{summary,complete_entry_count}'
       )::integer
    then
        raise exception
            'Jurnal yang diterima Kepala Ma''had belum lengkap.';
    end if;


    raise notice
        'KEPALA MAHAD JOURNAL DETAIL SUCCESS';


    -- =====================================================
    -- L. REVISION WITHOUT NOTE MUST FAIL
    -- =====================================================

    begin

        perform
            public.review_kepala_mahad_care_journal(
                v_journal_id,
                'revision_requested',
                null
            );


        raise exception
            'EXPECTED_REVISION_NOTE_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_REVISION_NOTE_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Catatan revisi wajib diisi%'
            then
                raise;
            end if;

    end;


    raise notice
        'REVISION NOTE REQUIREMENT SUCCESS';


    -- =====================================================
    -- M. REQUEST REVISION VERSION 1
    -- =====================================================

    v_review_result :=
        public.review_kepala_mahad_care_journal(
            v_journal_id,
            'revision_requested',
            'Mohon lengkapi kembali catatan penanganan salah satu santri.'
        );


    if (
        v_review_result
        ->> 'status'
    ) <> 'revision_requested'
    then
        raise exception
            'Status jurnal tidak menjadi revision_requested.';
    end if;


    if (
        v_review_result
        ->> 'submission_version'
    )::integer <> 1
    then
        raise exception
            'Review revisi tidak tercatat pada submission version 1.';
    end if;


    raise notice
        'KEPALA MAHAD REQUEST REVISION VERSION 1 SUCCESS';


    -- =====================================================
    -- N. CHECK REVIEW HISTORY VERSION 1
    -- =====================================================

    if not exists (
        select 1

        from public.care_journal_reviews
            as review

        where review.journal_id =
              v_journal_id

          and review.submission_version =
              1

          and review.action =
              'revision_requested'

          and review.reviewer_staff_id =
              v_kepala_staff_id
    ) then
        raise exception
            'Review history revision_requested version 1 tidak tersimpan.';
    end if;


    raise notice
        'REVIEW HISTORY VERSION 1 SUCCESS';


    -- =====================================================
    -- O. LOGIN BACK AS PENGASUH
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_pengasuh_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_pengasuh_profile_id,

            'role',
            'authenticated',

            'email',
            v_pengasuh_email
        )::text,
        true
    );


    -- =====================================================
    -- P. PICK ONE STUDENT FOR REVISION
    -- =====================================================

    select
        entry.student_id

    into
        v_special_student_id

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


    if v_special_student_id is null then
        raise exception
            'Santri untuk revision test tidak ditemukan.';
    end if;


    -- =====================================================
    -- Q. EDIT AFTER REVISION REQUEST
    -- =====================================================

    perform
        public.save_pengasuh_journal_entry(
            v_journal_id,
            v_special_student_id,
            'unwell',
            'needs_reminder',
            'quiet',
            false,
            'Santri memerlukan perhatian.',
            'Pengasuh melakukan pendampingan dan monitoring.'
        );


    select
        journal.status

    into
        v_status

    from public.care_journals
        as journal

    where journal.id =
          v_journal_id;


    if v_status <>
       'draft'
    then
        raise exception
            'Jurnal tidak kembali ke draft setelah direvisi Pengasuh.';
    end if;


    raise notice
        'PENGASUH EDIT REVISION -> DRAFT SUCCESS';


    -- =====================================================
    -- R. RESUBMIT VERSION 2
    -- =====================================================

    v_result :=
        public.submit_pengasuh_journal(
            v_journal_id
        );


    if (
        v_result
        ->> 'submission_version'
    )::integer <> 2
    then
        raise exception
            'Resubmit tidak menghasilkan submission version 2.';
    end if;


    raise notice
        'PENGASUH RESUBMIT VERSION 2 SUCCESS';


    -- =====================================================
    -- S. LOGIN AS KEPALA MA'HAD AGAIN
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
    -- T. COMPLETE REVIEW VERSION 2
    -- =====================================================

    v_review_result :=
        public.review_kepala_mahad_care_journal(
            v_journal_id,
            'reviewed',
            'Jurnal telah diperiksa dan dinyatakan sesuai.'
        );


    if (
        v_review_result
        ->> 'status'
    ) <> 'reviewed'
    then
        raise exception
            'Final review tidak menghasilkan status reviewed.';
    end if;


    if (
        v_review_result
        ->> 'submission_version'
    )::integer <> 2
    then
        raise exception
            'Final review tidak tercatat pada submission version 2.';
    end if;


    raise notice
        'KEPALA MAHAD REVIEW VERSION 2 SUCCESS';


    -- =====================================================
    -- U. VERIFY FINAL HEADER
    -- =====================================================

    select
        journal.status,
        journal.submission_version

    into
        v_status,
        v_submission_version

    from public.care_journals
        as journal

    where journal.id =
          v_journal_id;


    if v_status <>
       'reviewed'
    then
        raise exception
            'Final journal status bukan reviewed.';
    end if;


    if v_submission_version <>
       2
    then
        raise exception
            'Final submission version bukan 2.';
    end if;


    -- =====================================================
    -- V. VERIFY COMPLETE REVIEW HISTORY
    -- =====================================================

    select
        count(*)::integer,

        count(*) filter (
            where review.action =
                  'revision_requested'
        )::integer,

        count(*) filter (
            where review.action =
                  'reviewed'
        )::integer

    into
        v_review_count,
        v_revision_count,
        v_reviewed_count

    from public.care_journal_reviews
        as review

    where review.journal_id =
          v_journal_id;


    if v_review_count <> 2 then
        raise exception
            'Jumlah history review tidak sesuai. Expected 2, actual %.',
            v_review_count;
    end if;


    if v_revision_count <> 1 then
        raise exception
            'History revision_requested tidak sesuai.';
    end if;


    if v_reviewed_count <> 1 then
        raise exception
            'History reviewed tidak sesuai.';
    end if;


    raise notice
        'FULL REVIEW HISTORY SUCCESS: 2 REVIEWS';


    -- =====================================================
    -- W. REVIEWED JOURNAL CANNOT BE REVIEWED AGAIN
    -- =====================================================

    begin

        perform
            public.review_kepala_mahad_care_journal(
                v_journal_id,
                'reviewed',
                'Review ulang yang seharusnya ditolak.'
            );


        raise exception
            'EXPECTED_REVIEWED_STATUS_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_REVIEWED_STATUS_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%hanya dapat direview ketika berstatus submitted%'
            then
                raise;
            end if;

    end;


    raise notice
        'REVIEWED JOURNAL RE-REVIEW PROTECTION SUCCESS';


    -- =====================================================
    -- X. FIND NON KEPALA MA'HAD
    -- =====================================================

    select
        profile.id,
        auth_user.email

    into
        v_non_kepala_profile_id,
        v_non_kepala_email

    from public.profiles
        as profile

    inner join auth.users
        as auth_user
        on auth_user.id =
           profile.id

    where profile.is_active =
          true

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
                'kepala_mahad'
      )

    order by
        profile.created_at,
        profile.id

    limit 1;


    if v_non_kepala_profile_id is null then
        raise exception
            'Akun non-Kepala Ma''had untuk security test tidak ditemukan.';
    end if;


    -- =====================================================
    -- Y. LOGIN AS NON KEPALA MA'HAD
    -- =====================================================

    perform set_config(
        'request.jwt.claim.sub',
        v_non_kepala_profile_id::text,
        true
    );


    perform set_config(
        'request.jwt.claims',
        jsonb_build_object(
            'sub',
            v_non_kepala_profile_id,

            'role',
            'authenticated',

            'email',
            v_non_kepala_email
        )::text,
        true
    );


    -- =====================================================
    -- Z. NON KEPALA OVERVIEW MUST FAIL
    -- =====================================================

    begin

        perform
            public.get_kepala_mahad_care_journal_overview(
                null,
                v_test_date
            );


        raise exception
            'EXPECTED_NON_KEPALA_FAILURE';

    exception
        when others then

            if sqlerrm =
               'EXPECTED_NON_KEPALA_FAILURE'
            then
                raise;
            end if;


            if sqlerrm not ilike
               '%Akses review Jurnal Pengasuhan ditolak%'
            then
                raise;
            end if;

    end;


    raise notice
        'NON-KEPALA MAHAD ACCESS PROTECTION SUCCESS';


    -- =====================================================
    -- FINAL
    -- =====================================================

    raise notice
        'CARE JOURNAL END-TO-END WORKFLOW VERIFICATION SUCCESS';

end;
$verification$;


-- =========================================================
-- 3. ROLLBACK TEST DATA
-- =========================================================

rollback;


-- =========================================================
-- 4. FINAL OUTPUT
-- =========================================================

select
    'Workflow Pengasuh dan Kepala Ma''had berhasil diverifikasi.'
        as verification_status,

    now()
        as verified_at;