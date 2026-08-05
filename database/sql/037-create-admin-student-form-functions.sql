begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 037-create-admin-student-form-functions.sql
-- PURPOSE:
-- - Menyediakan opsi form santri
-- - Membuat santri baru
-- - Memperbarui data santri
-- - Menyimpan riwayat penempatan
-- - Membatasi operasi khusus role Admin
--
-- CATATAN:
-- - Tabel students tidak memiliki created_by
-- - Tabel students tidak memiliki updated_by
-- =========================================================


-- =========================================================
-- 1. OPSI FORM SANTRI
-- =========================================================

create or replace function public.get_admin_student_form_options()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_result jsonb;
begin
    -- =====================================================
    -- VALIDASI SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    -- =====================================================
    -- VALIDASI ROLE
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses opsi form santri ditolak.';
    end if;

    -- =====================================================
    -- SUSUN OPSI FORM
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
    into v_result;

    return v_result;
end;
$$;


-- =========================================================
-- 2. TAMBAH SANTRI
-- =========================================================

create or replace function public.create_admin_student(
    p_legacy_student_id text,
    p_nis text,
    p_full_name text,
    p_gender text,
    p_status text,
    p_class_id uuid,
    p_care_group_id uuid,
    p_tahfiz_group_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_legacy_student_id text;
    v_nis text;
    v_full_name text;
    v_gender text;
    v_status text;

    v_student_id uuid;

    v_academic_year_id uuid;
    v_academic_year_start date;

    v_class_grade_level integer;
    v_class_gender public.gender_type;

    v_care_gender public.gender_type;

    v_tahfiz_grade_level integer;
    v_tahfiz_gender public.gender_type;
begin
    -- =====================================================
    -- VALIDASI SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    -- =====================================================
    -- VALIDASI ROLE
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses tambah santri ditolak.';
    end if;

    -- =====================================================
    -- NORMALISASI INPUT
    -- =====================================================

    v_legacy_student_id :=
        nullif(
            btrim(
                coalesce(
                    p_legacy_student_id,
                    ''
                )
            ),
            ''
        );

    v_nis :=
        nullif(
            btrim(
                coalesce(
                    p_nis,
                    ''
                )
            ),
            ''
        );

    v_full_name :=
        regexp_replace(
            btrim(
                coalesce(
                    p_full_name,
                    ''
                )
            ),
            '\s+',
            ' ',
            'g'
        );

    v_gender :=
        lower(
            btrim(
                coalesce(
                    p_gender,
                    ''
                )
            )
        );

    v_status :=
        lower(
            btrim(
                coalesce(
                    p_status,
                    ''
                )
            )
        );

    -- =====================================================
    -- VALIDASI IDENTITAS
    -- =====================================================

    if v_legacy_student_id is null then
        raise exception
            'ID santri wajib diisi.';
    end if;

    if length(v_legacy_student_id) > 100 then
        raise exception
            'ID santri maksimal 100 karakter.';
    end if;

    if v_nis is not null
       and length(v_nis) > 100 then
        raise exception
            'NIS maksimal 100 karakter.';
    end if;

    if v_full_name = '' then
        raise exception
            'Nama lengkap wajib diisi.';
    end if;

    if length(v_full_name) > 200 then
        raise exception
            'Nama lengkap maksimal 200 karakter.';
    end if;

    if v_gender not in (
        'male',
        'female'
    ) then
        raise exception
            'Gender santri tidak valid.';
    end if;

    if v_status not in (
        'active',
        'inactive',
        'graduated',
        'withdrawn'
    ) then
        raise exception
            'Status santri tidak valid.';
    end if;

    -- =====================================================
    -- VALIDASI ID SANTRI DUPLIKAT
    -- =====================================================

    if exists (
        select 1

        from public.students as student

        where student.legacy_student_id
              is not null

          and lower(
              btrim(
                  student.legacy_student_id
              )
          ) = lower(
              v_legacy_student_id
          )
    ) then
        raise exception
            'ID santri % sudah digunakan.',
            v_legacy_student_id;
    end if;

    -- =====================================================
    -- VALIDASI NIS DUPLIKAT
    -- =====================================================

    if v_nis is not null
       and exists (
           select 1

           from public.students as student

           where student.nis is not null

             and lower(
                 btrim(
                     student.nis
                 )
             ) = lower(
                 v_nis
             )
       ) then
        raise exception
            'NIS % sudah digunakan.',
            v_nis;
    end if;

    -- =====================================================
    -- TAHUN AJARAN AKTIF
    -- =====================================================

    select
        academic_year.id,
        academic_year.start_date

    into
        v_academic_year_id,
        v_academic_year_start

    from public.academic_years
        as academic_year

    where academic_year.is_current = true

    order by academic_year.start_date desc
    limit 1;

    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;

    -- =====================================================
    -- VALIDASI PENEMPATAN SANTRI AKTIF
    -- =====================================================

    if v_status = 'active' then
        -- =================================================
        -- KELAS WAJIB
        -- =================================================

        if p_class_id is null then
            raise exception
                'Kelas wajib dipilih untuk santri aktif.';
        end if;

        -- =================================================
        -- PENGASUHAN WAJIB
        -- =================================================

        if p_care_group_id is null then
            raise exception
                'Kelompok pengasuhan wajib dipilih untuk santri aktif.';
        end if;

        -- =================================================
        -- TAHFIZ WAJIB
        -- =================================================

        if p_tahfiz_group_id is null then
            raise exception
                'Kelompok tahfiz wajib dipilih untuk santri aktif.';
        end if;

        -- =================================================
        -- VALIDASI KELAS
        -- =================================================

        select
            class.grade_level,
            class.gender

        into
            v_class_grade_level,
            v_class_gender

        from public.classes as class

        where class.id = p_class_id

          and class.academic_year_id =
              v_academic_year_id

          and class.is_active = true;

        if not found then
            raise exception
                'Kelas yang dipilih tidak tersedia pada tahun ajaran aktif.';
        end if;

        if v_class_gender is not null
           and v_class_gender::text <>
               v_gender then
            raise exception
                'Gender santri tidak sesuai dengan kelas.';
        end if;

        -- =================================================
        -- VALIDASI KELOMPOK PENGASUHAN
        -- =================================================

        select
            care_group.gender

        into
            v_care_gender

        from public.care_groups as care_group

        where care_group.id =
              p_care_group_id

          and care_group.academic_year_id =
              v_academic_year_id

          and care_group.is_active = true;

        if not found then
            raise exception
                'Kelompok pengasuhan tidak tersedia pada tahun ajaran aktif.';
        end if;

        if v_care_gender::text <>
           v_gender then
            raise exception
                'Gender santri tidak sesuai dengan kelompok pengasuhan.';
        end if;

        -- =================================================
        -- VALIDASI KELOMPOK TAHFIZ
        -- =================================================

        select
            tahfiz_group.grade_level,
            tahfiz_group.gender

        into
            v_tahfiz_grade_level,
            v_tahfiz_gender

        from public.tahfiz_groups
            as tahfiz_group

        where tahfiz_group.id =
              p_tahfiz_group_id

          and tahfiz_group.academic_year_id =
              v_academic_year_id

          and tahfiz_group.is_active = true;

        if not found then
            raise exception
                'Kelompok tahfiz tidak tersedia pada tahun ajaran aktif.';
        end if;

        if v_tahfiz_gender::text <>
           v_gender then
            raise exception
                'Gender santri tidak sesuai dengan kelompok tahfiz.';
        end if;

        if v_tahfiz_grade_level is not null
           and v_tahfiz_grade_level <>
               v_class_grade_level then
            raise exception
                'Tingkat kelompok tahfiz tidak sesuai dengan kelas santri.';
        end if;
    end if;

    -- =====================================================
    -- INSERT DATA SANTRI
    --
    -- created_by dan updated_by tidak digunakan karena
    -- kolom tersebut tidak tersedia pada tabel students.
    -- =====================================================

    insert into public.students (
        legacy_student_id,
        nis,
        full_name,
        gender,
        status
    )
    values (
        v_legacy_student_id,
        v_nis,
        v_full_name,
        v_gender::public.gender_type,
        v_status::public.student_status
    )
    returning id
    into v_student_id;

    -- =====================================================
    -- INSERT PENEMPATAN AKTIF
    -- =====================================================

    if v_status = 'active' then
        -- =================================================
        -- KELAS
        -- =================================================

        insert into public.class_enrollments (
            student_id,
            class_id,
            enrolled_at,
            left_at,
            is_active
        )
        values (
            v_student_id,
            p_class_id,
            greatest(
                current_date,
                v_academic_year_start
            ),
            null,
            true
        );

        -- =================================================
        -- PENGASUHAN
        -- =================================================

        insert into public.care_group_members (
            care_group_id,
            student_id,
            joined_at,
            left_at,
            is_active
        )
        values (
            p_care_group_id,
            v_student_id,
            greatest(
                current_date,
                v_academic_year_start
            ),
            null,
            true
        );

        -- =================================================
        -- TAHFIZ
        -- =================================================

        insert into public.tahfiz_group_members (
            tahfiz_group_id,
            student_id,
            joined_at,
            left_at,
            is_active
        )
        values (
            p_tahfiz_group_id,
            v_student_id,
            greatest(
                current_date,
                v_academic_year_start
            ),
            null,
            true
        );
    end if;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'created',

        'student_id',
        v_student_id,

        'legacy_student_id',
        v_legacy_student_id,

        'full_name',
        v_full_name
    );
