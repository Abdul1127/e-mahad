begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 094-create-care-journal-structure.sql
--
-- PURPOSE:
-- - Membuat fondasi Jurnal Pengasuhan
-- - Satu jurnal per kelompok + tanggal + sesi
-- - Detail jurnal per santri
-- - Riwayat review Kepala Ma'had
-- - Mendukung revisi tanpa menghapus history review
--
-- SECURITY:
-- - RLS diaktifkan
-- - authenticated/anon tidak mendapat direct table access
-- - akses aplikasi nanti melalui SECURITY DEFINER RPC
-- =========================================================


-- =========================================================
-- 1. CARE JOURNALS
-- =========================================================

create table public.care_journals (
    id uuid primary key
        default gen_random_uuid(),

    care_group_id uuid not null
        references public.care_groups(id)
        on update cascade
        on delete restrict,

    journal_date date not null,

    session text not null,

    status text not null
        default 'draft',

    submission_version integer not null
        default 0,

    created_by_staff_id uuid not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    updated_by_staff_id uuid not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    submitted_by_staff_id uuid
        references public.staff(id)
        on update cascade
        on delete restrict,

    submitted_at timestamptz,

    last_reviewed_at timestamptz,

    created_at timestamptz not null
        default now(),

    updated_at timestamptz not null
        default now(),

    constraint care_journals_session_check
        check (
            session in (
                'morning',
                'evening'
            )
        ),

    constraint care_journals_status_check
        check (
            status in (
                'draft',
                'submitted',
                'revision_requested',
                'reviewed'
            )
        ),

    constraint care_journals_submission_version_check
        check (
            submission_version >= 0
        ),

    constraint care_journals_group_date_session_unique
        unique (
            care_group_id,
            journal_date,
            session
        )
);


comment on table
public.care_journals
is
'Header Jurnal Pengasuhan. Satu jurnal mewakili satu kelompok pengasuhan, satu tanggal, dan satu sesi pagi/sore.';


comment on column
public.care_journals.session
is
'Waktu jurnal: morning = pagi, evening = sore.';


comment on column
public.care_journals.status
is
'Workflow jurnal: draft, submitted, revision_requested, reviewed. Status reviewed tidak berarti jurnal terkunci permanen.';


comment on column
public.care_journals.submission_version
is
'Nomor versi pengiriman jurnal. Bertambah setiap jurnal dikirim ulang untuk review.';


create index
care_journals_group_date_idx
on public.care_journals (
    care_group_id,
    journal_date desc
);


create index
care_journals_status_date_idx
on public.care_journals (
    status,
    journal_date desc
);


create index
care_journals_created_by_staff_idx
on public.care_journals (
    created_by_staff_id,
    journal_date desc
);


create trigger
set_care_journals_updated_at

before update
on public.care_journals

for each row

execute function
public.set_updated_at();


-- =========================================================
-- 2. CARE JOURNAL ENTRIES
-- =========================================================

create table public.care_journal_entries (
    id uuid primary key
        default gen_random_uuid(),

    journal_id uuid not null
        references public.care_journals(id)
        on update cascade
        on delete cascade,

    student_id uuid not null
        references public.students(id)
        on update cascade
        on delete restrict,

    health_condition text,

    sleep_compliance text,

    psychological_condition text,

    parent_visit boolean,

    case_notes text,

    handling_notes text,

    updated_by_staff_id uuid
        references public.staff(id)
        on update cascade
        on delete restrict,

    created_at timestamptz not null
        default now(),

    updated_at timestamptz not null
        default now(),

    constraint care_journal_entries_journal_student_unique
        unique (
            journal_id,
            student_id
        ),

    constraint care_journal_entries_health_condition_check
        check (
            health_condition is null
            or health_condition in (
                'healthy',
                'unwell'
            )
        ),

    constraint care_journal_entries_sleep_compliance_check
        check (
            sleep_compliance is null
            or sleep_compliance in (
                'on_time',
                'needs_reminder'
            )
        ),

    constraint care_journal_entries_psychological_condition_check
        check (
            psychological_condition is null
            or psychological_condition in (
                'cheerful',
                'gloomy',
                'quiet',
                'homesick',
                'emotional'
            )
        )
);


comment on table
public.care_journal_entries
is
'Catatan kondisi masing-masing santri dalam satu Jurnal Pengasuhan. Field kondisi diperbolehkan NULL selama jurnal masih draft.';


