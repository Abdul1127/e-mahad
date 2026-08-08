begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 096-create-pengasuh-care-journal-functions.sql
--
-- PURPOSE:
-- - Dashboard / overview Jurnal Pengasuhan
-- - Create / open jurnal
-- - Detail jurnal + entry santri
-- - Simpan kondisi santri
-- - Submit jurnal untuk review Kepala Ma'had
--
-- SECURITY:
-- - Seluruh scope berasal dari auth.uid()
-- - Hanya role Pengasuh aktif
-- - Hanya care group assignment aktif milik Pengasuh
-- - Tidak menerima staff_id dari client
-- =========================================================


-- =========================================================
-- 1. GET PENGASUH JOURNAL OVERVIEW
-- =========================================================

create or replace function
public.get_pengasuh_journal_overview(
    p_date date default current_date
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_login_id text;

    v_staff_id uuid;
    v_legacy_staff_id text;
    v_staff_name text;
    v_staff_position text;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_start_date date;
    v_end_date date;

    v_groups jsonb;

    v_group_count integer;
    v_journal_count integer;
    v_draft_count integer;
    v_submitted_count integer;
    v_revision_count integer;
    v_reviewed_count integer;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();

    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Jurnal Pengasuhan ditolak.';
    end if;


    -- =====================================================
    -- B. PROFILE
    -- =====================================================

    select
        profile.login_id

    into
        v_login_id

    from public.profiles
        as profile

    where profile.id =
          v_profile_id

      and profile.is_active =
          true;


    if not found then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    -- =====================================================
    -- C. STAFF
    -- =====================================================

    select
        staff.id,
        staff.legacy_staff_id,
        staff.full_name,
        staff.position

    into
        v_staff_id,
        v_legacy_staff_id,
        v_staff_name,
        v_staff_position

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- D. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.name,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
        v_academic_year_name,
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
            'Tahun ajaran aktif belum tersedia.';
    end if;


    if p_date is null then
        raise exception
            'Tanggal jurnal wajib diisi.';
    end if;


    if p_date < v_start_date
       or p_date > v_end_date
    then
        raise exception
            'Tanggal jurnal berada di luar tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- E. GROUP COUNT
    -- =====================================================

    select
        count(
            distinct care_group.id
        )::integer

    into
        v_group_count

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
          v_academic_year_id;


    -- =====================================================
    -- F. JOURNAL COUNTS FOR SELECTED DATE
    -- =====================================================

    select
        count(
            distinct journal.id
        )::integer,

        count(
            distinct journal.id
        ) filter (
            where journal.status =
                  'draft'
        )::integer,

        count(
            distinct journal.id
        ) filter (
            where journal.status =
                  'submitted'
        )::integer,

        count(
            distinct journal.id
        ) filter (
            where journal.status =
                  'revision_requested'
        )::integer,

        count(
            distinct journal.id
        ) filter (
            where journal.status =
                  'reviewed'
        )::integer

    into
        v_journal_count,
        v_draft_count,
        v_submitted_count,
        v_revision_count,
        v_reviewed_count

    from public.caregiver_assignments
        as assignment

    inner join public.care_groups
        as care_group
        on care_group.id =
           assignment.care_group_id

    inner join public.care_journals
        as journal
        on journal.care_group_id =
           care_group.id

       and journal.journal_date =
           p_date

    where assignment.staff_id =
          v_staff_id

      and assignment.is_active =
          true

      and care_group.is_active =
          true

      and care_group.academic_year_id =
          v_academic_year_id;


    -- =====================================================
    -- G. GROUP DATA
    -- =====================================================

    select coalesce(
        jsonb_agg(
            group_data.payload

            order by
                group_data.group_name,
                group_data.group_id
        ),
        '[]'::jsonb
    )

    into
        v_groups

    from (
        select
            care_group.id
                as group_id,

            care_group.name
                as group_name,

            jsonb_build_object(
                'id',
                care_group.id,

                'code',
                care_group.code,

                'name',
                care_group.name,

                'gender',
                care_group.gender::text,

                'active_student_count',
                (
                    select
                        count(*)::integer

                    from public.care_group_members
                        as membership

                    inner join public.students
                        as student
                        on student.id =
                           membership.student_id

                    where membership.care_group_id =
                          care_group.id

                      and membership.is_active =
                          true

                      and student.status =
                          'active'

                      and student.deleted_at
                          is null
                ),

                'journals',
                coalesce(
                    (
                        select
                            jsonb_agg(
                                jsonb_build_object(
                                    'id',
                                    journal.id,

                                    'session',
                                    journal.session,

                                    'status',
                                    journal.status,

                                    'submission_version',
                                    journal.submission_version,

                                    'submitted_at',
                                    journal.submitted_at,

                                    'last_reviewed_at',
                                    journal.last_reviewed_at,

                                    'created_at',
                                    journal.created_at,

                                    'updated_at',
                                    journal.updated_at,

                                    'entry_count',
                                    (
                                        select
                                            count(*)::integer

                                        from public.care_journal_entries
                                            as entry

                                        where entry.journal_id =
                                              journal.id
                                    ),

                                    'complete_entry_count',
                                    (
                                        select
                                            count(*)::integer

                                        from public.care_journal_entries
                                            as entry

                                        where entry.journal_id =
                                              journal.id

                                          and entry.health_condition
                                              is not null

                                          and entry.sleep_compliance
                                              is not null

                                          and entry.psychological_condition
                                              is not null

                                          and entry.parent_visit
                                              is not null
                                    )
                                )

                                order by
                                    case journal.session
                                        when 'morning'
                                            then 1
                                        when 'evening'
                                            then 2
                                        else 3
                                    end
                            )

                        from public.care_journals
                            as journal

                        where journal.care_group_id =
                              care_group.id

                          and journal.journal_date =
                              p_date
                    ),
                    '[]'::jsonb
                )
            ) as payload

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

        group by
            care_group.id,
            care_group.code,
            care_group.name,
            care_group.gender
    ) as group_data;


    -- =====================================================
    -- H. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'selected_date',
        p_date,

        'profile',
        jsonb_build_object(
            'id',
            v_profile_id,

            'login_id',
            v_login_id
        ),

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'legacy_staff_id',
            v_legacy_staff_id,

            'full_name',
            v_staff_name,

            'position',
            v_staff_position
        ),

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name,

            'start_date',
            v_start_date,

            'end_date',
            v_end_date
        ),

        'summary',
        jsonb_build_object(
            'group_count',
            coalesce(
                v_group_count,
                0
            ),

            'journal_count',
            coalesce(
                v_journal_count,
                0
            ),

            'draft_count',
            coalesce(
                v_draft_count,
                0
            ),

            'submitted_count',
            coalesce(
                v_submitted_count,
                0
            ),

            'revision_requested_count',
            coalesce(
                v_revision_count,
                0
            ),

            'reviewed_count',
            coalesce(
                v_reviewed_count,
                0
            )
        ),

        'groups',
        coalesce(
            v_groups,
            '[]'::jsonb
        )
    );

