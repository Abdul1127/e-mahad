begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 174-create-mahad-head-journal-module.sql
--
-- MODULE:
-- JURNAL KEPALA MA'HAD
--
-- SOURCE:
-- Sheet "JURNAL kepala mahad"
--
-- ACCESS:
-- Kepala Ma'had:
-- - create/open
-- - edit draft
-- - submit
-- - upload evidence
-- - lihat riwayat sendiri
--
-- Penanggung Jawab:
-- - read-only
-- - hanya jurnal submitted
--
-- EVIDENCE:
-- Private Supabase Storage
--
-- =========================================================


-- =========================================================
-- 1. CHECKLIST MASTER
-- =========================================================

create table if not exists
public.mahad_head_journal_checklist_items (
    id uuid
        primary key
        default gen_random_uuid(),

    item_key text
        not null
        unique,

    pillar_code text
        not null,

    pillar_name text
        not null,

    equivalent_jtm smallint
        not null
        default 3,

    sort_order smallint
        not null,

    label text
        not null,

    is_active boolean
        not null
        default true,

    created_at timestamptz
        not null
        default now(),

    updated_at timestamptz
        not null
        default now(),

    constraint mahad_head_checklist_pillar_check
        check (
            pillar_code in (
                'student_care',
                'tahfiz_academic',
                'facilities_digital',
                'administration_staff'
            )
        ),

    constraint mahad_head_checklist_jtm_check
        check (
            equivalent_jtm > 0
        ),

    constraint mahad_head_checklist_sort_check
        check (
            sort_order > 0
        ),

    constraint mahad_head_checklist_label_check
        check (
            length(
                btrim(label)
            ) > 0
        )
);


-- =========================================================
-- 2. JOURNAL HEADER
-- =========================================================

create table if not exists
public.mahad_head_journals (
    id uuid
        primary key
        default gen_random_uuid(),

    academic_year_id uuid
        not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    journal_date date
        not null,

    performance_notes text,

    obstacles_follow_up text,

    evidence_path text,

    status text
        not null
        default 'draft',

    created_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    updated_by_staff_id uuid
        not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    submitted_at timestamptz,

    created_at timestamptz
        not null
        default now(),

    updated_at timestamptz
        not null
        default now(),

    constraint mahad_head_journals_status_check
        check (
            status in (
                'draft',
                'submitted'
            )
        ),

    constraint mahad_head_journals_performance_notes_check
        check (
            performance_notes is null

            or length(
                performance_notes
            ) <= 5000
        ),

    constraint mahad_head_journals_obstacles_check
        check (
            obstacles_follow_up is null

            or length(
                obstacles_follow_up
            ) <= 5000
        ),

    constraint mahad_head_journals_submission_check
        check (
            (
                status = 'draft'
                and submitted_at is null
            )

            or

            (
                status = 'submitted'
                and submitted_at is not null
            )
        ),

    constraint mahad_head_journals_unique_day
        unique (
            academic_year_id,
            created_by_staff_id,
            journal_date
        )
);


-- =========================================================
-- 3. SELECTED CHECKLIST ITEMS
--
-- Hanya item yang dicentang yang disimpan.
-- =========================================================

create table if not exists
public.mahad_head_journal_checks (
    id uuid
        primary key
        default gen_random_uuid(),

    journal_id uuid
        not null
        references public.mahad_head_journals(id)
        on update cascade
        on delete cascade,

    checklist_item_id uuid
        not null
        references public.mahad_head_journal_checklist_items(id)
        on update cascade
        on delete restrict,

    created_at timestamptz
        not null
        default now(),

    constraint mahad_head_journal_checks_unique
        unique (
            journal_id,
            checklist_item_id
        )
);


-- =========================================================
-- 4. INDEXES
-- =========================================================

create index if not exists
mahad_head_journals_academic_year_idx

on public.mahad_head_journals (
    academic_year_id
);


create index if not exists
mahad_head_journals_staff_idx

on public.mahad_head_journals (
    created_by_staff_id
);


create index if not exists
mahad_head_journals_date_idx

on public.mahad_head_journals (
    journal_date desc
);


create index if not exists
mahad_head_journals_status_idx

on public.mahad_head_journals (
    status
);


create index if not exists
mahad_head_journal_checks_journal_idx

on public.mahad_head_journal_checks (
    journal_id
);


-- =========================================================
-- 5. UPDATED_AT
-- =========================================================

drop trigger if exists
set_mahad_head_journal_checklist_items_updated_at
on public.mahad_head_journal_checklist_items;


create trigger
set_mahad_head_journal_checklist_items_updated_at

before update
on public.mahad_head_journal_checklist_items

for each row

execute function
public.set_updated_at();


drop trigger if exists
set_mahad_head_journals_updated_at
on public.mahad_head_journals;


create trigger
set_mahad_head_journals_updated_at

before update
on public.mahad_head_journals

for each row

execute function
public.set_updated_at();


-- =========================================================
-- 6. SEED CHECKLIST
--
-- PILLAR 1
-- Manajemen Kesiswaan & Pengasuhan
-- =========================================================

