begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 098-create-pengasuh-journal-normal-fill.sql
--
-- PURPOSE:
-- - Mengisi kondisi normal untuk entry jurnal yang
--   masih belum lengkap
-- - Tidak menimpa nilai yang sudah pernah diisi
-- - Menambahkan entry apabila ada santri aktif yang
--   belum terdapat dalam jurnal
--
-- DEFAULT:
-- health_condition          = healthy
-- sleep_compliance          = on_time
-- psychological_condition   = cheerful
-- parent_visit              = false
--
-- SECURITY:
-- - Berdasarkan auth.uid()
-- - Hanya role Pengasuh aktif
-- - Hanya jurnal kelompok assignment Pengasuh
-- - Jurnal submitted tidak dapat diubah
-- =========================================================


create or replace function
public.fill_normal_pengasuh_journal_entries(
    p_journal_id uuid
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
    v_profile_id uuid;

    v_staff_id uuid;

    v_care_group_id uuid;

    v_journal_status text;

    v_new_status text;

    v_inserted_count integer := 0;

    v_updated_count integer := 0;

    v_total_entry_count integer := 0;

    v_complete_entry_count integer := 0;
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


    if not public.has_role(
        'pengasuh'
    ) then
        raise exception using
            errcode = '42501',
            message = 'Akses pengisian Jurnal Pengasuhan ditolak.';
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
            message = 'Profile Pengasuh tidak aktif.';
    end if;


    -- =====================================================
    -- B. STAFF
    -- =====================================================

    select
        staff.id

    into
        v_staff_id

    from public.staff
        as staff

    where staff.profile_id =
          v_profile_id

      and staff.is_active =
          true;


    if not found then
        raise exception
            'Data staf aktif untuk akun Pengasuh tidak ditemukan.';
    end if;


    -- =====================================================
    -- C. INPUT
    -- =====================================================

    if p_journal_id is null then
        raise exception
            'Journal ID wajib diisi.';
    end if;


    -- =====================================================
    -- D. LOCK JOURNAL
    -- =====================================================

    select
        journal.care_group_id,
        journal.status

    into
        v_care_group_id,
        v_journal_status

    from public.care_journals
        as journal

    where journal.id =
          p_journal_id

    for update;


    if not found then
        raise exception
            'Jurnal Pengasuhan tidak ditemukan.';
    end if;


    -- =====================================================
    -- E. ASSIGNMENT AUTHORIZATION
    -- =====================================================

    if not exists (
        select 1

        from public.caregiver_assignments
            as assignment

        inner join public.care_groups
            as care_group
            on care_group.id =
               assignment.care_group_id

        inner join public.academic_years
            as academic_year
            on academic_year.id =
               care_group.academic_year_id

        where assignment.staff_id =
              v_staff_id

          and assignment.care_group_id =
              v_care_group_id

          and assignment.is_active =
              true

          and care_group.is_active =
              true

          and academic_year.is_current =
              true
    ) then
        raise exception using
            errcode = '42501',
            message = 'Jurnal berada di luar assignment Pengasuh.';
    end if;


    -- =====================================================
    -- F. SUBMITTED = TEMPORARY LOCK
    -- =====================================================

    if v_journal_status =
       'submitted'
    then
        raise exception
            'Jurnal sedang menunggu review Kepala Ma''had dan belum dapat diedit.';
    end if;


    -- =====================================================
    -- G. SYNC MISSING CURRENT STUDENTS
    --
    -- Kalau setelah jurnal dibuat ada santri aktif yang
    -- belum mempunyai entry, tambahkan secara otomatis.
    -- =====================================================

    insert into public.care_journal_entries (
        journal_id,
        student_id,
        updated_by_staff_id
    )

    select
        p_journal_id,
        membership.student_id,
        v_staff_id

    from public.care_group_members
        as membership

    inner join public.students
        as student
        on student.id =
           membership.student_id

    where membership.care_group_id =
          v_care_group_id

      and membership.is_active =
          true

      and student.status =
          'active'

      and student.deleted_at
          is null

      and not exists (
          select 1

          from public.care_journal_entries
              as entry

          where entry.journal_id =
                p_journal_id

            and entry.student_id =
                membership.student_id
      )

    on conflict (
        journal_id,
        student_id
    )
    do nothing;


    get diagnostics
        v_inserted_count =
            row_count;


    -- =====================================================
    -- H. FILL ONLY MISSING REQUIRED VALUES
    --
    -- COALESCE memastikan nilai khusus yang sudah pernah
    -- diisi tidak tertimpa kondisi normal.
    -- =====================================================

    update public.care_journal_entries
        as entry

    set
        health_condition =
            coalesce(
                entry.health_condition,
                'healthy'
            ),

        sleep_compliance =
            coalesce(
                entry.sleep_compliance,
                'on_time'
            ),

        psychological_condition =
            coalesce(
                entry.psychological_condition,
                'cheerful'
            ),

        parent_visit =
            coalesce(
                entry.parent_visit,
                false
            ),

        updated_by_staff_id =
            v_staff_id

    where entry.journal_id =
          p_journal_id

      and (
          entry.health_condition
              is null

          or entry.sleep_compliance
              is null

          or entry.psychological_condition
              is null

          or entry.parent_visit
              is null
      )

      and exists (
          select 1

          from public.care_group_members
              as membership

          inner join public.students
              as student
              on student.id =
                 membership.student_id

          where membership.care_group_id =
                v_care_group_id

            and membership.student_id =
                entry.student_id

            and membership.is_active =
                true

            and student.status =
                'active'

            and student.deleted_at
                is null
      );


    get diagnostics
        v_updated_count =
            row_count;


    -- =====================================================
    -- I. STATUS AFTER CHANGES
    --
    -- Kalau jurnal pernah revision_requested/reviewed dan
    -- terdapat perubahan, status kembali ke draft.
    -- =====================================================

    if (
        v_inserted_count > 0

        or v_updated_count > 0
    ) then

        if v_journal_status in (
            'revision_requested',
            'reviewed'
        ) then
            v_new_status :=
                'draft';
        else
            v_new_status :=
                v_journal_status;
        end if;


        update public.care_journals

        set
            status =
                v_new_status,

            updated_by_staff_id =
                v_staff_id,

            submitted_by_staff_id =
                case
                    when v_new_status =
                         'draft'
                    then null
                    else submitted_by_staff_id
                end,

            submitted_at =
                case
                    when v_new_status =
                         'draft'
                    then null
                    else submitted_at
                end

        where id =
              p_journal_id;

    else

        v_new_status :=
            v_journal_status;

    end if;


    -- =====================================================
    -- J. FINAL COUNTS
    -- =====================================================

    select
        count(*)::integer,

        count(*) filter (
            where entry.health_condition
                  is not null

              and entry.sleep_compliance
                  is not null

              and entry.psychological_condition
                  is not null

              and entry.parent_visit
                  is not null
        )::integer

    into
        v_total_entry_count,
        v_complete_entry_count

    from public.care_journal_entries
        as entry

    where entry.journal_id =
          p_journal_id;


    -- =====================================================
    -- K. RESPONSE
    -- =====================================================

    return jsonb_build_object(
        'success',
        true,

        'journal_id',
        p_journal_id,

        'status',
        v_new_status,

        'inserted_entry_count',
        coalesce(
            v_inserted_count,
            0
        ),

        'filled_entry_count',
        coalesce(
            v_updated_count,
            0
        ),

        'total_entry_count',
        coalesce(
            v_total_entry_count,
            0
        ),

        'complete_entry_count',
        coalesce(
            v_complete_entry_count,
            0
        )
    );

end;
$function$;


comment on function
public.fill_normal_pengasuh_journal_entries(uuid)
is
'Mengisi nilai kondisi normal pada field wajib Jurnal Pengasuhan yang masih kosong tanpa menimpa data yang sudah diisi. Scope ditentukan dari auth.uid() dan assignment Pengasuh.';


-- =========================================================
-- PRIVILEGES
-- =========================================================

revoke all on function
public.fill_normal_pengasuh_journal_entries(uuid)
from public;


revoke all on function
public.fill_normal_pengasuh_journal_entries(uuid)
from anon;


grant execute on function
public.fill_normal_pengasuh_journal_entries(uuid)
to authenticated;


commit;