end;
$function$;


-- =========================================================
-- 2. CREATE OR OPEN JOURNAL
-- =========================================================

create or replace function
public.create_or_open_pengasuh_journal(
    p_care_group_id uuid,
    p_journal_date date,
    p_session text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_academic_year_id uuid;
    v_start_date date;
    v_end_date date;

    v_session text;

    v_journal_id uuid;
    v_status text;
    v_created boolean := false;

    v_entry_count integer;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses pembuatan Jurnal Pengasuhan ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. INPUT
    -- =====================================================

    if p_care_group_id is null then
        raise exception
            'Kelompok pengasuhan wajib dipilih.';
    end if;


    if p_journal_date is null then
        raise exception
            'Tanggal jurnal wajib diisi.';
    end if;


    v_session :=
        lower(
            btrim(
                coalesce(
                    p_session,
                    ''
                )
            )
        );


    if v_session not in (
        'morning',
        'evening'
    ) then
        raise exception
            'Sesi jurnal tidak valid.';
    end if;


    -- =====================================================
    -- C. CURRENT YEAR
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
            'Tahun ajaran aktif belum tersedia.';
    end if;


    if p_journal_date < v_start_date
       or p_journal_date > v_end_date
    then
        raise exception
            'Tanggal jurnal berada di luar tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- D. GROUP AUTHORIZATION
    -- =====================================================

    if not exists (
        select 1

        from public.caregiver_assignments
            as assignment

        inner join public.care_groups
            as care_group
            on care_group.id =
               assignment.care_group_id

        where assignment.staff_id =
              v_staff_id

          and assignment.care_group_id =
              p_care_group_id

          and assignment.is_active =
              true

          and care_group.is_active =
              true

          and care_group.academic_year_id =
              v_academic_year_id
    ) then
        raise exception using
            errcode = '42501',
            message = 'Anda tidak memiliki assignment aktif pada kelompok pengasuhan tersebut.';
    end if;


    -- =====================================================
    -- E. CREATE HEADER WHEN NOT EXISTS
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
        p_care_group_id,
        p_journal_date,
        v_session,
        'draft',
        0,
        v_staff_id,
        v_staff_id
    )

    on conflict (
        care_group_id,
        journal_date,
        session
    )
    do nothing

    returning
        id,
        status

    into
        v_journal_id,
        v_status;


    if v_journal_id is not null then
        v_created :=
            true;
    else

        select
            journal.id,
            journal.status

        into
            v_journal_id,
            v_status

        from public.care_journals
            as journal

        where journal.care_group_id =
              p_care_group_id

          and journal.journal_date =
              p_journal_date

          and journal.session =
              v_session;

    end if;


    if v_journal_id is null then
        raise exception
            'Jurnal Pengasuhan gagal dibuat atau dibuka.';
    end if;


    -- =====================================================
    -- F. INITIALIZE ACTIVE STUDENTS
    --
    -- Hanya ketika jurnal benar-benar baru dibuat.
    -- =====================================================

    if v_created then

        insert into public.care_journal_entries (
            journal_id,
            student_id,
            updated_by_staff_id
        )

        select
            v_journal_id,
            membership.student_id,
            v_staff_id

        from public.care_group_members
            as membership

        inner join public.students
            as student
            on student.id =
               membership.student_id

        where membership.care_group_id =
              p_care_group_id

          and membership.is_active =
              true

          and student.status =
              'active'

          and student.deleted_at
              is null

        on conflict (
            journal_id,
            student_id
        )
        do nothing;

    end if;


    -- =====================================================
    -- G. COUNT ENTRIES
    -- =====================================================

    select
        count(*)::integer

    into
        v_entry_count

    from public.care_journal_entries
        as entry

    where entry.journal_id =
          v_journal_id;


    -- =====================================================
    -- H. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'created',
        v_created,

        'journal_id',
        v_journal_id,

        'care_group_id',
        p_care_group_id,

        'journal_date',
        p_journal_date,

        'session',
        v_session,

        'status',
        v_status,

        'entry_count',
        coalesce(
            v_entry_count,
            0
        )
    );