insert into
public.mahad_head_journal_checklist_items (
    item_key,
    pillar_code,
    pillar_name,
    equivalent_jtm,
    sort_order,
    label,
    is_active
)
values
(
    'student_care_01',
    'student_care',
    'Manajemen Kesiswaan & Pengasuhan',
    3,
    1,
    'Memimpin rapat koordinasi dengan Koordinator Pengasuhan & Pengasuh Asrama',
    true
),
(
    'student_care_02',
    'student_care',
    'Manajemen Kesiswaan & Pengasuhan',
    3,
    2,
    'Melakukan konseling / penanganan disiplin khusus santri',
    true
),
(
    'student_care_03',
    'student_care',
    'Manajemen Kesiswaan & Pengasuhan',
    3,
    3,
    'Melakukan monitoring dan evaluasi kondisi kesehatan serta ketertiban asrama',
    true
),
(
    'student_care_04',
    'student_care',
    'Manajemen Kesiswaan & Pengasuhan',
    3,
    4,
    'Mengoordinasikan komunikasi & layanan informasi perkembangan santri kepada orang tua/wali',
    true
),
(
    'student_care_05',
    'student_care',
    'Manajemen Kesiswaan & Pengasuhan',
    3,
    5,
    'Meninjau rekapitulasi presensi dan catatan kedisiplinan harian santri',
    true
),

-- =========================================================
-- PILLAR 2
-- Manajemen Kurikulum Tahfiz & Akademik
-- =========================================================

(
    'tahfiz_academic_01',
    'tahfiz_academic',
    'Manajemen Kurikulum Tahfiz & Akademik',
    3,
    1,
    'Monitoring dan evaluasi setoran ziadah / muraja''ah via dashboard aplikasi laporan pembina tahfiz perpekan',
    true
),
(
    'tahfiz_academic_02',
    'tahfiz_academic',
    'Manajemen Kurikulum Tahfiz & Akademik',
    3,
    2,
    'Mengoordinasikan dan meninjau pelaksanaan program Klinik Tahsin / Remedial',
    true
),
(
    'tahfiz_academic_03',
    'tahfiz_academic',
    'Manajemen Kurikulum Tahfiz & Akademik',
    3,
    3,
    'Memimpin / menyetujui pelaksanaan Ujian Tasmi'' & Kenaikan Juz santri',
    true
),
(
    'tahfiz_academic_04',
    'tahfiz_academic',
    'Manajemen Kurikulum Tahfiz & Akademik',
    3,
    4,
    'Melakukan evaluasi kinerja Pembina Tahfiz dan Pembina Tilawah',
    true
),
(
    'tahfiz_academic_05',
    'tahfiz_academic',
    'Manajemen Kurikulum Tahfiz & Akademik',
    3,
    5,
    'Mengatur transisi dan efektivitas jadwal Sistem Blok Pembelajaran',
    true
),

-- =========================================================
-- PILLAR 3
-- Sarana Prasarana, Logistik & Sarana Digital
-- =========================================================

(
    'facilities_digital_01',
    'facilities_digital',
    'Sarana Prasarana, Logistik & Sarana Digital',
    3,
    1,
    'Inspeksi kelayakan sarana kamar, kamar mandi, dan fasilitas bersama asrama',
    true
),
(
    'facilities_digital_02',
    'facilities_digital',
    'Sarana Prasarana, Logistik & Sarana Digital',
    3,
    2,
    'Supervisi pasokan makanan dapur, nutrisi, serta kebersihan area makan santri, kelas, dan asrama',
    true
),
(
    'facilities_digital_03',
    'facilities_digital',
    'Sarana Prasarana, Logistik & Sarana Digital',
    3,
    3,
    'Pemeliharaan dan pengelolaan aplikasi',
    true
),
(
    'facilities_digital_04',
    'facilities_digital',
    'Sarana Prasarana, Logistik & Sarana Digital',
    3,
    4,
    'Monitoring operasional unit kewirausahaan Ma''had (laundry dan warung santri)',
    true
),
(
    'facilities_digital_05',
    'facilities_digital',
    'Sarana Prasarana, Logistik & Sarana Digital',
    3,
    5,
    'Pengurusan dan koordinasi perbaikan fisik / quick fix fasilitas rusak',
    true
),

-- =========================================================
-- PILLAR 4
-- Supervisi Administrasi & Kepegawaian
-- =========================================================

(
    'administration_staff_01',
    'administration_staff',
    'Supervisi Administrasi & Kepegawaian',
    3,
    1,
    'Memeriksa dan menyetujui rekapitulasi keuangan harian/pekanan bersama Bendahara',
    true
),
(
    'administration_staff_02',
    'administration_staff',
    'Supervisi Administrasi & Kepegawaian',
    3,
    2,
    'Mengevaluasi kerapian arsip, legalitas, dan administrasi kesekretariatan bersama Sekretaris',
    true
),
(
    'administration_staff_03',
    'administration_staff',
    'Supervisi Administrasi & Kepegawaian',
    3,
    3,
    'Menyusun laporan kinerja mingguan/bulanan untuk dikirimkan ke Kepala Madrasah',
    true
),
(
    'administration_staff_04',
    'administration_staff',
    'Supervisi Administrasi & Kepegawaian',
    3,
    4,
    'Memimpin evaluasi berkala kinerja seluruh staf dan unsur pendukung Ma''had',
    true
)

