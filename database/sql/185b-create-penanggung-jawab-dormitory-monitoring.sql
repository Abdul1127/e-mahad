-- ============================================================
-- E-MA'HAD
-- STAGE 185B
--
-- PENANGGUNG JAWAB
-- MONITORING ASRAMA
--
-- READ ONLY EXECUTIVE MONITORING
--
-- SUMBER:
-- 1. Jurnal Pengasuhan
-- 2. Jurnal Kepala Ma'had
-- 3. Tahfiz
--
-- TIDAK MEMUAT DATA KEUANGAN
-- ============================================================


create or replace function public.get_penanggung_jawab_dormitory_monitoring()
returns jsonb
language plpgsql
stable
security definer
set search_path to ''
as $function$

declare

    -- ========================================================
    -- AUTH
    -- ========================================================

    v_profile_id uuid;

    v_login_id text;

    v_staff_id uuid;
    v_staff_name text;
    v_staff_position text;


    -- ========================================================
    -- ACADEMIC YEAR
    -- ========================================================

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;


    -- ========================================================
    -- CURRENT WEEK
    -- ========================================================

    v_week_start date;
    v_week_end date;


    -- ========================================================
    -- CARE / PENGASUHAN
    -- ========================================================

    v_care_group_count integer := 0;

    v_care_journal_count integer := 0;

    v_care_draft_count integer := 0;

    v_care_submitted_count integer := 0;

    v_care_revision_requested_count integer := 0;

    v_care_reviewed_count integer := 0;

    v_care_attention_student_count integer := 0;

    v_care_latest_journal_date date;

    v_care_recent_items jsonb :=
        '[]'::jsonb;


    -- ========================================================
    -- MAHAD HEAD JOURNAL
    -- ========================================================

    v_head_journal_submitted_count integer := 0;

    v_head_latest_journal_date date;

    v_head_latest_submitted_at timestamptz;

    v_head_latest_checked_count integer := 0;

    v_head_total_checklist_count integer := 0;

    v_head_latest_completion_percentage integer := 0;

    v_head_latest_item jsonb;


    -- ========================================================
    -- TAHFIZ
    -- ========================================================

    v_tahfiz_group_count integer := 0;

    v_tahfiz_student_count integer := 0;

    v_tahfiz_published_count integer := 0;

    v_tahfiz_missing_count integer := 0;

    v_tahfiz_attention_count integer := 0;

    v_tahfiz_completion_percentage integer := 0;

    v_tahfiz_groups jsonb :=
        '[]'::jsonb;

