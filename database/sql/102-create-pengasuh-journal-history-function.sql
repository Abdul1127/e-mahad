begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 102-create-pengasuh-journal-history-function.sql
--
-- PURPOSE:
-- - Riwayat Jurnal Pengasuhan untuk Pengasuh
-- - Hanya menampilkan jurnal kelompok yang diampu
-- - Tahun ajaran aktif
-- - Filter:
--     status
--     session
--     tanggal
-- - Pagination
--
-- SECURITY:
-- - Berdasarkan auth.uid()
-- - Hanya role Pengasuh aktif
-- - Hanya care group assignment Pengasuh
-- =========================================================


create or replace function
public.get_pengasuh_journal_history(
    p_status text default null,
    p_session text default null,
    p_date date default null,
    p_limit integer default 50,
    p_offset integer default 0
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

    v_session text;

    v_total_count integer := 0;

    v_filtered_count integer := 0;

    v_draft_count integer := 0;

    v_submitted_count integer := 0;

    v_revision_requested_count integer := 0;

    v_reviewed_count integer := 0;

    v_items jsonb := '[]'::jsonb;
begin

    -- =====================================================
    -- A. AUTHENTICATION
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
            message = 'Akses Riwayat Pengasuhan ditolak.';
    end if;


    -- =====================================================
    -- B. ACTIVE PROFILE
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
    -- C. ACTIVE STAFF
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
            'Data staf aktif Pengasuh tidak ditemukan.';
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
    -- E. NORMALIZE STATUS FILTER
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


    -- =====================================================
    -- F. NORMALIZE SESSION FILTER
    -- =====================================================

    v_session :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_session,
                        ''
                    )
                )
            ),
            ''
        );


    if v_session is not null
       and v_session not in (
           'morning',
           'evening'
       )
    then
        raise exception
            'Filter sesi jurnal tidak valid.';
    end if;


    -- =====================================================
    -- G. DATE VALIDATION
    -- =====================================================

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
    -- H. PAGINATION VALIDATION
    -- =====================================================

    if p_limit is null
       or p_limit < 1
       or p_limit > 100
    then
        raise exception
            'Limit harus berada antara 1 sampai 100.';
    end if;


    if p_offset is null
       or p_offset < 0
    then
        raise exception
            'Offset tidak boleh negatif.';
    end if;


    -- =====================================================
    -- I. SUMMARY - ALL OWN JOURNALS
    -- =====================================================

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
        )::integer

    into
        v_total_count,
        v_draft_count,
        v_submitted_count,
        v_revision_requested_count,
        v_reviewed_count

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

      and exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.care_group_id =
                journal.care_group_id

            and assignment.is_active =
                true
      );


    -- =====================================================
    -- J. FILTERED COUNT
    -- =====================================================

    select
        count(*)::integer

    into
        v_filtered_count

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

      and exists (
          select 1

          from public.caregiver_assignments
              as assignment

          where assignment.staff_id =
                v_staff_id

            and assignment.care_group_id =
                journal.care_group_id

            and assignment.is_active =
                true
      )

      and (
          v_status is null

          or journal.status =
             v_status
      )

      and (
          v_session is null

          or journal.session =
             v_session
      )

      and (
          p_date is null

          or journal.journal_date =
             p_date
      );


    -- =====================================================
    -- K. HISTORY ITEMS
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                paged.payload

                order by
                    paged.journal_date desc,

                    case
                        paged.session
                        when 'morning'
                            then 1
                        when 'evening'
                            then 2
                        else 3
                    end,

                    paged.group_name
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

                'review_count',
                (
                    select
                        count(*)::integer

                    from public.care_journal_reviews
                        as review

                    where review.journal_id =
                          journal.id
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

          and exists (
              select 1

              from public.caregiver_assignments
                  as assignment

              where assignment.staff_id =
                    v_staff_id

                and assignment.care_group_id =
                    journal.care_group_id

                and assignment.is_active =
                    true
          )

          and (
              v_status is null

              or journal.status =
                 v_status
          )

          and (
              v_session is null

              or journal.session =
                 v_session
          )

          and (
              p_date is null

              or journal.journal_date =
                 p_date
          )

        order by
            journal.journal_date desc,

            case
                journal.session
                when 'morning'
                    then 1
                when 'evening'
                    then 2
                else 3
            end,

            care_group.name

        limit p_limit

        offset p_offset
    ) as paged;


    -- =====================================================
    -- L. RESPONSE
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

            'session',
            v_session,

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

        'pagination',
        jsonb_build_object(
            'limit',
            p_limit,

            'offset',
            p_offset,

            'filtered_count',
            coalesce(
                v_filtered_count,
                0
            ),

            'returned_count',
            jsonb_array_length(
                coalesce(
                    v_items,
                    '[]'::jsonb
                )
            ),

            'has_more',
            (
                p_offset +
                jsonb_array_length(
                    coalesce(
                        v_items,
                        '[]'::jsonb
                    )
                )
            ) <
            coalesce(
                v_filtered_count,
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


comment on function
public.get_pengasuh_journal_history(
    text,
    text,
    date,
    integer,
    integer
)
is
'Riwayat Jurnal Pengasuhan tahun ajaran aktif yang dibatasi pada care group assignment milik Pengasuh yang sedang login.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.get_pengasuh_journal_history(
    text,
    text,
    date,
    integer,
    integer
)
from public;


revoke all on function
public.get_pengasuh_journal_history(
    text,
    text,
    date,
    integer,
    integer
)
from anon;


grant execute on function
public.get_pengasuh_journal_history(
    text,
    text,
    date,
    integer,
    integer
)
to authenticated;


commit;