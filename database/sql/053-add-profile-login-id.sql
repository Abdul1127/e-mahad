begin;

-- =========================================================
-- E-MA'HAD DATABASE
-- FILE:
-- 053-add-profile-login-id.sql
--
-- PURPOSE:
-- - Menambahkan login_id pada profiles
-- - Menormalisasi format login ID
-- - Memberikan login ID kepada akun existing
-- - Menjamin login ID unik tanpa membedakan kapital
--
-- CATATAN:
-- - Belum mengubah email pada Supabase Auth
-- - Login lama masih tetap dapat digunakan
-- - login_id masih nullable agar alur pembuatan akun
--   existing tidak langsung rusak sebelum frontend diperbarui
-- =========================================================


-- =========================================================
-- 1. FUNGSI NORMALISASI LOGIN ID
-- =========================================================

create or replace function
public.normalize_login_id(
    p_login_id text
)
returns text
language sql
immutable
strict
set search_path = ''
as $$
    select trim(
        both '-'
        from regexp_replace(
            upper(
                btrim(p_login_id)
            ),
            '[^A-Z0-9]+',
            '-',
            'g'
        )
    );
$$;


comment on function
public.normalize_login_id(text)
is
'Menormalisasi login ID menjadi huruf kapital, angka, dan tanda hubung.';


-- =========================================================
-- 2. TAMBAHKAN KOLOM LOGIN ID
-- =========================================================

alter table public.profiles
add column if not exists login_id text;


comment on column
public.profiles.login_id
is
'ID yang digunakan pengguna untuk login, misalnya ADM-001, STF-24-P-007, atau ORT-247201-01.';


-- =========================================================
-- 3. CONSTRAINT FORMAT LOGIN ID
-- =========================================================

do $constraint$
begin
    if not exists (
        select 1

        from pg_constraint

        where conname =
              'profiles_login_id_format_check'

          and conrelid =
              'public.profiles'::regclass
    ) then
        alter table public.profiles

        add constraint
        profiles_login_id_format_check

        check (
            login_id is null

            or (
                char_length(login_id)
                    between 3 and 64

                and login_id =
                    public.normalize_login_id(
                        login_id
                    )

                and login_id ~
                    '^[A-Z0-9]+(-[A-Z0-9]+)*$'
            )
        );
    end if;
end;
$constraint$;


-- =========================================================
-- 4. UNIQUE INDEX CASE-INSENSITIVE
-- =========================================================

create unique index if not exists
profiles_login_id_lower_unique
on public.profiles (
    lower(login_id)
)
where login_id is not null;


-- =========================================================
-- 5. IDENTIFIKASI AKUN ADMIN
-- =========================================================

with admin_accounts as (
    select
        profile.id
            as profile_id,

        row_number() over (
            order by
                profile.created_at,
                profile.id
        ) as account_order

    from public.profiles as profile

    where exists (
        select 1

        from public.user_roles
            as user_role

        inner join public.roles as role
            on role.id =
               user_role.role_id

        where user_role.user_id =
              profile.id

          and role.code =
              'admin'
    )
)

update public.profiles as profile

set
    login_id =
        concat(
            'ADM-',
            lpad(
                admin_account.account_order::text,
                3,
                '0'
            )
        ),

    updated_at =
        now()

from admin_accounts as admin_account

where profile.id =
      admin_account.profile_id

  and profile.login_id is null;


-- =========================================================
-- 6. IDENTIFIKASI AKUN STAF
-- =========================================================

with staff_accounts as (
    select distinct on (
        staff.profile_id
    )
        staff.profile_id,

        concat(
            'STF-',
            public.normalize_login_id(
                staff.legacy_staff_id
            )
        ) as candidate_login_id

    from public.staff as staff

    where staff.profile_id is not null

      and staff.legacy_staff_id
          is not null

      and btrim(
          staff.legacy_staff_id
      ) <> ''

    order by
        staff.profile_id,
        staff.created_at,
        staff.id
)

update public.profiles as profile

set
    login_id =
        staff_account.candidate_login_id,

    updated_at =
        now()

from staff_accounts as staff_account

where profile.id =
      staff_account.profile_id

  and profile.login_id is null;


-- =========================================================
-- 7. AMBIL SUMBER NIS/ID SANTRI UNTUK WALI
-- =========================================================

with guardian_child_seed as (
    select
        guardian.id
            as guardian_id,

        min(
            student.legacy_student_id
        ) filter (
            where student.legacy_student_id
                  is not null

              and btrim(
                  student.legacy_student_id
              ) <> ''
        ) as student_seed

    from public.guardians as guardian

    left join public.guardian_students
        as guardian_student
        on guardian_student.guardian_id =
           guardian.id

    left join public.students as student
        on student.id =
           guardian_student.student_id

    group by
        guardian.id
),

guardian_ranked as (
    select
        guardian.id
            as guardian_id,

        guardian.profile_id,
        guardian.legacy_guardian_id,
        guardian.created_at,

        child_seed.student_seed,

        case
            when child_seed.student_seed
                 is not null
                then row_number() over (
                    partition by
                        child_seed.student_seed

                    order by
                        guardian.created_at,
                        guardian.id
                )

            else null
        end as guardian_order

    from public.guardians as guardian

    left join guardian_child_seed
        as child_seed
        on child_seed.guardian_id =
           guardian.id
),

guardian_accounts as (
    select
        guardian.profile_id,

        case
            when guardian.student_seed
                 is not null
                then concat(
                    'ORT-',

                    public.normalize_login_id(
                        guardian.student_seed
                    ),

                    '-',

                    lpad(
                        guardian.guardian_order::text,
                        2,
                        '0'
                    )
                )

            when guardian.legacy_guardian_id
                 is not null

                 and btrim(
                     guardian.legacy_guardian_id
                 ) <> ''
                then concat(
                    'ORT-',

                    public.normalize_login_id(
                        guardian.legacy_guardian_id
                    )
                )

            else concat(
                'ORT-',

                upper(
                    guardian.guardian_id::text
                )
            )
        end as candidate_login_id

    from guardian_ranked as guardian

    where guardian.profile_id is not null
)

update public.profiles as profile

set
    login_id =
        guardian_account.candidate_login_id,

    updated_at =
        now()

from guardian_accounts
    as guardian_account

where profile.id =
      guardian_account.profile_id

  and profile.login_id is null;


-- =========================================================
-- 8. FALLBACK UNTUK PROFILE LAIN
-- =========================================================

update public.profiles as profile

set
    login_id =
        concat(
            'USR-',
            upper(
                profile.id::text
            )
        ),

    updated_at =
        now()

where profile.login_id is null;


commit;


-- =========================================================
-- 9. HASIL MIGRASI
-- =========================================================

select
    profile.id
        as profile_id,

    profile.full_name,
    profile.login_id,

    auth_user.email::text
        as current_auth_email,

    concat(
        lower(profile.login_id),
        '@login.emahad.id'
    ) as future_internal_auth_email,

    profile.is_active,

    coalesce(
        jsonb_agg(
            distinct jsonb_build_object(
                'code',
                role.code,

                'name',
                role.name
            )
        ) filter (
            where role.id is not null
        ),
        '[]'::jsonb
    ) as roles

from public.profiles as profile

inner join auth.users as auth_user
    on auth_user.id =
       profile.id

left join public.user_roles as user_role
    on user_role.user_id =
       profile.id

left join public.roles as role
    on role.id =
       user_role.role_id

group by
    profile.id,
    profile.full_name,
    profile.login_id,
    auth_user.email,
    profile.is_active

order by
    profile.login_id;