end;
$$;


-- =========================================================
-- 3. EDIT SANTRI
-- =========================================================

create or replace function public.update_admin_student(
    p_student_id uuid,
    p_legacy_student_id text,
    p_nis text,
    p_full_name text,
    p_gender text,
    p_status text,
    p_class_id uuid,
    p_care_group_id uuid,
    p_tahfiz_group_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_legacy_student_id text;
    v_nis text;
    v_full_name text;
    v_gender text;
    v_status text;

    v_academic_year_id uuid;

    v_class_grade_level integer;
    v_class_gender public.gender_type;

    v_care_gender public.gender_type;

    v_tahfiz_grade_level integer;
    v_tahfiz_gender public.gender_type;
begin
    -- =====================================================
    -- VALIDASI SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    -- =====================================================
    -- VALIDASI ROLE
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses edit santri ditolak.';
    end if;

    -- =====================================================
    -- VALIDASI STUDENT ID
    -- =====================================================

    if p_student_id is null then
        raise exception
            'Student ID wajib diisi.';
    end if;

    perform 1

    from public.students as student

    where student.id =
          p_student_id

      and student.deleted_at is null

    for update;

    if not found then
        raise exception
            'Data santri tidak ditemukan.';
    end if;

    -- =====================================================
    -- NORMALISASI INPUT
    -- =====================================================

    v_legacy_student_id :=
        nullif(
            btrim(
                coalesce(
                    p_legacy_student_id,
                    ''
                )
            ),
            ''
        );

    v_nis :=
        nullif(
            btrim(
                coalesce(
                    p_nis,
                    ''
                )
            ),
            ''
        );

    v_full_name :=
        regexp_replace(
            btrim(
                coalesce(
                    p_full_name,
                    ''
                )
            ),
            '\s+',
            ' ',
            'g'
        );

    v_gender :=
        lower(
            btrim(
                coalesce(
                    p_gender,
                    ''
                )
            )
        );

    v_status :=
        lower(
            btrim(
                coalesce(
                    p_status,
                    ''
                )
            )
        );

    -- =====================================================
    -- VALIDASI IDENTITAS
    -- =====================================================

    if v_legacy_student_id is null then
        raise exception
            'ID santri wajib diisi.';
    end if;

    if length(v_legacy_student_id) > 100 then
        raise exception
            'ID santri maksimal 100 karakter.';
    end if;

    if v_nis is not null
       and length(v_nis) > 100 then
        raise exception
            'NIS maksimal 100 karakter.';
    end if;

    if v_full_name = '' then
        raise exception
            'Nama lengkap wajib diisi.';
    end if;

    if length(v_full_name) > 200 then
        raise exception
            'Nama lengkap maksimal 200 karakter.';
    end if;

    if v_gender not in (
        'male',
        'female'
    ) then
        raise exception
            'Gender santri tidak valid.';
    end if;

    if v_status not in (
        'active',
        'inactive',
        'graduated',
        'withdrawn'
    ) then
        raise exception
            'Status santri tidak valid.';
    end if;

    -- =====================================================
    -- VALIDASI ID SANTRI DUPLIKAT
    -- =====================================================

    if exists (
        select 1

        from public.students as student

        where student.id <>
              p_student_id

          and student.legacy_student_id
              is not null

          and lower(
              btrim(
                  student.legacy_student_id
              )
          ) = lower(
              v_legacy_student_id
          )
    ) then
        raise exception
            'ID santri % sudah digunakan.',
            v_legacy_student_id;
    end if;

    -- =====================================================
    -- VALIDASI NIS DUPLIKAT
    -- =====================================================

    if v_nis is not null
       and exists (
           select 1

           from public.students as student

           where student.id <>
                 p_student_id

             and student.nis is not null

             and lower(
                 btrim(
                     student.nis
                 )
             ) = lower(
                 v_nis
             )
       ) then
        raise exception
            'NIS % sudah digunakan.',
            v_nis;
    end if;

    -- =====================================================
    -- TAHUN AJARAN AKTIF
    -- =====================================================

    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current = true

    order by academic_year.start_date desc
    limit 1;

    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;

    -- =====================================================
    -- VALIDASI PENEMPATAN SANTRI AKTIF
    -- =====================================================

    if v_status = 'active' then
        if p_class_id is null then
            raise exception
                'Kelas wajib dipilih untuk santri aktif.';
        end if;

        if p_care_group_id is null then
            raise exception
                'Kelompok pengasuhan wajib dipilih untuk santri aktif.';
        end if;

        if p_tahfiz_group_id is null then
            raise exception
                'Kelompok tahfiz wajib dipilih untuk santri aktif.';
        end if;

        -- =================================================
        -- VALIDASI KELAS
        -- =================================================

        select
            class.grade_level,
            class.gender

        into
            v_class_grade_level,
            v_class_gender

        from public.classes as class

        where class.id = p_class_id

          and class.academic_year_id =
              v_academic_year_id

          and class.is_active = true;

        if not found then
            raise exception
                'Kelas yang dipilih tidak tersedia.';
        end if;

        if v_class_gender is not null
           and v_class_gender::text <>
               v_gender then
            raise exception
                'Gender santri tidak sesuai dengan kelas.';
        end if;

        -- =================================================
        -- VALIDASI KELOMPOK PENGASUHAN
        -- =================================================

        select
            care_group.gender

        into
            v_care_gender

        from public.care_groups as care_group

        where care_group.id =
              p_care_group_id

          and care_group.academic_year_id =
              v_academic_year_id

          and care_group.is_active = true;

        if not found then
            raise exception
                'Kelompok pengasuhan tidak tersedia.';
        end if;

        if v_care_gender::text <>
           v_gender then
            raise exception
                'Gender santri tidak sesuai dengan kelompok pengasuhan.';
        end if;

        -- =================================================
        -- VALIDASI KELOMPOK TAHFIZ
        -- =================================================

        select
            tahfiz_group.grade_level,
            tahfiz_group.gender

        into
            v_tahfiz_grade_level,
            v_tahfiz_gender

        from public.tahfiz_groups
            as tahfiz_group

        where tahfiz_group.id =
              p_tahfiz_group_id

          and tahfiz_group.academic_year_id =
              v_academic_year_id

          and tahfiz_group.is_active = true;

        if not found then
            raise exception
                'Kelompok tahfiz tidak tersedia.';
        end if;

        if v_tahfiz_gender::text <>
           v_gender then
            raise exception
                'Gender santri tidak sesuai dengan kelompok tahfiz.';
        end if;

        if v_tahfiz_grade_level is not null
           and v_tahfiz_grade_level <>
               v_class_grade_level then
            raise exception
                'Tingkat kelompok tahfiz tidak sesuai dengan kelas.';
        end if;
    end if;

    -- =====================================================
    -- UPDATE IDENTITAS SANTRI
    --
    -- updated_by tidak digunakan karena kolom tersebut
    -- tidak tersedia pada tabel students.
    -- =====================================================

    update public.students

    set
        legacy_student_id =
            v_legacy_student_id,

        nis =
            v_nis,

        full_name =
            v_full_name,

        gender =
            v_gender::public.gender_type,

        status =
            v_status::public.student_status,

        updated_at =
            now()

    where id =
          p_student_id;

    -- =====================================================
    -- STATUS NONAKTIF
    -- TUTUP SELURUH PENEMPATAN AKTIF
    -- =====================================================

    if v_status <> 'active' then
        -- =================================================
        -- TUTUP KELAS
        -- =================================================

        update public.class_enrollments

        set
            is_active = false,

            left_at = coalesce(
                left_at,
                current_date
            ),

            updated_at = now()

        where student_id =
              p_student_id

          and is_active = true;

        -- =================================================
        -- TUTUP PENGASUHAN
        -- =================================================

        update public.care_group_members

        set
            is_active = false,

            left_at = coalesce(
                left_at,
                current_date
            ),

            updated_at = now()

        where student_id =
              p_student_id

          and is_active = true;

        -- =================================================
        -- TUTUP TAHFIZ
        -- =================================================

        update public.tahfiz_group_members

        set
            is_active = false,

            left_at = coalesce(
                left_at,
                current_date
            ),

            updated_at = now()

        where student_id =
              p_student_id

          and is_active = true;

    else
        -- =================================================
        -- STATUS AKTIF
        -- PERBARUI KELAS
        -- =================================================

        update public.class_enrollments

        set
            is_active = false,

            left_at = coalesce(
                left_at,
                current_date
            ),

            updated_at = now()

        where student_id =
              p_student_id

          and is_active = true

          and class_id <>
              p_class_id;

        insert into public.class_enrollments
            as enrollment (
                student_id,
                class_id,
                enrolled_at,
                left_at,
                is_active
            )
        values (
            p_student_id,
            p_class_id,
            current_date,
            null,
            true
        )
        on conflict (
            student_id,
            class_id
        )
        do update

        set
            left_at = null,
            is_active = true,
            updated_at = now();

        -- =================================================
        -- PERBARUI PENGASUHAN
        -- =================================================

        update public.care_group_members

        set
            is_active = false,

            left_at = coalesce(
                left_at,
                current_date
            ),

            updated_at = now()

        where student_id =
              p_student_id

          and is_active = true

          and care_group_id <>
              p_care_group_id;

        insert into public.care_group_members
            as membership (
                care_group_id,
                student_id,
                joined_at,
                left_at,
                is_active
            )
        values (
            p_care_group_id,
            p_student_id,
            current_date,
            null,
            true
        )
        on conflict (
            care_group_id,
            student_id
        )
        do update

        set
            left_at = null,
            is_active = true,
            updated_at = now();

        -- =================================================
        -- PERBARUI TAHFIZ
        -- =================================================

        update public.tahfiz_group_members

        set
            is_active = false,

            left_at = coalesce(
                left_at,
                current_date
            ),

            updated_at = now()

        where student_id =
              p_student_id

          and is_active = true

          and tahfiz_group_id <>
              p_tahfiz_group_id;

        insert into public.tahfiz_group_members
            as membership (
                tahfiz_group_id,
                student_id,
                joined_at,
                left_at,
                is_active
            )
        values (
            p_tahfiz_group_id,
            p_student_id,
            current_date,
            null,
            true
        )
        on conflict (
            tahfiz_group_id,
            student_id
        )
        do update

        set
            left_at = null,
            is_active = true,
            updated_at = now();
    end if;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'updated',

        'student_id',
        p_student_id,

        'legacy_student_id',
        v_legacy_student_id,

        'full_name',
        v_full_name,

        'status',
        v_status
    );
