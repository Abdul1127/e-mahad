begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 022-seed-staff-and-assignments-2026-2027.sql
-- PURPOSE:
-- - Memasukkan 12 pengurus unik dari sheet DATA ADMIN
-- - Menggabungkan orang yang mempunyai beberapa peran
-- - Membuat assignment Pengasuh
-- - Membuat assignment Pembina Tahfiz
-- - Belum membuat akun Supabase Auth
-- - Aman dijalankan ulang
-- =========================================================

-- =========================================================
-- 1. VALIDASI STRUKTUR REFERENSI
-- =========================================================

do $$
declare
    academic_year_count integer;
    care_group_count integer;
    tahfiz_group_count integer;
begin
    select count(*)
    into academic_year_count
    from public.academic_years
    where name = '2026/2027'
      and is_current = true;

    if academic_year_count <> 1 then
        raise exception
            'Tahun ajaran aktif 2026/2027 tidak ditemukan atau berjumlah lebih dari satu.';
    end if;

    select count(*)
    into care_group_count
    from public.care_groups as care_group
    inner join public.academic_years as academic_year
        on academic_year.id = care_group.academic_year_id
    where academic_year.name = '2026/2027'
      and academic_year.is_current = true
      and care_group.is_active = true
      and care_group.name in (
          'Pengasuhan Putra',
          'Pengasuhan Putri'
      );

    if care_group_count <> 2 then
        raise exception
            'Kelompok Pengasuhan Putra dan Putri belum lengkap. Ditemukan % kelompok.',
            care_group_count;
    end if;

    select count(*)
    into tahfiz_group_count
    from public.tahfiz_groups as tahfiz_group
    inner join public.academic_years as academic_year
        on academic_year.id = tahfiz_group.academic_year_id
    where academic_year.name = '2026/2027'
      and academic_year.is_current = true
      and tahfiz_group.is_active = true
      and tahfiz_group.name in (
          '7 Putra',
          '7 Putri',
          '8 Putra',
          '8 Putri',
          '9 Putra',
          '9 Putri'
      );

    if tahfiz_group_count <> 6 then
        raise exception
            'Enam kelompok tahfiz belum lengkap. Ditemukan % kelompok.',
            tahfiz_group_count;
    end if;
end;
$$;

-- =========================================================
-- 2. DATA PENGURUS
-- =========================================================

insert into public.staff (
    legacy_staff_id,
    full_name,
    position,
    is_active
)
values
    (
        '22-P-001',
        'Mappataliang, S.Pd.,M.A.,M.Pd.',
        'Kepala Sekolah / Penanggung Jawab',
        true
    ),
    (
        '20-P-002',
        'Hidayati Fauziah',
        'Kepala Ma''had / Ketua Asrama',
        true
    ),
    (
        '20-P-003',
        'Irmawati, S.Pd.,M.Pd.',
        'Bendahara',
        true
    ),
    (
        '22-P-004',
        'Edy Nor Sobah',
        'Pembina Tahfiz',
        true
    ),
    (
        '22-P-005',
        'Dayaneu Permatasari',
        'Pembina Tahfiz',
        true
    ),
    (
        '22-P-006',
        'Farnida',
        'Admin',
        true
    ),
    (
        '24-P-007',
        'Muh Lubis',
        'Pengasuh / Pembina Tahfiz',
        true
    ),
    (
        '24-P-008',
        'Nur Jannah',
        'Pengasuh / Pembina Tahfiz',
        true
    ),
    (
        '25-P-009',
        'Yus Munandar',
        'Pembina Tahfiz',
        true
    ),
    (
        '25-P-010',
        'Devi permatasari',
        'Pengasuh',
        true
    ),
    (
        '25-P-011',
        'Faiz Shodiq',
        'Pembina Tahfiz',
        true
    ),
    (
        '26-P-012',
        'Gusmawati',
        'Pengasuh',
        true
    )

on conflict (legacy_staff_id)
do update set
    full_name = excluded.full_name,
    position = excluded.position,
    is_active = true,
    updated_at = now();

-- =========================================================
-- 3. VALIDASI DATA PENGURUS
-- =========================================================

do $$
declare
    imported_staff_count integer;
begin
    select count(*)
    into imported_staff_count
    from public.staff
    where legacy_staff_id in (
        '22-P-001',
        '20-P-002',
        '20-P-003',
        '22-P-004',
        '22-P-005',
        '22-P-006',
        '24-P-007',
        '24-P-008',
        '25-P-009',
        '25-P-010',
        '25-P-011',
        '26-P-012'
    );

    if imported_staff_count <> 12 then
        raise exception
            'Jumlah pengurus hasil import harus 12, tetapi ditemukan %.',
            imported_staff_count;
    end if;
end;
$$;

-- =========================================================
-- 4. ASSIGNMENT PENGASUH
-- =========================================================

