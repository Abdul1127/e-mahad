begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 044-create-admin-guardian-student-relations.sql
-- PURPOSE:
-- - Menampilkan pilihan santri untuk wali
-- - Menghubungkan wali dengan santri
-- - Memperbarui jenis hubungan dan kontak utama
-- - Melepas hubungan wali dengan santri
-- - Menjamin maksimal satu kontak utama per santri
--
-- STRUKTUR AKTUAL:
--
-- guardians:
-- id, profile_id, legacy_guardian_id, full_name,
-- phone, email, is_active, created_at, updated_at
--
-- guardian_students:
-- id, guardian_id, student_id, relationship_type,
-- is_primary_contact, created_at
-- =========================================================


-- =========================================================
-- 1. CEK DATA KONTAK UTAMA GANDA
-- =========================================================

do $check_primary_contact$
begin
    if exists (
        select
            relation.student_id

        from public.guardian_students
            as relation

        where relation.is_primary_contact = true

        group by relation.student_id

        having count(*) > 1
    ) then
        raise exception
            'Masih terdapat santri dengan lebih dari satu kontak utama.';
    end if;
end;
$check_primary_contact$;


-- =========================================================
-- 2. UNIQUE INDEX KONTAK UTAMA
-- =========================================================

create unique index if not exists
guardian_students_one_primary_per_student_idx

on public.guardian_students (
    student_id
)

where is_primary_contact = true;


-- =========================================================
-- 3. PILIHAN SANTRI UNTUK DIHUBUNGKAN
-- =========================================================

create or replace function
public.get_admin_guardian_student_options(
    p_guardian_id uuid,
    p_search text default null,
    p_limit integer default 50
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
    v_search text;
    v_limit integer;
    v_result jsonb;
begin
    -- =====================================================
    -- VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses pilihan santri ditolak.';
    end if;

    -- =====================================================
    -- VALIDASI WALI
    -- =====================================================

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
    end if;

    if not exists (
        select 1

        from public.guardians as guardian

        where guardian.id =
              p_guardian_id
    ) then
        raise exception
            'Data wali tidak ditemukan.';
    end if;

    -- =====================================================
    -- NORMALISASI PARAMETER
    -- =====================================================

    v_search :=
        nullif(
            btrim(
                coalesce(
                    p_search,
                    ''
                )
            ),
            ''
        );

    v_limit :=
        least(
            greatest(
                coalesce(
                    p_limit,
                    50
                ),
                1
            ),
            100
        );

    -- =====================================================
    -- SUSUN PILIHAN SANTRI
    -- =====================================================

    with student_options as (
        select
            student.id as student_id,
            student.legacy_student_id,
            student.nis,
            student.full_name,
            student.gender,
            student.status,

            class_data.class_id,
            class_data.class_name,
            class_data.grade_level,
            class_data.academic_year_name,

            coalesce(
                relation_data.guardian_count,
                0
            )::integer as guardian_count,

            relation_data.primary_guardian_name

        from public.students as student

        left join lateral (
            select
                class.id as class_id,
                class.name as class_name,
                class.grade_level,

                academic_year.name
                    as academic_year_name

            from public.class_enrollments
                as enrollment

            inner join public.classes
                as class
                on class.id =
                   enrollment.class_id

            inner join public.academic_years
                as academic_year
                on academic_year.id =
                   class.academic_year_id

            where enrollment.student_id =
                  student.id

              and enrollment.is_active = true

              and class.is_active = true

            order by
                academic_year.is_current desc,
                enrollment.enrolled_at desc,
                enrollment.id desc

            limit 1
        ) as class_data
            on true

        left join lateral (
            select
                count(*)::integer
                    as guardian_count,

                max(
                    guardian.full_name
                ) filter (
                    where relation.is_primary_contact
                          = true
                ) as primary_guardian_name

            from public.guardian_students
                as relation

            inner join public.guardians
                as guardian
                on guardian.id =
                   relation.guardian_id

            where relation.student_id =
                  student.id
        ) as relation_data
            on true

        where student.status =
              'active'::public.student_status

          and student.deleted_at is null

          and not exists (
              select 1

              from public.guardian_students
                  as existing_relation

              where existing_relation.guardian_id =
                    p_guardian_id

                and existing_relation.student_id =
                    student.id
          )

          and (
              v_search is null

              or student.full_name ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.legacy_student_id,
                  ''
              ) ilike
                 '%' || v_search || '%'

              or coalesce(
                  student.nis,
                  ''
              ) ilike
                 '%' || v_search || '%'
          )

        order by
            lower(student.full_name),
            student.id

        limit v_limit
    )

    select jsonb_build_object(
        'guardian_id',
        p_guardian_id,

        'search',
        v_search,

        'limit',
        v_limit,

        'items',
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'student_id',
                    option.student_id,

                    'legacy_student_id',
                    option.legacy_student_id,

                    'nis',
                    option.nis,

                    'full_name',
                    option.full_name,

                    'gender',
                    option.gender,

                    'status',
                    option.status,

                    'class_id',
                    option.class_id,

                    'class_name',
                    option.class_name,

                    'grade_level',
                    option.grade_level,

                    'academic_year_name',
                    option.academic_year_name,

                    'guardian_count',
                    option.guardian_count,

                    'primary_guardian_name',
                    option.primary_guardian_name
                )

                order by
                    lower(option.full_name),
                    option.student_id
            ),
            '[]'::jsonb
        )
    )

    into v_result

    from student_options as option;

    return v_result;
