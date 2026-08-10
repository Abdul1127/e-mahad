begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 100-create-kepala-mahad-care-journal-review-functions.sql
--
-- PURPOSE:
-- - Overview jurnal untuk Kepala Ma'had
-- - Detail jurnal untuk proses review
-- - Selesai Direview
-- - Minta Revisi
-- - Menyimpan review history per submission version
--
-- SECURITY:
-- - Identitas reviewer berasal dari auth.uid()
-- - Hanya role kepala_mahad aktif
-- - Hanya jurnal pada tahun ajaran aktif
-- - Hanya jurnal berstatus submitted yang dapat direview
-- =========================================================


-- =========================================================
-- 1. GET KEPALA MA'HAD CARE JOURNAL OVERVIEW
-- =========================================================

create or replace function
public.get_kepala_mahad_care_journal_overview(
    p_status text default null,
    p_date date default null
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

    v_full_name text;

    v_position text;

    v_academic_year_id uuid;

    v_academic_year_name text;

    v_start_date date;

    v_end_date date;

    v_status text;

    v_items jsonb;

    v_total_count integer;

    v_submitted_count integer;

    v_revision_requested_count integer;

    v_reviewed_count integer;

    v_draft_count integer;
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
        'kepala_mahad'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses review Jurnal Pengasuhan ditolak.';
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
            message = 'Profile Kepala Ma''had tidak aktif.';
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
        v_full_name,
        v_position

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif Kepala Ma''had tidak ditemukan.';
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


    -- =====================================================
    -- E. FILTER STATUS
    -- =====================================================

    v_status :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_status,
                        ''
                    )
                )
            ),
            ''
        );


    if v_status is not null
       and v_status not in (
           'draft',
           'submitted',
           'revision_requested',
           'reviewed'
       )
    then
        raise exception
            'Filter status jurnal tidak valid.';
    end if;


    if p_date is not null
       and (
           p_date < v_start_date
           or p_date > v_end_date
       )
    then
        raise exception
            'Tanggal berada di luar tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- F. SUMMARY
    -- =====================================================

    select
        count(*)::integer,

        count(*) filter (
            where journal.status =
                  'submitted'
        )::integer,

        count(*) filter (
            where journal.status =
                  'revision_requested'
        )::integer,

        count(*) filter (
            where journal.status =
                  'reviewed'
        )::integer,

        count(*) filter (
            where journal.status =
                  'draft'
        )::integer

    into
        v_total_count,
        v_submitted_count,
        v_revision_requested_count,
        v_reviewed_count,
        v_draft_count

    from public.care_journals
        as journal

    inner join public.care_groups
        as care_group
        on care_group.id =
           journal.care_group_id

    where care_group.academic_year_id =
          v_academic_year_id

      and care_group.is_active =
          true;


    -- =====================================================
    -- G. JOURNAL ITEMS
    -- =====================================================

    select coalesce(
        jsonb_agg(
            item_data.payload

            order by
                item_data.journal_date desc,

                case
                    item_data.session
                    when 'morning'
                        then 1
                    when 'evening'
                        then 2
                    else 3
                end,

                item_data.group_name
        ),
        '[]'::jsonb
    )

    into
        v_items

    from (
        select
            journal.journal_date,

            journal.session,

            care_group.name
                as group_name,

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
                ),

                'created_by',
                jsonb_build_object(
                    'staff_id',
                    creator.id,

                    'legacy_staff_id',
                    creator.legacy_staff_id,

                    'full_name',
                    creator.full_name,

                    'position',
                    creator.position
                ),

                'submitted_by',
                case
                    when submitter.id
                         is null
                    then null

                    else jsonb_build_object(
                        'staff_id',
                        submitter.id,

                        'legacy_staff_id',
                        submitter.legacy_staff_id,

                        'full_name',
                        submitter.full_name,

                        'position',
                        submitter.position
                    )
                end,

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
                ),

                'latest_review',
                (
                    select
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

                            'reviewer_name',
                            reviewer.full_name
                        )

                    from public.care_journal_reviews
                        as review

                    inner join public.staff
                        as reviewer
                        on reviewer.id =
                           review.reviewer_staff_id

                    where review.journal_id =
                          journal.id

                    order by
                        review.created_at desc,
                        review.id desc

                    limit 1
                )
            ) as payload

        from public.care_journals
            as journal

        inner join public.care_groups
            as care_group
            on care_group.id =
               journal.care_group_id

        inner join public.staff
            as creator
            on creator.id =
               journal.created_by_staff_id

        left join public.staff
            as submitter
            on submitter.id =
               journal.submitted_by_staff_id

        where care_group.academic_year_id =
              v_academic_year_id

          and care_group.is_active =
              true

          and (
              v_status is null

              or journal.status =
                 v_status
          )

          and (
              p_date is null

              or journal.journal_date =
                 p_date
          )
    ) as item_data;


    -- =====================================================
    -- H. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

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
            v_full_name,

            'position',
            v_position
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

        'filters',
        jsonb_build_object(
            'status',
            v_status,

            'date',
            p_date
        ),

        'summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_total_count,
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
                v_revision_requested_count,
                0
            ),

            'reviewed_count',
            coalesce(
                v_reviewed_count,
                0
            )
        ),

        'items',
        coalesce(
            v_items,
            '[]'::jsonb
        )
    );