comment on column
public.care_journal_entries.health_condition
is
'healthy = Sehat, unwell = Kurang Fit.';


comment on column
public.care_journal_entries.sleep_compliance
is
'on_time = Tepat Waktu, needs_reminder = Perlu Teguran.';


comment on column
public.care_journal_entries.psychological_condition
is
'Kondisi psikologis santri: cheerful, gloomy, quiet, homesick, emotional.';


comment on column
public.care_journal_entries.parent_visit
is
'TRUE apabila terdapat kunjungan orang tua/wali pada sesi jurnal. NULL berarti data belum diisi.';


comment on column
public.care_journal_entries.case_notes
is
'Catatan kejadian, kasus, atau kondisi khusus santri.';


comment on column
public.care_journal_entries.handling_notes
is
'Catatan solusi atau tindakan penanganan yang dilakukan Pengasuh.';


create index
care_journal_entries_journal_idx
on public.care_journal_entries (
    journal_id
);


create index
care_journal_entries_student_idx
on public.care_journal_entries (
    student_id,
    created_at desc
);


create trigger
set_care_journal_entries_updated_at

before update
on public.care_journal_entries

for each row

execute function
public.set_updated_at();


-- =========================================================
-- 3. CARE JOURNAL REVIEWS
-- =========================================================

create table public.care_journal_reviews (
    id uuid primary key
        default gen_random_uuid(),

    journal_id uuid not null
        references public.care_journals(id)
        on update cascade
        on delete cascade,

    reviewer_staff_id uuid not null
        references public.staff(id)
        on update cascade
        on delete restrict,

    submission_version integer not null,

    action text not null,

    note text,

    created_at timestamptz not null
        default now(),

    constraint care_journal_reviews_submission_version_check
        check (
            submission_version > 0
        ),

    constraint care_journal_reviews_action_check
        check (
            action in (
                'reviewed',
                'revision_requested'
            )
        ),

    constraint care_journal_reviews_revision_note_check
        check (
            action <> 'revision_requested'

            or nullif(
                btrim(note),
                ''
            ) is not null
        )
);


comment on table
public.care_journal_reviews
is
'Riwayat review Jurnal Pengasuhan oleh Kepala Ma''had. History tidak dihapus ketika jurnal direvisi atau dikirim ulang.';


comment on column
public.care_journal_reviews.submission_version
is
'Versi submission jurnal yang sedang direview.';


comment on column
public.care_journal_reviews.action
is
'reviewed = diterima/review selesai, revision_requested = diminta revisi.';


create index
care_journal_reviews_journal_idx
on public.care_journal_reviews (
    journal_id,
    created_at desc
);


create index
care_journal_reviews_reviewer_idx
on public.care_journal_reviews (
    reviewer_staff_id,
    created_at desc
);


create index
care_journal_reviews_action_idx
on public.care_journal_reviews (
    action,
    created_at desc
);


-- =========================================================
-- 4. ENABLE ROW LEVEL SECURITY
-- =========================================================

alter table
public.care_journals
enable row level security;


alter table
public.care_journal_entries
enable row level security;


alter table
public.care_journal_reviews
enable row level security;


-- =========================================================
-- 5. BLOCK DIRECT CLIENT TABLE ACCESS
--
-- Aplikasi tidak membaca/menulis tabel jurnal secara
-- langsung.
--
-- RPC SECURITY DEFINER yang akan kita buat pada tahap
-- berikutnya menjadi pintu akses utama.
-- =========================================================

revoke all
on table public.care_journals
from public;


revoke all
on table public.care_journals
from anon;


revoke all
on table public.care_journals
from authenticated;


revoke all
on table public.care_journal_entries
from public;


revoke all
on table public.care_journal_entries
from anon;


revoke all
on table public.care_journal_entries
from authenticated;


revoke all
on table public.care_journal_reviews
from public;


revoke all
on table public.care_journal_reviews
from anon;


revoke all
on table public.care_journal_reviews
from authenticated;


-- =========================================================
-- 6. SERVICE ROLE
-- =========================================================

grant
    select,
    insert,
    update,
    delete

on table
public.care_journals

to service_role;


grant
    select,
    insert,
    update,
    delete

on table
public.care_journal_entries

to service_role;


grant
    select,
    insert,
    update,
    delete

on table
public.care_journal_reviews

to service_role;


commit;