end;
$$;


-- =========================================================
-- 4. COMMENTS
-- =========================================================

comment on function
public.get_admin_student_form_options()
is
'Mengambil opsi kelas, pengasuhan, dan tahfiz untuk form santri Admin.';

comment on function public.create_admin_student(
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
is
'Membuat santri baru dan penempatan aktif melalui role Admin.';

comment on function public.update_admin_student(
    uuid,
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
is
'Memperbarui identitas dan penempatan santri melalui role Admin.';


-- =========================================================
-- 5. PRIVILEGES OPSI FORM
-- =========================================================

revoke all on function
public.get_admin_student_form_options()
from public;

revoke all on function
public.get_admin_student_form_options()
from anon;

grant execute on function
public.get_admin_student_form_options()
to authenticated;


-- =========================================================
-- 6. PRIVILEGES TAMBAH SANTRI
-- =========================================================

revoke all on function public.create_admin_student(
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
from public;

revoke all on function public.create_admin_student(
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
from anon;

grant execute on function public.create_admin_student(
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
to authenticated;


-- =========================================================
-- 7. PRIVILEGES EDIT SANTRI
-- =========================================================

revoke all on function public.update_admin_student(
    uuid,
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
from public;

revoke all on function public.update_admin_student(
    uuid,
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
from anon;

grant execute on function public.update_admin_student(
    uuid,
    text,
    text,
    text,
    text,
    text,
    uuid,
    uuid,
    uuid
)
to authenticated;

commit;