on conflict (
    item_key
)

do update
set
    pillar_code =
        excluded.pillar_code,

    pillar_name =
        excluded.pillar_name,

    equivalent_jtm =
        excluded.equivalent_jtm,

    sort_order =
        excluded.sort_order,

    label =
        excluded.label,

    is_active =
        excluded.is_active;


-- =========================================================
-- 7. PRIVATE STORAGE BUCKET
-- =========================================================

insert into
storage.buckets (
    id,
    name,
    public,
    file_size_limit,
    allowed_mime_types
)
values (
    'mahad-head-journal-evidence',
    'mahad-head-journal-evidence',
    false,
    5242880,
    array[
        'image/jpeg',
        'image/png',
        'image/webp',
        'application/pdf'
    ]::text[]
)

on conflict (
    id
)

do update
set
    public =
        false,

    file_size_limit =
        excluded.file_size_limit,

    allowed_mime_types =
        excluded.allowed_mime_types;


-- =========================================================
-- 8. STORAGE ACCESS HELPER
-- =========================================================

create or replace function
public.can_access_mahad_head_journal_evidence(
    p_object_name text,
    p_for_write boolean default false
)
returns boolean
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_journal_id_text text;
    v_journal_id uuid;

    v_role_is_kepala boolean;
    v_role_is_penanggung_jawab boolean;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        return false;
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
        return false;
    end if;


    v_journal_id_text :=
        split_part(
            coalesce(
                p_object_name,
                ''
            ),
            '/',
            1
        );


    if v_journal_id_text !~
       '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89aAbB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$'
    then
        return false;
    end if;


    if split_part(
        coalesce(
            p_object_name,
            ''
        ),
        '/',
        2
    ) = ''
    then
        return false;
    end if;


    v_journal_id :=
        v_journal_id_text::uuid;


    v_role_is_kepala :=
        public.has_role(
            'kepala_mahad'
        );


    v_role_is_penanggung_jawab :=
        public.has_role(
            'penanggung_jawab'
        );


    if not v_role_is_kepala
       and not v_role_is_penanggung_jawab
    then
        return false;
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

    limit 1;


    if v_staff_id is null then
        return false;
    end if;


    -- =====================================================
    -- KEPALA MA'HAD
    -- =====================================================

    if v_role_is_kepala then

        if p_for_write then

            return exists (
                select 1

                from public.mahad_head_journals
                    as journal

                inner join public.academic_years
                    as academic_year

                    on academic_year.id =
                       journal.academic_year_id

                where journal.id =
                      v_journal_id

                  and journal.created_by_staff_id =
                      v_staff_id

                  and journal.status =
                      'draft'

                  and academic_year.is_current =
                      true
            );

        end if;


        return exists (
            select 1

            from public.mahad_head_journals
                as journal

            inner join public.academic_years
                as academic_year

                on academic_year.id =
                   journal.academic_year_id

            where journal.id =
                  v_journal_id

              and journal.created_by_staff_id =
                  v_staff_id

              and journal.evidence_path =
                  p_object_name

              and academic_year.is_current =
                  true
        );

    end if;


    -- =====================================================
    -- PENANGGUNG JAWAB
    -- READ ONLY
    -- =====================================================

    if p_for_write then
        return false;
    end if;


    return exists (
        select 1

        from public.mahad_head_journals
            as journal

        inner join public.academic_years
            as academic_year

            on academic_year.id =
               journal.academic_year_id

        where journal.id =
              v_journal_id

          and journal.status =
              'submitted'

          and journal.evidence_path =
              p_object_name

          and academic_year.is_current =
              true
    );

end;
$function$;


-- =========================================================
-- 9. STORAGE POLICIES
-- =========================================================

drop policy if exists
"mahad_head_journal_evidence_select"
on storage.objects;


create policy
"mahad_head_journal_evidence_select"

on storage.objects

for select

to authenticated

using (
    bucket_id =
        'mahad-head-journal-evidence'

    and public.can_access_mahad_head_journal_evidence(
        name,
        false
    )
);


drop policy if exists
"mahad_head_journal_evidence_insert"
on storage.objects;


create policy
"mahad_head_journal_evidence_insert"

on storage.objects

for insert

to authenticated

with check (
    bucket_id =
        'mahad-head-journal-evidence'

    and public.can_access_mahad_head_journal_evidence(
        name,
        true
    )
);


drop policy if exists
"mahad_head_journal_evidence_delete"
on storage.objects;


create policy
"mahad_head_journal_evidence_delete"

on storage.objects

for delete

to authenticated

using (
    bucket_id =
        'mahad-head-journal-evidence'

    and public.can_access_mahad_head_journal_evidence(
        name,
        true
    )
);


-- =========================================================
-- 10. TABLE RLS
--
-- Semua akses aplikasi melalui RPC.
-- =========================================================

