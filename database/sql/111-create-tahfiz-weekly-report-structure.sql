begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 111-create-tahfiz-weekly-report-structure.sql
--
-- PURPOSE:
-- - Struktur Laporan Tahfiz Mingguan per santri
-- - Satu santri hanya memiliki satu laporan per pekan
-- - Mendukung Draft dan Published
-- - Published nantinya dapat ditampilkan kepada Orang Tua
--
-- REPORT CONTENT:
-- - Hafalan baru
-- - Murajaah
-- - Kelancaran
-- - Tajwid
-- - Konsistensi
-- - Catatan Pembina
-- - Target pekan berikutnya
--
-- SECURITY:
-- - RLS enabled
-- - Tidak ada direct access authenticated
-- - Akses aplikasi nantinya melalui SECURITY DEFINER RPC
-- =========================================================


-- =========================================================
-- 1. TABLE
-- =========================================================

create table if not exists
public.tahfiz_weekly_reports (
    id uuid
        primary key
        default gen_random_uuid(),

    academic_year_id uuid
        not null
        references public.academic_years(id)
        on update cascade
        on delete restrict,

    tahfiz_group_id uuid
        not null
        references public.tahfiz_groups(id)
        on update cascade
        on delete restrict,

    student_id uuid
        not null
        references public.students(id)
        on update cascade
        on delete restrict,

    week_start date
        not null,

    week_end date
        not null,

    -- =====================================================
    -- REPORT CONTENT
    -- =====================================================

    memorization_achievement text
        null,

    murajaah_achievement text
        null,

    fluency_rating text
        null,

    tajwid_rating text
        null,

    consistency_rating text
        null,

    supervisor_notes text
        null,

    next_week_target text
        null,

    -- =====================================================
    -- WORKFLOW
    -- =====================================================

    status text
        not null
        default 'draft',

    published_at timestamptz
        null,

    published_by_staff_id uuid
        null
        references public.staff(id)
        on update cascade
        on delete restrict,

    -- =====================================================
    -- AUDIT
    -- =====================================================

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

    created_at timestamptz
        not null
        default now(),

    updated_at timestamptz
        not null
        default now(),

    -- =====================================================
    -- CONSTRAINTS
    -- =====================================================

    constraint tahfiz_weekly_reports_valid_week
        check (
            week_end =
            week_start + 6
        ),

    constraint tahfiz_weekly_reports_week_starts_monday
        check (
            extract(
                isodow
                from week_start
            ) = 1
        ),

    constraint tahfiz_weekly_reports_status_check
        check (
            status in (
                'draft',
                'published'
            )
        ),

    constraint tahfiz_weekly_reports_fluency_rating_check
        check (
            fluency_rating is null

            or fluency_rating in (
                'excellent',
                'good',
                'fair',
                'needs_guidance'
            )
        ),

    constraint tahfiz_weekly_reports_tajwid_rating_check
        check (
            tajwid_rating is null

            or tajwid_rating in (
                'excellent',
                'good',
                'fair',
                'needs_guidance'
            )
        ),

    constraint tahfiz_weekly_reports_consistency_rating_check
        check (
            consistency_rating is null

            or consistency_rating in (
                'excellent',
                'good',
                'fair',
                'needs_guidance'
            )
        ),

    constraint tahfiz_weekly_reports_publication_consistency
        check (
            (
                status = 'draft'

                and published_at
                    is null

                and published_by_staff_id
                    is null
            )

            or

            (
                status = 'published'

                and published_at
                    is not null

                and published_by_staff_id
                    is not null
            )
        ),

    constraint tahfiz_weekly_reports_student_week_unique
        unique (
            student_id,
            academic_year_id,
            week_start
        )
);


-- =========================================================
-- 2. INDEXES
-- =========================================================

create index if not exists
idx_tahfiz_weekly_reports_student_week
on public.tahfiz_weekly_reports (
    student_id,
    week_start desc
);


create index if not exists
idx_tahfiz_weekly_reports_group_week
on public.tahfiz_weekly_reports (
    tahfiz_group_id,
    week_start desc
);


create index if not exists
idx_tahfiz_weekly_reports_academic_year_week
on public.tahfiz_weekly_reports (
    academic_year_id,
    week_start desc
);


create index if not exists
idx_tahfiz_weekly_reports_status_week
on public.tahfiz_weekly_reports (
    status,
    week_start desc
);


create index if not exists
idx_tahfiz_weekly_reports_published
on public.tahfiz_weekly_reports (
    published_at desc
)
where status = 'published';


-- =========================================================
-- 3. UPDATED_AT TRIGGER
-- =========================================================

drop trigger if exists
set_tahfiz_weekly_reports_updated_at
on public.tahfiz_weekly_reports;


create trigger
set_tahfiz_weekly_reports_updated_at
before update
on public.tahfiz_weekly_reports
for each row
execute function
public.set_updated_at();


-- =========================================================
-- 4. ROW LEVEL SECURITY
-- =========================================================

alter table
public.tahfiz_weekly_reports
enable row level security;


-- =========================================================
-- 5. PRIVILEGES
--
-- Application will use SECURITY DEFINER RPCs.
-- No direct table CRUD for authenticated users.
-- =========================================================

revoke all
on public.tahfiz_weekly_reports
from public;


revoke all
on public.tahfiz_weekly_reports
from anon;


revoke all
on public.tahfiz_weekly_reports
from authenticated;


grant
select,
insert,
update,
delete
on public.tahfiz_weekly_reports
to service_role;


-- =========================================================
-- 6. COMMENTS
-- =========================================================

comment on table
public.tahfiz_weekly_reports
is
'Laporan Tahfiz individual per santri per pekan. Draft hanya dikelola Pembina Tahfiz; laporan published nantinya dapat ditampilkan kepada Orang Tua.';


comment on column
public.tahfiz_weekly_reports.memorization_achievement
is
'Capaian hafalan baru santri pada pekan tersebut dalam format teks fleksibel.';


comment on column
public.tahfiz_weekly_reports.murajaah_achievement
is
'Capaian murajaah santri pada pekan tersebut dalam format teks fleksibel.';


comment on column
public.tahfiz_weekly_reports.fluency_rating
is
'Penilaian kelancaran: excellent, good, fair, needs_guidance.';


comment on column
public.tahfiz_weekly_reports.tajwid_rating
is
'Penilaian tajwid: excellent, good, fair, needs_guidance.';


comment on column
public.tahfiz_weekly_reports.consistency_rating
is
'Penilaian konsistensi: excellent, good, fair, needs_guidance.';


comment on column
public.tahfiz_weekly_reports.supervisor_notes
is
'Catatan evaluasi Pembina Tahfiz untuk santri.';


comment on column
public.tahfiz_weekly_reports.next_week_target
is
'Target Tahfiz untuk pekan berikutnya.';


commit;