end;
$function$;


-- =========================================================
-- 2. GET JOURNAL DETAIL FOR KEPALA MA'HAD
-- =========================================================

create or replace function
public.get_kepala_mahad_care_journal_detail(
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
        'kepala_mahad'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses detail review Jurnal Pengasuhan ditolak.';
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
            message = 'Profile Kepala Ma''had tidak aktif.';
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
            'Data staf aktif Kepala Ma''had tidak ditemukan.';
    end if;


    if p_journal_id is null then
        raise exception
            'Journal ID wajib diisi.';
    end if;


    -- =====================================================
    -- B. CURRENT ACADEMIC YEAR
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
    -- C. HEADER
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
            ),

            'created_by',
            jsonb_build_object(
                'staff_id',
                creator.id,

                'legacy_staff_id',
                creator.legacy_staff_id,

                'full_name',
                creator.full_name,

                'position',
                creator.position
            ),

            'submitted_by',
            case
                when submitter.id
                     is null
                then null

                else jsonb_build_object(
                    'staff_id',
                    submitter.id,

                    'legacy_staff_id',
                    submitter.legacy_staff_id,

                    'full_name',
                    submitter.full_name,

                    'position',
                    submitter.position
                )
            end
        )

    into
        v_journal

    from public.care_journals
        as journal

    inner join public.care_groups
        as care_group
        on care_group.id =
           journal.care_group_id

    inner join public.staff
        as creator
        on creator.id =
           journal.created_by_staff_id

    left join public.staff
        as submitter
        on submitter.id =
           journal.submitted_by_staff_id

    where journal.id =
          p_journal_id

      and care_group.academic_year_id =
          v_academic_year_id;


    if v_journal is null then
        raise exception
            'Jurnal Pengasuhan tidak ditemukan pada tahun ajaran aktif.';
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
-- 3. REVIEW JOURNAL
-- =========================================================