alter table
public.mahad_head_journal_checklist_items
enable row level security;


alter table
public.mahad_head_journals
enable row level security;


alter table
public.mahad_head_journal_checks
enable row level security;


drop policy if exists
"mahad_head_checklist_service_role_all"
on public.mahad_head_journal_checklist_items;


create policy
"mahad_head_checklist_service_role_all"

on public.mahad_head_journal_checklist_items

for all

to service_role

using (
    true
)

with check (
    true
);


drop policy if exists
"mahad_head_journals_service_role_all"
on public.mahad_head_journals;


create policy
"mahad_head_journals_service_role_all"

on public.mahad_head_journals

for all

to service_role

using (
    true
)

with check (
    true
);


drop policy if exists
"mahad_head_journal_checks_service_role_all"
on public.mahad_head_journal_checks;


create policy
"mahad_head_journal_checks_service_role_all"

on public.mahad_head_journal_checks

for all

to service_role

using (
    true
)

with check (
    true
);


revoke all
on table
public.mahad_head_journal_checklist_items
from anon,
     authenticated;


revoke all
on table
public.mahad_head_journals
from anon,
     authenticated;


revoke all
on table
public.mahad_head_journal_checks
from anon,
     authenticated;


grant select,
      insert,
      update,
      delete
on table
public.mahad_head_journal_checklist_items
to service_role;


grant select,
      insert,
      update,
      delete
on table
public.mahad_head_journals
to service_role;


grant select,
      insert,
      update,
      delete
on table
public.mahad_head_journal_checks
to service_role;


-- =========================================================
-- 11. CREATE OR OPEN JOURNAL
-- =========================================================

