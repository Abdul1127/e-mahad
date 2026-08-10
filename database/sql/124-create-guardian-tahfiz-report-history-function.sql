begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 124-create-guardian-tahfiz-report-history-function.sql
--
-- PURPOSE:
-- Riwayat Laporan Tahfiz seorang anak untuk Orang Tua/Wali.
--
-- RULES:
-- - Hanya role guardian.
-- - Guardian/profile harus aktif.
-- - Student wajib terhubung dengan guardian melalui
--   guardian_students.
-- - Hanya laporan status PUBLISHED.
-- - Draft tidak pernah dikembalikan.
-- - Tahun ajaran aktif.
-- - Mendukung pagination.
--
-- SECURITY:
-- SECURITY DEFINER + explicit relationship authorization.
-- =========================================================


create or replace function
public.get_guardian_tahfiz_report_history(
    p_student_id uuid,
    p_limit integer default 20,
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

    v_guardian_id uuid;
    v_guardian_name text;

    v_academic_year_id uuid;
    v_academic_year_name text;
    v_academic_year_start date;
    v_academic_year_end date;

    v_student_name text;
    v_student_nis text;
    v_student_legacy_id text;
    v_student_gender text;

    v_relationship_type text;
    v_is_primary_contact boolean;

    v_limit integer;
    v_offset integer;

    v_total_count integer := 0;

    v_items jsonb := '[]'::jsonb;
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
        'guardian'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Riwayat Tahfiz Orang Tua/Wali ditolak.';
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
            message = 'Profile Orang Tua/Wali tidak aktif.';
    end if;


    -- =====================================================
    -- B. ACTIVE GUARDIAN
    -- =====================================================

    select
        guardian.id,
        guardian.full_name

    into
        v_guardian_id,
        v_guardian_name

    from public.guardians
        as guardian

    where guardian.profile_id =
          v_profile_id

      and guardian.is_active =
          true

    limit 1;


    if v_guardian_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data Orang Tua/Wali aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. INPUT
    -- =====================================================

    if p_student_id is null then
        raise exception
            'Student ID wajib diisi.';
    end if;


    v_limit :=
        least(
            greatest(
                coalesce(
                    p_limit,
                    20
                ),
                1
            ),
            100
        );


    v_offset :=
        greatest(
            coalesce(
                p_offset,
                0
            ),
            0
        );


    -- =====================================================
    -- D. VERIFY GUARDIAN ↔ STUDENT RELATION
    --
    -- Ini adalah security boundary utama.
    -- =====================================================

    select
        student.full_name,
        student.nis,
        student.legacy_student_id,
        student.gender::text,

        guardian_student.relationship_type,
        guardian_student.is_primary_contact

    into
        v_student_name,
        v_student_nis,
        v_student_legacy_id,
        v_student_gender,
        v_relationship_type,
        v_is_primary_contact

    from public.guardian_students
        as guardian_student

    inner join public.students
        as student
        on student.id =
           guardian_student.student_id

    where guardian_student.guardian_id =
          v_guardian_id

      and guardian_student.student_id =
          p_student_id

      and student.status =
          'active'

      and student.deleted_at
          is null

    limit 1;


    if not found then
        raise exception using
            errcode = '42501',
            message = 'Santri tidak terhubung dengan akun Orang Tua/Wali ini.';
    end if;


    -- =====================================================
    -- E. CURRENT ACADEMIC YEAR
    -- =====================================================

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


    -- =====================================================
    -- F. PUBLISHED REPORT COUNT
    -- =====================================================

    select
        count(*)::integer

    into
        v_total_count

    from public.tahfiz_weekly_reports
        as report

    where report.student_id =
          p_student_id

      and report.academic_year_id =
          v_academic_year_id

      and report.status =
          'published'

      and report.published_at
          is not null;


    -- =====================================================
    -- G. REPORT ITEMS
    --
    -- IMPORTANT:
    -- Semua filter published diterapkan di query database,
    -- bukan hanya disembunyikan oleh frontend.
    -- =====================================================

    select
        coalesce(
            jsonb_agg(
                report_data.payload

                order by
                    report_data.week_start desc,
                    report_data.published_at desc,
                    report_data.report_id desc
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            report.id
                as report_id,

            report.week_start,

            report.published_at,

            jsonb_build_object(
                'id',
                report.id,

                'week_start',
                report.week_start,

                'week_end',
                report.week_end,

                'memorization_achievement',
                report.memorization_achievement,

                'murajaah_achievement',
                report.murajaah_achievement,

                'fluency_rating',
                report.fluency_rating,

                'tajwid_rating',
                report.tajwid_rating,

                'consistency_rating',
                report.consistency_rating,

                'supervisor_notes',
                report.supervisor_notes,

                'next_week_target',
                report.next_week_target,

                'status',
                report.status,

                'published_at',
                report.published_at,

                'updated_at',
                report.updated_at,

                'tahfiz_group',
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
                    tahfiz_group.grade_level
                )
            ) as payload

        from public.tahfiz_weekly_reports
            as report

        inner join public.tahfiz_groups
            as tahfiz_group
            on tahfiz_group.id =
               report.tahfiz_group_id

        where report.student_id =
              p_student_id

          and report.academic_year_id =
              v_academic_year_id

          and report.status =
              'published'

          and report.published_at
              is not null

        order by
            report.week_start desc,
            report.published_at desc,
            report.id desc

        limit
            v_limit

        offset
            v_offset
    ) as report_data;


    -- =====================================================
    -- H. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'generated_at',
        now(),

        'guardian',
        jsonb_build_object(
            'id',
            v_guardian_id,

            'full_name',
            v_guardian_name
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

        'relationship',
        jsonb_build_object(
            'type',
            v_relationship_type,

            'is_primary_contact',
            v_is_primary_contact
        ),

        'student',
        jsonb_build_object(
            'id',
            p_student_id,

            'legacy_student_id',
            v_student_legacy_id,

            'nis',
            v_student_nis,

            'full_name',
            v_student_name,

            'gender',
            v_student_gender
        ),

        'summary',
        jsonb_build_object(
            'published_report_count',
            coalesce(
                v_total_count,
                0
            )
        ),

        'pagination',
        jsonb_build_object(
            'limit',
            v_limit,

            'offset',
            v_offset,

            'has_previous',
            v_offset > 0,

            'has_next',
            (
                v_offset +
                jsonb_array_length(
                    v_items
                )
            ) <
            v_total_count
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
public.get_guardian_tahfiz_report_history(
    uuid,
    integer,
    integer
)
is
'Riwayat laporan Tahfiz published untuk santri yang terhubung dengan akun Orang Tua/Wali.';


revoke all on function
public.get_guardian_tahfiz_report_history(
    uuid,
    integer,
    integer
)
from public;


revoke all on function
public.get_guardian_tahfiz_report_history(
    uuid,
    integer,
    integer
)
from anon;


grant execute on function
public.get_guardian_tahfiz_report_history(
    uuid,
    integer,
    integer
)
to authenticated;


commit;