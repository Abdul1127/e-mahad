begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE: 018-correct-student-staging-gender.sql
-- PURPOSE:
-- - Memperbaiki empat gender berdasarkan hasil konfirmasi
-- - Tidak mengubah nama, kelas, atau kelompok tahfiz
-- =========================================================

update staging.student_import_rows
set gender_code = case legacy_student_id
    when '247211' then 'P' -- Firdiana Ayuwandari
    when '247112' then 'L' -- Hutamalaki Alrizky Hasyim
    when '257134' then 'L' -- Rukyatul Hilal Aswan
    when '267203' then 'P' -- Abiyadu Nurnisa
    else gender_code
end
where batch_code = '2026-2027-initial'
  and legacy_student_id in (
      '247211',
      '247112',
      '257134',
      '267203'
  );

-- =========================================================
-- VALIDASI KOREKSI
-- =========================================================

do $$
declare
    corrected_student_count integer;
    remaining_mismatch_count integer;
begin
    select count(*)
    into corrected_student_count
    from staging.student_import_rows
    where batch_code = '2026-2027-initial'
      and (
          (
              legacy_student_id = '247211'
              and upper(btrim(gender_code)) = 'P'
          )
          or (
              legacy_student_id = '247112'
              and upper(btrim(gender_code)) = 'L'
          )
          or (
              legacy_student_id = '257134'
              and upper(btrim(gender_code)) = 'L'
          )
          or (
              legacy_student_id = '267203'
              and upper(btrim(gender_code)) = 'P'
          )
      );

    if corrected_student_count <> 4 then
        raise exception
            'Koreksi gender tidak lengkap. Hanya % dari 4 data yang sesuai.',
            corrected_student_count;
    end if;

    select count(*)
    into remaining_mismatch_count
    from staging.student_import_rows
    where batch_code = '2026-2027-initial'
      and (
          (
              upper(
                  regexp_replace(
                      btrim(tahfiz_group_name),
                      '\s+',
                      ' ',
                      'g'
                  )
              ) like '% PUTRA'
              and upper(btrim(gender_code)) <> 'L'
          )
          or (
              upper(
                  regexp_replace(
                      btrim(tahfiz_group_name),
                      '\s+',
                      ' ',
                      'g'
                  )
              ) like '% PUTRI'
              and upper(btrim(gender_code)) <> 'P'
          )
      );

    if remaining_mismatch_count > 0 then
        raise exception
            'Masih ditemukan % ketidaksesuaian gender dan kelompok tahfiz.',
            remaining_mismatch_count;
    end if;
end;
$$;

commit;