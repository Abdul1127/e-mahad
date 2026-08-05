begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 042-create-admin-guardian-functions.sql
-- PURPOSE:
-- - Menambahkan data orang tua/wali
-- - Memperbarui identitas orang tua/wali
-- - Mengambil detail wali dan anak yang terhubung
-- - Membatasi akses khusus role Admin
--
-- STRUKTUR AKTUAL:
-- guardians:
-- id, profile_id, legacy_guardian_id, full_name,
-- phone, email, is_active, created_at, updated_at
--
-- guardian_students:
-- id, guardian_id, student_id, relationship_type,
-- is_primary_contact, created_at
-- =========================================================


-- =========================================================
-- 1. DETAIL WALI
-- =========================================================

create or replace function public.get_admin_guardian_detail(
    p_guardian_id uuid
)
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
    -- VALIDASI INPUT
    -- =====================================================

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
    end if;

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
            message = 'Akses detail wali ditolak.';
    end if;

    -- =====================================================
    -- SUSUN DETAIL WALI
    -- =====================================================

    with target_guardian as (
        select
            guardian.id,
            guardian.profile_id,
            guardian.legacy_guardian_id,
            guardian.full_name,
            guardian.phone,
            guardian.email,
            guardian.is_active,
            guardian.created_at,
            guardian.updated_at,

            (
                guardian.profile_id is not null
            ) as account_linked,

            coalesce(
                profile.is_active,
                false
            ) as account_active,

            auth_user.email::text
                as account_email

        from public.guardians as guardian

        left join public.profiles as profile
            on profile.id =
               guardian.profile_id

        left join auth.users as auth_user
            on auth_user.id =
               guardian.profile_id

        where guardian.id =
              p_guardian_id

        limit 1
    ),

    child_data as (
        select
            relation.id as relation_id,
            relation.relationship_type,
            relation.is_primary_contact,
            relation.created_at as linked_at,

            student.id as student_id,
            student.legacy_student_id,
            student.nis,
            student.full_name,
            student.gender,
            student.status,

            class_data.class_id,
            class_data.class_name,
            class_data.grade_level,
            class_data.academic_year_name

        from target_guardian as guardian

        inner join public.guardian_students
            as relation
            on relation.guardian_id =
               guardian.id

        inner join public.students as student
            on student.id =
               relation.student_id

        left join lateral (
            select
                class.id as class_id,
                class.name as class_name,
                class.grade_level,
                academic_year.name
                    as academic_year_name

            from public.class_enrollments
                as enrollment

            inner join public.classes as class
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
                enrollment.enrolled_at desc

            limit 1
        ) as class_data
            on true
    ),

    child_summary as (
        select
            count(*)::integer
                as children_count,

            count(*) filter (
                where status =
                      'active'::public.student_status
            )::integer
                as active_children_count,

            count(*) filter (
                where is_primary_contact = true
            )::integer
                as primary_contact_count

        from child_data
    )

    select
        case
            when not exists (
                select 1
                from target_guardian
            ) then null

            else jsonb_build_object(
                'generated_at',
                now(),

                'guardian',
                (
                    select jsonb_build_object(
                        'id',
                        guardian.id,

                        'profile_id',
                        guardian.profile_id,

                        'legacy_guardian_id',
                        guardian.legacy_guardian_id,

                        'full_name',
                        guardian.full_name,

                        'phone',
                        guardian.phone,

                        'email',
                        guardian.email,

                        'is_active',
                        guardian.is_active,

                        'created_at',
                        guardian.created_at,

                        'updated_at',
                        guardian.updated_at
                    )

                    from target_guardian
                        as guardian
                ),

                'account',
                (
                    select jsonb_build_object(
                        'linked',
                        guardian.account_linked,

                        'active',
                        guardian.account_active,

                        'profile_id',
                        guardian.profile_id,

                        'login_email',
                        guardian.account_email
                    )

                    from target_guardian
                        as guardian
                ),

                'summary',
                (
                    select jsonb_build_object(
                        'children_count',
                        summary.children_count,

                        'active_children_count',
                        summary.active_children_count,

                        'primary_contact_count',
                        summary.primary_contact_count
                    )

                    from child_summary
                        as summary
                ),

                'children',
                (
                    select coalesce(
                        jsonb_agg(
                            jsonb_build_object(
                                'relation_id',
                                child.relation_id,

                                'relationship_type',
                                child.relationship_type,

                                'is_primary_contact',
                                child.is_primary_contact,

                                'linked_at',
                                child.linked_at,

                                'student_id',
                                child.student_id,

                                'legacy_student_id',
                                child.legacy_student_id,

                                'nis',
                                child.nis,

                                'full_name',
                                child.full_name,

                                'gender',
                                child.gender,

                                'status',
                                child.status,

                                'class_id',
                                child.class_id,

                                'class_name',
                                child.class_name,

                                'grade_level',
                                child.grade_level,

                                'academic_year_name',
                                child.academic_year_name
                            )

                            order by
                                child.is_primary_contact desc,
                                lower(child.full_name)
                        ),
                        '[]'::jsonb
                    )

                    from child_data as child
                )
            )
        end

    into v_result;

    return v_result;
