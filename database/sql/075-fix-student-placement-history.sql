begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 075-fix-student-placement-history.sql
--
-- PURPOSE:
-- - Mengizinkan satu santri kembali ke kelas/kelompok
--   yang pernah ditempatinya
-- - Setiap periode placement disimpan sebagai row baru
-- - Tetap membatasi satu placement aktif per santri
-- - Memperbaiki update_admin_student()
--
-- IMPORTANT:
-- Struktur + function diperbarui dalam SATU transaksi.
-- =========================================================


-- =========================================================
-- 1. PREFLIGHT DATA SAFETY
-- =========================================================

do $preflight$
begin
    if exists (
        select 1

        from public.class_enrollments

        where is_active = true

        group by student_id

        having count(*) > 1
    ) then
        raise exception
            'Migration dibatalkan: terdapat santri dengan lebih dari satu kelas aktif.';
    end if;


    if exists (
        select 1

        from public.care_group_members

        where is_active = true

        group by student_id

        having count(*) > 1
    ) then
        raise exception
            'Migration dibatalkan: terdapat santri dengan lebih dari satu kelompok pengasuhan aktif.';
    end if;


    if exists (
        select 1

        from public.tahfiz_group_members

        where is_active = true

        group by student_id

        having count(*) > 1
    ) then
        raise exception
            'Migration dibatalkan: terdapat santri dengan lebih dari satu kelompok tahfiz aktif.';
    end if;
end;
$preflight$;


-- =========================================================
-- 2. HAPUS UNIQUE "SEUMUR HIDUP"
--
-- Sebelumnya:
-- student + destination hanya boleh ada satu row.
--
-- Sekarang:
-- student boleh kembali ke destination lama,
-- tetapi setiap periode menjadi row tersendiri.
-- =========================================================

alter table public.class_enrollments
drop constraint if exists
class_enrollments_student_class_unique;


alter table public.care_group_members
drop constraint if exists
care_group_members_group_student_unique;


alter table public.tahfiz_group_members
drop constraint if exists
tahfiz_group_members_group_student_unique;


-- =========================================================
-- 3. INDEX NON-UNIQUE UNTUK QUERY HISTORY
-- =========================================================

create index if not exists
class_enrollments_student_class_idx
on public.class_enrollments (
    student_id,
    class_id
);


create index if not exists
care_group_members_group_student_idx
on public.care_group_members (
    care_group_id,
    student_id
);


create index if not exists
tahfiz_group_members_group_student_idx
on public.tahfiz_group_members (
    tahfiz_group_id,
    student_id
);


-- =========================================================
-- 4. UPDATE FUNCTION
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
as $function$
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

    v_current_class_id uuid;
    v_current_care_group_id uuid;
    v_current_tahfiz_group_id uuid;
begin

    -- =====================================================
    -- SESSION
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    -- =====================================================
    -- ROLE
    -- =====================================================

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses edit santri ditolak.';
    end if;


    -- =====================================================
    -- STUDENT
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
    -- NORMALISASI
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
    -- DUPLIKAT ID SANTRI
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
    -- DUPLIKAT NIS
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
       )
    then
        raise exception
            'NIS % sudah digunakan.',
            v_nis;
    end if;


    -- =====================================================
    -- TAHUN AJARAN
    -- =====================================================

    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current = true

    order by
        academic_year.start_date desc

    limit 1;


    if v_academic_year_id is null then
        raise exception
            'Tahun ajaran aktif belum tersedia.';
    end if;


    -- =====================================================
    -- VALIDASI PLACEMENT UNTUK SANTRI AKTIF
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
        -- CLASS
        -- =================================================

        select
            class.grade_level,
            class.gender

        into
            v_class_grade_level,
            v_class_gender

        from public.classes
            as class

        where class.id =
              p_class_id

          and class.academic_year_id =
              v_academic_year_id

          and class.is_active = true;


        if not found then
            raise exception
                'Kelas yang dipilih tidak tersedia.';
        end if;


        if v_class_gender is not null
           and v_class_gender::text <>
               v_gender
        then
            raise exception
                'Gender santri tidak sesuai dengan kelas.';
        end if;


        -- =================================================
        -- CARE
        -- =================================================

        select
            care_group.gender

        into
            v_care_gender

        from public.care_groups
            as care_group

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
           v_gender
        then
            raise exception
                'Gender santri tidak sesuai dengan kelompok pengasuhan.';
        end if;


        -- =================================================
        -- TAHFIZ
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
           v_gender
        then
            raise exception
                'Gender santri tidak sesuai dengan kelompok tahfiz.';
        end if;


        if v_tahfiz_grade_level is not null
           and v_tahfiz_grade_level <>
               v_class_grade_level
        then
            raise exception
                'Tingkat kelompok tahfiz tidak sesuai dengan kelas santri.';
        end if;
    end if;


    -- =====================================================
    -- UPDATE IDENTITAS
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
    -- NONACTIVE STUDENT
    -- =====================================================

    if v_status <> 'active' then

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
        -- CURRENT CLASS
        -- =================================================

        select
            enrollment.class_id

        into
            v_current_class_id

        from public.class_enrollments
            as enrollment

        where enrollment.student_id =
              p_student_id

          and enrollment.is_active = true

        limit 1;


        if v_current_class_id is distinct from
           p_class_id
        then

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


            insert into public.class_enrollments (
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
            );

        elsif v_current_class_id is null then

            insert into public.class_enrollments (
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
            );

        end if;


        -- =================================================
        -- CURRENT CARE GROUP
        -- =================================================

        select
            membership.care_group_id

        into
            v_current_care_group_id

        from public.care_group_members
            as membership

        where membership.student_id =
              p_student_id

          and membership.is_active = true

        limit 1;


        if v_current_care_group_id is distinct from
           p_care_group_id
        then

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


            insert into public.care_group_members (
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
            );

        elsif v_current_care_group_id is null then

            insert into public.care_group_members (
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
            );

        end if;


        -- =================================================
        -- CURRENT TAHFIZ GROUP
        -- =================================================

        select
            membership.tahfiz_group_id

        into
            v_current_tahfiz_group_id

        from public.tahfiz_group_members
            as membership

        where membership.student_id =
              p_student_id

          and membership.is_active = true

        limit 1;


        if v_current_tahfiz_group_id is distinct from
           p_tahfiz_group_id
        then

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


            insert into public.tahfiz_group_members (
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
            );

        elsif v_current_tahfiz_group_id is null then

            insert into public.tahfiz_group_members (
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
            );

        end if;

    end if;


    -- =====================================================
    -- RESULT
    -- =====================================================

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
$function$;


-- =========================================================
-- 5. DOCUMENTATION
-- =========================================================

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
'Memperbarui data dan placement santri. Setiap periode placement baru disimpan sebagai row baru sehingga riwayat tidak ditimpa.';


-- =========================================================
-- 6. PRIVILEGES
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