create or replace function
public.create_or_open_kepala_mahad_journal(
    p_journal_date date
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

    v_academic_year_id uuid;
    v_academic_year_start date;
    v_academic_year_end date;

    v_journal_id uuid;
    v_created boolean :=
        false;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null then
        raise exception using
            errcode = '42501',
            message = 'Pengguna belum terautentikasi.';
    end if;


    if not public.has_role(
        'kepala_mahad'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses Jurnal Kepala Ma''had ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Kepala Ma''had aktif tidak ditemukan.';
    end if;


    select
        academic_year.id,
        academic_year.start_date,
        academic_year.end_date

    into
        v_academic_year_id,
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


    if p_journal_date is null then
        raise exception
            'Tanggal pelaksanaan wajib diisi.';
    end if;


    if p_journal_date <
       v_academic_year_start

       or p_journal_date >
          v_academic_year_end
    then
        raise exception
            'Tanggal jurnal berada di luar tahun ajaran aktif.';
    end if;


    select
        journal.id

    into
        v_journal_id

    from public.mahad_head_journals
        as journal

    where journal.academic_year_id =
          v_academic_year_id

      and journal.created_by_staff_id =
          v_staff_id

      and journal.journal_date =
          p_journal_date

    limit 1;


    if v_journal_id is null then

        insert into
        public.mahad_head_journals (
            academic_year_id,
            journal_date,
            status,
            created_by_staff_id,
            updated_by_staff_id
        )
        values (
            v_academic_year_id,
            p_journal_date,
            'draft',
            v_staff_id,
            v_staff_id
        )
        returning id
        into v_journal_id;


        v_created :=
            true;

    end if;


    return jsonb_build_object(
        'success',
        true,

        'created',
        v_created,

        'journal_id',
        v_journal_id
    );

end;
$function$;


-- =========================================================
-- 12. KEPALA MA'HAD JOURNAL LIST
-- =========================================================

create or replace function
public.get_kepala_mahad_journal_overview(
    p_date_from date default null,
    p_date_to date default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;
    v_staff_name text;

    v_academic_year_id uuid;
    v_academic_year_name text;

    v_date_from date;
    v_date_to date;

    v_items jsonb :=
        '[]'::jsonb;

    v_total_count integer :=
        0;

    v_draft_count integer :=
        0;

    v_submitted_count integer :=
        0;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null
       or not public.has_role(
           'kepala_mahad'
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Akses Jurnal Kepala Ma''had ditolak.';
    end if;


    select
        staff.id,
        staff.full_name

    into
        v_staff_id,
        v_staff_name

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Kepala Ma''had aktif tidak ditemukan.';
    end if;


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


    v_date_from :=
        coalesce(
            p_date_from,
            date_trunc(
                'month',
                current_date
            )::date
        );


    v_date_to :=
        coalesce(
            p_date_to,
            current_date
        );


    if v_date_to <
       v_date_from
    then
        raise exception
            'Rentang tanggal tidak valid.';
    end if;


    select
        coalesce(
            jsonb_agg(
                journal_data.payload

                order by
                    journal_data.journal_date desc,
                    journal_data.journal_id desc
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            journal.id
                as journal_id,

            journal.journal_date,

            jsonb_build_object(
                'id',
                journal.id,

                'journal_date',
                journal.journal_date,

                'status',
                journal.status,

                'performance_notes',
                journal.performance_notes,

                'obstacles_follow_up',
                journal.obstacles_follow_up,

                'has_evidence',
                journal.evidence_path
                    is not null,

                'evidence_path',
                journal.evidence_path,

                'submitted_at',
                journal.submitted_at,

                'updated_at',
                journal.updated_at,

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
                (
                    select
                        count(*)::integer

                    from public.mahad_head_journal_checklist_items
                        as checklist_item

                    where checklist_item.is_active =
                          true
                )
            )
                as payload

        from public.mahad_head_journals
            as journal

        where journal.academic_year_id =
              v_academic_year_id

          and journal.created_by_staff_id =
              v_staff_id

          and journal.journal_date
              between
              v_date_from
              and
              v_date_to
    )
        as journal_data;


    select
        count(*)::integer,

        count(*) filter (
            where journal.status =
                  'draft'
        )::integer,

        count(*) filter (
            where journal.status =
                  'submitted'
        )::integer

    into
        v_total_count,
        v_draft_count,
        v_submitted_count

    from public.mahad_head_journals
        as journal

    where journal.academic_year_id =
          v_academic_year_id

      and journal.created_by_staff_id =
          v_staff_id

      and journal.journal_date
          between
          v_date_from
          and
          v_date_to;


    return jsonb_build_object(
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

        'filters',
        jsonb_build_object(
            'date_from',
            v_date_from,

            'date_to',
            v_date_to
        ),

        'summary',
        jsonb_build_object(
            'total_count',
            v_total_count,

            'draft_count',
            v_draft_count,

            'submitted_count',
            v_submitted_count
        ),

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- 13. KEPALA MA'HAD DETAIL
-- =========================================================

create or replace function
public.get_kepala_mahad_journal_detail(
    p_journal_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_academic_year_id uuid;

    v_journal jsonb;
    v_checklist jsonb :=
        '[]'::jsonb;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null
       or not public.has_role(
           'kepala_mahad'
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Akses Jurnal Kepala Ma''had ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    limit 1;


    select
        jsonb_build_object(
            'id',
            journal.id,

            'journal_date',
            journal.journal_date,

            'status',
            journal.status,

            'performance_notes',
            journal.performance_notes,

            'obstacles_follow_up',
            journal.obstacles_follow_up,

            'evidence_path',
            journal.evidence_path,

            'has_evidence',
            journal.evidence_path
                is not null,

            'submitted_at',
            journal.submitted_at,

            'created_at',
            journal.created_at,

            'updated_at',
            journal.updated_at
        )

    into
        v_journal

    from public.mahad_head_journals
        as journal

    where journal.id =
          p_journal_id

      and journal.academic_year_id =
          v_academic_year_id

      and journal.created_by_staff_id =
          v_staff_id

    limit 1;


    if v_journal is null then
        raise exception using
            errcode = '42501',
            message = 'Jurnal tidak ditemukan atau tidak dapat diakses.';
    end if;


    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    checklist_item.id,

                    'item_key',
                    checklist_item.item_key,

                    'pillar_code',
                    checklist_item.pillar_code,

                    'pillar_name',
                    checklist_item.pillar_name,

                    'equivalent_jtm',
                    checklist_item.equivalent_jtm,

                    'sort_order',
                    checklist_item.sort_order,

                    'label',
                    checklist_item.label,

                    'is_checked',
                    exists (
                        select 1

                        from public.mahad_head_journal_checks
                            as journal_check

                        where journal_check.journal_id =
                              p_journal_id

                          and journal_check.checklist_item_id =
                              checklist_item.id
                    )
                )

                order by
                    case checklist_item.pillar_code
                        when 'student_care'
                            then 1

                        when 'tahfiz_academic'
                            then 2

                        when 'facilities_digital'
                            then 3

                        when 'administration_staff'
                            then 4

                        else 99
                    end,

                    checklist_item.sort_order
            ),
            '[]'::jsonb
        )

    into
        v_checklist

    from public.mahad_head_journal_checklist_items
        as checklist_item

    where checklist_item.is_active =
          true;


    return jsonb_build_object(
        'journal',
        v_journal,

        'checklist',
        v_checklist
    );

end;
$function$;


-- =========================================================
-- 14. SAVE DRAFT
-- =========================================================

create or replace function
public.save_kepala_mahad_journal(
    p_journal_id uuid,
    p_checked_item_keys text[],
    p_performance_notes text default null,
    p_obstacles_follow_up text default null
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

    v_academic_year_id uuid;

    v_checked_item_keys text[] :=
        coalesce(
            p_checked_item_keys,
            array[]::text[]
        );

    v_performance_notes text;
    v_obstacles_follow_up text;

    v_input_count integer;
    v_distinct_count integer;
    v_valid_count integer;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null
       or not public.has_role(
           'kepala_mahad'
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Akses Jurnal Kepala Ma''had ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data staf Kepala Ma''had aktif tidak ditemukan.';
    end if;


    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    limit 1;


    perform 1

    from public.mahad_head_journals
        as journal

    where journal.id =
          p_journal_id

      and journal.academic_year_id =
          v_academic_year_id

      and journal.created_by_staff_id =
          v_staff_id

      and journal.status =
          'draft'

    for update;


    if not found then
        raise exception
            'Jurnal tidak ditemukan, sudah dikirim, atau tidak dapat diedit.';
    end if;


    v_performance_notes :=
        nullif(
            btrim(
                coalesce(
                    p_performance_notes,
                    ''
                )
            ),
            ''
        );


    v_obstacles_follow_up :=
        nullif(
            btrim(
                coalesce(
                    p_obstacles_follow_up,
                    ''
                )
            ),
            ''
        );


    if v_performance_notes is not null
       and length(
           v_performance_notes
       ) > 5000
    then
        raise exception
            'Catatan kinerja maksimal 5000 karakter.';
    end if;


    if v_obstacles_follow_up is not null
       and length(
           v_obstacles_follow_up
       ) > 5000
    then
        raise exception
            'Kendala dan tindak lanjut maksimal 5000 karakter.';
    end if;


    v_input_count :=
        cardinality(
            v_checked_item_keys
        );


    select
        count(
            distinct item_key
        )::integer

    into
        v_distinct_count

    from unnest(
        v_checked_item_keys
    )
        as input_item(
            item_key
        );


    if v_distinct_count <>
       v_input_count
    then
        raise exception
            'Terdapat checklist yang dikirim lebih dari satu kali.';
    end if;


    select
        count(*)::integer

    into
        v_valid_count

    from public.mahad_head_journal_checklist_items
        as checklist_item

    where checklist_item.is_active =
          true

      and checklist_item.item_key =
          any(
              v_checked_item_keys
          );


    if v_valid_count <>
       v_input_count
    then
        raise exception
            'Terdapat item checklist yang tidak valid.';
    end if;


    delete from
    public.mahad_head_journal_checks

    where journal_id =
          p_journal_id;


    if v_input_count >
       0
    then

        insert into
        public.mahad_head_journal_checks (
            journal_id,
            checklist_item_id
        )

        select
            p_journal_id,
            checklist_item.id

        from public.mahad_head_journal_checklist_items
            as checklist_item

        where checklist_item.is_active =
              true

          and checklist_item.item_key =
              any(
                  v_checked_item_keys
              );

    end if;


    update
    public.mahad_head_journals

    set
        performance_notes =
            v_performance_notes,

        obstacles_follow_up =
            v_obstacles_follow_up,

        updated_by_staff_id =
            v_staff_id

    where id =
          p_journal_id;


    return
        public.get_kepala_mahad_journal_detail(
            p_journal_id
        );

end;
$function$;


-- =========================================================
-- 15. ATTACH EVIDENCE PATH
-- =========================================================

create or replace function
public.attach_kepala_mahad_journal_evidence(
    p_journal_id uuid,
    p_evidence_path text
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

    v_academic_year_id uuid;

    v_existing_path text;

    v_path text;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null
       or not public.has_role(
           'kepala_mahad'
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Akses bukti Jurnal Kepala Ma''had ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    limit 1;


    v_path :=
        nullif(
            btrim(
                coalesce(
                    p_evidence_path,
                    ''
                )
            ),
            ''
        );


    if v_path is null then
        raise exception
            'Path bukti kinerja wajib diisi.';
    end if;


    if split_part(
        v_path,
        '/',
        1
    ) <>
       p_journal_id::text
    then
        raise exception
            'Path bukti tidak sesuai dengan jurnal.';
    end if;


    select
        journal.evidence_path

    into
        v_existing_path

    from public.mahad_head_journals
        as journal

    where journal.id =
          p_journal_id

      and journal.academic_year_id =
          v_academic_year_id

      and journal.created_by_staff_id =
          v_staff_id

      and journal.status =
          'draft'

    for update;


    if not found then
        raise exception
            'Jurnal tidak ditemukan, sudah dikirim, atau tidak dapat diedit.';
    end if;


    if v_existing_path is not null
       and v_existing_path <>
           v_path
    then
        raise exception
            'Jurnal sudah mempunyai bukti kinerja.';
    end if;


    if not exists (
        select 1

        from storage.objects
            as storage_object

        where storage_object.bucket_id =
              'mahad-head-journal-evidence'

          and storage_object.name =
              v_path
    ) then
        raise exception
            'File bukti belum ditemukan pada private Storage.';
    end if;


    update
    public.mahad_head_journals

    set
        evidence_path =
            v_path,

        updated_by_staff_id =
            v_staff_id

    where id =
          p_journal_id;


    return
        public.get_kepala_mahad_journal_detail(
            p_journal_id
        );

end;
$function$;


-- =========================================================
-- 16. SUBMIT JOURNAL
-- =========================================================

create or replace function
public.submit_kepala_mahad_journal(
    p_journal_id uuid
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

    v_academic_year_id uuid;

    v_performance_notes text;

    v_check_count integer;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null
       or not public.has_role(
           'kepala_mahad'
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Akses Jurnal Kepala Ma''had ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    select
        academic_year.id

    into
        v_academic_year_id

    from public.academic_years
        as academic_year

    where academic_year.is_current =
          true

    limit 1;


    select
        journal.performance_notes

    into
        v_performance_notes

    from public.mahad_head_journals
        as journal

    where journal.id =
          p_journal_id

      and journal.academic_year_id =
          v_academic_year_id

      and journal.created_by_staff_id =
          v_staff_id

      and journal.status =
          'draft'

    for update;


    if not found then
        raise exception
            'Jurnal tidak ditemukan atau sudah dikirim.';
    end if;


    select
        count(*)::integer

    into
        v_check_count

    from public.mahad_head_journal_checks
        as journal_check

    where journal_check.journal_id =
          p_journal_id;


    if v_check_count =
       0
    then
        raise exception
            'Pilih minimal satu kegiatan yang telah dilaksanakan.';
    end if;


    if nullif(
        btrim(
            coalesce(
                v_performance_notes,
                ''
            )
        ),
        ''
    ) is null
    then
        raise exception
            'Catatan kinerja wajib diisi sebelum jurnal dikirim.';
    end if;


    update
    public.mahad_head_journals

    set
        status =
            'submitted',

        submitted_at =
            now(),

        updated_by_staff_id =
            v_staff_id

    where id =
          p_journal_id;


    return
        public.get_kepala_mahad_journal_detail(
            p_journal_id
        );

end;
$function$;


-- =========================================================
-- 17. PENANGGUNG JAWAB OVERVIEW
-- =========================================================

create or replace function
public.get_penanggung_jawab_mahad_head_journal_overview(
    p_date_from date default null,
    p_date_to date default null
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;
    v_staff_id uuid;

    v_academic_year_id uuid;
    v_academic_year_name text;

    v_date_from date;
    v_date_to date;

    v_items jsonb :=
        '[]'::jsonb;

    v_total_count integer :=
        0;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null
       or not public.has_role(
           'penanggung_jawab'
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Akses monitoring Jurnal Kepala Ma''had ditolak.';
    end if;


    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    inner join public.profiles
        as profile

        on profile.id =
           staff.profile_id

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true

      and profile.is_active =
          true

    limit 1;


    if v_staff_id is null then
        raise exception using
            errcode = '42501',
            message = 'Data Penanggung Jawab aktif tidak ditemukan.';
    end if;


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


    v_date_from :=
        coalesce(
            p_date_from,
            date_trunc(
                'month',
                current_date
            )::date
        );


    v_date_to :=
        coalesce(
            p_date_to,
            current_date
        );


    if v_date_to <
       v_date_from
    then
        raise exception
            'Rentang tanggal tidak valid.';
    end if;


    select
        coalesce(
            jsonb_agg(
                journal_data.payload

                order by
                    journal_data.journal_date desc,
                    journal_data.journal_id desc
            ),
            '[]'::jsonb
        )

    into
        v_items

    from (
        select
            journal.id
                as journal_id,

            journal.journal_date,

            jsonb_build_object(
                'id',
                journal.id,

                'journal_date',
                journal.journal_date,

                'status',
                journal.status,

                'performance_notes',
                journal.performance_notes,

                'obstacles_follow_up',
                journal.obstacles_follow_up,

                'has_evidence',
                journal.evidence_path
                    is not null,

                'evidence_path',
                journal.evidence_path,

                'submitted_at',
                journal.submitted_at,

                'staff',
                jsonb_build_object(
                    'id',
                    staff.id,

                    'full_name',
                    staff.full_name,

                    'position',
                    staff.position
                ),

                'checked_count',
                (
                    select
                        count(*)::integer

                    from public.mahad_head_journal_checks
                        as journal_check

                    where journal_check.journal_id =
                          journal.id
                )
            )
                as payload

        from public.mahad_head_journals
            as journal

        inner join public.staff
            as staff

            on staff.id =
               journal.created_by_staff_id

        where journal.academic_year_id =
              v_academic_year_id

          and journal.status =
              'submitted'

          and journal.journal_date
              between
              v_date_from
              and
              v_date_to
    )
        as journal_data;


    select
        count(*)::integer

    into
        v_total_count

    from public.mahad_head_journals
        as journal

    where journal.academic_year_id =
          v_academic_year_id

      and journal.status =
          'submitted'

      and journal.journal_date
          between
          v_date_from
          and
          v_date_to;


    return jsonb_build_object(
        'academic_year',
        jsonb_build_object(
            'id',
            v_academic_year_id,

            'name',
            v_academic_year_name
        ),

        'filters',
        jsonb_build_object(
            'date_from',
            v_date_from,

            'date_to',
            v_date_to
        ),

        'summary',
        jsonb_build_object(
            'submitted_count',
            v_total_count
        ),

        'items',
        v_items
    );

end;
$function$;


-- =========================================================
-- 18. PENANGGUNG JAWAB DETAIL
-- =========================================================

create or replace function
public.get_penanggung_jawab_mahad_head_journal_detail(
    p_journal_id uuid
)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_journal jsonb;
    v_checklist jsonb :=
        '[]'::jsonb;
begin

    v_profile_id :=
        auth.uid();


    if v_profile_id is null
       or not public.has_role(
           'penanggung_jawab'
       )
    then
        raise exception using
            errcode = '42501',
            message = 'Akses monitoring Jurnal Kepala Ma''had ditolak.';
    end if;


    if not exists (
        select 1

        from public.profiles
            as profile

        inner join public.staff
            as staff

            on staff.profile_id =
               profile.id

        where profile.id =
              v_profile_id

          and profile.is_active =
              true

          and staff.is_active =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Data Penanggung Jawab aktif tidak ditemukan.';
    end if;


    select
        jsonb_build_object(
            'id',
            journal.id,

            'journal_date',
            journal.journal_date,

            'status',
            journal.status,

            'performance_notes',
            journal.performance_notes,

            'obstacles_follow_up',
            journal.obstacles_follow_up,

            'evidence_path',
            journal.evidence_path,

            'has_evidence',
            journal.evidence_path
                is not null,

            'submitted_at',
            journal.submitted_at,

            'staff',
            jsonb_build_object(
                'id',
                staff.id,

                'full_name',
                staff.full_name,

                'position',
                staff.position
            )
        )

    into
        v_journal

    from public.mahad_head_journals
        as journal

    inner join public.staff
        as staff

        on staff.id =
           journal.created_by_staff_id

    inner join public.academic_years
        as academic_year

        on academic_year.id =
           journal.academic_year_id

    where journal.id =
          p_journal_id

      and journal.status =
          'submitted'

      and academic_year.is_current =
          true

    limit 1;


    if v_journal is null then
        raise exception using
            errcode = '42501',
            message = 'Jurnal tidak ditemukan atau belum dikirim.';
    end if;


    select
        coalesce(
            jsonb_agg(
                jsonb_build_object(
                    'id',
                    checklist_item.id,

                    'item_key',
                    checklist_item.item_key,

                    'pillar_code',
                    checklist_item.pillar_code,

                    'pillar_name',
                    checklist_item.pillar_name,

                    'equivalent_jtm',
                    checklist_item.equivalent_jtm,

                    'sort_order',
                    checklist_item.sort_order,

                    'label',
                    checklist_item.label,

                    'is_checked',
                    exists (
                        select 1

                        from public.mahad_head_journal_checks
                            as journal_check

                        where journal_check.journal_id =
                              p_journal_id

                          and journal_check.checklist_item_id =
                              checklist_item.id
                    )
                )

                order by
                    case checklist_item.pillar_code
                        when 'student_care'
                            then 1

                        when 'tahfiz_academic'
                            then 2

                        when 'facilities_digital'
                            then 3

                        when 'administration_staff'
                            then 4

                        else 99
                    end,

                    checklist_item.sort_order
            ),
            '[]'::jsonb
        )

    into
        v_checklist

    from public.mahad_head_journal_checklist_items
        as checklist_item

    where checklist_item.is_active =
          true;


    return jsonb_build_object(
        'journal',
        v_journal,

        'checklist',
        v_checklist
    );

end;
$function$;


-- =========================================================
-- 19. FUNCTION PRIVILEGES
-- =========================================================

revoke all
on function
public.can_access_mahad_head_journal_evidence(
    text,
    boolean
)
from public,
     anon;


grant execute
on function
public.can_access_mahad_head_journal_evidence(
    text,
    boolean
)
to authenticated;


revoke all
on function
public.create_or_open_kepala_mahad_journal(
    date
)
from public,
     anon;


grant execute
on function
public.create_or_open_kepala_mahad_journal(
    date
)
to authenticated;


revoke all
on function
public.get_kepala_mahad_journal_overview(
    date,
    date
)
from public,
     anon;


grant execute
on function
public.get_kepala_mahad_journal_overview(
    date,
    date
)
to authenticated;


revoke all
on function
public.get_kepala_mahad_journal_detail(
    uuid
)
from public,
     anon;


grant execute
on function
public.get_kepala_mahad_journal_detail(
    uuid
)
to authenticated;


revoke all
on function
public.save_kepala_mahad_journal(
    uuid,
    text[],
    text,
    text
)
from public,
     anon;


grant execute
on function
public.save_kepala_mahad_journal(
    uuid,
    text[],
    text,
    text
)
to authenticated;


revoke all
on function
public.attach_kepala_mahad_journal_evidence(
    uuid,
    text
)
from public,
     anon;


grant execute
on function
public.attach_kepala_mahad_journal_evidence(
    uuid,
    text
)
to authenticated;


revoke all
on function
public.submit_kepala_mahad_journal(
    uuid
)
from public,
     anon;


grant execute
on function
public.submit_kepala_mahad_journal(
    uuid
)
to authenticated;


revoke all
on function
public.get_penanggung_jawab_mahad_head_journal_overview(
    date,
    date
)
from public,
     anon;


grant execute
on function
public.get_penanggung_jawab_mahad_head_journal_overview(
    date,
    date
)
to authenticated;


revoke all
on function
public.get_penanggung_jawab_mahad_head_journal_detail(
    uuid
)
from public,
     anon;


grant execute
on function
public.get_penanggung_jawab_mahad_head_journal_detail(
    uuid
)
to authenticated;


commit;