begin

    -- ========================================================
    -- 1. AUTHENTICATION
    -- ========================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- ========================================================
    -- 2. ROLE
    -- ========================================================

    if not public.has_role(
        'penanggung_jawab'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Monitoring Asrama Penanggung Jawab ditolak.';
    end if;


    -- ========================================================
    -- 3. ACTIVE PROFILE
    -- ========================================================

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
            message = 'Profile Penanggung Jawab tidak aktif.';
    end if;


    -- ========================================================
    -- 4. ACTIVE STAFF
    -- ========================================================

    select
        staff.id,
        staff.full_name,
        staff.position

    into
        v_staff_id,
        v_staff_name,
        v_staff_position

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Penanggung Jawab aktif tidak ditemukan.';
    end if;


    -- ========================================================
    -- 5. CURRENT ACADEMIC YEAR
    -- ========================================================

    select
        academic_year.id,
        academic_year.name,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
        v_academic_year_name,
        v_academic_year_start,
        v_academic_year_end

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


    -- ========================================================
    -- 6. CURRENT WEEK
    --
    -- Senin - Minggu.
    -- Sama dengan konsep pekan laporan Tahfiz.
    -- ========================================================

    v_week_start :=
        date_trunc(
            'week',
            current_date
        )::date;


    v_week_end :=
        v_week_start + 6;


    -- ========================================================
    -- 7. ACTIVE CARE GROUPS
    -- ========================================================

    select
        count(*)::integer

    into
        v_care_group_count

    from public.care_groups
        as care_group

    where care_group.academic_year_id =
          v_academic_year_id

      and care_group.is_active =
          true;


    -- ========================================================
    -- 8. CARE JOURNAL SUMMARY
    --
    -- PJ hanya memperoleh metadata monitoring.
    -- Tidak ada isi jurnal individual pada response ini.
    -- ========================================================

    select
        count(*)::integer,

        count(*) filter (
            where journal.status =
                  'draft'
        )::integer,

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

        max(
            journal.journal_date
        )

    into
        v_care_journal_count,
        v_care_draft_count,
        v_care_submitted_count,
        v_care_revision_requested_count,
        v_care_reviewed_count,
        v_care_latest_journal_date

    from public.care_journals
        as journal

    inner join public.care_groups
        as care_group

        on care_group.id =
           journal.care_group_id

    where care_group.academic_year_id =
          v_academic_year_id

      and care_group.is_active =
          true

      and journal.journal_date
          between
          v_week_start
          and
          v_week_end;


    -- ========================================================
    -- 9. CARE STUDENTS NEEDING ATTENTION
    --
    -- Unique santri pada jurnal pekan berjalan.
    --
    -- Indikasi:
    -- - kurang sehat
    -- - perlu teguran tidur
    -- - kondisi psikologis selain cheerful
    -- - ada catatan kasus
    -- ========================================================

    select
        count(
            distinct entry.student_id
        )::integer

    into
        v_care_attention_student_count

    from public.care_journal_entries
        as entry

    inner join public.care_journals
        as journal

        on journal.id =
           entry.journal_id

    inner join public.care_groups
        as care_group

        on care_group.id =
           journal.care_group_id

    inner join public.students
        as student

        on student.id =
           entry.student_id

    where care_group.academic_year_id =
          v_academic_year_id

      and care_group.is_active =
          true

      and student.status =
          'active'

      and student.deleted_at
          is null

      and journal.journal_date
          between
          v_week_start
          and
          v_week_end

      and (
          entry.health_condition =
              'unwell'

          or entry.sleep_compliance =
              'needs_reminder'

          or entry.psychological_condition in (
              'gloomy',
              'quiet',
              'homesick',
              'emotional'
          )

          or nullif(
              btrim(
                  coalesce(
                      entry.case_notes,
                      ''
                  )
              ),
              ''
          ) is not null
      );


    -- ========================================================
    -- 10. RECENT CARE JOURNALS
    --
    -- Metadata saja.
    -- Maksimal 5.
    -- ========================================================

    select
        coalesce(
            jsonb_agg(
                care_data.payload

                order by
                    care_data.journal_date desc,

                    case
                        when care_data.session =
                             'morning'
                        then 1

                        when care_data.session =
                             'evening'
                        then 2

                        else 3
                    end,

                    care_data.group_name
            ),
            '[]'::jsonb
        )

    into
        v_care_recent_items

    from (
        select
            journal.id
                as journal_id,

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

                'entry_count',
                (
                    select
                        count(*)::integer

                    from public.care_journal_entries
                        as entry_count

                    where entry_count.journal_id =
                          journal.id
                ),

                'attention_student_count',
                (
                    select
                        count(
                            distinct attention_entry.student_id
                        )::integer

                    from public.care_journal_entries
                        as attention_entry

                    where attention_entry.journal_id =
                          journal.id

                      and (
                          attention_entry.health_condition =
                              'unwell'

                          or attention_entry.sleep_compliance =
                              'needs_reminder'

                          or attention_entry.psychological_condition in (
                              'gloomy',
                              'quiet',
                              'homesick',
                              'emotional'
                          )

                          or nullif(
                              btrim(
                                  coalesce(
                                      attention_entry.case_notes,
                                      ''
                                  )
                              ),
                              ''
                          ) is not null
                      )
                )
            )
                as payload

        from public.care_journals
            as journal

        inner join public.care_groups
            as care_group

            on care_group.id =
               journal.care_group_id

        where care_group.academic_year_id =
              v_academic_year_id

          and care_group.is_active =
              true

          and journal.journal_date
              between
              v_week_start
              and
              v_week_end

        order by
            journal.journal_date desc,

            case
                when journal.session =
                     'morning'
                then 1

                when journal.session =
                     'evening'
                then 2

                else 3
            end,

            care_group.name

        limit 5
    )
        as care_data;


    -- ========================================================
    -- 11. HEAD JOURNAL ACTIVE CHECKLIST COUNT
    -- ========================================================

    select
        count(*)::integer

    into
        v_head_total_checklist_count

    from public.mahad_head_journal_checklist_items
        as checklist_item

    where checklist_item.is_active =
          true;


    -- ========================================================
    -- 12. HEAD JOURNAL SUMMARY
    --
    -- PJ hanya boleh melihat jurnal submitted.
    -- ========================================================

    select
        count(*)::integer,

        max(
            journal.journal_date
        )

    into
        v_head_journal_submitted_count,
        v_head_latest_journal_date

    from public.mahad_head_journals
        as journal

    where journal.academic_year_id =
          v_academic_year_id

      and journal.status =
          'submitted'

      and journal.journal_date
          between
          v_week_start
          and
          v_week_end;


    -- ========================================================
    -- 13. LATEST SUBMITTED HEAD JOURNAL
    -- ========================================================

    select
        journal.submitted_at,

        (
            select
                count(*)::integer

            from public.mahad_head_journal_checks
                as journal_check

            where journal_check.journal_id =
                  journal.id
        ),

        jsonb_build_object(
            'id',
            journal.id,

            'journal_date',
            journal.journal_date,

            'status',
            journal.status,

            'submitted_at',
            journal.submitted_at,

            'has_evidence',
            journal.evidence_path
                is not null,

            'checked_count',
            (
                select
                    count(*)::integer

                from public.mahad_head_journal_checks
                    as journal_check

                where journal_check.journal_id =
                      journal.id
            ),

            'total_checklist_count',
            v_head_total_checklist_count,

            'staff',
            jsonb_build_object(
                'id',
                creator.id,

                'full_name',
                creator.full_name,

                'position',
                creator.position
            )
        )

    into
        v_head_latest_submitted_at,
        v_head_latest_checked_count,
        v_head_latest_item

    from public.mahad_head_journals
        as journal

    inner join public.staff
        as creator

        on creator.id =
           journal.created_by_staff_id

    where journal.academic_year_id =
          v_academic_year_id

      and journal.status =
          'submitted'

      and journal.journal_date
          between
          v_week_start
          and
          v_week_end

    order by
        journal.journal_date desc,
        journal.submitted_at desc nulls last,
        journal.id desc

    limit 1;


    if
        v_head_latest_checked_count is not null

        and v_head_total_checklist_count > 0
    then

        v_head_latest_completion_percentage :=
            least(
                100,
                round(
                    (
                        v_head_latest_checked_count::numeric
                        /
                        v_head_total_checklist_count::numeric
                    )
                    * 100
                )::integer
            );

    else

        v_head_latest_checked_count :=
            0;

        v_head_latest_completion_percentage :=
            0;

    end if;


    -- ========================================================
    -- 14. ACTIVE TAHFIZ GROUPS
    -- ========================================================

    select
        count(*)::integer

    into
        v_tahfiz_group_count

    from public.tahfiz_groups
        as tahfiz_group

    where tahfiz_group.academic_year_id =
          v_academic_year_id

      and tahfiz_group.is_active =
          true;


    -- ========================================================
    -- 15. ACTIVE TAHFIZ STUDENTS ON CURRENT WEEK
    -- ========================================================

    select
        count(
            distinct membership.student_id
        )::integer

    into
        v_tahfiz_student_count

    from public.tahfiz_group_members
        as membership

    inner join public.tahfiz_groups
        as tahfiz_group

        on tahfiz_group.id =
           membership.tahfiz_group_id

    inner join public.students
        as student

        on student.id =
           membership.student_id

    where tahfiz_group.academic_year_id =
          v_academic_year_id

      and tahfiz_group.is_active =
          true

      and student.status =
          'active'

      and student.deleted_at
          is null

      and membership.joined_at <=
          v_week_end

      and (
          membership.left_at
              is null

          or membership.left_at >=
             v_week_start
      );


    -- ========================================================
    -- 16. PUBLISHED TAHFIZ STUDENTS
    -- ========================================================

    select
        count(
            distinct report.student_id
        )::integer

    into
        v_tahfiz_published_count

    from public.tahfiz_weekly_reports
        as report

    inner join public.students
        as student

        on student.id =
           report.student_id

    where report.academic_year_id =
          v_academic_year_id

      and report.week_start =
          v_week_start

      and report.status =
          'published'

      and report.published_at
          is not null

      and student.status =
          'active'

      and student.deleted_at
          is null;


    v_tahfiz_missing_count :=
        greatest(
            v_tahfiz_student_count -
            v_tahfiz_published_count,
            0
        );


    -- ========================================================
    -- 17. TAHFIZ NEEDS ATTENTION
    -- ========================================================

    select
        count(
            distinct report.student_id
        )::integer

    into
        v_tahfiz_attention_count

    from public.tahfiz_weekly_reports
        as report

    inner join public.students
        as student

        on student.id =
           report.student_id

    where report.academic_year_id =
          v_academic_year_id

      and report.week_start =
          v_week_start

      and report.status =
          'published'

      and report.published_at
          is not null

      and student.status =
          'active'

      and student.deleted_at
          is null

      and (
          report.fluency_rating =
              'needs_guidance'

          or report.tajwid_rating =
              'needs_guidance'

          or report.consistency_rating =
              'needs_guidance'
      );


    if v_tahfiz_student_count > 0 then

        v_tahfiz_completion_percentage :=
            least(
                100,
                round(
                    (
                        v_tahfiz_published_count::numeric
                        /
                        v_tahfiz_student_count::numeric
                    )
                    * 100
                )::integer
            );

    else

        v_tahfiz_completion_percentage :=
            0;

    end if;


    -- ========================================================
    -- 18. TAHFIZ GROUP SUMMARY
    -- ========================================================

    select
        coalesce(
            jsonb_agg(
                group_data.payload

                order by
                    group_data.grade_level nulls last,
                    group_data.gender,
                    group_data.group_name
            ),
            '[]'::jsonb
        )

    into
        v_tahfiz_groups

    from (
        select
            tahfiz_group.grade_level,

            tahfiz_group.gender,

            tahfiz_group.name
                as group_name,

            jsonb_build_object(
                'id',
                tahfiz_group.id,

                'code',
                tahfiz_group.code,

                'name',
                tahfiz_group.name,

                'gender',
                tahfiz_group.gender::text,

                'grade_level',
                tahfiz_group.grade_level,

                'student_count',
                (
                    select
                        count(
                            distinct membership.student_id
                        )::integer

                    from public.tahfiz_group_members
                        as membership

                    inner join public.students
                        as student

                        on student.id =
                           membership.student_id

                    where membership.tahfiz_group_id =
                          tahfiz_group.id

                      and student.status =
                          'active'

                      and student.deleted_at
                          is null

                      and membership.joined_at <=
                          v_week_end

                      and (
                          membership.left_at
                              is null

                          or membership.left_at >=
                             v_week_start
                      )
                ),

                'published_count',
                (
                    select
                        count(
                            distinct report.student_id
                        )::integer

                    from public.tahfiz_weekly_reports
                        as report

                    inner join public.students
                        as student

                        on student.id =
                           report.student_id

                    where report.tahfiz_group_id =
                          tahfiz_group.id

                      and report.academic_year_id =
                          v_academic_year_id

                      and report.week_start =
                          v_week_start

                      and report.status =
                          'published'

                      and report.published_at
                          is not null

                      and student.status =
                          'active'

                      and student.deleted_at
                          is null
                ),

                'missing_count',
                greatest(
                    (
                        select
                            count(
                                distinct membership.student_id
                            )::integer

                        from public.tahfiz_group_members
                            as membership

                        inner join public.students
                            as student

                            on student.id =
                               membership.student_id

                        where membership.tahfiz_group_id =
                              tahfiz_group.id

                          and student.status =
                              'active'

                          and student.deleted_at
                              is null

                          and membership.joined_at <=
                              v_week_end

                          and (
                              membership.left_at
                                  is null

                              or membership.left_at >=
                                 v_week_start
                          )
                    )
                    -
                    (
                        select
                            count(
                                distinct report.student_id
                            )::integer

                        from public.tahfiz_weekly_reports
                            as report

                        inner join public.students
                            as student

                            on student.id =
                               report.student_id

                        where report.tahfiz_group_id =
                              tahfiz_group.id

                          and report.academic_year_id =
                              v_academic_year_id

                          and report.week_start =
                              v_week_start

                          and report.status =
                              'published'

                          and report.published_at
                              is not null

                          and student.status =
                              'active'

                          and student.deleted_at
                              is null
                    ),
                    0
                )
            )
                as payload

        from public.tahfiz_groups
            as tahfiz_group

        where tahfiz_group.academic_year_id =
              v_academic_year_id

          and tahfiz_group.is_active =
              true
    )
        as group_data;


    -- ========================================================
    -- 19. RESPONSE
    -- ========================================================

    return jsonb_build_object(

        'generated_at',
        now(),

        'access_mode',
        'penanggung_jawab_read_only_monitoring',

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
            v_academic_year_start,

            'end_date',
            v_academic_year_end
        ),

        'week',
        jsonb_build_object(
            'start',
            v_week_start,

            'end',
            v_week_end
        ),

        'care',
        jsonb_build_object(
            'summary',
            jsonb_build_object(
                'group_count',
                coalesce(
                    v_care_group_count,
                    0
                ),

                'journal_count',
                coalesce(
                    v_care_journal_count,
                    0
                ),

                'draft_count',
                coalesce(
                    v_care_draft_count,
                    0
                ),

                'submitted_count',
                coalesce(
                    v_care_submitted_count,
                    0
                ),

                'revision_requested_count',
                coalesce(
                    v_care_revision_requested_count,
                    0
                ),

                'reviewed_count',
                coalesce(
                    v_care_reviewed_count,
                    0
                ),

                'pending_review_count',
                coalesce(
                    v_care_submitted_count,
                    0
                ),

                'follow_up_count',
                coalesce(
                    v_care_revision_requested_count,
                    0
                ),

                'attention_student_count',
                coalesce(
                    v_care_attention_student_count,
                    0
                ),

                'latest_journal_date',
                v_care_latest_journal_date
            ),

            'recent_items',
            coalesce(
                v_care_recent_items,
                '[]'::jsonb
            )
        ),

        'mahad_head_journal',
        jsonb_build_object(
            'summary',
            jsonb_build_object(
                'submitted_count',
                coalesce(
                    v_head_journal_submitted_count,
                    0
                ),

                'latest_journal_date',
                v_head_latest_journal_date,

                'latest_submitted_at',
                v_head_latest_submitted_at,

                'latest_checked_count',
                coalesce(
                    v_head_latest_checked_count,
                    0
                ),

                'total_checklist_count',
                coalesce(
                    v_head_total_checklist_count,
                    0
                ),

                'latest_completion_percentage',
                coalesce(
                    v_head_latest_completion_percentage,
                    0
                )
            ),

            'latest_item',
            v_head_latest_item
        ),

        'tahfiz',
        jsonb_build_object(
            'summary',
            jsonb_build_object(
                'group_count',
                coalesce(
                    v_tahfiz_group_count,
                    0
                ),

                'student_count',
                coalesce(
                    v_tahfiz_student_count,
                    0
                ),

                'published_count',
                coalesce(
                    v_tahfiz_published_count,
                    0
                ),

                'missing_count',
                coalesce(
                    v_tahfiz_missing_count,
                    0
                ),

                'attention_count',
                coalesce(
                    v_tahfiz_attention_count,
                    0
                ),

                'completion_percentage',
                coalesce(
                    v_tahfiz_completion_percentage,
                    0
                )
            ),

            'groups',
            coalesce(
                v_tahfiz_groups,
                '[]'::jsonb
            )
        )
    );

end;

$function$;


-- ============================================================
-- SECURITY
-- ============================================================

revoke all
on function public.get_penanggung_jawab_dormitory_monitoring()
from public;


revoke all
on function public.get_penanggung_jawab_dormitory_monitoring()
from anon;


grant execute
on function public.get_penanggung_jawab_dormitory_monitoring()
to authenticated;


grant execute
on function public.get_penanggung_jawab_dormitory_monitoring()
to service_role;


comment on function public.get_penanggung_jawab_dormitory_monitoring()
is
'Monitoring Asrama read-only untuk Penanggung Jawab E-Ma''had. Menggabungkan metadata Pengasuhan, Jurnal Kepala Ma''had submitted, dan laporan Tahfiz published tanpa data keuangan.';