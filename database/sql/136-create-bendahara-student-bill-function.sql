begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 136-create-bendahara-student-bill-function.sql
--
-- PURPOSE:
-- Membuat tagihan individual untuk satu santri.
--
-- DIGUNAKAN OLEH:
-- Bendahara
--
-- VALIDATION:
-- - Harus login
-- - Harus role Bendahara
-- - Profile aktif
-- - Staff aktif
-- - Tahun ajaran aktif tersedia
-- - Santri aktif
-- - Judul wajib
-- - Kategori wajib
-- - Nominal > 0
-- - Periode valid
--
-- RESULT:
-- Mengembalikan tagihan yang baru dibuat.
--
-- SECURITY:
-- SECURITY DEFINER + RPC only.
-- =========================================================


create or replace function
public.create_bendahara_student_bill(
    p_student_id uuid,
    p_title text,
    p_category text,
    p_amount numeric,
    p_description text default null,
    p_period_label text default null,
    p_period_start date default null,
    p_period_end date default null,
    p_due_date date default null
)
returns jsonb
language plpgsql
volatile
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_staff_id uuid;
    v_staff_name text;

    v_academic_year_id uuid;
    v_academic_year_name text;

    v_student_name text;
    v_student_nis text;
    v_student_legacy_id text;
    v_student_gender text;

    v_title text;
    v_category text;
    v_description text;
    v_period_label text;

    v_bill_code text;
    v_bill_id uuid;

    v_created_at timestamptz;
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


    -- =====================================================
    -- B. ROLE
    -- =====================================================

    if not public.has_role(
        'bendahara'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses pembuatan tagihan Bendahara ditolak.';
    end if;


    -- =====================================================
    -- C. ACTIVE PROFILE
    -- =====================================================

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
            message = 'Profile Bendahara tidak aktif.';
    end if;


    -- =====================================================
    -- D. ACTIVE STAFF
    -- =====================================================

    select
        staff.id,
        staff.full_name

    into
        v_staff_id,
        v_staff_name

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
            message = 'Data staf Bendahara aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- E. CURRENT ACADEMIC YEAR
    -- =====================================================

    select
        academic_year.id,
        academic_year.name

    into
        v_academic_year_id,
        v_academic_year_name

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
    -- F. STUDENT
    -- =====================================================

    if p_student_id is null then
        raise exception
            'Santri wajib dipilih.';
    end if;


    select
        student.full_name,
        student.nis,
        student.legacy_student_id,
        student.gender::text

    into
        v_student_name,
        v_student_nis,
        v_student_legacy_id,
        v_student_gender

    from public.students
        as student

    where student.id =
          p_student_id

      and student.status =
          'active'

      and student.deleted_at
          is null;


    if not found then
        raise exception
            'Santri aktif tidak ditemukan.';
    end if;


    -- =====================================================
    -- G. NORMALIZE INPUT
    -- =====================================================

    v_title :=
        nullif(
            btrim(
                coalesce(
                    p_title,
                    ''
                )
            ),
            ''
        );


    v_category :=
        nullif(
            lower(
                btrim(
                    coalesce(
                        p_category,
                        ''
                    )
                )
            ),
            ''
        );


    v_description :=
        nullif(
            btrim(
                coalesce(
                    p_description,
                    ''
                )
            ),
            ''
        );


    v_period_label :=
        nullif(
            btrim(
                coalesce(
                    p_period_label,
                    ''
                )
            ),
            ''
        );


    -- =====================================================
    -- H. TITLE VALIDATION
    -- =====================================================

    if v_title is null then
        raise exception
            'Nama tagihan wajib diisi.';
    end if;


    if length(
        v_title
    ) > 150 then
        raise exception
            'Nama tagihan maksimal 150 karakter.';
    end if;


    -- =====================================================
    -- I. CATEGORY VALIDATION
    -- =====================================================

    if v_category is null then
        raise exception
            'Kategori tagihan wajib diisi.';
    end if;


    if length(
        v_category
    ) > 80 then
        raise exception
            'Kategori tagihan maksimal 80 karakter.';
    end if;


    -- =====================================================
    -- J. DESCRIPTION
    -- =====================================================

    if v_description is not null
       and length(
           v_description
       ) > 1000
    then
        raise exception
            'Keterangan tagihan maksimal 1000 karakter.';
    end if;


    -- =====================================================
    -- K. PERIOD LABEL
    -- =====================================================

    if v_period_label is not null
       and length(
           v_period_label
       ) > 100
    then
        raise exception
            'Label periode maksimal 100 karakter.';
    end if;


    -- =====================================================
    -- L. AMOUNT
    -- =====================================================

    if p_amount is null
       or p_amount <= 0
    then
        raise exception
            'Nominal tagihan harus lebih besar dari 0.';
    end if;


    if p_amount >
       999999999999.99
    then
        raise exception
            'Nominal tagihan melebihi batas yang diperbolehkan.';
    end if;


    -- =====================================================
    -- M. PERIOD VALIDATION
    -- =====================================================

    if p_period_start is not null
       and p_period_end is not null
       and p_period_end <
           p_period_start
    then
        raise exception
            'Tanggal akhir periode tidak boleh sebelum tanggal mulai.';
    end if;


    -- =====================================================
    -- N. GENERATE BILL CODE
    --
    -- Contoh:
    --
    -- TAG-202608-A1B2C3D4
    --
    -- UUID digunakan supaya aman terhadap concurrency
    -- tanpa membutuhkan sequence tambahan.
    -- =====================================================

    v_bill_code :=
        'TAG-' ||
        to_char(
            current_date,
            'YYYYMM'
        ) ||
        '-' ||
        upper(
            substr(
                replace(
                    gen_random_uuid()::text,
                    '-',
                    ''
                ),
                1,
                8
            )
        );


    -- =====================================================
    -- O. INSERT
    -- =====================================================

    insert into public.student_bills (
        academic_year_id,
        student_id,

        bill_code,

        title,
        description,
        category,

        period_label,
        period_start,
        period_end,

        amount,
        due_date,

        status,

        created_by_staff_id,
        updated_by_staff_id
    )
    values (
        v_academic_year_id,
        p_student_id,

        v_bill_code,

        v_title,
        v_description,
        v_category,

        v_period_label,
        p_period_start,
        p_period_end,

        p_amount,
        p_due_date,

        'unpaid',

        v_staff_id,
        v_staff_id
    )
    returning
        id,
        created_at

    into
        v_bill_id,
        v_created_at;


    -- =====================================================
    -- P. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'message',
        'Tagihan santri berhasil dibuat.',

        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name
        ),

        'staff',
        jsonb_build_object(
            'id',
            v_staff_id,

            'full_name',
            v_staff_name
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

        'bill',
        jsonb_build_object(
            'id',
            v_bill_id,

            'bill_code',
            v_bill_code,

            'title',
            v_title,

            'description',
            v_description,

            'category',
            v_category,

            'period_label',
            v_period_label,

            'period_start',
            p_period_start,

            'period_end',
            p_period_end,

            'amount',
            p_amount,

            'paid_amount',
            0,

            'outstanding_amount',
            p_amount,

            'due_date',
            p_due_date,

            'status',
            'unpaid',

            'created_at',
            v_created_at
        )
    );

end;
$function$;


-- =========================================================
-- COMMENT
-- =========================================================

comment on function
public.create_bendahara_student_bill(
    uuid,
    text,
    text,
    numeric,
    text,
    text,
    date,
    date,
    date
)
is
'Membuat tagihan individual untuk santri aktif oleh Bendahara pada tahun ajaran aktif.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all
on function
public.create_bendahara_student_bill(
    uuid,
    text,
    text,
    numeric,
    text,
    text,
    date,
    date,
    date
)
from public;


revoke all
on function
public.create_bendahara_student_bill(
    uuid,
    text,
    text,
    numeric,
    text,
    text,
    date,
    date,
    date
)
from anon;


grant execute
on function
public.create_bendahara_student_bill(
    uuid,
    text,
    text,
    numeric,
    text,
    text,
    date,
    date,
    date
)
to authenticated;


commit;