end;
$function$;


-- =========================================================
-- 3. GET JOURNAL DETAIL
-- =========================================================

create or replace function
public.get_pengasuh_journal_detail(
    p_journal_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_academic_year_id uuid;

    v_journal jsonb;
    v_entries jsonb;
    v_reviews jsonb;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses detail Jurnal Pengasuhan ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    if p_journal_id is null then
        raise exception
            'Journal ID wajib diisi.';
    end if;


    -- =====================================================
    -- B. CURRENT YEAR
    -- =====================================================

    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;


    -- =====================================================
    -- C. JOURNAL + AUTHORIZATION
    -- =====================================================

    select
        jsonb_build_object(
            'id',
            journal.id,

            'journal_date',
            journal.journal_date,

            'session',
            journal.session,

            'status',
            journal.status,

            'submission_version',
            journal.submission_version,

            'submitted_at',
            journal.submitted_at,

            'last_reviewed_at',
            journal.last_reviewed_at,

            'created_at',
            journal.created_at,

            'updated_at',
            journal.updated_at,

            'care_group',
            jsonb_build_object(
                'id',
                care_group.id,

                'code',
                care_group.code,

                'name',
                care_group.name,

                'gender',
                care_group.gender::text
            )
        )

    into
        v_journal

    from public.care_journals
        as journal

    inner join public.care_groups
        as care_group
        on care_group.id =
           journal.care_group_id

    where journal.id =
          p_journal_id

      and care_group.is_active =
          true

      and care_group.academic_year_id =
          v_academic_year_id

      and exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.care_group_id =
                care_group.id

            and assignment.is_active =
                true
      );


    if v_journal is null then
        raise exception using
            errcode = '42501',
            message = 'Jurnal tidak ditemukan atau berada di luar assignment Anda.';
    end if;


    -- =====================================================
    -- D. ENTRIES
    -- =====================================================

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                entry.id,

                'student_id',
                student.id,

                'legacy_student_id',
                student.legacy_student_id,

                'nis',
                student.nis,

                'full_name',
                student.full_name,

                'gender',
                student.gender::text,

                'health_condition',
                entry.health_condition,

                'sleep_compliance',
                entry.sleep_compliance,

                'psychological_condition',
                entry.psychological_condition,

                'parent_visit',
                entry.parent_visit,

                'case_notes',
                entry.case_notes,

                'handling_notes',
                entry.handling_notes,

                'updated_at',
                entry.updated_at,

                'class',
                case
                    when current_class.class_id
                         is null
                    then null

                    else jsonb_build_object(
                        'id',
                        current_class.class_id,

                        'name',
                        current_class.class_name,

                        'grade_level',
                        current_class.grade_level
                    )
                end
            )

            order by
                student.full_name,
                student.id
        ),
        '[]'::jsonb
    )

    into
        v_entries

    from public.care_journal_entries
        as entry

    inner join public.students
        as student
        on student.id =
           entry.student_id

    left join lateral (
        select
            class.id
                as class_id,

            class.name
                as class_name,

            class.grade_level

        from public.class_enrollments
            as enrollment

        inner join public.classes
            as class
            on class.id =
               enrollment.class_id

        where enrollment.student_id =
              student.id

          and enrollment.is_active =
              true

          and class.is_active =
              true

          and class.academic_year_id =
              v_academic_year_id

        order by
            enrollment.enrolled_at desc,
            enrollment.created_at desc

        limit 1
    ) as current_class
        on true

    where entry.journal_id =
          p_journal_id;


    -- =====================================================
    -- E. REVIEW HISTORY
    -- =====================================================

    select coalesce(
        jsonb_agg(
            jsonb_build_object(
                'id',
                review.id,

                'submission_version',
                review.submission_version,

                'action',
                review.action,

                'note',
                review.note,

                'created_at',
                review.created_at,

                'reviewer',
                jsonb_build_object(
                    'staff_id',
                    reviewer.id,

                    'legacy_staff_id',
                    reviewer.legacy_staff_id,

                    'full_name',
                    reviewer.full_name,

                    'position',
                    reviewer.position
                )
            )

            order by
                review.created_at desc,
                review.id desc
        ),
        '[]'::jsonb
    )

    into
        v_reviews

    from public.care_journal_reviews
        as review

    inner join public.staff
        as reviewer
        on reviewer.id =
           review.reviewer_staff_id

    where review.journal_id =
          p_journal_id;


    -- =====================================================
    -- F. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'journal',
        v_journal,

        'summary',
        jsonb_build_object(
            'entry_count',
            jsonb_array_length(
                v_entries
            ),

            'complete_entry_count',
            (
                select
                    count(*)::integer

                from public.care_journal_entries
                    as entry

                where entry.journal_id =
                      p_journal_id

                  and entry.health_condition
                      is not null

                  and entry.sleep_compliance
                      is not null

                  and entry.psychological_condition
                      is not null

                  and entry.parent_visit
                      is not null
            ),

            'review_count',
            jsonb_array_length(
                v_reviews
            )
        ),

        'entries',
        v_entries,

        'reviews',
        v_reviews
    );