with expected_assignments (
    legacy_staff_id,
    care_group_name
) as (
    values
        (
            '24-P-007',
            'Pengasuhan Putra'
        ),
        (
            '24-P-008',
            'Pengasuhan Putra'
        ),
        (
            '25-P-010',
            'Pengasuhan Putri'
        ),
        (
            '26-P-012',
            'Pengasuhan Putri'
        )
)

insert into public.caregiver_assignments (
    staff_id,
    care_group_id,
    is_primary,
    assigned_at,
    ended_at,
    is_active
)

select
    staff.id,
    care_group.id,
    false,
    date '2026-07-01',
    null,
    true

from expected_assignments as expected

inner join public.staff as staff
    on staff.legacy_staff_id = expected.legacy_staff_id
   and staff.is_active = true

inner join public.care_groups as care_group
    on care_group.name = expected.care_group_name
   and care_group.is_active = true

inner join public.academic_years as academic_year
    on academic_year.id = care_group.academic_year_id
   and academic_year.name = '2026/2027'
   and academic_year.is_current = true

where not exists (
    select 1
    from public.caregiver_assignments as existing_assignment
    where existing_assignment.staff_id = staff.id
      and existing_assignment.care_group_id = care_group.id
      and existing_assignment.is_active = true
);

-- =========================================================
-- 5. ASSIGNMENT PEMBINA TAHFIZ
-- =========================================================

with expected_assignments (
    legacy_staff_id,
    tahfiz_group_name
) as (
    values
        (
            '24-P-007',
            '7 Putra'
        ),
        (
            '24-P-008',
            '7 Putri'
        ),
        (
            '25-P-011',
            '8 Putra'
        ),
        (
            '22-P-004',
            '8 Putri'
        ),
        (
            '25-P-009',
            '9 Putra'
        ),
        (
            '22-P-005',
            '9 Putri'
        )
)

insert into public.tahfiz_supervisor_assignments (
    staff_id,
    tahfiz_group_id,
    is_primary,
    assigned_at,
    ended_at,
    is_active
)

select
    staff.id,
    tahfiz_group.id,
    true,
    date '2026-07-01',
    null,
    true

from expected_assignments as expected

inner join public.staff as staff
    on staff.legacy_staff_id = expected.legacy_staff_id
   and staff.is_active = true

inner join public.tahfiz_groups as tahfiz_group
    on tahfiz_group.name = expected.tahfiz_group_name
   and tahfiz_group.is_active = true

inner join public.academic_years as academic_year
    on academic_year.id = tahfiz_group.academic_year_id
   and academic_year.name = '2026/2027'
   and academic_year.is_current = true

where not exists (
    select 1
    from public.tahfiz_supervisor_assignments
        as existing_assignment
    where existing_assignment.staff_id = staff.id
      and existing_assignment.tahfiz_group_id =
          tahfiz_group.id
      and existing_assignment.is_active = true
);

-- =========================================================
-- 6. VALIDASI ASSIGNMENT DI DALAM TRANSAKSI
-- =========================================================

do $$
declare
    caregiver_assignment_count integer;
    tahfiz_assignment_count integer;
begin
    select count(*)
    into caregiver_assignment_count

    from public.caregiver_assignments as assignment

    inner join public.staff as staff
        on staff.id = assignment.staff_id

    inner join public.care_groups as care_group
        on care_group.id = assignment.care_group_id

    where assignment.is_active = true
      and (
          staff.legacy_staff_id,
          care_group.name
      ) in (
          (
              '24-P-007',
              'Pengasuhan Putra'
          ),
          (
              '24-P-008',
              'Pengasuhan Putra'
          ),
          (
              '25-P-010',
              'Pengasuhan Putri'
          ),
          (
              '26-P-012',
              'Pengasuhan Putri'
          )
      );

    if caregiver_assignment_count <> 4 then
        raise exception
            'Assignment Pengasuh harus berjumlah 4, tetapi ditemukan %.',
            caregiver_assignment_count;
    end if;

    select count(*)
    into tahfiz_assignment_count

    from public.tahfiz_supervisor_assignments
        as assignment

    inner join public.staff as staff
        on staff.id = assignment.staff_id

    inner join public.tahfiz_groups as tahfiz_group
        on tahfiz_group.id = assignment.tahfiz_group_id

    where assignment.is_active = true
      and assignment.is_primary = true
      and (
          staff.legacy_staff_id,
          tahfiz_group.name
      ) in (
          (
              '24-P-007',
              '7 Putra'
          ),
          (
              '24-P-008',
              '7 Putri'
          ),
          (
              '25-P-011',
              '8 Putra'
          ),
          (
              '22-P-004',
              '8 Putri'
          ),
          (
              '25-P-009',
              '9 Putra'
          ),
          (
              '22-P-005',
              '9 Putri'
          )
      );

    if tahfiz_assignment_count <> 6 then
        raise exception
            'Assignment Pembina Tahfiz harus berjumlah 6, tetapi ditemukan %.',
            tahfiz_assignment_count;
    end if;
end;
$$;

commit;