end;
$$;


-- =========================================================
-- 2. TAMBAH WALI
-- =========================================================

create or replace function public.create_admin_guardian(
    p_legacy_guardian_id text,
    p_full_name text,
    p_phone text,
    p_email text,
    p_is_active boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_legacy_guardian_id text;
    v_full_name text;
    v_phone text;
    v_email text;
    v_is_active boolean;

    v_guardian_id uuid;
    v_phone_digits text;
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
            message = 'Akses tambah wali ditolak.';
    end if;

    -- =====================================================
    -- NORMALISASI INPUT
    -- =====================================================

    v_legacy_guardian_id :=
        nullif(
            btrim(
                coalesce(
                    p_legacy_guardian_id,
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

    v_phone :=
        nullif(
            btrim(
                coalesce(
                    p_phone,
                    ''
                )
            ),
            ''
        );

    v_email :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_email,
                        ''
                    )
                )
            ),
            ''
        );

    v_is_active :=
        coalesce(
            p_is_active,
            true
        );

    -- =====================================================
    -- VALIDASI ID WALI
    -- =====================================================

    if v_legacy_guardian_id is not null
       and length(v_legacy_guardian_id) > 100 then
        raise exception
            'ID wali maksimal 100 karakter.';
    end if;

    if v_legacy_guardian_id is not null
       and exists (
           select 1

           from public.guardians as guardian

           where guardian.legacy_guardian_id
                 is not null

             and lower(
                 btrim(
                     guardian.legacy_guardian_id
                 )
             ) = lower(
                 v_legacy_guardian_id
             )
       ) then
        raise exception
            'ID wali % sudah digunakan.',
            v_legacy_guardian_id;
    end if;

    -- =====================================================
    -- VALIDASI NAMA
    -- =====================================================

    if length(v_full_name) < 2 then
        raise exception
            'Nama lengkap wali minimal 2 karakter.';
    end if;

    if length(v_full_name) > 200 then
        raise exception
            'Nama lengkap wali maksimal 200 karakter.';
    end if;

    -- =====================================================
    -- VALIDASI TELEPON
    -- =====================================================

    if v_phone is not null then
        if length(v_phone) > 30 then
            raise exception
                'Nomor telepon maksimal 30 karakter.';
        end if;

        if v_phone !~ '^[0-9+() ./-]+$' then
            raise exception
                'Format nomor telepon tidak valid.';
        end if;

        v_phone_digits :=
            regexp_replace(
                v_phone,
                '[^0-9]',
                '',
                'g'
            );

        if length(v_phone_digits) < 8 then
            raise exception
                'Nomor telepon minimal memiliki 8 digit.';
        end if;
    end if;

    -- =====================================================
    -- VALIDASI EMAIL
    -- =====================================================

    if v_email is not null then
        if length(v_email) > 254 then
            raise exception
                'Email maksimal 254 karakter.';
        end if;

        if v_email !~*
           '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
            raise exception
                'Format email tidak valid.';
        end if;
    end if;

    -- =====================================================
    -- INSERT WALI
    -- =====================================================

    insert into public.guardians (
        legacy_guardian_id,
        full_name,
        phone,
        email,
        is_active
    )
    values (
        v_legacy_guardian_id,
        v_full_name,
        v_phone,
        v_email,
        v_is_active
    )
    returning id
    into v_guardian_id;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'created',

        'guardian_id',
        v_guardian_id,

        'legacy_guardian_id',
        v_legacy_guardian_id,

        'full_name',
        v_full_name,

        'is_active',
        v_is_active
    );
end;
$$;


-- =========================================================
-- 3. EDIT WALI
-- =========================================================