end;
$$;


-- =========================================================
-- 4. HUBUNGKAN WALI DENGAN SANTRI
-- =========================================================

create or replace function
public.create_admin_guardian_student_relation(
    p_guardian_id uuid,
    p_student_id uuid,
    p_relationship_type text,
    p_is_primary_contact boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_relationship_type text;
    v_requested_primary boolean;
    v_final_primary boolean;

    v_guardian_active boolean;
    v_existing_relation_count integer;

    v_relation_id uuid;
begin
    -- =====================================================
    -- VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses menghubungkan wali ditolak.';
    end if;

    -- =====================================================
    -- VALIDASI PARAMETER
    -- =====================================================

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
    end if;

    if p_student_id is null then
        raise exception
            'Student ID wajib diisi.';
    end if;

    v_relationship_type :=
        lower(
            btrim(
                coalesce(
                    p_relationship_type,
                    ''
                )
            )
        );

    if v_relationship_type not in (
        'father',
        'mother',
        'guardian',
        'other'
    ) then
        raise exception
            'Jenis hubungan tidak valid.';
    end if;

    v_requested_primary :=
        coalesce(
            p_is_primary_contact,
            false
        );

    -- =====================================================
    -- KUNCI DAN VALIDASI WALI
    -- =====================================================

    select guardian.is_active

    into v_guardian_active

    from public.guardians as guardian

    where guardian.id =
          p_guardian_id

    for update;

    if not found then
        raise exception
            'Data wali tidak ditemukan.';
    end if;

    if v_guardian_active is not true then
        raise exception
            'Wali tidak aktif tidak dapat dihubungkan dengan santri.';
    end if;

    -- =====================================================
    -- KUNCI DAN VALIDASI SANTRI
    -- =====================================================

    perform 1

    from public.students as student

    where student.id =
          p_student_id

      and student.status =
          'active'::public.student_status

      and student.deleted_at is null

    for update;

    if not found then
        raise exception
            'Santri aktif tidak ditemukan.';
    end if;

    -- =====================================================
    -- CEK HUBUNGAN GANDA
    -- =====================================================

    if exists (
        select 1

        from public.guardian_students
            as relation

        where relation.guardian_id =
              p_guardian_id

          and relation.student_id =
              p_student_id
    ) then
        raise exception
            'Wali sudah terhubung dengan santri tersebut.';
    end if;

    -- =====================================================
    -- TENTUKAN KONTAK UTAMA
    -- =====================================================

    select count(*)::integer

    into v_existing_relation_count

    from public.guardian_students
        as relation

    where relation.student_id =
          p_student_id;

    -- Hubungan pertama selalu menjadi kontak utama.
    v_final_primary :=
        case
            when v_existing_relation_count = 0
                then true
            else v_requested_primary
        end;

    if v_final_primary then
        update public.guardian_students

        set is_primary_contact = false

        where student_id =
              p_student_id

          and is_primary_contact = true;
    end if;

    -- =====================================================
    -- INSERT HUBUNGAN
    -- =====================================================

    insert into public.guardian_students (
        guardian_id,
        student_id,
        relationship_type,
        is_primary_contact
    )
    values (
        p_guardian_id,
        p_student_id,
        v_relationship_type,
        v_final_primary
    )
    returning id
    into v_relation_id;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'created',

        'relation_id',
        v_relation_id,

        'guardian_id',
        p_guardian_id,

        'student_id',
        p_student_id,

        'relationship_type',
        v_relationship_type,

        'is_primary_contact',
        v_final_primary
    );
