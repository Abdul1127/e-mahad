begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 033-create-admin-student-list.sql
-- PURPOSE:
-- - Menyediakan daftar santri untuk Admin
-- - Mendukung pencarian
-- - Mendukung filter kelas, gender, pengasuhan, dan tahfiz
-- - Mendukung pagination
-- - Mengembalikan opsi filter dari tahun ajaran aktif
-- =========================================================

create or replace function public.get_admin_student_list(
    p_search text default null,
    p_grade_level integer default null,
    p_gender text default null,
    p_care_group_id uuid default null,
    p_tahfiz_group_id uuid default null,
    p_page integer default 1,
    p_page_size integer default 20
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_search text;
    v_gender text;

    v_page integer;
    v_page_size integer;
    v_offset integer;

    v_result jsonb;
begin
    -- =====================================================
    -- 1. VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses daftar santri ditolak.';
    end if;

    -- =====================================================
    -- 2. NORMALISASI PARAMETER
    -- =====================================================

    v_search := nullif(btrim(p_search), '');
    v_gender := nullif(lower(btrim(p_gender)), '');

    v_page := greatest(
        coalesce(p_page, 1),
        1
    );

    v_page_size := least(
        greatest(
            coalesce(p_page_size, 20),
            1
        ),
        100
    );

    v_offset := (v_page - 1) * v_page_size;

    if v_gender is not null
       and v_gender not in ('male', 'female') then
        raise exception
            'Filter gender harus bernilai male atau female.';
    end if;

    if p_grade_level is not null
       and p_grade_level not between 1 and 12 then
        raise exception
            'Tingkat kelas harus berada antara 1 dan 12.';
    end if;

    -- =====================================================
    -- 3. SUSUN RESPONSE
    -- =====================================================

    with current_year as (
        select
            academic_year.id,
            academic_year.name,
            academic_year.start_date,
            academic_year.end_date

        from public.academic_years as academic_year

        where academic_year.is_current = true

        order by academic_year.start_date desc
        limit 1
    ),

    base_students as (
        select
            student.id,
            student.legacy_student_id,
            student.nis,
            student.full_name,
            student.gender,
            student.photo_url,
            student.status,

            class_data.class_id,
            class_data.class_name,
            class_data.grade_level,

            care_data.care_group_id,
            care_data.care_group_name,

            tahfiz_data.tahfiz_group_id,
            tahfiz_data.tahfiz_group_name,

            coalesce(
                guardian_data.guardian_count,
                0
            )::integer as guardian_count

        from public.students as student

        -- =================================================
        -- KELAS AKTIF
        -- =================================================

        left join lateral (
            select
                class.id as class_id,
                class.name as class_name,
                class.grade_level

            from public.class_enrollments
                as enrollment

            inner join public.classes as class
                on class.id = enrollment.class_id
               and class.is_active = true

            inner join current_year as academic_year
                on academic_year.id =
                   class.academic_year_id

            where enrollment.student_id = student.id
              and enrollment.is_active = true

            limit 1
        ) as class_data
            on true

        -- =================================================
        -- KELOMPOK PENGASUHAN AKTIF
        -- =================================================

        left join lateral (
            select
                care_group.id as care_group_id,
                care_group.name as care_group_name

            from public.care_group_members
                as membership

            inner join public.care_groups
                as care_group
                on care_group.id =
                   membership.care_group_id
               and care_group.is_active = true

            inner join current_year as academic_year
                on academic_year.id =
                   care_group.academic_year_id

            where membership.student_id = student.id
              and membership.is_active = true

            limit 1
        ) as care_data
            on true

        -- =================================================
        -- KELOMPOK TAHFIZ AKTIF
        -- =================================================

        left join lateral (
            select
                tahfiz_group.id as tahfiz_group_id,
                tahfiz_group.name as tahfiz_group_name

            from public.tahfiz_group_members
                as membership

            inner join public.tahfiz_groups
                as tahfiz_group
                on tahfiz_group.id =
                   membership.tahfiz_group_id
               and tahfiz_group.is_active = true

            inner join current_year as academic_year
                on academic_year.id =
                   tahfiz_group.academic_year_id

            where membership.student_id = student.id
              and membership.is_active = true

            limit 1
        ) as tahfiz_data
            on true

        -- =================================================
        -- JUMLAH WALI AKTIF
        -- =================================================

        left join lateral (
            select
                count(*)::integer as guardian_count

            from public.guardian_students
                as guardian_student

            inner join public.guardians as guardian
                on guardian.id =
                   guardian_student.guardian_id
               and guardian.is_active = true

            where guardian_student.student_id =
                  student.id
        ) as guardian_data
            on true

        where student.status =
              'active'::public.student_status
          and student.deleted_at is null
    ),

    filtered_students as (
        select
            base.*

        from base_students as base

        where (
            v_search is null

            or base.full_name ilike
               '%' || v_search || '%'

            or coalesce(
                base.legacy_student_id,
                ''
            ) ilike '%' || v_search || '%'

            or coalesce(
                base.nis,
                ''
            ) ilike '%' || v_search || '%'
        )

        and (
            p_grade_level is null
            or base.grade_level = p_grade_level
        )

        and (
            v_gender is null
            or base.gender::text = v_gender
        )

        and (
            p_care_group_id is null
            or base.care_group_id =
               p_care_group_id
        )

        and (
            p_tahfiz_group_id is null
            or base.tahfiz_group_id =
               p_tahfiz_group_id
        )
    ),

    total_data as (
        select
            count(*)::integer as total_items

        from filtered_students
    ),

    page_data as (
        select
            filtered.*

        from filtered_students as filtered

        order by
            lower(filtered.full_name),
            filtered.legacy_student_id nulls last,
            filtered.id

        limit v_page_size
        offset v_offset
    ),

    class_options as (
        select
            class.id,
            class.name,
            class.grade_level,
            class.gender

        from public.classes as class

        inner join current_year as academic_year
            on academic_year.id =
               class.academic_year_id

        where class.is_active = true
    ),

    care_group_options as (
        select
            care_group.id,
            care_group.name,
            care_group.gender

        from public.care_groups as care_group

        inner join current_year as academic_year
            on academic_year.id =
               care_group.academic_year_id

        where care_group.is_active = true
    ),

    tahfiz_group_options as (
        select
            tahfiz_group.id,
            tahfiz_group.name,
            tahfiz_group.grade_level,
            tahfiz_group.gender

        from public.tahfiz_groups as tahfiz_group

        inner join current_year as academic_year
            on academic_year.id =
               tahfiz_group.academic_year_id

        where tahfiz_group.is_active = true
    )

    select jsonb_build_object(
        'generated_at',
        now(),

        'academic_year',
        (
            select jsonb_build_object(
                'id',
                academic_year.id,

                'name',
                academic_year.name,

                'start_date',
                academic_year.start_date,

                'end_date',
                academic_year.end_date
            )
            from current_year as academic_year
        ),

        'filters',
        jsonb_build_object(
            'search',
            v_search,

            'grade_level',
            p_grade_level,

            'gender',
            v_gender,

            'care_group_id',
            p_care_group_id,

            'tahfiz_group_id',
            p_tahfiz_group_id
        ),

        'pagination',
        (
            select jsonb_build_object(
                'current_page',
                v_page,

                'page_size',
                v_page_size,

                'total_items',
                total.total_items,

                'total_pages',
                case
                    when total.total_items = 0 then 0
                    else ceil(
                        total.total_items::numeric /
                        v_page_size
                    )::integer
                end,

                'from_item',
                case
                    when total.total_items = 0 then 0
                    else least(
                        v_offset + 1,
                        total.total_items
                    )
                end,

                'to_item',
                least(
                    v_offset + v_page_size,
                    total.total_items
                )
            )
            from total_data as total
        ),

        'items',
        (
            select coalesce(
                jsonb_agg(
                    jsonb_build_object(
                        'id',
                        student.id,

                        'legacy_student_id',
                        student.legacy_student_id,

                        'nis',
                        student.nis,

                        'full_name',
                        student.full_name,

                        'gender',
                        student.gender,

                        'photo_url',
                        student.photo_url,

                        'status',
                        student.status,

                        'class_id',
                        student.class_id,

                        'class_name',
                        student.class_name,

                        'grade_level',
                        student.grade_level,

                        'care_group_id',
                        student.care_group_id,

                        'care_group_name',
                        student.care_group_name,

                        'tahfiz_group_id',
                        student.tahfiz_group_id,

                        'tahfiz_group_name',
                        student.tahfiz_group_name,

                        'guardian_count',
                        student.guardian_count
                    )
                    order by
                        lower(student.full_name),
                        student.legacy_student_id
                ),
                '[]'::jsonb
            )
            from page_data as student
        ),

        'filter_options',
        jsonb_build_object(
            'classes',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'id',
                            option.id,

                            'name',
                            option.name,

                            'grade_level',
                            option.grade_level,

                            'gender',
                            option.gender
                        )
                        order by
                            option.grade_level,
                            option.name
                    ),
                    '[]'::jsonb
                )
                from class_options as option
            ),

            'care_groups',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'id',
                            option.id,

                            'name',
                            option.name,

                            'gender',
                            option.gender
                        )
                        order by
                            option.gender,
                            option.name
                    ),
                    '[]'::jsonb
                )
                from care_group_options as option
            ),

            'tahfiz_groups',
            (
                select coalesce(
                    jsonb_agg(
                        jsonb_build_object(
                            'id',
                            option.id,

                            'name',
                            option.name,

                            'grade_level',
                            option.grade_level,

                            'gender',
                            option.gender
                        )
                        order by
                            option.grade_level,
                            option.gender,
                            option.name
                    ),
                    '[]'::jsonb
                )
                from tahfiz_group_options as option
            )
        )
    )
    into v_result;

    return v_result;
end;
$$;

comment on function public.get_admin_student_list(
    text,
    integer,
    text,
    uuid,
    uuid,
    integer,
    integer
) is
'Daftar santri Admin dengan pencarian, filter, dan pagination.';

revoke all on function public.get_admin_student_list(
    text,
    integer,
    text,
    uuid,
    uuid,
    integer,
    integer
) from public;

revoke all on function public.get_admin_student_list(
    text,
    integer,
    text,
    uuid,
    uuid,
    integer,
    integer
) from anon;

grant execute on function public.get_admin_student_list(
    text,
    integer,
    text,
    uuid,
    uuid,
    integer,
    integer
) to authenticated;

commit;