create or replace function
public.review_kepala_mahad_care_journal(
    p_journal_id uuid,
    p_action text,
    p_note text default null
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

    v_submission_version integer;

    v_care_group_id uuid;

    v_action text;

    v_note text;

    v_review_id uuid;

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
        'kepala_mahad'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses review Jurnal Pengasuhan ditolak.';
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
            message = 'Profile Kepala Ma''had tidak aktif.';
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
            'Data staf aktif Kepala Ma''had tidak ditemukan.';
    end if;


    -- =====================================================
    -- B. INPUT
    -- =====================================================

    if p_journal_id is null then
        raise exception
            'Journal ID wajib diisi.';
    end if;


    v_action :=
        lower(
            btrim(
                coalesce(
                    p_action,
                    ''
                )
            )
        );


    if v_action not in (
        'reviewed',
        'revision_requested'
    ) then
        raise exception
            'Aksi review tidak valid.';
    end if;


    v_note :=
        nullif(
            btrim(
                coalesce(
                    p_note,
                    ''
                )
            ),
            ''
        );


    if v_action =
       'revision_requested'
       and v_note is null
    then
        raise exception
            'Catatan revisi wajib diisi.';
    end if;


    -- =====================================================
    -- C. LOCK JOURNAL
    -- =====================================================

    select
        journal.status,
        journal.submission_version,
        journal.care_group_id

    into
        v_journal_status,
        v_submission_version,
        v_care_group_id

    from public.care_journals
        as journal

    inner join public.care_groups
        as care_group
        on care_group.id =
           journal.care_group_id

    inner join public.academic_years
        as academic_year
        on academic_year.id =
           care_group.academic_year_id

    where journal.id =
          p_journal_id

      and academic_year.is_current =
          true

    for update of journal;


    if not found then
        raise exception
            'Jurnal Pengasuhan tidak ditemukan pada tahun ajaran aktif.';
    end if;


    -- =====================================================
    -- D. STATUS MUST BE SUBMITTED
    -- =====================================================

    if v_journal_status <>
       'submitted'
    then
        raise exception
            'Jurnal hanya dapat direview ketika berstatus submitted.';
    end if;


    if coalesce(
        v_submission_version,
        0
    ) <= 0
    then
        raise exception
            'Submission version jurnal tidak valid.';
    end if;


    -- =====================================================
    -- E. PROTECT DUPLICATE REVIEW FOR SAME VERSION
    -- =====================================================

    if exists (
        select 1

        from public.care_journal_reviews
            as review

        where review.journal_id =
              p_journal_id

          and review.submission_version =
              v_submission_version
    ) then
        raise exception
            'Submission versi ini sudah pernah direview.';
    end if;


    -- =====================================================
    -- F. INSERT REVIEW HISTORY
    -- =====================================================

    insert into public.care_journal_reviews (
        journal_id,
        reviewer_staff_id,
        submission_version,
        action,
        note
    )

    values (
        p_journal_id,
        v_staff_id,
        v_submission_version,
        v_action,
        v_note
    )

    returning id
    into v_review_id;


    -- =====================================================
    -- G. UPDATE JOURNAL
    -- =====================================================

    if v_action =
       'reviewed'
    then
        v_new_status :=
            'reviewed';
    else
        v_new_status :=
            'revision_requested';
    end if;


    update public.care_journals

    set
        status =
            v_new_status,

        last_reviewed_at =
            now()

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

        'review_id',
        v_review_id,

        'submission_version',
        v_submission_version,

        'action',
        v_action,

        'status',
        v_new_status,

        'note',
        v_note,

        'reviewed_by_staff_id',
        v_staff_id,

        'reviewed_at',
        now()
    );

end;
$function$;


-- =========================================================
-- 4. COMMENTS
-- =========================================================

comment on function
public.get_kepala_mahad_care_journal_overview(text,date)
is
'Overview Jurnal Pengasuhan untuk Kepala Mahad. Menampilkan jurnal tahun ajaran aktif dan dapat difilter berdasarkan status/tanggal.';


comment on function
public.get_kepala_mahad_care_journal_detail(uuid)
is
'Detail Jurnal Pengasuhan untuk proses review Kepala Mahad.';


comment on function
public.review_kepala_mahad_care_journal(uuid,text,text)
is
'Menyelesaikan review atau meminta revisi Jurnal Pengasuhan. Hanya jurnal submitted yang dapat direview dan history disimpan per submission version.';


-- =========================================================
-- 5. PRIVILEGES
-- =========================================================

revoke all on function
public.get_kepala_mahad_care_journal_overview(
    text,
    date
)
from public;

revoke all on function
public.get_kepala_mahad_care_journal_overview(
    text,
    date
)
from anon;

grant execute on function
public.get_kepala_mahad_care_journal_overview(
    text,
    date
)
to authenticated;


revoke all on function
public.get_kepala_mahad_care_journal_detail(
    uuid
)
from public;

revoke all on function
public.get_kepala_mahad_care_journal_detail(
    uuid
)
from anon;

grant execute on function
public.get_kepala_mahad_care_journal_detail(
    uuid
)
to authenticated;


revoke all on function
public.review_kepala_mahad_care_journal(
    uuid,
    text,
    text
)
from public;

revoke all on function
public.review_kepala_mahad_care_journal(
    uuid,
    text,
    text
)
from anon;

grant execute on function
public.review_kepala_mahad_care_journal(
    uuid,
    text,
    text
)
to authenticated;


commit;