create or replace function public.update_admin_guardian(
    p_guardian_id uuid,
    p_legacy_guardian_id text,
    p_full_name text,
    p_phone text,
    p_email text,
    p_is_active boolean
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
    v_legacy_guardian_id text;
    v_full_name text;
    v_phone text;
    v_email text;
    v_is_active boolean;

    v_phone_digits text;
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
            message = 'Akses edit wali ditolak.';
    end if;

    -- =====================================================
    -- VALIDASI GUARDIAN ID
    -- =====================================================

    if p_guardian_id is null then
        raise exception
            'Guardian ID wajib diisi.';
    end if;

    perform 1

    from public.guardians as guardian

    where guardian.id =
          p_guardian_id

    for update;

    if not found then
        raise exception
            'Data wali tidak ditemukan.';
    end if;

    -- =====================================================
    -- NORMALISASI INPUT
    -- =====================================================

    v_legacy_guardian_id :=
        nullif(
            btrim(
                coalesce(
                    p_legacy_guardian_id,
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

    v_phone :=
        nullif(
            btrim(
                coalesce(
                    p_phone,
                    ''
                )
            ),
            ''
        );

    v_email :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_email,
                        ''
                    )
                )
            ),
            ''
        );

    v_is_active :=
        coalesce(
            p_is_active,
            true
        );

    -- =====================================================
    -- VALIDASI ID WALI
    -- =====================================================

    if v_legacy_guardian_id is not null
       and length(v_legacy_guardian_id) > 100 then
        raise exception
            'ID wali maksimal 100 karakter.';
    end if;

    if v_legacy_guardian_id is not null
       and exists (
           select 1

           from public.guardians as guardian

           where guardian.id <>
                 p_guardian_id

             and guardian.legacy_guardian_id
                 is not null

             and lower(
                 btrim(
                     guardian.legacy_guardian_id
                 )
             ) = lower(
                 v_legacy_guardian_id
             )
       ) then
        raise exception
            'ID wali % sudah digunakan.',
            v_legacy_guardian_id;
    end if;

    -- =====================================================
    -- VALIDASI NAMA
    -- =====================================================

    if length(v_full_name) < 2 then
        raise exception
            'Nama lengkap wali minimal 2 karakter.';
    end if;

    if length(v_full_name) > 200 then
        raise exception
            'Nama lengkap wali maksimal 200 karakter.';
    end if;

    -- =====================================================
    -- VALIDASI TELEPON
    -- =====================================================

    if v_phone is not null then
        if length(v_phone) > 30 then
            raise exception
                'Nomor telepon maksimal 30 karakter.';
        end if;

        if v_phone !~ '^[0-9+() ./-]+$' then
            raise exception
                'Format nomor telepon tidak valid.';
        end if;

        v_phone_digits :=
            regexp_replace(
                v_phone,
                '[^0-9]',
                '',
                'g'
            );

        if length(v_phone_digits) < 8 then
            raise exception
                'Nomor telepon minimal memiliki 8 digit.';
        end if;
    end if;

    -- =====================================================
    -- VALIDASI EMAIL
    -- =====================================================

    if v_email is not null then
        if length(v_email) > 254 then
            raise exception
                'Email maksimal 254 karakter.';
        end if;

        if v_email !~*
           '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
            raise exception
                'Format email tidak valid.';
        end if;
    end if;

    -- =====================================================
    -- UPDATE WALI
    -- =====================================================

    update public.guardians

    set
        legacy_guardian_id =
            v_legacy_guardian_id,

        full_name =
            v_full_name,

        phone =
            v_phone,

        email =
            v_email,

        is_active =
            v_is_active,

        updated_at =
            now()

    where id =
          p_guardian_id;

    return jsonb_build_object(
        'success',
        true,

        'operation',
        'updated',

        'guardian_id',
        p_guardian_id,

        'legacy_guardian_id',
        v_legacy_guardian_id,

        'full_name',
        v_full_name,

        'is_active',
        v_is_active
    );
end;
$$;


-- =========================================================
-- 4. COMMENTS
-- =========================================================

comment on function public.get_admin_guardian_detail(uuid)
is
'Detail wali Admin beserta status akun dan santri yang terhubung.';

comment on function public.create_admin_guardian(
    text,
    text,
    text,
    text,
    boolean
)
is
'Membuat data orang tua atau wali melalui role Admin.';

comment on function public.update_admin_guardian(
    uuid,
    text,
    text,
    text,
    text,
    boolean
)
is
'Memperbarui data orang tua atau wali melalui role Admin.';


-- =========================================================
-- 5. PRIVILEGES DETAIL
-- =========================================================

revoke all on function
public.get_admin_guardian_detail(uuid)
from public;

revoke all on function
public.get_admin_guardian_detail(uuid)
from anon;

grant execute on function
public.get_admin_guardian_detail(uuid)
to authenticated;


-- =========================================================
-- 6. PRIVILEGES CREATE
-- =========================================================

revoke all on function public.create_admin_guardian(
    text,
    text,
    text,
    text,
    boolean
)
from public;

revoke all on function public.create_admin_guardian(
    text,
    text,
    text,
    text,
    boolean
)
from anon;

grant execute on function public.create_admin_guardian(
    text,
    text,
    text,
    text,
    boolean
)
to authenticated;


-- =========================================================
-- 7. PRIVILEGES UPDATE
-- =========================================================

revoke all on function public.update_admin_guardian(
    uuid,
    text,
    text,
    text,
    text,
    boolean
)
from public;

revoke all on function public.update_admin_guardian(
    uuid,
    text,
    text,
    text,
    text,
    boolean
)
from anon;

grant execute on function public.update_admin_guardian(
    uuid,
    text,
    text,
    text,
    text,
    boolean
)
to authenticated;

commit;