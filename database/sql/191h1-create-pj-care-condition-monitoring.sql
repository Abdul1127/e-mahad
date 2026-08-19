-- ============================================================
-- E-MA'HAD
-- STAGE 191H-1
--
-- PENANGGUNG JAWAB
-- CARE CONDITION MONITORING
--
-- READ ONLY
--
-- Menampilkan kondisi individual santri dari Jurnal Pengasuhan
-- yang sudah masuk workflow resmi:
--
-- - submitted
-- - revision_requested
-- - reviewed
--
-- Draft TIDAK ditampilkan kepada Penanggung Jawab.
--
-- Tidak menyediakan fungsi edit / review.
-- Tidak memuat data keuangan.
-- ============================================================


create or replace function public.get_penanggung_jawab_care_condition_monitoring(
    p_condition text default 'exception',
    p_search text default null,
    p_date date default null,
    p_page integer default 1,
    p_page_size integer default 20
)
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
    -- FILTER
    -- ========================================================

    v_condition text;

    v_search text;

    v_effective_date date;

    v_page integer;

    v_page_size integer;


    -- ========================================================
    -- SUMMARY
    -- ========================================================

    v_total_count integer := 0;

    v_exception_count integer := 0;

    v_attention_count integer := 0;

    v_unwell_count integer := 0;

    v_sleep_attention_count integer := 0;

    v_psychological_count integer := 0;

    v_note_count integer := 0;

    v_parent_visit_count integer := 0;

    v_normal_count integer := 0;


    -- ========================================================
    -- PAGINATION
    -- ========================================================

    v_filtered_count integer := 0;

    v_total_pages integer := 1;

    v_offset integer := 0;


    -- ========================================================
    -- RESULT
    -- ========================================================

    v_items jsonb :=
        '[]'::jsonb;