end;
$$;


-- =========================================================
-- 5. PERBARUI HUBUNGAN WALI-SANTRI
-- =========================================================

create or replace function
public.update_admin_guardian_student_relation(
    p_relation_id uuid,
    p_relationship_type text,
    p_is_primary_contact boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_relationship_type text;
    v_requested_primary boolean;
    v_final_primary boolean;

    v_guardian_id uuid;
    v_student_id uuid;
    v_was_primary boolean;

    v_other_relation_count integer;
    v_promoted_relation_id uuid;
begin
    -- =====================================================
    -- VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses mengubah hubungan wali ditolak.';
    end if;

    -- =====================================================
    -- VALIDASI PARAMETER
    -- =====================================================

    if p_relation_id is null then
        raise exception
            'Relation ID wajib diisi.';
    end if;

    v_relationship_type :=
        lower(
            btrim(
                coalesce(
                    p_relationship_type,
                    ''
                )
            )
        );

    if v_relationship_type not in (
        'father',
        'mother',
        'guardian',
        'other'
    ) then
        raise exception
            'Jenis hubungan tidak valid.';
    end if;

    v_requested_primary :=
        coalesce(
            p_is_primary_contact,
            false
        );

    -- =====================================================
    -- KUNCI HUBUNGAN
    -- =====================================================

    select
        relation.guardian_id,
        relation.student_id,
        relation.is_primary_contact

    into
        v_guardian_id,
        v_student_id,
        v_was_primary

    from public.guardian_students
        as relation

    where relation.id =
          p_relation_id

    for update;

    if not found then
        raise exception
            'Hubungan wali dan santri tidak ditemukan.';
    end if;

    -- Kunci santri agar perubahan kontak utama
    -- tidak bertabrakan dengan transaksi lain.

    perform 1

    from public.students as student

    where student.id =
          v_student_id

    for update;

    -- =====================================================
    -- HITUNG HUBUNGAN LAIN
    -- =====================================================

    select count(*)::integer

    into v_other_relation_count

    from public.guardian_students
        as relation

    where relation.student_id =
          v_student_id

      and relation.id <>
          p_relation_id;

    -- Jika hubungan ini satu-satunya,
    -- maka harus tetap menjadi kontak utama.

    v_final_primary :=
        case
            when v_other_relation_count = 0
                then true
            else v_requested_primary
        end;

    -- =====================================================
    -- JIKA DIPILIH MENJADI KONTAK UTAMA
    -- =====================================================

    if v_final_primary then
        update public.guardian_students

        set is_primary_contact = false

        where student_id =
              v_student_id

          and id <>
              p_relation_id

          and is_primary_contact = true;
    end if;

    -- =====================================================
    -- UPDATE HUBUNGAN
    -- =====================================================

    update public.guardian_students

    set
        relationship_type =
            v_relationship_type,

        is_primary_contact =
            v_final_primary

    where id =
          p_relation_id;

    -- =====================================================
    -- PROMOSIKAN KONTAK UTAMA LAIN
    -- =====================================================

    if v_was_primary = true
       and v_final_primary = false then

        select relation.id

        into v_promoted_relation_id

        from public.guardian_students
            as relation

        where relation.student_id =
              v_student_id

          and relation.id <>
              p_relation_id

        order by
            relation.created_at,
            relation.id

        limit 1

        for update;

        if v_promoted_relation_id is not null then
            update public.guardian_students

            set is_primary_contact = true

            where id =
                  v_promoted_relation_id;
        end if;
    end if;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'updated',

        'relation_id',
        p_relation_id,

        'guardian_id',
        v_guardian_id,

        'student_id',
        v_student_id,

        'relationship_type',
        v_relationship_type,

        'is_primary_contact',
        v_final_primary,

        'promoted_relation_id',
        v_promoted_relation_id
    );
end;
$$;


-- =========================================================
-- 6. LEPASKAN HUBUNGAN WALI-SANTRI
-- =========================================================