end;
$function$;


-- =========================================================
-- 4. SAVE ONE JOURNAL ENTRY
-- =========================================================

create or replace function
public.save_pengasuh_journal_entry(
    p_journal_id uuid,
    p_student_id uuid,
    p_health_condition text,
    p_sleep_compliance text,
    p_psychological_condition text,
    p_parent_visit boolean,
    p_case_notes text default null,
    p_handling_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_journal_status text;
    v_care_group_id uuid;

    v_health_condition text;
    v_sleep_compliance text;
    v_psychological_condition text;

    v_case_notes text;
    v_handling_notes text;

    v_entry_id uuid;
    v_new_status text;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses perubahan Jurnal Pengasuhan ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. JOURNAL
    -- =====================================================

    select
        journal.status,
        journal.care_group_id

    into
        v_journal_status,
        v_care_group_id

    from public.care_journals
        as journal

    where journal.id =
          p_journal_id;


    if not found then
        raise exception
            'Jurnal Pengasuhan tidak ditemukan.';
    end if;


    if not exists (
        select 1

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
              v_staff_id

          and assignment.care_group_id =
              v_care_group_id

          and assignment.is_active =
              true

          and care_group.is_active =
              true

          and academic_year.is_current =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Jurnal berada di luar assignment Pengasuh.';
    end if;


    -- =====================================================
    -- C. SUBMITTED JOURNAL IS TEMPORARILY LOCKED
    --
    -- Bukan permanent lock.
    -- Setelah review/revision, jurnal bisa diedit lagi.
    -- =====================================================

    if v_journal_status =
       'submitted'
    then
        raise exception
            'Jurnal sedang menunggu review Kepala Ma''had dan belum dapat diedit.';
    end if;


    -- =====================================================
    -- D. ENTRY MUST BELONG TO JOURNAL
    -- =====================================================

    select
        entry.id

    into
        v_entry_id

    from public.care_journal_entries
        as entry

    where entry.journal_id =
          p_journal_id

      and entry.student_id =
          p_student_id;


    if not found then
        raise exception
            'Santri tidak terdapat dalam jurnal tersebut.';
    end if;


    -- =====================================================
    -- E. NORMALIZE VALUES
    -- =====================================================

    v_health_condition :=
        lower(
            btrim(
                coalesce(
                    p_health_condition,
                    ''
                )
            )
        );


    if v_health_condition not in (
        'healthy',
        'unwell'
    ) then
        raise exception
            'Kondisi kesehatan tidak valid.';
    end if;


    v_sleep_compliance :=
        lower(
            btrim(
                coalesce(
                    p_sleep_compliance,
                    ''
                )
            )
        );


    if v_sleep_compliance not in (
        'on_time',
        'needs_reminder'
    ) then
        raise exception
            'Kepatuhan jam tidur tidak valid.';
    end if;


    v_psychological_condition :=
        lower(
            btrim(
                coalesce(
                    p_psychological_condition,
                    ''
                )
            )
        );


    if v_psychological_condition not in (
        'cheerful',
        'gloomy',
        'quiet',
        'homesick',
        'emotional'
    ) then
        raise exception
            'Kondisi psikologis tidak valid.';
    end if;


    if p_parent_visit is null then
        raise exception
            'Status kunjungan orang tua wajib diisi.';
    end if;


    v_case_notes :=
        nullif(
            btrim(
                coalesce(
                    p_case_notes,
                    ''
                )
            ),
            ''
        );


    v_handling_notes :=
        nullif(
            btrim(
                coalesce(
                    p_handling_notes,
                    ''
                )
            ),
            ''
        );


    -- =====================================================
    -- F. UPDATE ENTRY
    -- =====================================================

    update public.care_journal_entries

    set
        health_condition =
            v_health_condition,

        sleep_compliance =
            v_sleep_compliance,

        psychological_condition =
            v_psychological_condition,

        parent_visit =
            p_parent_visit,

        case_notes =
            v_case_notes,

        handling_notes =
            v_handling_notes,

        updated_by_staff_id =
            v_staff_id

    where id =
          v_entry_id;


    -- =====================================================
    -- G. HEADER STATUS AFTER EDIT
    --
    -- revision_requested / reviewed kembali draft
    -- ketika isi jurnal diubah.
    -- =====================================================

    if v_journal_status in (
        'revision_requested',
        'reviewed'
    ) then
        v_new_status :=
            'draft';
    else
        v_new_status :=
            v_journal_status;
    end if;


    update public.care_journals

    set
        status =
            v_new_status,

        updated_by_staff_id =
            v_staff_id,

        submitted_by_staff_id =
            case
                when v_new_status =
                     'draft'
                then null
                else submitted_by_staff_id
            end,

        submitted_at =
            case
                when v_new_status =
                     'draft'
                then null
                else submitted_at
            end

    where id =
          p_journal_id;


    -- =====================================================
    -- H. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'journal_id',
        p_journal_id,

        'student_id',
        p_student_id,

        'entry_id',
        v_entry_id,

        'status',
        v_new_status
    );

end;
$function$;


-- =========================================================
-- 5. SUBMIT JOURNAL FOR REVIEW
-- =========================================================

create or replace function
public.submit_pengasuh_journal(
    p_journal_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_journal_status text;
    v_care_group_id uuid;
    v_submission_version integer;

    v_required_student_count integer;
    v_complete_student_count integer;
    v_missing_student_count integer;

    v_new_submission_version integer;
begin

    -- =====================================================
    -- A. AUTH
    -- =====================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses submit Jurnal Pengasuhan ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        where profile.id =
              v_profile_id

          and profile.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. LOCK JOURNAL
    -- =====================================================

    select
        journal.status,
        journal.care_group_id,
        journal.submission_version

    into
        v_journal_status,
        v_care_group_id,
        v_submission_version

    from public.care_journals
        as journal

    where journal.id =
          p_journal_id

    for update;


    if not found then
        raise exception
            'Jurnal Pengasuhan tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. ASSIGNMENT AUTHORIZATION
    -- =====================================================

    if not exists (
        select 1

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
              v_staff_id

          and assignment.care_group_id =
              v_care_group_id

          and assignment.is_active =
              true

          and care_group.is_active =
              true

          and academic_year.is_current =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Jurnal berada di luar assignment Pengasuh.';
    end if;


    -- =====================================================
    -- D. STATUS
    -- =====================================================

    if v_journal_status =
       'submitted'
    then
        raise exception
            'Jurnal sudah dikirim dan sedang menunggu review Kepala Ma''had.';
    end if;


    if v_journal_status =
       'reviewed'
    then
        raise exception
            'Jurnal yang sudah direview harus diedit terlebih dahulu sebelum dikirim ulang.';
    end if;


    -- =====================================================
    -- E. CURRENT ACTIVE STUDENTS
    -- =====================================================

    select
        count(*)::integer

    into
        v_required_student_count

    from public.care_group_members
        as membership

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where membership.care_group_id =
          v_care_group_id

      and membership.is_active =
          true

      and student.status =
          'active'

      and student.deleted_at
          is null;


    if v_required_student_count = 0 then
        raise exception
            'Kelompok tidak memiliki santri aktif.';
    end if;


    -- =====================================================
    -- F. COMPLETE CURRENT MEMBERS
    -- =====================================================

    select
        count(*)::integer

    into
        v_complete_student_count

    from public.care_group_members
        as membership

    inner join public.students
        as student
        on student.id =
           membership.student_id

    inner join public.care_journal_entries
        as entry
        on entry.student_id =
           student.id

       and entry.journal_id =
           p_journal_id

    where membership.care_group_id =
          v_care_group_id

      and membership.is_active =
          true

      and student.status =
          'active'

      and student.deleted_at
          is null

      and entry.health_condition
          is not null

      and entry.sleep_compliance
          is not null

      and entry.psychological_condition
          is not null

      and entry.parent_visit
          is not null;


    v_missing_student_count :=
        v_required_student_count -
        v_complete_student_count;


    if v_missing_student_count > 0 then
        raise exception
            'Jurnal belum lengkap. Masih ada % santri yang belum diisi.',
            v_missing_student_count;
    end if;


    -- =====================================================
    -- G. SUBMIT
    -- =====================================================

    v_new_submission_version :=
        coalesce(
            v_submission_version,
            0
        ) + 1;


    update public.care_journals

    set
        status =
            'submitted',

        submission_version =
            v_new_submission_version,

        submitted_by_staff_id =
            v_staff_id,

        submitted_at =
            now(),

        updated_by_staff_id =
            v_staff_id

    where id =
          p_journal_id;


    -- =====================================================
    -- H. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'journal_id',
        p_journal_id,

        'status',
        'submitted',

        'submission_version',
        v_new_submission_version,

        'student_count',
        v_required_student_count,

        'submitted_at',
        now()
    );

end;
$function$;


-- =========================================================
-- 6. COMMENTS
-- =========================================================

comment on function
public.get_pengasuh_journal_overview(date)
is
'Overview Jurnal Pengasuhan berdasarkan auth.uid() dan assignment aktif Pengasuh.';


comment on function
public.create_or_open_pengasuh_journal(uuid,date,text)
is
'Membuat atau membuka jurnal kelompok Pengasuh. Jurnal baru otomatis menginisialisasi entry seluruh santri aktif kelompok.';


comment on function
public.get_pengasuh_journal_detail(uuid)
is
'Mengambil detail jurnal dan seluruh entry santri yang berada dalam assignment Pengasuh.';


comment on function
public.save_pengasuh_journal_entry(uuid,uuid,text,text,text,boolean,text,text)
is
'Menyimpan satu entry santri dalam Jurnal Pengasuhan. Jurnal submitted tidak dapat diedit; reviewed/revision_requested kembali draft ketika diedit.';


comment on function
public.submit_pengasuh_journal(uuid)
is
'Mengirim Jurnal Pengasuhan lengkap kepada Kepala Mahad untuk proses review.';


-- =========================================================
-- 7. PRIVILEGES
-- =========================================================

revoke all on function
public.get_pengasuh_journal_overview(date)
from public;

revoke all on function
public.get_pengasuh_journal_overview(date)
from anon;

grant execute on function
public.get_pengasuh_journal_overview(date)
to authenticated;


revoke all on function
public.create_or_open_pengasuh_journal(uuid,date,text)
from public;

revoke all on function
public.create_or_open_pengasuh_journal(uuid,date,text)
from anon;

grant execute on function
public.create_or_open_pengasuh_journal(uuid,date,text)
to authenticated;


revoke all on function
public.get_pengasuh_journal_detail(uuid)
from public;

revoke all on function
public.get_pengasuh_journal_detail(uuid)
from anon;

grant execute on function
public.get_pengasuh_journal_detail(uuid)
to authenticated;


revoke all on function
public.save_pengasuh_journal_entry(
    uuid,
    uuid,
    text,
    text,
    text,
    boolean,
    text,
    text
)
from public;

revoke all on function
public.save_pengasuh_journal_entry(
    uuid,
    uuid,
    text,
    text,
    text,
    boolean,
    text,
    text
)
from anon;

grant execute on function
public.save_pengasuh_journal_entry(
    uuid,
    uuid,
    text,
    text,
    text,
    boolean,
    text,
    text
)
to authenticated;


revoke all on function
public.submit_pengasuh_journal(uuid)
from public;

revoke all on function
public.submit_pengasuh_journal(uuid)
from anon;

grant execute on function
public.submit_pengasuh_journal(uuid)
to authenticated;


commit;