begin

    -- ========================================================
    -- 01. AUTHENTICATION
    -- ========================================================

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message =
                'Pengguna belum terautentikasi.';
    end if;


    -- ========================================================
    -- 02. ROLE
    -- ========================================================

    if not public.has_role(
        'penanggung_jawab'
    ) then
        raise exception using
            errcode = '42501',
            message =
                'Akses monitoring kondisi Pengasuhan ditolak.';
    end if;


    -- ========================================================
    -- 03. ACTIVE PROFILE
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
            message =
                'Profile Penanggung Jawab tidak aktif.';
    end if;


    -- ========================================================
    -- 04. ACTIVE STAFF
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
            message =
                'Data staf Penanggung Jawab aktif tidak ditemukan.';
    end if;


    -- ========================================================
    -- 05. CURRENT ACADEMIC YEAR
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
    -- 06. NORMALIZE FILTER
    -- ========================================================

    v_condition :=
        lower(
            btrim(
                coalesce(
                    p_condition,
                    'exception'
                )
            )
        );


    if v_condition not in (
        'all',
        'exception',
        'attention',
        'unwell',
        'needs_reminder',
        'psychological',
        'case_notes',
        'parent_visit',
        'normal'
    ) then
        raise exception
            'Filter kondisi Pengasuhan tidak valid.';
    end if;


    v_search :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_search,
                        ''
                    )
                )
            ),
            ''
        );


    if v_search is not null
       and char_length(v_search) > 100
    then
        raise exception
            'Pencarian maksimal 100 karakter.';
    end if;


    v_page :=
        greatest(
            coalesce(
                p_page,
                1
            ),
            1
        );


    v_page_size :=
        least(
            greatest(
                coalesce(
                    p_page_size,
                    20
                ),
                1
            ),
            50
        );


    -- ========================================================
    -- 07. EFFECTIVE DATE
    --
    -- Kalau tanggal tidak dipilih:
    -- gunakan tanggal jurnal resmi paling baru.
    -- ========================================================

    if p_date is not null then

        if p_date <
           v_academic_year_start

           or p_date >
              v_academic_year_end
        then
            raise exception
                'Tanggal berada di luar tahun ajaran aktif.';
        end if;


        v_effective_date :=
            p_date;

    else

        select
            max(
                journal.journal_date
            )

        into
            v_effective_date

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

          and journal.status in (
              'submitted',
              'revision_requested',
              'reviewed'
          );


        if v_effective_date is null then
            v_effective_date :=
                least(
                    v_academic_year_end,
                    greatest(
                        v_academic_year_start,
                        current_date
                    )
                );
        end if;

    end if;


    -- ========================================================
    -- 08. SUMMARY
    -- ========================================================

    with base as (
        select
            entry.id,

            (
                entry.health_condition =
                    'healthy'

                and entry.sleep_compliance =
                    'on_time'

                and entry.psychological_condition =
                    'cheerful'

                and entry.parent_visit =
                    false

                and nullif(
                    btrim(
                        coalesce(
                            entry.case_notes,
                            ''
                        )
                    ),
                    ''
                ) is null

                and nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is null
            ) as is_normal,

            (
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

                or nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null
            ) as needs_attention,

            (
                nullif(
                    btrim(
                        coalesce(
                            entry.case_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null

                or nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null
            ) as has_notes,

            entry.health_condition,

            entry.sleep_compliance,

            entry.psychological_condition,

            entry.parent_visit

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

          and journal.journal_date =
              v_effective_date

          and journal.status in (
              'submitted',
              'revision_requested',
              'reviewed'
          )
    )

    select
        count(*)::integer,

        count(*) filter (
            where is_normal
                  is not true
        )::integer,

        count(*) filter (
            where needs_attention =
                  true
        )::integer,

        count(*) filter (
            where health_condition =
                  'unwell'
        )::integer,

        count(*) filter (
            where sleep_compliance =
                  'needs_reminder'
        )::integer,

        count(*) filter (
            where psychological_condition in (
                'gloomy',
                'quiet',
                'homesick',
                'emotional'
            )
        )::integer,

        count(*) filter (
            where has_notes =
                  true
        )::integer,

        count(*) filter (
            where parent_visit =
                  true
        )::integer,

        count(*) filter (
            where is_normal =
                  true
        )::integer

    into
        v_total_count,
        v_exception_count,
        v_attention_count,
        v_unwell_count,
        v_sleep_attention_count,
        v_psychological_count,
        v_note_count,
        v_parent_visit_count,
        v_normal_count

    from base;


    -- ========================================================
    -- 09. FILTERED COUNT
    -- ========================================================

    with base as (
        select
            entry.id,

            student.full_name,
            student.nis,
            student.legacy_student_id,

            care_group.name
                as group_name,

            (
                entry.health_condition =
                    'healthy'

                and entry.sleep_compliance =
                    'on_time'

                and entry.psychological_condition =
                    'cheerful'

                and entry.parent_visit =
                    false

                and nullif(
                    btrim(
                        coalesce(
                            entry.case_notes,
                            ''
                        )
                    ),
                    ''
                ) is null

                and nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is null
            ) as is_normal,

            (
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

                or nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null
            ) as needs_attention,

            (
                nullif(
                    btrim(
                        coalesce(
                            entry.case_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null

                or nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null
            ) as has_notes,

            entry.health_condition,

            entry.sleep_compliance,

            entry.psychological_condition,

            entry.parent_visit

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

          and journal.journal_date =
              v_effective_date

          and journal.status in (
              'submitted',
              'revision_requested',
              'reviewed'
          )
    ),

    filtered as (
        select
            *

        from base

        where (
            v_search is null

            or lower(
                full_name
            ) like
                '%' || v_search || '%'

            or lower(
                coalesce(
                    nis,
                    ''
                )
            ) like
                '%' || v_search || '%'

            or lower(
                coalesce(
                    legacy_student_id,
                    ''
                )
            ) like
                '%' || v_search || '%'

            or lower(
                group_name
            ) like
                '%' || v_search || '%'
        )

        and (
            v_condition =
                'all'

            or (
                v_condition =
                    'exception'

                and is_normal
                    is not true
            )

            or (
                v_condition =
                    'attention'

                and needs_attention =
                    true
            )

            or (
                v_condition =
                    'unwell'

                and health_condition =
                    'unwell'
            )

            or (
                v_condition =
                    'needs_reminder'

                and sleep_compliance =
                    'needs_reminder'
            )

            or (
                v_condition =
                    'psychological'

                and psychological_condition in (
                    'gloomy',
                    'quiet',
                    'homesick',
                    'emotional'
                )
            )

            or (
                v_condition =
                    'case_notes'

                and has_notes =
                    true
            )

            or (
                v_condition =
                    'parent_visit'

                and parent_visit =
                    true
            )

            or (
                v_condition =
                    'normal'

                and is_normal =
                    true
            )
        )
    )

    select
        count(*)::integer

    into
        v_filtered_count

    from filtered;


    v_total_pages :=
        greatest(
            1,
            ceil(
                v_filtered_count::numeric
                /
                v_page_size::numeric
            )::integer
        );


    v_page :=
        least(
            v_page,
            v_total_pages
        );


    v_offset :=
        (
            v_page -
            1
        )
        *
        v_page_size;


    -- ========================================================
    -- 10. RESULT ITEMS
    -- ========================================================

    with base as (
        select
            entry.id,

            entry.student_id,

            student.legacy_student_id,

            student.nis,

            student.full_name,

            student.gender::text
                as gender,

            entry.health_condition,

            entry.sleep_compliance,

            entry.psychological_condition,

            entry.parent_visit,

            entry.case_notes,

            entry.handling_notes,

            entry.updated_at,

            journal.id
                as journal_id,

            journal.journal_date,

            journal.session,

            journal.status,

            journal.submission_version,

            care_group.id
                as care_group_id,

            care_group.code
                as care_group_code,

            care_group.name
                as care_group_name,

            care_group.gender::text
                as care_group_gender,

            (
                entry.health_condition =
                    'healthy'

                and entry.sleep_compliance =
                    'on_time'

                and entry.psychological_condition =
                    'cheerful'

                and entry.parent_visit =
                    false

                and nullif(
                    btrim(
                        coalesce(
                            entry.case_notes,
                            ''
                        )
                    ),
                    ''
                ) is null

                and nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is null
            ) as is_normal,

            (
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

                or nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null
            ) as needs_attention,

            (
                nullif(
                    btrim(
                        coalesce(
                            entry.case_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null

                or nullif(
                    btrim(
                        coalesce(
                            entry.handling_notes,
                            ''
                        )
                    ),
                    ''
                ) is not null
            ) as has_notes,

            current_class.class_id,

            current_class.class_name,

            current_class.grade_level

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

        where care_group.academic_year_id =
              v_academic_year_id

          and care_group.is_active =
              true

          and student.status =
              'active'

          and student.deleted_at
              is null

          and journal.journal_date =
              v_effective_date

          and journal.status in (
              'submitted',
              'revision_requested',
              'reviewed'
          )
    ),

    filtered as (
        select
            *

        from base

        where (
            v_search is null

            or lower(
                full_name
            ) like
                '%' || v_search || '%'

            or lower(
                coalesce(
                    nis,
                    ''
                )
            ) like
                '%' || v_search || '%'

            or lower(
                coalesce(
                    legacy_student_id,
                    ''
                )
            ) like
                '%' || v_search || '%'

            or lower(
                care_group_name
            ) like
                '%' || v_search || '%'
        )

        and (
            v_condition =
                'all'

            or (
                v_condition =
                    'exception'

                and is_normal
                    is not true
            )

            or (
                v_condition =
                    'attention'

                and needs_attention =
                    true
            )

            or (
                v_condition =
                    'unwell'

                and health_condition =
                    'unwell'
            )

            or (
                v_condition =
                    'needs_reminder'

                and sleep_compliance =
                    'needs_reminder'
            )

            or (
                v_condition =
                    'psychological'

                and psychological_condition in (
                    'gloomy',
                    'quiet',
                    'homesick',
                    'emotional'
                )
            )

            or (
                v_condition =
                    'case_notes'

                and has_notes =
                    true
            )

            or (
                v_condition =
                    'parent_visit'

                and parent_visit =
                    true
            )

            or (
                v_condition =
                    'normal'

                and is_normal =
                    true
            )
        )
    ),

    paged as (
        select
            *

        from filtered

        order by
            care_group_name,

            case
                when session =
                     'morning'
                then 1

                when session =
                     'evening'
                then 2

                else 3
            end,

            full_name,
            student_id

        limit
            v_page_size

        offset
            v_offset
    )

    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    paged.id,

                    'student_id',
                    paged.student_id,

                    'legacy_student_id',
                    paged.legacy_student_id,

                    'nis',
                    paged.nis,

                    'full_name',
                    paged.full_name,

                    'gender',
                    paged.gender,

                    'health_condition',
                    paged.health_condition,

                    'sleep_compliance',
                    paged.sleep_compliance,

                    'psychological_condition',
                    paged.psychological_condition,

                    'parent_visit',
                    paged.parent_visit,

                    'case_notes',
                    paged.case_notes,

                    'handling_notes',
                    paged.handling_notes,

                    'updated_at',
                    paged.updated_at,

                    'is_normal',
                    paged.is_normal,

                    'needs_attention',
                    paged.needs_attention,

                    'has_notes',
                    paged.has_notes,

                    'journal',
                    jsonb_build_object(
                        'id',
                        paged.journal_id,

                        'journal_date',
                        paged.journal_date,

                        'session',
                        paged.session,

                        'status',
                        paged.status,

                        'submission_version',
                        paged.submission_version
                    ),

                    'care_group',
                    jsonb_build_object(
                        'id',
                        paged.care_group_id,

                        'code',
                        paged.care_group_code,

                        'name',
                        paged.care_group_name,

                        'gender',
                        paged.care_group_gender
                    ),

                    'class',
                    case
                        when paged.class_id
                             is null
                        then null

                        else jsonb_build_object(
                            'id',
                            paged.class_id,

                            'name',
                            paged.class_name,

                            'grade_level',
                            paged.grade_level
                        )
                    end
                )

                order by
                    paged.care_group_name,

                    case
                        when paged.session =
                             'morning'
                        then 1

                        when paged.session =
                             'evening'
                        then 2

                        else 3
                    end,

                    paged.full_name,
                    paged.student_id
            ),
            '[]'::jsonb
        )

    into
        v_items

    from paged;


    -- ========================================================
    -- 11. RESPONSE
    -- ========================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'access_mode',
        'penanggung_jawab_read_only_care_conditions',

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

        'filters',
        jsonb_build_object(
            'condition',
            v_condition,

            'search',
            v_search,

            'requested_date',
            p_date,

            'effective_date',
            v_effective_date,

            'page',
            v_page,

            'page_size',
            v_page_size
        ),

        'summary',
        jsonb_build_object(
            'total_count',
            coalesce(
                v_total_count,
                0
            ),

            'exception_count',
            coalesce(
                v_exception_count,
                0
            ),

            'attention_count',
            coalesce(
                v_attention_count,
                0
            ),

            'unwell_count',
            coalesce(
                v_unwell_count,
                0
            ),

            'sleep_attention_count',
            coalesce(
                v_sleep_attention_count,
                0
            ),

            'psychological_count',
            coalesce(
                v_psychological_count,
                0
            ),

            'note_count',
            coalesce(
                v_note_count,
                0
            ),

            'parent_visit_count',
            coalesce(
                v_parent_visit_count,
                0
            ),

            'normal_count',
            coalesce(
                v_normal_count,
                0
            )
        ),

        'pagination',
        jsonb_build_object(
            'filtered_count',
            coalesce(
                v_filtered_count,
                0
            ),

            'page',
            v_page,

            'page_size',
            v_page_size,

            'total_pages',
            v_total_pages
        ),

        'items',
        coalesce(
            v_items,
            '[]'::jsonb
        )
    );

end;
$function$;


-- ============================================================
-- SECURITY
-- ============================================================

revoke all
on function public.get_penanggung_jawab_care_condition_monitoring(
    text,
    text,
    date,
    integer,
    integer
)
from public;


revoke all
on function public.get_penanggung_jawab_care_condition_monitoring(
    text,
    text,
    date,
    integer,
    integer
)
from anon;


grant execute
on function public.get_penanggung_jawab_care_condition_monitoring(
    text,
    text,
    date,
    integer,
    integer
)
to authenticated;


grant execute
on function public.get_penanggung_jawab_care_condition_monitoring(
    text,
    text,
    date,
    integer,
    integer
)
to service_role;


comment on function public.get_penanggung_jawab_care_condition_monitoring(
    text,
    text,
    date,
    integer,
    integer
)
is
'Monitoring kondisi individual Jurnal Pengasuhan read-only untuk Penanggung Jawab. Hanya jurnal submitted, revision_requested, dan reviewed. Draft dan data keuangan tidak ditampilkan.';