create or replace function
public.delete_admin_guardian_student_relation(
    p_relation_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_guardian_id uuid;
    v_student_id uuid;
    v_was_primary boolean;

    v_promoted_relation_id uuid;
begin
    -- =====================================================
    -- VALIDASI SESSION DAN ROLE
    -- =====================================================

    if auth.uid() is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;

    if not public.has_role('admin') then
        raise exception using
            errcode = '42501',
            message = 'Akses melepas hubungan wali ditolak.';
    end if;

    if p_relation_id is null then
        raise exception
            'Relation ID wajib diisi.';
    end if;

    -- =====================================================
    -- KUNCI HUBUNGAN
    -- =====================================================

    select
        relation.guardian_id,
        relation.student_id,
        relation.is_primary_contact

    into
        v_guardian_id,
        v_student_id,
        v_was_primary

    from public.guardian_students
        as relation

    where relation.id =
          p_relation_id

    for update;

    if not found then
        raise exception
            'Hubungan wali dan santri tidak ditemukan.';
    end if;

    perform 1

    from public.students as student

    where student.id =
          v_student_id

    for update;

    -- =====================================================
    -- HAPUS HUBUNGAN
    -- =====================================================

    delete from public.guardian_students

    where id =
          p_relation_id;

    -- =====================================================
    -- PROMOSIKAN KONTAK UTAMA PENGGANTI
    -- =====================================================

    if v_was_primary = true then
        select relation.id

        into v_promoted_relation_id

        from public.guardian_students
            as relation

        where relation.student_id =
              v_student_id

        order by
            relation.created_at,
            relation.id

        limit 1

        for update;

        if v_promoted_relation_id is not null then
            update public.guardian_students

            set is_primary_contact = true

            where id =
                  v_promoted_relation_id;
        end if;
    end if;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'deleted',

        'relation_id',
        p_relation_id,

        'guardian_id',
        v_guardian_id,

        'student_id',
        v_student_id,

        'was_primary_contact',
        v_was_primary,

        'promoted_relation_id',
        v_promoted_relation_id
    );
end;
$$;


-- =========================================================
-- 7. COMMENTS
-- =========================================================

comment on function
public.get_admin_guardian_student_options(
    uuid,
    text,
    integer
)
is
'Pilihan santri aktif yang belum terhubung dengan wali tertentu.';

comment on function
public.create_admin_guardian_student_relation(
    uuid,
    uuid,
    text,
    boolean
)
is
'Menghubungkan wali dengan santri serta mengatur kontak utama.';

comment on function
public.update_admin_guardian_student_relation(
    uuid,
    text,
    boolean
)
is
'Memperbarui jenis hubungan dan kontak utama wali-santri.';

comment on function
public.delete_admin_guardian_student_relation(
    uuid
)
is
'Melepas hubungan wali-santri dan mempromosikan kontak utama pengganti.';


-- =========================================================
-- 8. PRIVILEGES OPTIONS
-- =========================================================

revoke all on function
public.get_admin_guardian_student_options(
    uuid,
    text,
    integer
)
from public;

revoke all on function
public.get_admin_guardian_student_options(
    uuid,
    text,
    integer
)
from anon;

grant execute on function
public.get_admin_guardian_student_options(
    uuid,
    text,
    integer
)
to authenticated;


-- =========================================================
-- 9. PRIVILEGES CREATE RELATION
-- =========================================================

revoke all on function
public.create_admin_guardian_student_relation(
    uuid,
    uuid,
    text,
    boolean
)
from public;

revoke all on function
public.create_admin_guardian_student_relation(
    uuid,
    uuid,
    text,
    boolean
)
from anon;

grant execute on function
public.create_admin_guardian_student_relation(
    uuid,
    uuid,
    text,
    boolean
)
to authenticated;


-- =========================================================
-- 10. PRIVILEGES UPDATE RELATION
-- =========================================================

revoke all on function
public.update_admin_guardian_student_relation(
    uuid,
    text,
    boolean
)
from public;

revoke all on function
public.update_admin_guardian_student_relation(
    uuid,
    text,
    boolean
)
from anon;

grant execute on function
public.update_admin_guardian_student_relation(
    uuid,
    text,
    boolean
)
to authenticated;


-- =========================================================
-- 11. PRIVILEGES DELETE RELATION
-- =========================================================

revoke all on function
public.delete_admin_guardian_student_relation(
    uuid
)
from public;

revoke all on function
public.delete_admin_guardian_student_relation(
    uuid
)
from anon;

grant execute on function
public.delete_admin_guardian_student_relation(
    uuid
)
to authenticated;

commit;